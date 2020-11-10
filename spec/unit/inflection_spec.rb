# frozen_string_literal: true

RSpec.describe TTY::Runner::Inflection, "#camelcase" do
  {
    "some_class_name" => "SomeClassName",
    "html_class" => "HtmlClass",
    "some_html_class" => "SomeHtmlClass",
    "ipv6_class" => "Ipv6Class"
  }.each do |underscored, class_name|
    it "converts #{underscored.inspect} to #{class_name.inspect}" do
      expect(described_class.camelcase(underscored)).to eq(class_name)
    end
  end
end
