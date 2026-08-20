require "rails_helper"

describe Widgets do
  describe "number_line" do
    it "checks the placed value with tolerance" do
      Widgets.correct?("number_line", solution: { "value" => 5, "tolerance" => 0.5 }, state: { "value" => 5.4 }).should be(true)
      Widgets.correct?("number_line", solution: { "value" => 5 }, state: { "value" => 5.4 }).should be(false)
      Widgets.correct?("number_line", solution: { "value" => 5 }, state: {}).should be(false)
    end
  end

  describe "ordering" do
    it "checks exact sequence" do
      solution = { "order" => %w[a b c] }
      params = { "items" => [ { "id" => "a", "label" => "1" }, { "id" => "b", "label" => "2" }, { "id" => "c", "label" => "3" } ] }

      Widgets.correct?("ordering", solution:, state: { "order" => %w[a b c] }, params:).should be(true)
      Widgets.correct?("ordering", solution:, state: { "order" => %w[b a c] }, params:).should be(false)
      Widgets.display("ordering", state: { "order" => %w[b a] }, params:).should eq("2 → 1")
    end
  end

  describe "fraction_bars" do
    it "checks shaded segment count" do
      Widgets.correct?("fraction_bars", solution: { "shaded" => 3 }, state: { "shaded" => 3 }, params: { "segments" => 4 }).should be(true)
      Widgets.correct?("fraction_bars", solution: { "shaded" => 3 }, state: { "shaded" => 2 }, params: { "segments" => 4 }).should be(false)
      Widgets.display("fraction_bars", state: { "shaded" => 3 }, params: { "segments" => 4 }).should eq("3/4")
    end
  end

  it "raises on unknown widgets" do
    expect { Widgets.find("marquee") }.to raise_error(ArgumentError)
  end
end
