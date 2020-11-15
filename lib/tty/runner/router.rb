# frozen_string_literal: true

require_relative "context"

module TTY
  class Runner
    # Map command names to commands
    class Router
      attr_reader :context

      def initialize(mod_extension: nil)
        @context = Context.new("")
        @mod_extension = mod_extension
      end

      # Evaluate all commands
      #
      # @api private
      def evaluate(&block)
        instance_exec(&block)
      end

      # Map command name with runnable commands
      #
      # @example
      #   on "foo" do
      #     on "bar" do
      #       # matches
      #     end
      #   end
      #
      # @param [String, Proc] name
      #   the command name to match
      # @param [Object] run
      #   the object to run
      # @param [Array<String>] aliases
      #   the command aliases
      #
      # @api public
      def on(name, desc = nil, run: nil, aliases: [], action: :call, &block)
        name = convert(name)

        with_context(name, aliases: aliases) do
          desc(desc) if desc

          run(run, action: action)

          block.call if block
        end
      end

      # Provide summary for the command
      #
      # @param [String] description
      #
      # @api public
      def desc(description)
        @context.desc = description
      end

      # Specify code to run when command is matched
      #
      # @param [Class] command
      #
      # @api public
      def run(command = nil, action: nil, &block)
        if block && !command.nil?
          raise Error, "cannot provide both command object and block"
        end

        if block
          runnable = Class.new
          runnable.__send__(:include, @mod_extension) if @mod_extension
          runnable.module_eval(&block)
        else
          runnable = command
        end

        @context.runnable = runnable
        @context.action = action if action
      end

      # Mount other commands runner
      #
      # @example
      #   on :foo do
      #     mount TagCommands
      #   end
      #
      # @api public
      def mount(object)
        unless runner_class?(object)
          raise Error, "A TTY::Runner type must be given"
        end

        instance_exec(&object.commands_block)
      end

      private

      # Evaluate block with a new context
      #
      # @api private
      def with_context(name, aliases: [])
        @context = @context.add(name, aliases: aliases)
        yield
      ensure
        @context = @context.parent
      end

      # Check if runner is of TTY::Runner type
      #
      # @api private
      def runner_class?(object)
        object.is_a?(Class) && object < TTY::Runner
      end

      # Convert matcher to string value
      #
      # @api private
      def convert(matcher)
        case matcher
        when String, Symbol
          matcher.to_s
        when Proc
          matcher.call.to_s
        else
          unsupported_matcher(matcher)
        end
      end

      # Matcher not supported
      #
      # @api private
      def unsupported_matcher(matcher)
        raise Error, "unsupported matcher: #{matcher.inspect}"
      end
    end # Router
  end # Runner
end # TTY
