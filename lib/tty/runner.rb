# frozen_string_literal: true

require "monitor"

require_relative "runner/inflection"
require_relative "runner/parser"
require_relative "runner/router"
require_relative "runner/version"

module TTY
  class Runner
    class Error < StandardError; end

    @commands_block = nil
    @commands_namespace = Object
    @program_name = ::File.basename($0, ".*")

    module ClassMethods
      attr_reader :commands_block

      attr_reader :commands_namespace

      attr_reader :program_name

      # Copy class instance variables into the subclass
      def inherited(subclass)
        super
        subclass.instance_variable_set(:@commands_block, commands_block)
        subclass.instance_variable_set(:@commands_namespace, commands_namespace)
        subclass.instance_variable_set(:@program_name, program_name.dup)
      end

      # Run commands
      #
      # @example
      #   TTY::Runner.run
      #
      # @param [Array<String>] argv
      #   the command line arguments
      # @param [Hash] env
      #   the hash of environment variables
      # @param [IO] output
      #   the output stream
      #
      # @api public
      def run(argv = ARGV, env = ENV, output: $stdout)
        new(output: output).call(argv, env)
      end

      # The entry point of setting up applications commands.
      #
      # @example
      #   TTY::Runner.commands do |c|
      #     c.on "foo", run: FooCommand
      #   end
      #
      # This should be called only once per class.
      #
      # @api public
      def commands(namespace: Object, &block)
        unless block
          raise Error, "no block provided"
        end
        unless namespace.is_a?(Module)
          raise Error, "invalid namespace: #{namespace.inspect}, " \
                       "needs to be a class or module."
        end

        @commands_block = block
        @commands_namespace = namespace
      end

      # Configure name for the runner
      #
      # @example
      #   TTY::Runner.program "foo"
      #
      # @api public
      def program(name)
        @program_name = name
      end
    end

    attr_reader :_router

    attr_reader :_parser

    def initialize(output: $stdout)
      @output = output
      @_router = Router.new
      @lock = Monitor.new
      if self.class.commands_block
        @_router.evaluate(&self.class.commands_block)
      end
      @_parser = Parser.new(@_router.context)
    end

    # Process command line arguments
    #
    # @param [Array<String>] argv
    #   the command line arguments
    # @param [Hash] env
    #   the hash of environment variables
    #
    # @api public
    def call(argv = ARGV, env = ENV)
      context, prefix, any_match = *_parser.parse(argv, env)

      if context
        if context.runnable?
          invoke_command(context)
        else
          @output.puts usage(context, prefix: prefix)
        end
      elsif !any_match
        @output.puts("Command '#{_parser.unknown_command}' not found")
      end
    end

    private

    # Invoke runnable from command context
    #
    # @api private
    def invoke_command(context)
      @lock.synchronize do
        command, action = *split_runnable(context)
        runnable = instantiate_command(context, command)
        runnable.__send__(action, *runnable_args(runnable, action))
      end
    end

    # Split runnable into command and action
    #
    # @param [Context] context
    #
    # @return [Array<Object,String>]
    #
    # @api private
    def split_runnable(context)
      command = context.runnable
      if command.is_a?(::String)
        command, action = *command.to_s.split(/#/)
      end
      [command, action || context.action]
    end

    # @api private
    def instantiate_command(context, command)
      return command if command.respond_to?(:call)

      case command
      when ::Class
        command.new
      when ::String, ::Symbol
        to_runnable_class(context, command).new
      else
        raise Error, "unsupported runnable: #{command.inspect}"
      end
    end

    # @api private
    def to_runnable_class(context, command)
      return command unless command.is_a?(::String)

      cmds = []
      until context.parent.root?
        context = context.parent
        cmds.unshift(context.name)
      end
      cmds << command

      const_name = cmds.map(&Inflection.method(:camelcase)).join("::")
      self.class.commands_namespace.const_get(const_name)
    end

    # @api private
    def runnable_args(runnable, action)
      arity = if runnable.respond_to?(:arity)
        runnable.arity
      else
        runnable.method(action.to_sym).arity
      end

      if arity < 1
        []
      elsif arity == 1
        [@_parser.remaining_argv]
      end
    end

    # Print commands usage information
    #
    # @api private
    def usage(context, prefix: "")
      indent = " " * 2
      longest_name = context.map { |name, _| name.length }.max
      list = context.each_with_object([]) do |(name, cmd_context), acc|
               next if name.empty?
               cmd = format("%s%s%-#{longest_name}s", indent,
                            "#{prefix}#{' ' unless prefix.empty?}", name)
               acc << cmd
             end
      list.sort! { |cmd_a, cmd_b| cmd_a <=> cmd_b }

      "Commands:\n#{list.join("\n")}"
    end

    extend ClassMethods
  end # Runner
end # TTY
