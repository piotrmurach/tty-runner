# frozen_string_literal: true

require_relative "inflection"

module TTY
  class Runner
    class Loader
      # Mappings of an absolute command path to a namespace
      #
      # @example
      #   "/Users/tty/my_cli/commands" => MyCLI::Commands
      #
      # @api private
      attr_reader :dir_mappings

      def initialize
        @dir_mappings = {}
      end

      # A collection of all the command directories
      #
      # @return [Array<String>]
      #
      # @api public
      def command_dirs
        dir_mappings.keys
      end

      # Add directory to load commands from
      #
      # @example
      #   add_dir "cli/commands"
      #
      # @param [String] dir
      #   the absolute directory path
      # @param [Object] namespace
      #   the namespace for all commands inside the directory
      #
      # @raise [TTY::Runner::Error]
      #
      # @api public
      def add_dir(dir, namespace: Object)
        unless namespace.is_a?(Module)
          raise Error, "invalid namespace: #{namespace.inspect}, " \
                       "needs to be a class or module."
        end

        abs_path = ::File.expand_path(dir)
        if ::File.directory?(abs_path)
          @dir_mappings[abs_path] = namespace
        else
          raise Error, "directory #{abs_path} does not exist"
        end
      end

      # Load a command from a file matching commands path
      #
      # @param [Array[String]] cmds
      # @param [Object] namespace
      #
      # @api public
      def load_command(*cmds, namespace: Object)
        dir_mappings.each do |dir, object|
          cmd_path = ::File.join(dir, *cmds.map(&:to_s))
          if ::File.file?("#{cmd_path}.rb")
            Kernel.require(cmd_path)
            namespace = object unless object == Object
            break
          end
        end

        const_name = cmds.map(&Inflection.method(:camelcase)).join("::")
        namespace.const_get(const_name)
      end
    end # Loader
  end # Runner
end # TTY
