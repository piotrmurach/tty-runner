# frozen_string_literal: true

require_relative "../lib/tty-runner"

class AddCommand
  include TTY::Option

  usage do
    program "app"

    command "add"

    desc "Add config entry"
  end

  argument :name do
    required
    desc "The name for the configuration option"
  end

  argument :value do
    required
    desc "The value for the configuration option"
  end

  def run(argv)
    puts "config adding #{params["name"]}:#{params["value"]}"
  end
end

class App < TTY::Runner
  commands do
    on "add", "Add config entry", run: "add_command#run"

    on "get", "Get config entry" do
      run do
        program :app

        command :get

        desc "Get an entry by name"

        argument :name do
          required
          desc "The name of the configured option"
        end

        def call(argv)
          puts "config getting #{params["name"]}"
        end
      end
    end
  end
end

App.run
