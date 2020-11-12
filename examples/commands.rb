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
    on "config", "Manage config file" do
      on "add", "Add a new entry", run: Config::AddCommand

      on :get, "Get value for a key", run: "get_command"

      on "remove", aliases: %w[rm] do
        desc "Remove an entry"

        run "remove_command#execute"
      end

      on "edit", "Open an editor" do
        run { puts "config editing..." }
      end
    end

    on "tag", "Manage tags" do
      on "create", "Add a new tag object", run: -> { puts "tag creating..." }

      on "delete", "Delete a tag object", run: -> { puts "tag deleting..." }
    end
  end
end

App.run
