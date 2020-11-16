# frozen_string_literal: true

RSpec.describe TTY::Runner, "intercepting action" do
  context "defined command" do
    before do
      stub_const("FooCommand", Class.new do
        include TTY::Option

        command :foo

        argument :a, desc: "A desc"
        argument :b, desc: "B desc"

        def call
          puts "foo a=#{params[:a]} b=#{params[:b]}"
        end
      end)

      stub_const("BarCommand", Class.new do
        include TTY::Option

        command :bar

        option :a, short: "-a N", desc: "A desc"

        flag :help, short: "-h", long: "--help", desc: "Print help information"

        def execute
          puts "bar a=#{params[:a]} rest=#{params.remaining}"
        end
      end)

      stub_const("A", Class.new(TTY::Runner) do
        commands do
          on "foo", run: "foo_command"

          on "bar", run: "bar_command#execute"
        end
      end)
    end

    it "displays help information" do
      help_info = unindent(<<-EOS)
      Usage: rspec foo [OPTIONS] A B

      Arguments:
        A  A desc
        B  B desc

      Options:
        -h, --help  Print usage
      EOS

      expect {
        expect { A.run(%w[foo -h]) }.to raise_error(SystemExit)
      }.to output(help_info).to_stderr
    end

    it "parses parameters" do
      expect {
        A.run(%w[foo 1 2])
      }.to output("foo a=1 b=2\n").to_stdout
    end

    it "collects remaining parameters" do
      expect {
        A.run(%w[bar -a 1 2])
      }.to output("bar a=1 rest=[\"2\"]\n").to_stdout
    end

    it "redefines help flag in 'bar' command" do
      help_info = unindent(<<-EOS)
      Usage: rspec bar [OPTIONS]

      Options:
        -h, --help  Print help information
        -a          A desc
      EOS

      expect {
        expect { A.run(%w[bar -h]) }.to raise_error(SystemExit)
      }.to output(help_info).to_stderr
    end
  end

  context "defined command without action" do
    it "raises error when action definition is missing" do
      stub_const("FooCommand", Class.new do
        include TTY::Option

        # no action
      end)

      stub_const("X", Class.new(TTY::Runner) do
        commands do
          on "foo", run: "foo_command#execute"
        end
      end)

      expect {
        X.run(%w[foo])
      }.to raise_error(TTY::Runner::Error, "missing command action: \"execute\"")
    end
  end

  context "anonymous command" do
    before do
      stub_const("B", Class.new(TTY::Runner) do
        commands do
          on "foo" do
            run do
              command :foo

              argument :a, desc: "A desc"

              option :b, short: "-b N", desc: "B desc"

              def call
                puts "foo a=#{params[:a]} b=#{params[:b]}"
              end
            end
          end
        end
      end)
    end

    it "parses parameters" do
      expect {
        B.run(%w[foo 1 -b 2])
      }.to output("foo a=1 b=2\n").to_stdout
    end

    it "displays help information" do
      help_info = unindent(<<-EOS)
      Usage: rspec foo [OPTIONS] A

      Arguments:
        A  A desc

      Options:
        -h, --help  Print usage
        -b          B desc
      EOS

      expect {
        expect { B.run(%w[foo -h]) }.to raise_error(SystemExit)
      }.to output(help_info).to_stderr
    end
  end

  context "anonymous class without action" do
    it "raises error when action definition is missing" do
      stub_const("X", Class.new(TTY::Runner) do
        commands do
          on "foo" do
            run do
              # no action
            end
          end
        end
      end)

      expect {
        X.run(%w[foo])
      }.to raise_error(TTY::Runner::Error, "missing command action: \"call\"")
    end
  end
end
