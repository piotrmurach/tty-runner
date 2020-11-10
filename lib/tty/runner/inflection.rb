# frozen_string_literal: true

module TTY
  class Runner
    module Inflection
      # Convert snakecase string into camelcase
      #
      # @param [String] string
      #
      # @api public
      def camelcase(string)
        string.split("_").each(&:capitalize!).join
      end
      module_function :camelcase
    end
  end # Runner
end # TTY
