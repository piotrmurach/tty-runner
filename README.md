<div align="center">
  <a href="https://ttytoolkit.org"><img width="130" src="https://github.com/piotrmurach/tty/raw/master/images/tty.png" alt="TTY Toolkit logo" /></a>
</div>

# TTY::Runner

[![Gem Version](https://badge.fury.io/rb/tty-runner.svg)][gem]
[![Build Status](https://secure.travis-ci.org/piotrmurach/tty-runner.svg?branch=master)][travis]
[![Build status](https://ci.appveyor.com/api/projects/status/re0e9nyi6gavni77?svg=true)][appveyor]
[![Maintainability](https://api.codeclimate.com/v1/badges/03169126a4ba2d031ece/maintainability)][codeclimate]
[![Coverage Status](https://coveralls.io/repos/github/piotrmurach/tty-runner/badge.svg)][coverage]
[![Inline docs](http://inch-ci.org/github/piotrmurach/tty-runner.svg?branch=master)][inchpages]

[gem]: http://badge.fury.io/rb/tty-runner
[travis]: http://travis-ci.org/piotrmurach/tty-runner
[appveyor]: https://ci.appveyor.com/project/piotrmurach/tty-runner
[codeclimate]: https://codeclimate.com/github/piotrmurach/tty-runner/maintainability
[coverage]: https://coveralls.io/github/piotrmurach/tty-runner
[inchpages]: http://inch-ci.org/github/piotrmurach/tty-runner

> A command routing tree for terminal applications.

**TTY::Runner** provides independent command running component for [TTY](https://github.com/piotrmurach/tty) toolkit.

## Installation

Add this line to your application's Gemfile:

```ruby
gem "tty-runner"
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install tty-runner

## Contents

* [1. Usage](#1-usage)
* [2. API](#2-api)
  * [2.1 on](#21-on)
  * [2.2 run](#22-run)
  * [2.3 mount](#23-mount)

## 1. Usage

Here's an example of an application showing routing of commands and subcommands:

```ruby
# app.rb
require "tty-runner"

class App < TTY::Runner
  # The command line application commands are declared with the 'commands' method.
  commands do
    # Runs code inside a block when no commands are given. This is not
    # required as by default all commands will be listed instead.
    run do
      def call(argv)
        puts "root"
      end
    end

    # Matches when bare 'config' command is issued and by default
    # lists all immediate subcommands.
    on "config" do
      # Matches 'config add' subcommand and loads 'Config::AddCommand' object
      # based on the snake case name from the ':run' value. The 'Config::AddCommand'
      # needs to only implement a 'call' method that will be automatically invoked.
      on "add", "Add a new entry", run: "add_command"

      # The :run keyword accepts any callable object like a proc that will be
      # lazily evaluated when the 'config remove' command or 'config rm' alias
      # are matched.
      on "remove", aliases: %w[rm], run: -> { puts "removing from config..." }

      # The command can be given in an "command#action" format either via :run
      # keyword or using the 'run' helper method.
      # This will automatically convert 'get_command' into 'Config::GetCommand'
      # when 'config get' command is entered and invoke the 'execute' method.
      on "get" do
        run "get_command#execute"
      end

      # The 'run' helper can also accept a block that will be converted to
      # a command object when 'edit' subcommand is matched. It expects
      # a 'call' method implementation that optionally gets the rest of
      # unparsed command line arguments as a parameter.
      on "edit" do
        run do
          def call(argv)
            puts "editing with #{argv}"
          end
        end
      end
    end

    on "tag" do
      # This will match all commands starting with 'tag' and continue
      # matching process with subcommands from 'TagCommands' runner that
      # needs to be an instance of 'TTY::Runner'. This way you can compose
      # complex applications from smaller routing pieces.
      mount TagCommands
    end
  end
end

# Another 'TTY::Runner' application with commands that can be mounted
# inside another runner application. This way you can build complex
# command line applications from smaller parts.
class TagCommands < TTY::Runner
  commands do
    on "create" do
      run -> { puts "tag creating..." }
    end

    on "delete" do
      run -> { puts "tag deleting..." }
    end
  end
end
```

Then run your application with `run`:

```ruby
App.run
```

When no arguments are provided, the top level run block will trigger:

```
app.rb
# =>
# root
```

Supplying `config` command will list all the subcommands:

```
app.rb config
# =>
#  config add
#  config edit
#  config get
#  config remove
```

And when specific subcommand `rm` within the `config` scope is given:

```
app.rb config rm
# =>
# removing from config...
```

We can also run mounted `create` subcommand from `TagCommands` runner under the `tag` command:

```
app.rb tag create
# =>
# tag creating...
```

## 2. API

### 2.1 on

Using the `on` you can specify the name for the command that will match the command line input. With the `:run` parameter you can specify a command object to run. Supported values include an object that respond to `call` method or a string given as a snake case representing an object with corresponding action.

Here are few examples how to specify a command to run:

```ruby
on "cmd", run: -> { }                      # a proc to call
on "cmd", run: Command                     # a Command object to instantiate and call
on "cmd", run: "command"                   # invokes 'call' method by default
on "cmd", run: "command#action"            # specified custom 'action' method
on "cmd", run: "command", action: "action" # specifies custom 'action'
```

The same values can be provided to the `run` method inside the block:

```ruby
on "cmd" do
  run "command#action"
end
```

The `on` method also serves as a namespace for other (sub)commands. There is no limit on how deeply you can nest commands.

```ruby
on "foo", run: FooCommand do       # matches 'foo' and invokes 'call' on FooCommand instance
  on "bar", run: "bar_command" do  # matches 'foo bar' and invokes 'call' on BarCommand instance
    on "baz" do                    # matches 'foo bar baz' and invokes 'execute' on BazCommand instance
      run "baz_command#execute"
    end
  end
end
```

### 2.2 run

### 2.3 mount

In cases when your application grows in complexity and has many commands and each of these in turn has many subcommands, you can split and group commands into separate runner applications.

For example, given a `FooSubcommands` runner application that groups all `foo` related subcommands:

```ruby
# foo_subcommands.rb

class FooSubcommands < TTY::Runner
  commands do
    on "bar", run: -> { puts "run bar" }
    on "baz", run: -> { puts "run baz" }
  end
end
```

Using `mount`, we can nest our subcommands inside the `foo` command in the main application runner like so:

```ruby
require_relative "foo_subcommands"

class App < TTY::Runner
  commands do
    on "foo" do
      mount Subcommands
    end
  end
end
```

See [mount example](https://github.com/piotrmurach/tty-runner/blob/master/examples/mount.rb).

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/piotrmurach/tty-runner. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/piotrmurach/tty-runner/blob/master/CODE_OF_CONDUCT.md).


## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the TTY::Runner project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/piotrmurach/tty-runner/blob/master/CODE_OF_CONDUCT.md).

## Copyright

Copyright (c) 2020 Piotr Murach. See LICENSE for further details.
