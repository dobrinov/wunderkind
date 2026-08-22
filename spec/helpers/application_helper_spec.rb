require "rails_helper"

describe ApplicationHelper, type: :helper do
  describe "#internal_path" do
    it "accepts an app-internal path" do
      helper.internal_path("/calendar", "/").should eq("/calendar")
    end

    it "falls back on anything that could leave the site" do
      helper.internal_path("https://evil.com", "/").should eq("/")
      helper.internal_path("javascript:alert(1)", "/").should eq("/")
      helper.internal_path("//evil.com", "/").should eq("/")
      # Browsers normalize "\" to "/", so these are "//evil.com" in disguise.
      helper.internal_path("/\\evil.com", "/").should eq("/")
      helper.internal_path("\\/evil.com", "/").should eq("/")
      helper.internal_path("/calendar\\..", "/").should eq("/")
    end

    it "falls back on blank values" do
      helper.internal_path(nil, "/").should eq("/")
      helper.internal_path("", "/").should eq("/")
    end
  end
end
