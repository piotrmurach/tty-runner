# frozen_string_literal: true

RSpec.describe TTY::Runner, "commands_dir" do
  context "without namespace" do
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

    after do
      remove_const :FooCommand
      remove_const :Foo
    end
  end

  context "with namespace" do
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
        stub_const("B", Class.new(TTY::Runner) do
          commands_dir "commands"

          commands namespace: Commands do
            on "foo", run: "foo_command" do
              on "bar", run: "bar_command"
            end
          end
        end)

        expect(::File.directory?("commands")).to eq(true)

        expect { B.run(%w[foo]) }.to output("running FooCommand\n").to_stdout

        expect { B.run(%w[foo bar]) }.to output("running Foo::BarCommand\n").to_stdout
      end
    end
  end

  context "when multiple dirs & namespaces" do
    it "loads commands from multiple directories with different namespaces" do
      stub_const("ACommands", Module.new)
      stub_const("BCommands", Module.new)

      files = [
        ["a_dir/foo_command.rb", <<-EOS],
        module ACommands
          class FooCommand
            def call
              puts "running ACommands::FooCommand in a_dir"
            end
          end
        end
        EOS
        ["b_dir/bar_command.rb", <<-EOS],
        module BCommands
          class BarCommand
            def call
              puts "running BCommands::BarCommand in b_dir"
            end
          end
        end
        EOS
      ]

      with_files(files) do
        stub_const("C", Class.new(TTY::Runner) do
          commands_dir "a_dir", namespace: ACommands

          commands_dir "b_dir", namespace: BCommands

          commands do
            on "foo", run: "foo_command"
            on "bar", run: "bar_command"
          end
        end)

        expect(::File.directory?("a_dir")).to eq(true)
        expect(::File.directory?("b_dir")).to eq(true)

        expect {
          C.run(%w[foo])
        }.to output("running ACommands::FooCommand in a_dir\n").to_stdout

        expect {
          C.run(%w[bar])
        }.to output("running BCommands::BarCommand in b_dir\n").to_stdout
      end
    end
  end

  context "when non-existent directory" do
    it "fails to find commands directory" do
      expect {
        TTY::Runner.commands_dir "#{__dir__}/unknown"
      }.to raise_error(TTY::Runner::Error,
                       "directory #{__dir__}/unknown does not exist")
    end
  end
end
