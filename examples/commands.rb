# frozen_string_literal: true

require_relative "../lib/tty-runner"

module Config
  class AddCommand
    def call
      puts "config adding..."
    end
  end

  class GetCommand
    def call
      puts "config getting..."
    end
  end

  class RemoveCommand
    def execute
      puts "config removing..."
    end
  end
end

class App < TTY::Runner
  commands do
    on "config" do
      on "add", run: Config::AddCommand

      on :get, run: "get_command"

      on "remove", aliases: %w[rm] do
        run "remove_command#execute"
      end

      on "edit" do
        run { puts "config editing..." }
      end
    end

    on "tag" do
      on "create", run: -> { puts "tag creating..." }

      on "delete", run: -> { puts "tag deleting..." }
    end
  end
end

App.run
