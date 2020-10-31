# frozen_string_literal: true

require_relative "lib/tty/runner/version"

Gem::Specification.new do |spec|
  spec.name          = "tty-runner"
  spec.version       = TTY::Runner::VERSION
  spec.authors       = ["Piotr Murach"]
  spec.email         = ["piot@piotrmurach.com"]
  spec.summary       = %q{A command routing tree for terminal applications.}
  spec.description   = %q{A command routing tree for terminal applications.}
  spec.homepage      = "https://ttytoolkit.org"
  spec.license       = "MIT"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"
  spec.metadata["bug_tracker_uri"] = "https://github.com/piotrmurach/tty-runner/issues"
  spec.metadata["changelog_uri"] = "https://github.com/piotrmurach/tty-runner/blob/master/CHANGELOG.md"
  spec.metadata["documentation_uri"] = "https://www.rubydoc.info/gems/tty-runner"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/piotrmurach/tty-runner"

  spec.files         = Dir["lib/**/*"]
  spec.extra_rdoc_files = ["README.md", "CHANGELOG.md", "LICENSE.txt"]
  spec.require_paths = ["lib"]
  spec.required_ruby_version = Gem::Requirement.new(">= 2.0.0")

  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec", ">= 3.0"
end
