require "rails_helper"
require "open3"

# The calculator pages' arithmetic and drawing are JavaScript
# (app/javascript/lib/calculators); their cases are a node test, run here over
# every page's file so the suite fails when a page's printed example and its
# script disagree.
RSpec.describe "calculators" do
  it "computes what each page says, and draws at every slider's ends" do
    skip "node is not installed" unless system("node", "--version", out: File::NULL, err: File::NULL)

    pages = Calculators.all.map do |calculator|
      { slug: calculator.slug, modes: calculator.modes.map { |mode| { key: mode.key, inputs: mode.inputs.map(&:to_h) } },
        **calculator.by_locale.transform_values { |content| content.slice("copy", "modes") } }
    end

    output, status = Open3.capture2e({ "CALCULATORS" => pages.to_json }, "node", "--test",
                                     Rails.root.join("spec/javascript/calculators.test.mjs").to_s)
    expect(status).to be_success, output
  end
end
