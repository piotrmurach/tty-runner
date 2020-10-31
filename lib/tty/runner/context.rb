# frozen_string_literal: true

module TTY
  class Runner
    # Command context
    class Context
      include Comparable
      include Enumerable

      # The parent that owns this context
      attr_accessor :parent

      # The command name
      attr_reader :name

      # The object to call when running command
      attr_accessor :runnable

      # The nested commands
      attr_reader :children

      # The aliases for this context command
      attr_reader :aliases

      def initialize(name, parent = EMPTY, runnable: nil)
        @name = name
        @parent = parent
        @runnable = runnable
        @children = {}
        @aliases = {}
      end

      # Add a child context
      #
      # @param [String] name
      # @param [Object|nil] runnable
      # @param [Array<String>] aliases
      #
      # @api public
      def add(name, runnable = nil, aliases: [])
        context = self.class.new(name, self, runnable: runnable)
        @children[name] = context
        aliases.each { |aliaz| @aliases[aliaz] = name }
        context
      end

      # Check if this context is empty
      def empty?
        @name.nil? && @parent.nil?
      end

      # Check if this context is top level
      def root?
        @parent.empty?
      end

      # Check if context has runnable command
      def runnable?
        !@runnable.nil?
      end

      def children?
        !@children.empty?
      end

      # Compare two different contexts
      def <=>(other)
        @name <=> other.name
      end

      # Lookup context based on the command name
      #
      # @param [String] name
      #
      # @api public
      def [](name)
        return self if @name == name && root?

        @children[@aliases.fetch(name, name)]
      end

      # Iterate over all the child contexts
      def each(&block)
        @children.each(&block)
      end

      # This context name
      def to_s
        name
      end

      # Dump the subcommands structure
      #
      # Useful for debugging
      #
      # @api private
      def dump
        res = name
        res += " => [#{each.map { |_, v| v.dump }.join(', ')}]" if children?
        res
      end

      EMPTY = Context.new(nil, nil)
    end # Context
  end # Runner
end # TTY
