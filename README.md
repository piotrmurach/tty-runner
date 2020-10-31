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

## Usage

Here's an example of an application showing routing of commands and subcommands:

```ruby
# app.rb
require "tty-runner"

class App < TTY::Runner
  # The 'commands' is the main entry point for defining commands
  # and subcommands. There is no limit for the level of possible nesting.
  commands do
    # Runs code inside a block when no commands are given. This is not
    # required as by default all commands will be listed instead.
    run { puts "root" }

    # Matches 'config' command and lists all immediate subcommands.
    on "config" do
      # Matches 'config add' subcommand and invokes 'AddCommand'
      # provided via the ':run' keyword. The AddCommand needs to
      # only provide a 'call' method.
      on "add", run: AddCommand

      # The run keyword accepts any callable object like a proc that will be
      # lazily evaluated when the 'config remove' command or 'config rm' alias
      # are matched.
      on "remove", aliases: %w[rm], run: -> { puts "removing from config..." }

      # The command can be given with a 'run' helper that will instantiate
      # and execute 'GetCommand' when 'config get' command is entered.
      on "get" do
        run GetCommand
      end

      # The 'run' helper will also execute a block when 'edit' subcommand matches.
      on "edit" do
        run { puts "editing..." }
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
      run { puts "tag creating..." }
    end

    on "delete" do
      run { puts "tag deleting..." }
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
