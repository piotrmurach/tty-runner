# frozen_string_literal: true

RSpec.describe TTY::Runner, "#desc" do
  let(:stdout) { StringIO.new }

  context "displays command summaries" do
    before do
      stub_const("A", Class.new(TTY::Runner) do
        commands do
          on "foo", "Foo cmd desc" do
            on "a", "A cmd desc"
            on "b" do
              desc "B cmd desc"
            end
            on "c", "C cmd desc"
          end

          on "bar" do
            desc "Bar cmd desc"

            on "d", "D cmd desc"
            on "f", "F cmd desc"

            on "baz", "Baz cmd desc" do
              on "e", "E cmd desc"
            end
          end
        end
      end)

    end

    it "displays top level commands descriptions" do
      A.run(%w[], output: stdout)
      stdout.rewind
      expect(stdout.string).to eq([
        "Commands:",
        "  bar  Bar cmd desc",
        "  foo  Foo cmd desc\n"
      ].join("\n"))
    end

    it "displays 'foo' subcommands descriptions" do
      A.run(%w[foo], output: stdout)
      stdout.rewind
      expect(stdout.string).to eq([
        "Commands:",
        "  foo a  A cmd desc",
        "  foo b  B cmd desc",
        "  foo c  C cmd desc\n"
      ].join("\n"))
    end

    it "displays 'bar' subcommands descriptions" do
      A.run(%w[bar], output: stdout)
      stdout.rewind
      expect(stdout.string).to eq([
        "Commands:",
        "  bar baz  Baz cmd desc",
        "  bar d    D cmd desc",
        "  bar f    F cmd desc\n"
      ].join("\n"))
    end

    it "displays 'bar baz' subcommands descriptions" do
      A.run(%w[bar baz], output: stdout)
      stdout.rewind
      expect(stdout.string).to eq([
        "Commands:",
        "  bar baz e  E cmd desc\n"
      ].join("\n"))
    end
  end
end
