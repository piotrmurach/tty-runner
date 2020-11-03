# frozen_string_literal: true

require "optparse"

require_relative "../lib/tty-runner"

class AddCommand
  def parser
    @parser ||= create_option_parser
  end

  def create_option_parser
    OptionParser.new do |opts|
      opts.banner = "Usage: app add [OPTIONS] NAME VALUE"
      opts.separator "\nRun an add command"
      opts.separator "\nArguments:"
      opts.separator "  NAME   The name for the configuration option"
      opts.separator "  VALUE  The value for the configuration option"
      opts.separator "\nOptions"

      opts.on("-h", "--help", "Print usage") do
        puts opts
        exit
      end
    end
  end

  def parse(argv)
    parser.parse(argv)
  end

  def run(argv)
    parse(argv)

    params = {}
    params["name"] = argv.shift
    params["value"] = argv.shift

    if params["name"].nil?
      puts parser
      exit
    end

    puts "config adding #{params["name"]}:#{params["value"]}"
  end
end

class App < TTY::Runner
  commands do
    on "add", run: "add_command#run"
  end
end

App.run
