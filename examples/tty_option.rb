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
  end
end

App.run
