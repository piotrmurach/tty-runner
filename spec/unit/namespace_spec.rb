# frozen_string_literal: true

RSpec.describe TTY::Runner, "namespace" do
  context "nested commands" do
    before do
      stub_const("MyCLI::Commands::FooCommand", Class.new do
        def call
          print "running FooCommand"
        end
      end)

      stub_const("MyCLI::Commands::Foo::BarCommand", Class.new do
        def call
          print "running Foo::BarCommand"
        end
      end)

      stub_const("MyCLI::Commands::Foo::Bar::BazCommand", Class.new do
        def call
          print "running Foo::Bar::BazCommand"
        end
      end)

      stub_const("A", Class.new(TTY::Runner) do
        commands namespace: MyCLI::Commands do
          on "foo", run: "foo_command" do
            on "bar", run: "bar_command" do
              on "baz" do
                run "baz_command"
              end
            end
          end
        end
      end)
    end

    it "prepends top level 'foo' command with MyCLI::Commands" do
      expect { A.run(%w[foo]) }.to output("running FooCommand").to_stdout
    end

    it "prepends first level 'bar' command with MyCLI::Commands" do
      expect {
        A.run(%w[foo bar])
      }.to output("running Foo::BarCommand").to_stdout
    end

    it "prepends second level 'baz' command with MyCLI::Commands" do
      expect {
        A.run(%w[foo bar baz])
      }.to output("running Foo::Bar::BazCommand").to_stdout
    end
  end

  context "error" do
    it "fails when namespace is not a class or a module" do
      expect {
        TTY::Runner.commands namespace: :invalid do
        end
      }.to raise_error(described_class::Error,
                       "invalid namespace: :invalid, needs to be " \
                       "a class or module.")
    end
  end
end
