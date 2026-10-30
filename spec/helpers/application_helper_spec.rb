require "rails_helper"

describe ApplicationHelper, type: :helper do
  describe "#internal_path" do
    it "accepts an app-internal path" do
      helper.internal_path("/home", "/").should eq("/home")
    end

    it "falls back on anything that could leave the site" do
      helper.internal_path("https://evil.com", "/").should eq("/")
      helper.internal_path("javascript:alert(1)", "/").should eq("/")
      helper.internal_path("//evil.com", "/").should eq("/")
      # Browsers normalize "\" to "/", so these are "//evil.com" in disguise.
      helper.internal_path("/\\evil.com", "/").should eq("/")
      helper.internal_path("\\/evil.com", "/").should eq("/")
      helper.internal_path("/home\\..", "/").should eq("/")
    end

    it "falls back on blank values" do
      helper.internal_path(nil, "/").should eq("/")
      helper.internal_path("", "/").should eq("/")
    end
  end

  describe "#scratchpad_suggested?" do
    it "suggests the paper for a word problem long enough to need its numbers written down" do
      helper.scratchpad_suggested?(create(:question, text: "а" * ApplicationHelper::SCRATCHPAD_TEXT_LENGTH)).should be(true)
      helper.scratchpad_suggested?(create(:question, text: "Колко е 6 · 7?")).should be(false)
    end

    it "leaves a widget alone, however long its text" do
      helper.scratchpad_suggested?(create(:question, :interactive, text: "а" * 200)).should be(false)
    end
  end
end
