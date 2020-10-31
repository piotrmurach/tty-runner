# frozen_string_literal: true

RSpec.describe TTY::Runner::Context do
  describe "#add" do
    it "add child context" do
      root_context = described_class.new("foo")

      expect(root_context.root?).to eq(true)
      expect(root_context.children?).to eq(false)

      bar_context = root_context.add("bar")
      baz_context = root_context.add("baz")

      expect(root_context.children?).to eq(true)

      expect do |block|
        root_context.each(&block)
      end.to yield_successive_args(["bar", bar_context], ["baz", baz_context])
    end
  end

  describe "#runnable?" do
    it "doesn't set runnable by default" do
      foo_context = described_class.new("foo")
      expect(foo_context.runnable?).to eq(false)
    end

    it "sets runnable" do
      foo_context = described_class.new("foo", runnable: -> { "bar" })
      expect(foo_context.runnable?).to eq(true)
    end
  end

  describe "#<=>" do
    it "compares by command context name in alphabetical order" do
      foo_context = described_class.new("foo")
      bar_context = described_class.new("bar")

      expect(bar_context).to be < foo_context
    end
  end

  describe "#to_s" do
    it "returns name" do
      cmd_context = described_class.new("foo")
      expect(cmd_context.to_s).to eq("foo")
    end
  end

  describe "#dump" do
    it "dumps root context" do
      cmd_context = described_class.new("foo")
      expect(cmd_context.dump).to eq("foo")
    end

    it "dumps nested contexts" do
      cmd_context = described_class.new("foo")
      cmd_context.add("bar")
      get_cmd_context = cmd_context.add("baz")
      get_cmd_context.add("qux")

      expect(cmd_context.dump).to eq("foo => [bar, baz => [qux]]")
    end
  end
end
