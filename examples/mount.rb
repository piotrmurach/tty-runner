# frozen_string_literal: true

require_relative "../lib/tty-runner"

class Config < TTY::Runner
  commands do
    on "add", run: -> { puts "config adding..." }

    on :get, run: -> { puts "config getting..." }

    on "rm", run: -> { puts "config removing..."}

    on "edit", run: -> { puts "config editing..." }
  end
end

class Tag < TTY::Runner
  commands do
    on "create", run: -> { puts "tag creating..." }

    on "delete", run: -> { puts "tag deleting..." }
  end
end

class App < TTY::Runner
  commands do
    on "config" do
      mount Config
    end
    on "tag" do
      mount Tag
    end
  end
end

App.run
