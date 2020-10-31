# frozen_string_literal: true

RSpec.describe TTY::Runner::Parser do
  it "finds no matching command" do
    root_context = TTY::Runner::Context.new("")
    parser = described_class.new(root_context)

    res = parser.parse(%w[foo], {})

    expect(res).to eq([nil, "", false])
    expect(parser.matched_argv).to eq([])
    expect(parser.remaining_argv).to eq(%w[foo])
  end

  it "finds a top level 'foo' command" do
    root_context = TTY::Runner::Context.new("")
    foo_context = root_context.add("foo")
    parser = described_class.new(root_context)

    res = parser.parse(%w[foo], {})

    expect(res).to eq([foo_context, "foo", true])
    expect(parser.matched_argv).to eq(%w[foo])
    expect(parser.remaining_argv).to eq([])
  end

  it "finds an exact match 'foo bar' subcommand " do
    root_context = TTY::Runner::Context.new("")
    foo_context = root_context.add("foo")
    bar_context = foo_context.add("bar")
    parser = described_class.new(root_context)

    res = parser.parse(%w[foo bar], {})

    expect(res).to eq([bar_context, "foo bar", true])
    expect(parser.matched_argv).to eq(%w[foo bar])
    expect(parser.remaining_argv).to eq([])
  end

  it "returns command when 'foo bar' matched and runnable" do
    root_context = TTY::Runner::Context.new("")
    foo_context = root_context.add("foo")
    runnable = -> { "baz" }
    bar_context = foo_context.add("bar", runnable)
    parser = described_class.new(root_context)

    res = parser.parse(%w[foo bar extra], {})

    expect(res).to eq([bar_context, "foo bar", true])
    expect(parser.matched_argv).to eq(%w[foo bar])
    expect(parser.remaining_argv).to eq(%w[extra])
  end
end
