# frozen_string_literal: true

RSpec.describe TTY::Runner do
  let(:output) { StringIO.new }

  context "matching commands with runnable procs" do
    before do
      stub_const("A", Class.new(TTY::Runner) do
        commands do
          run { |out| out.puts "running root" }

          on "foo" do
            on "foo", run: ->(out) { out.puts "running foo foo" }

            on "bar" do
              run { |out| out.puts "running foo bar" }

              on "baz" do
                run { |out| out.puts "running foo bar baz" }
              end
            end
          end

          on "bar" do
            run { |out| out.puts "running bar" }
          end
        end
      end)
    end

    it "matches no commands" do
      A.run([], output: output)
      output.rewind
      expect(output.string).to eq("running root\n")
    end

    it "shows available 'foo' subcommands when no runnable found" do
      A.run(%w[foo], output: output)
      output.rewind
      expect(output.string).to eq([
        "Commands:",
        "  foo bar",
        "  foo foo\n"
      ].join("\n"))
    end

    it "matches top level 'bar' command" do
      A.run(%w[bar], output: output)
      output.rewind
      expect(output.string).to eq("running bar\n")
    end

    it "matches similarly named nested 'foo' subcommand" do
      A.run(%w[foo foo], output: output)
      output.rewind
      expect(output.string).to eq("running foo foo\n")
    end

    it "matches one level deep 'bar' subcommand" do
      A.run(%w[foo bar], output: output)
      output.rewind
      expect(output.string).to eq("running foo bar\n")
    end

    it "matches two levels deep 'baz' subcommand" do
      A.run(%w[foo bar baz], output: output)
      output.rewind
      expect(output.string).to eq("running foo bar baz\n")
    end

    it "consumes only matching argument on top level" do
      A.run(%w[bar extra], output: output)
      output.rewind
      expect(output.string).to eq("running bar\n")
    end

    it "consumes only matching arguments one level deep" do
      A.run(%w[foo bar extra], output: output)
      output.rewind
      expect(output.string).to eq("Command 'foo bar extra' not found\n")
    end

    it "consumes only matching arguments two levels deep" do
      A.run(%w[foo bar baz extra], output: output)
      output.rewind
      expect(output.string).to eq("running foo bar baz\n")
    end

    it "fails to match top level command" do
      A.run(%w[unknown], output: output)
      output.rewind
      expect(output.string).to eq("Command 'unknown' not found\n")
    end
  end

  context "matching commands with runnable objects" do
    before do
      stub_const("FooBarCommand", Class.new do
        def call(out)
          out.puts "running foo bar"
        end
      end)

      stub_const("FooBazCommand", Class.new do
        def call(out)
          out.puts "running foo baz"
        end
      end)

      stub_const("BarCommand", Class.new do
        def call(out)
          out.puts "running bar"
        end
      end)

      stub_const("B", Class.new(TTY::Runner) do
        commands do
          on "foo" do
            on :bar, run: FooBarCommand

            on :baz do
              run "foo_baz_command"
            end
          end

          on "bar", run: BarCommand

          on "qux", run: true
        end
      end)
    end

    it "matches no commands" do
      B.run([], output: output)
      output.rewind
      expect(output.string).to eq([
        "Commands:",
        "  bar",
        "  foo",
        "  qux\n"
      ].join("\n"))
    end

    it "shows available 'foo' subcommands when no runnable found" do
      B.run(%w[foo], output: output)
      output.rewind
      expect(output.string).to eq([
        "Commands:",
        "  foo bar",
        "  foo baz\n"
      ].join("\n"))
    end

    it "matches top level 'bar' command" do
      B.run(%w[bar], output: output)
      output.rewind
      expect(output.string).to eq("running bar\n")
    end

    it "matches one level deep 'bar' subcommand" do
      B.run(%w[foo bar], output: output)
      output.rewind
      expect(output.string).to eq("running foo bar\n")
    end

    it "matches one levels deep 'baz' subcommand" do
      B.run(%w[foo baz], output: output)
      output.rewind
      expect(output.string).to eq("running foo baz\n")
    end

    it "fails to recognize runnable type" do
      expect {
        B.run(%w[qux])
      }.to raise_error(TTY::Runner::Error,
                      "unsupported runnable: true")
    end
  end

  context "uses different objects as matchers" do
    before do
      stub_const("C", Class.new(TTY::Runner) do
        commands do
          on :foo, run: ->(out) { out.puts "matched foo"}
          on -> { "bar" }, run: ->(out) { out.puts "matched bar" }
          on "baz", run: ->(out) { out.puts "" }
        end
      end)
    end

    it "matches with :foo symbol" do
      C.run(%w[foo], output: output)
      output.rewind
      expect(output.string).to eq("matched foo\n")
    end

    it "matches with proc" do
      C.run(%w[bar], output: output)
      output.rewind
      expect(output.string).to eq("matched bar\n")
    end
  end

  context "mounting commands" do
    before do
      stub_const("D", Class.new(TTY::Runner) do
        commands do
          on "bar", run: ->(out) { out.puts "running bar" }
        end
      end)

      stub_const("E", Class.new(TTY::Runner) do
        commands do
          on "baz", run: ->(out) { out.puts "running baz" }
        end
      end)

      stub_const("F", Class.new(TTY::Runner) do
        commands do
          on "foo" do
            mount D
          end

          mount E
        end
      end)
    end

    it "mounts 'baz' command at the top level" do
      F.run(%w[baz], output: output)
      output.rewind
      expect(output.string).to eq("running baz\n")
    end

    it "mounts 'bar' command inside 'foo' command" do
      F.run(%w[foo bar], output: output)
      output.rewind
      expect(output.string).to eq("running bar\n")
    end

    it "doesn't mount none runner type" do
      stub_const("G", Class.new(TTY::Runner) do
        commands do
          mount Class
        end
      end)

      expect {
        G.run
      }.to raise_error(TTY::Runner::Error,
                      "A TTY::Runner type must be given")
    end
  end

  context "prints nested commands" do
    before do
      stub_const("G", Class.new(TTY::Runner) do
        commands do
          on :foo do
            on :bar do
              on :baz do
                on :qux, run: ->(out) { out.puts "running qux" }

                on :quux, run: ->(out) { out.puts "running quux" }
              end
            end
          end
        end
      end)
    end

    it "shows all deeply nested commands" do
      G.run(%w[foo bar baz], output: output)
      output.rewind
      expect(output.string).to eq([
        "Commands:",
        "  foo bar baz quux",
        "  foo bar baz qux\n"
      ].join("\n"))
    end
  end

  context "matching commands with runnable procs" do
    before do
      stub_const("H", Class.new(TTY::Runner) do
        commands do
          on "foo", aliases: %w[fo f] do
            run { |out| out.puts "running foo"}

            on "bar", aliases: %w[r] do
              run { |out| out.puts "running foo bar"}
            end

            on "baz", aliases: %w[z] do
              run { |out| out.puts "running foo baz" }
            end
          end

          on "qux", aliases: %w[q], run: ->(out) { out.puts "running qux" }
        end
      end)
    end

    it "runs aliased command 'fo' -> 'foo' at the top level" do
      H.run(%w[fo], output: output)
      output.rewind
      expect(output.string).to eq("running foo\n")
    end

    it "runs aliased command 'f' -> 'foo' for subcommand" do
      H.run(%w[f], output: output)
      output.rewind
      expect(output.string).to eq("running foo\n")
    end

    it "runs aliased command 'r' -> 'bar' for subcommand" do
      H.run(%w[foo r], output: output)
      output.rewind
      expect(output.string).to eq("running foo bar\n")
    end

    it "runs aliased command 'z' -> 'baz' for subcommand" do
      H.run(%w[foo z], output: output)
      output.rewind
      expect(output.string).to eq("running foo baz\n")
    end

    it "runs aliased command 'q' -> 'qux' at the top level with inlined runnable" do
      H.run(%w[q], output: output)
      output.rewind
      expect(output.string).to eq("running qux\n")
    end
  end

  context "errors" do
    it "doesn't allow empty commands" do
      expect {
        TTY::Runner.commands
      }.to raise_error(described_class::Error,
                      "no block provided")
    end

    it "doesn't allow mixing object with block in run" do
      stub_const("J", Class.new(TTY::Runner) do
        commands do
          run(Object) { puts "run" }
        end
      end)
      expect {
          J.run
      }.to raise_error(described_class::Error,
                      "cannot provide both command object and block")
    end

    it "doesn't allow using object in match condition" do
      stub_const("K", Class.new(TTY::Runner) do
        commands do
          on Object, run: -> { }
        end
      end)
      expect {
          K.run
      }.to raise_error(described_class::Error, "unsupported matcher: Object")
    end
  end
end
