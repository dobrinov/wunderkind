require "rails_helper"
require "open3"

# „Прочети ми" turns maths into words in the browser (app/javascript/lib/speakable.js);
# its cases are a node test, run here so the suite fails when they do.
RSpec.describe "speakable.js" do
  it "says the maths the way it is read aloud" do
    skip "node is not installed" unless system("node", "--version", out: File::NULL, err: File::NULL)

    output, status = Open3.capture2e("node", "--test", Rails.root.join("spec/javascript/speakable.test.mjs").to_s)
    expect(status).to be_success, output
  end
end
