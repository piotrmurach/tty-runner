# frozen_string_literal: true

require "tty-option"

require_relative "../lib/tty-runner"

class BaseCommand
  include TTY::Option

  flag :help do
    short "-h"
    long "--help"
    desc "Print usage"
  end

  def run(argv)
    parse(argv)

    if params["help"] || argv.first == "help"
      puts help
      exit
    end
  end
end

class AddCommand < BaseCommand
  usage do
    program "app"

    command "add"

    desc "Run an add command"
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
    super(argv)

    puts "config adding #{params["name"]}:#{params["value"]}"
  end
end

class App < TTY::Runner
  commands do
    on "add", run: "add_command#run"
  end
end

App.run
