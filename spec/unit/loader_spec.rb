# frozen_string_literal: true

RSpec.describe TTY::Runner::Loader do
  context "#add_dir" do
    it "has not directories by default" do
      loader = described_class.new

      expect(loader.dir_mappings).to be_empty
      expect(loader.command_dirs).to be_empty
    end

    it "adds only a directory and defaults the namespace to an Object" do
      loader = described_class.new

      loader.add_dir "."

      expect(loader.dir_mappings).to eq({ Dir.pwd => Object })
      expect(loader.command_dirs).to eq([Dir.pwd])
    end

    it "adds a directory with a namespace mapping" do
      stub_const("Commands", Module.new)
      loader = described_class.new

      loader.add_dir ".", namespace: Commands

      expect(loader.dir_mappings).to eq({ Dir.pwd => Commands })
      expect(loader.command_dirs).to eq([Dir.pwd])
    end

    it "adds two directories where one has a custom namespace" do
      parent_dir = ::File.expand_path("..")
      loader = described_class.new

      loader.add_dir "."
      loader.add_dir "..", namespace: Module

      expect(loader.dir_mappings).to eq({ Dir.pwd => Object, parent_dir => Module })
      expect(loader.command_dirs).to eq([Dir.pwd, parent_dir])
    end

    it "fails to add directory that doesn't exist" do
      loader = described_class.new
      unknown_dir = ::File.expand_path("unknown")

      expect {
        loader.add_dir "unknown"
      }.to raise_error(TTY::Runner::Error,
                       "directory #{unknown_dir} does not exist")
    end

    it "fails to add directory with a namespace that isn't a class or module " do
      loader = described_class.new

      expect {
        loader.add_dir ".", namespace: :unknown
      }.to raise_error(TTY::Runner::Error,
                       "invalid namespace: :unknown, needs to be " \
                       "a class or module.")
    end
  end

  context "#load_command" do
    it "loads a top level command from the current directory" do
      files = [
        ["foo_command.rb", "class FooCommand; end"]
      ]
      with_files files do
        loader = described_class.new
        loader.add_dir "."

        expect(Object.const_defined?(:FooCommand)).to eq(false)

        command = loader.load_command "foo_command"

        expect(command).to eq(FooCommand)
      end
      remove_const :FooCommand
    end

    it "loads a top level command from the 'cli/commands' directory" do
      files = [
        ["cli/commands/foo_command.rb", "class FooCommand; end"]
      ]
      with_files files do
        loader = described_class.new
        loader.add_dir "cli/commands"

        expect(Object.const_defined?(:FooCommand)).to eq(false)

        command = loader.load_command "foo_command"

        expect(command).to eq(FooCommand)
      end
      remove_const :FooCommand
    end

    it "loads a nested command from the current directory" do
      stub_const("Foo", Module.new)
      files = [
        ["foo/bar_command.rb", "class Foo::BarCommand; end"]
      ]
      with_files files do
        loader = described_class.new
        loader.add_dir "."

        expect(Foo.const_defined?(:BarCommand)).to eq(false)

        command = loader.load_command "foo", "bar_command"

        expect(command).to eq(Foo::BarCommand)
      end
      remove_const :BarCommand, parent: Foo
    end

    it "loads a nested command from the 'cli/commands' directory" do
      stub_const("Foo", Module.new)
      files = [
        ["cli/commands/foo/bar_command.rb", "class Foo::BarCommand; end"]
      ]
      with_files files do
        loader = described_class.new
        loader.add_dir "cli/commands"

        expect(Foo.const_defined?(:BarCommand)).to eq(false)

        command = loader.load_command "foo", "bar_command"

        expect(command).to eq(Foo::BarCommand)
      end
      remove_const :BarCommand, parent: Foo
    end

    it "loads a command inside a namespace from the current directory" do
      stub_const("Commands", Module.new)
      files = [
        ["foo_command.rb", "class Commands::FooCommand; end"]
      ]
      with_files files do
        loader = described_class.new
        loader.add_dir ".", namespace: Commands

        expect(Commands.const_defined?(:FooCommand)).to eq(false)

        command = loader.load_command "foo_command"

        expect(command).to eq(Commands::FooCommand)
      end
      remove_const :FooCommand, parent: Commands
    end

    it "loads a command inside a namespace from the 'cli/commands' directory" do
      stub_const("Commands", Module.new)
      files = [
        ["cli/commands/foo_command.rb", "class Commands::FooCommand; end"]
      ]
      with_files files do
        loader = described_class.new
        loader.add_dir "cli/commands", namespace: Commands

        expect(Commands.const_defined?(:FooCommand)).to eq(false)

        command = loader.load_command "foo_command"

        expect(command).to eq(Commands::FooCommand)
      end
      remove_const :FooCommand, parent: Commands
    end
  end
end
