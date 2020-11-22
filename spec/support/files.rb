# frozen_string_literal: true

require "tmpdir"

module Support
  module Files
    def within_tmpdir(&block)
      ::Dir.mktmpdir do |dir|
        ::Dir.chdir(dir, &block)
      end
    end

    def with_files(files)
      within_tmpdir do
        files.each do |fname, contents|
          ::FileUtils.mkdir_p(::File.dirname(fname))
          ::File.write(fname, contents)
        end
        yield
      end
    end
  end # Files
end # Support

RSpec.configure do |config|
  config.include(Support::Files)
end
