# frozen_string_literal: true

require "monitor"

require_relative "runner/parser"
require_relative "runner/router"
require_relative "runner/version"

module TTY
  class Runner
    class Error < StandardError; end

    @commands_block = nil
    @program_name = ::File.basename($0, ".*")

    module ClassMethods
      attr_reader :commands_block

      attr_reader :program_name

      # Copy class instance variables into the subclass
      def inherited(subclass)
        super
        subclass.instance_variable_set(:@commands_block, commands_block)
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
      def commands(&block)
        unless block
          raise Error, "no block provided"
        end

        @commands_block = block
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
      @_router.evaluate(&self.class.commands_block)
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
          invoke_command(context.runnable)
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
    def invoke_command(runnable)
      @lock.synchronize do
        runnable = instantiate_command(runnable)
        runnable.call(*runnable_args(runnable))
      end
    end

    # @api private
    def instantiate_command(runnable)
      return runnable if runnable.respond_to?(:call)

      case runnable
      when ::Class
        runnable.new
      when ::String, ::Symbol
        const_name = runnable.to_s.split("_").each(&:capitalize!).join
        runnable_class = self.class.const_get(const_name)
        runnable_class.new
      else
        raise Error, "unsupported runnable: #{runnable.inspect}"
      end
    end

    # @api private
    def runnable_args(runnable)
      arity = if runnable.respond_to?(:arity)
        runnable.arity
      else
        runnable.method(:call).arity
      end

      if arity < 1
        []
      elsif arity == 1
        [@output]
      end
    end

    # Print commands usage information
    #
    # @api private
    def usage(context, prefix: "")
      indent = " " * 2
      list = context.each_with_object([]) do |(name, cmd_context), acc|
               next if name.empty?
               cmd = "#{indent}#{prefix}#{' ' unless prefix.empty?}#{name}"
               acc << cmd
             end
      list.sort! { |cmd_a, cmd_b| cmd_a <=> cmd_b }

      "Commands:\n#{list.join("\n")}"
    end

    extend ClassMethods
  end # Runner
end # TTY
