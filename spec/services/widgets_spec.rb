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

  describe "multi_select" do
    let(:params) { { "options" => [ { "id" => "a", "label" => "12" }, { "id" => "b", "label" => "17" }, { "id" => "c", "label" => "24" } ] } }
    let(:solution) { { "correct" => %w[a c] } }

    it "needs every right option and no wrong one" do
      Widgets.correct?("multi_select", solution:, state: { "selected" => %w[c a] }, params:).should be(true)
      Widgets.correct?("multi_select", solution:, state: { "selected" => %w[a] }, params:).should be(false)
      Widgets.correct?("multi_select", solution:, state: { "selected" => %w[a b c] }, params:).should be(false)
      Widgets.correct?("multi_select", solution:, state: {}, params:).should be(false)
    end

    it "shows the chosen labels in the order the options are listed" do
      Widgets.display("multi_select", state: { "selected" => %w[c a] }, params:).should eq("12, 24")
    end

    it "shows the solution as labels too, not as an empty box" do
      Widgets.solution_display("multi_select", solution:, params:).should eq("12, 24")
    end

    it "separates options that are lists of their own" do
      params = { "options" => [ { "id" => "a", "label" => "7, 10, 13" }, { "id" => "b", "label" => "4, 9, 16" } ] }

      Widgets.solution_display("multi_select", solution: { "correct" => %w[a] }, params:).should eq("7, 10, 13")
      Widgets.display("multi_select", state: { "selected" => %w[a b] }, params:).should eq("7, 10, 13 | 4, 9, 16")
    end
  end

  describe "blanks" do
    let(:params) { { "fields" => [ { "id" => "x1", "label" => "x₁" }, { "id" => "x2", "label" => "x₂" } ] } }
    let(:solution) { { "values" => { "x1" => "3", "x2" => "0,5" } } }

    it "accepts any equivalent way of writing each value" do
      Widgets.correct?("blanks", solution:, state: { "values" => { "x1" => "3", "x2" => "1/2" } }, params:).should be(true)
      Widgets.correct?("blanks", solution:, state: { "values" => { "x1" => "3", "x2" => "0.5" } }, params:).should be(true)
      Widgets.correct?("blanks", solution:, state: { "values" => { "x1" => "3" } }, params:).should be(false)
      Widgets.correct?("blanks", solution:, state: { "values" => { "x1" => "4", "x2" => "0,5" } }, params:).should be(false)
    end

    it "shows each blank with its label" do
      Widgets.display("blanks", state: { "values" => { "x1" => "3", "x2" => "4" } }, params:).should eq("x₁ = 3, x₂ = 4")
    end
  end

  describe "grid_fill" do
    let(:solution) { { "cells" => { "0,1" => "15", "1,0" => "8" } } }

    it "checks every blank cell" do
      Widgets.correct?("grid_fill", solution:, state: { "cells" => { "0,1" => "15", "1,0" => "8" } }).should be(true)
      Widgets.correct?("grid_fill", solution:, state: { "cells" => { "0,1" => "15", "1,0" => "9" } }).should be(false)
      Widgets.correct?("grid_fill", solution:, state: { "cells" => { "0,1" => "15" } }).should be(false)
    end
  end

  describe "grid_shade" do
    it "checks the exact cells when the solution names them" do
      solution = { "cells" => [ "0,0", "1,2" ] }

      Widgets.correct?("grid_shade", solution:, state: { "cells" => [ "1,2", "0,0" ] }).should be(true)
      Widgets.correct?("grid_shade", solution:, state: { "cells" => [ "0,0" ] }).should be(false)
    end

    it "checks only how many when the solution names a count" do
      solution = { "count" => 3 }

      Widgets.correct?("grid_shade", solution:, state: { "cells" => [ "0,0", "0,1", "2,3" ] }).should be(true)
      Widgets.correct?("grid_shade", solution:, state: { "cells" => [ "0,0", "0,1" ] }).should be(false)
    end

    it "describes a counted solution rather than naming cells it does not have" do
      Widgets.solution_display("grid_shade", solution: { "count" => 3 }).should eq("кои да е 3 клетки")
      Widgets.solution_display("grid_shade", solution: { "cells" => [ "1,2", "0,0" ] }).should eq("2: 0,0, 1,2")
    end
  end

  describe "coordinate_plot" do
    let(:solution) { { "points" => [ [ 2, 1 ], [ -1, -3 ] ] } }

    it "ignores the order the points were placed in" do
      Widgets.correct?("coordinate_plot", solution:, state: { "points" => [ [ -1, -3 ], [ 2, 1 ] ] }).should be(true)
      Widgets.correct?("coordinate_plot", solution:, state: { "points" => [ [ 2, 1 ] ] }).should be(false)
      Widgets.correct?("coordinate_plot", solution:, state: { "points" => [ [ 2, 1 ], [ -1, 3 ] ] }).should be(false)
    end

    it "shows the points as coordinates" do
      Widgets.display("coordinate_plot", state: { "points" => [ [ 2, 1 ] ] }).should eq("(2; 1)")
    end
  end

  describe "categorize" do
    let(:params) do
      { "bins" => [ { "id" => "p", "label" => "просто" }, { "id" => "c", "label" => "съставно" } ],
        "items" => [ { "id" => "i1", "label" => "17" }, { "id" => "i2", "label" => "21" } ] }
    end
    let(:solution) { { "assignment" => { "i1" => "p", "i2" => "c" } } }

    it "needs every item in the right group" do
      Widgets.correct?("categorize", solution:, state: { "assignment" => { "i1" => "p", "i2" => "c" } }, params:).should be(true)
      Widgets.correct?("categorize", solution:, state: { "assignment" => { "i1" => "p", "i2" => "p" } }, params:).should be(false)
      Widgets.correct?("categorize", solution:, state: { "assignment" => { "i1" => "p" } }, params:).should be(false)
    end

    it "shows the groups the student built" do
      Widgets.display("categorize", state: { "assignment" => { "i1" => "p", "i2" => "c" } }, params:).
        should eq("просто: 17 | съставно: 21")
    end
  end

  describe "matcher" do
    let(:params) do
      { "left" => [ { "id" => "l1", "label" => "1/4" } ], "right" => [ { "id" => "r1", "label" => "25%" }, { "id" => "r2", "label" => "50%" } ] }
    end
    let(:solution) { { "pairs" => { "l1" => "r1" } } }

    it "checks every pair" do
      Widgets.correct?("matcher", solution:, state: { "pairs" => { "l1" => "r1" } }, params:).should be(true)
      Widgets.correct?("matcher", solution:, state: { "pairs" => { "l1" => "r2" } }, params:).should be(false)
      Widgets.correct?("matcher", solution:, state: {}, params:).should be(false)
    end

    it "shows the pairing" do
      Widgets.display("matcher", state: { "pairs" => { "l1" => "r1" } }, params:).should eq("1/4 → 25%")
    end
  end

  describe "angle_dial" do
    it "checks the angle within tolerance" do
      Widgets.correct?("angle_dial", solution: { "degrees" => 135, "tolerance" => 5 }, state: { "degrees" => 130 }).should be(true)
      Widgets.correct?("angle_dial", solution: { "degrees" => 135 }, state: { "degrees" => 130 }).should be(false)
      Widgets.correct?("angle_dial", solution: { "degrees" => 135 }, state: {}).should be(false)
    end
  end

  describe "clock_hands" do
    it "compares hours modulo 12" do
      Widgets.correct?("clock_hands", solution: { "hours" => 3, "minutes" => 40 }, state: { "hours" => 15, "minutes" => 40 }).should be(true)
      Widgets.correct?("clock_hands", solution: { "hours" => 3, "minutes" => 40 }, state: { "hours" => 3, "minutes" => 45 }).should be(false)
      Widgets.display("clock_hands", state: { "hours" => 3, "minutes" => 5 }).should eq("3:05")
    end
  end

  it "raises on unknown widgets" do
    expect { Widgets.find("marquee") }.to raise_error(ArgumentError)
  end
end
