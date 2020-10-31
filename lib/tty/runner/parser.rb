# frozen_string_literal: true

module TTY
  class Runner
    # Responsible for parsing command line arguments
    class Parser
      attr_reader :matched_argv

      attr_reader :remaining_argv

      def initialize(context)
        @context = context
        @argv = []
        @matched_argv = []
        @remaining_argv = []
      end

      # Parse command line arguments and find a matching command context
      #
      # @param [Array<String>] argv
      #   the command line arguments
      #
      # @param [Hash<String>] env
      #   the command environment variables
      #
      # @return [Context, String, Boolean]
      #
      # @api private
      def parse(argv, env)
        @argv = argv.dup
        @env = env

        tuple = find_command(@context, prefix: "")

        while (val = @argv.shift)
          @remaining_argv << val
        end

        tuple
      end

      # Find a command that matches argument
      #
      # @return [Context, String, Boolean]
      #
      # @api private
      def find_command(context, prefix: "")
        any_match = false
        name = peek.to_s
        cmd_context = context[name]

        if cmd_context
          any_match = true
          @matched_argv << consume
          prefix = "#{prefix}#{' ' if !prefix.empty? && name}#{name}"

          if !last? && cmd_context.children? && command?
            return find_command(cmd_context, prefix: prefix)
          end
        end

        [cmd_context, prefix, any_match]
      end

      def last?
        @argv.empty?
      end

      def command?
        peek && !peek.to_s.match(/^-{1,2}\S+/)
      end

      def peek
        @argv.first
      end

      def consume
        @argv.shift
      end

      def unknown_command
        out = @matched_argv.join(" ")
        out += " " unless @matched_argv.empty?
        out += @remaining_argv.first unless @remaining_argv.empty?
        out
      end
    end # Parser
  end # Runner
end # TTY
