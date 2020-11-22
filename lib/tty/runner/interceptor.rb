# frozen_string_literal: true

require "tty-option"

module TTY
  class Runner
    module Interceptor
      def self.intercept(runnable, action: :call)
        unless runnable.included_modules.include?(TTY::Option)
          return
        end

        runnable.extend(ClassMethods)
        runnable.add_help_flag if runnable.respond_to?(:parameters)
        runnable.redefine_action(action) if runnable.method_defined?(action)
      end

      module ClassMethods
        def add_help_flag
          module_eval do
            unless parameters.map(&:key).include?(:help)
              flag :help, short: "-h", long: "--help", desc: "Print usage"
            end
          end
        end

        def redefine_action(action)
          module_eval do
            new_action = :"#{action}"
            old_action = :"tty_runner_original_#{action}"

            alias_method old_action, new_action

            define_method(new_action) do |argv|
              parse(argv)

              if params["help"] || argv.first == "help"
                $stderr.puts help
                exit
              end

              met_params = method(old_action).parameters
              req_args = met_params.select { |mp| [:req].include?(mp[0]) }
              arity = req_args.size
              args = arity < 1 ? [] : [argv]

              public_send(old_action, *args)
            end
          end
        end
      end
    end # Interceptor
  end # Runner
end # TTY
