# frozen_string_literal: true

RSpec.describe TTY::Runner do
  let(:stdout) { StringIO.new }

  context "matching commands with runnable procs" do
    before do
      stub_const("A", Class.new(TTY::Runner) do
        commands do
          run { puts "running root" }

          on "foo" do
            on "foo", run: -> { puts "running foo foo" }

            on "bar" do
              run { puts "running foo bar" }

              on "baz" do
                run { puts "running foo bar baz" }
              end
            end
          end

          on "bar" do
            run { |argv| puts "running bar with #{argv}" }
          end
        end
      end)
    end

    it "matches no commands" do
      expect {
        A.run([])
      }.to output("running root\n").to_stdout
    end

    it "shows available 'foo' subcommands when no runnable found" do
      A.run(%w[foo], output: stdout)
      stdout.rewind
      expect(stdout.string).to eq([
        "Commands:",
        "  foo bar",
        "  foo foo\n"
      ].join("\n"))
    end

    it "matches top level 'bar' command" do
      expect {
        A.run(%w[bar])
      }.to output("running bar with []\n").to_stdout
    end

    it "matches similarly named nested 'foo' subcommand" do
      expect {
        A.run(%w[foo foo])
      }.to output("running foo foo\n").to_stdout
    end

    it "matches one level deep 'bar' subcommand" do
      expect {
        A.run(%w[foo bar])
      }.to output("running foo bar\n").to_stdout
    end

    it "matches two levels deep 'baz' subcommand" do
      expect {
        A.run(%w[foo bar baz])
      }.to output("running foo bar baz\n").to_stdout
    end

    it "consumes only matching argument on top level" do
      expect {
        A.run(%w[bar extra])
      }.to output("running bar with [\"extra\"]\n").to_stdout
    end

    it "consumes only matching arguments one level deep" do
      A.run(%w[foo bar extra], output: stdout)
      stdout.rewind
      expect(stdout.string).to eq("Command 'foo bar extra' not found\n")
    end

    it "consumes only matching arguments two levels deep" do
      expect {
        A.run(%w[foo bar baz extra])
      }.to output("running foo bar baz\n").to_stdout
    end

    it "fails to match top level command" do
      A.run(%w[unknown], output: stdout)
      stdout.rewind
      expect(stdout.string).to eq("Command 'unknown' not found\n")
    end
  end

  context "matching commands with runnable objects" do
    before do
      stub_const("Foo::BarCommand", Class.new do
        def call(argv)
          puts "running foo bar"
        end
      end)

      stub_const("Foo::BazCommand", Class.new do
        def call(argv)
          puts "running foo baz"
        end
      end)

      stub_const("Foo::QuxCommand", Class.new do
        def execute(argv)
          puts "running foo qux"
        end
      end)

      stub_const("BarCommand", Class.new do
        def execute(argv)
          puts "running bar"
        end
      end)

      stub_const("BazCommand", Class.new do
        def execute(argv)
          puts "running baz"
        end
      end)

      stub_const("B", Class.new(TTY::Runner) do
        commands do
          on "foo" do
            on :bar, run: Foo::BarCommand

            on :baz do
              run "baz_command"
            end

            on :qux do
              run "qux_command#execute"
            end

            on :quux do
              run "qux_command", action: :execute
            end
          end

          on "bar", run: "bar_command#execute"

          on "baz", run: "baz_command", action: "execute"

          on "qux", run: true
        end
      end)
    end

    it "matches no commands" do
      B.run([], output: stdout)
      stdout.rewind
      expect(stdout.string).to eq([
        "Commands:",
        "  bar",
        "  baz",
        "  foo",
        "  qux\n"
      ].join("\n"))
    end

    it "shows available 'foo' subcommands when no runnable found" do
      B.run(%w[foo], output: stdout)
      stdout.rewind
      expect(stdout.string).to eq([
        "Commands:",
        "  foo bar ",
        "  foo baz ",
        "  foo quux",
        "  foo qux \n"
      ].join("\n"))
    end

    it "matches top level 'bar' command" do
      expect {
        B.run(%w[bar])
      }.to output("running bar\n").to_stdout
    end

    it "matches top level 'baz' command with custom action" do
      expect {
        B.run(%w[baz])
      }.to output("running baz\n").to_stdout
    end

    it "matches one level deep 'bar' subcommand" do
      expect {
        B.run(%w[foo bar])
      }.to output("running foo bar\n").to_stdout
    end

    it "matches one level deep 'baz' subcommand" do
      expect {
        B.run(%w[foo baz])
      }.to output("running foo baz\n").to_stdout
    end

    it "matches one level deep 'qux' subcommand with custom action" do
      expect {
        B.run(%w[foo qux])
      }.to output("running foo qux\n").to_stdout
    end

    it "matches one level deep 'quux' subcommand with custom action" do
      expect {
        B.run(%w[foo quux])
      }.to output("running foo qux\n").to_stdout
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
          on :foo, run: -> { puts "matched foo"}
          on -> { "bar" }, run: -> { puts "matched bar" }
          on "baz", run: -> { puts "" }
        end
      end)
    end

    it "matches with :foo symbol" do
      expect {
        C.run(%w[foo])
      }.to output("matched foo\n").to_stdout
    end

    it "matches with proc" do
      expect {
        C.run(%w[bar])
      }.to output("matched bar\n").to_stdout
    end
  end

  context "mounting commands" do
    before do
      stub_const("D", Class.new(TTY::Runner) do
        commands do
          on "bar", run: -> { puts "running bar" }
        end
      end)

      stub_const("E", Class.new(TTY::Runner) do
        commands do
          on "baz", run: -> { puts "running baz" }
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
      expect {
        F.run(%w[baz])
      }.to output("running baz\n").to_stdout
    end

    it "mounts 'bar' command inside 'foo' command" do
      expect {
        F.run(%w[foo bar])
      }.to output("running bar\n").to_stdout
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
                on :qux, run: -> { puts "running qux" }

                on :quux, run: -> { puts "running quux" }
              end
            end
          end
        end
      end)
    end

    it "shows all deeply nested commands" do
      G.run(%w[foo bar baz], output: stdout)
      stdout.rewind
      expect(stdout.string).to eq([
        "Commands:",
        "  foo bar baz quux",
        "  foo bar baz qux \n"
      ].join("\n"))
    end
  end

  context "matching commands with runnable procs" do
    before do
      stub_const("H", Class.new(TTY::Runner) do
        commands do
          on "foo", aliases: %w[fo f] do
            run { puts "running foo"}

            on "bar", aliases: %w[r] do
              run { puts "running foo bar"}
            end

            on "baz", aliases: %w[z] do
              run { puts "running foo baz" }
            end
          end

          on "qux", aliases: %w[q], run: -> { puts "running qux" }
        end
      end)
    end

    it "runs aliased command 'fo' -> 'foo' at the top level" do
      expect {
        H.run(%w[fo])
      }.to output("running foo\n").to_stdout
    end

    it "runs aliased command 'f' -> 'foo' for subcommand" do
      expect {
        H.run(%w[f])
      }.to output("running foo\n").to_stdout
    end

    it "runs aliased command 'r' -> 'bar' for subcommand" do
      expect {
        H.run(%w[foo r])
      }.to output("running foo bar\n").to_stdout
    end

    it "runs aliased command 'z' -> 'baz' for subcommand" do
      expect {
        H.run(%w[foo z])
      }.to output("running foo baz\n").to_stdout
    end

    it "runs aliased command 'q' -> 'qux' at the top level with inlined runnable" do
      expect {
        H.run(%w[q])
      }.to output("running qux\n").to_stdout
    end
  end

  context "matches runanble subcommand with runnable parent command" do
    before do
      stub_const("I", Class.new(TTY::Runner) do
        commands do
          on "foo", run: -> { puts "running foo"} do
            on "bar", run: -> { puts "running bar" }
          end
        end
      end)
    end

    it "runs the top level 'foo' command with runnable 'bar' subcommand" do
      expect {
        I.run(%w[foo])
      }.to output("running foo\n").to_stdout
    end

    it "runs 'bar' subcommand with runnable 'foo' parent" do
      expect {
        I.run(%w[foo bar])
      }.to output("running bar\n").to_stdout
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
