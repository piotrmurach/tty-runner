# frozen_string_literal: true

RSpec.describe TTY::Runner, "commands_dir" do
  it "loads commands from a relative directory" do
    files = [
      ["commands/foo_command.rb", <<-EOS],
        class FooCommand
          def call
            puts "running FooCommand"
          end
        end
      EOS
      ["commands/foo/bar_command.rb", <<-EOS]
        module Foo
          class BarCommand
            def call
              puts "running Foo::BarCommand"
            end
          end
        end
      EOS
    ]

    with_files(files) do
      stub_const("A", Class.new(TTY::Runner) do
        commands_dir "commands"

        commands do
          on "foo", run: "foo_command" do
            on "bar", run: "bar_command"
          end
        end
      end)

      expect(::File.directory?("commands")).to eq(true)

      expect { A.run(%w[foo]) }.to output("running FooCommand\n").to_stdout

      expect { A.run(%w[foo bar]) }.to output("running Foo::BarCommand\n").to_stdout
    end
  end

  it "loads commands from a directory with a Commands namespace" do
    stub_const("Commands", Module.new)

    files = [
      ["commands/foo_command.rb", <<-EOS],
        module Commands
          class FooCommand
            def call
              puts "running FooCommand"
            end
          end
        end
      EOS
      ["commands/foo/bar_command.rb", <<-EOS]
        module Commands
          module Foo
            class BarCommand
              def call
                puts "running Foo::BarCommand"
              end
            end
          end
        end
      EOS
    ]

    with_files(files) do
      stub_const("A", Class.new(TTY::Runner) do
        commands_dir "commands"

        commands namespace: Commands do
          on "foo", run: "foo_command" do
            on "bar", run: "bar_command"
          end
        end
      end)

      expect(::File.directory?("commands")).to eq(true)

      expect { A.run(%w[foo]) }.to output("running FooCommand\n").to_stdout

      expect { A.run(%w[foo bar]) }.to output("running Foo::BarCommand\n").to_stdout
    end
  end

  it "fails to find commands directory" do
    expect {
      TTY::Runner.commands_dir "#{__dir__}/unknown"
    }.to raise_error(TTY::Runner::Error,
                     "directory #{__dir__}/unknown does not exist")
  end
end
