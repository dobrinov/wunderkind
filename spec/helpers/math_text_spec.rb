require "rails_helper"

describe ApplicationHelper, type: :helper do
  describe "#math_text" do
    it "stacks every fraction in running text, the way the question above it does" do
      html = helper.math_text("3/4 от 36 са 27. Остават 9, а 1/3 от тях е 3.")

      html.scan(%(class="frac")).length.should eq(2)
      html.should include("от 36 са 27")
    end

    it "leaves what is not a fraction alone and escapes the rest" do
      html = helper.math_text("60 km/h, 0,5/2 и <b>1/2/3</b>")

      html.should_not include(%(class="frac"))
      html.should include("&lt;b&gt;")
    end
  end
end
