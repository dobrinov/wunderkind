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

    it "accepts a rectangle of the right sides either way round" do
      solution = { "rectangle" => [ 2, 3 ] }
      across = [ "1,1", "1,2", "1,3", "2,1", "2,2", "2,3" ]
      down = [ "0,0", "0,1", "1,0", "1,1", "2,0", "2,1" ]

      Widgets.correct?("grid_shade", solution:, state: { "cells" => across }).should be(true)
      Widgets.correct?("grid_shade", solution:, state: { "cells" => down }).should be(true)
      Widgets.correct?("grid_shade", solution:, state: { "cells" => across.first(5) + [ "0,0" ] }).should be(false)
      Widgets.correct?("grid_shade", solution:, state: { "cells" => [ "0,0", "0,1", "0,2", "0,3", "0,4", "0,5" ] }).should be(false)
    end

    it "pins a rectangle to the top-left corner when the solution says so" do
      solution = { "rectangle" => [ 2, 3 ], "corner" => true }

      Widgets.correct?("grid_shade", solution:, state: { "cells" => [ "0,0", "0,1", "1,0", "1,1", "2,0", "2,1" ] }).should be(true)
      Widgets.correct?("grid_shade", solution:, state: { "cells" => [ "1,1", "1,2", "1,3", "2,1", "2,2", "2,3" ] }).should be(false)
    end

    it "describes a counted solution rather than naming cells it does not have" do
      Widgets.solution_display("grid_shade", solution: { "count" => 3 }).should eq("кои да е 3 клетки")
      Widgets.solution_display("grid_shade", solution: { "rectangle" => [ 2, 3 ] }).should eq("правоъгълник 2 на 3")
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

  describe "column_arithmetic" do
    let(:params) { { "operands" => %w[478 356], "op" => "+" } }

    it "grades the result row and ignores the carries" do
      Widgets.correct?("column_arithmetic", solution: { "result" => "834" }, state: { "result" => "834", "helpers" => {} }, params:).should be(true)
      Widgets.correct?("column_arithmetic", solution: { "result" => "834" }, state: { "result" => "0834" }, params:).should be(true)
      Widgets.correct?("column_arithmetic", solution: { "result" => "834" }, state: { "result" => "724", "helpers" => { "1" => "1" } }, params:).should be(false)
      Widgets.correct?("column_arithmetic", solution: { "result" => "834" }, state: {}, params:).should be(false)
    end
  end

  describe "balance_scale" do
    let(:params) { { "left" => { "x" => 3, "units" => 2 }, "right" => { "x" => 1, "units" => 8 } } }
    let(:solution) { { "x" => 3 } }
    let(:moves) { [ { "op" => "x", "k" => 1 }, { "op" => "units", "k" => 2 }, { "op" => "divide", "k" => 2 } ] }

    it "grades the value written for x, with or without moves" do
      Widgets.correct?("balance_scale", solution:, state: { "steps" => moves, "x" => "3" }, params:).should be(true)
      Widgets.correct?("balance_scale", solution:, state: { "x" => "3" }, params:).should be(true)
      Widgets.correct?("balance_scale", solution:, state: { "steps" => moves, "x" => "4" }, params:).should be(false)
      Widgets.correct?("balance_scale", solution:, state: { "steps" => moves }, params:).should be(false)
    end

    it "replays only the moves the pans can take" do
      Widgets.balance_after(params, [ { "op" => "units", "k" => 3 } ]).should be_nil
      Widgets.balance_after(params, [ { "op" => "divide", "k" => 3 } ]).should be_nil
      Widgets.balance_solved(Widgets.balance_after(params, moves)).should eq(3)
    end

    it "caps the moves, and shows the working only as far as a refused one" do
      Widgets.balance_after(params, [ { "op" => "divide", "k" => 1 } ] * 10_000).should be_nil
      Widgets.display("balance_scale", state: { "steps" => [ { "op" => "x", "k" => 1 }, { "op" => "units", "k" => 9 } ], "x" => "3" }, params:).
        should eq("3x + 2 = x + 8 → 2x + 2 = 8 → x = 3")
    end

    it "writes the moves out as equations, ending on the value written" do
      Widgets.display("balance_scale", state: { "steps" => moves, "x" => "3" }, params:).
        should eq("3x + 2 = x + 8 → 2x + 2 = 8 → 2x = 6 → x = 3")
      Widgets.display("balance_scale", state: { "steps" => moves.first(1), "x" => "4" }, params:).
        should eq("3x + 2 = x + 8 → 2x + 2 = 8 → x = 4")
      Widgets.solution_display("balance_scale", solution:, params:).should eq("x = 3")
    end
  end

  describe "geoboard" do
    let(:params) { { "size" => 7 } }
    let(:solution) { { "shape" => "rectangle", "area" => 12, "perimeter" => 14 } }

    it "accepts any rectangle that fits the rule, wherever it is drawn" do
      Widgets.correct?("geoboard", solution:, state: { "points" => [ [ 0, 0 ], [ 4, 0 ], [ 4, 3 ], [ 0, 3 ] ] }, params:).should be(true)
      Widgets.correct?("geoboard", solution:, state: { "points" => [ [ 2, 1 ], [ 2, 5 ], [ 5, 5 ], [ 5, 1 ] ] }, params:).should be(true)
      Widgets.correct?("geoboard", solution:, state: { "points" => [ [ 0, 0 ], [ 2, 0 ], [ 4, 0 ], [ 4, 3 ], [ 0, 3 ] ] }, params:).should be(true)
    end

    it "refuses the wrong size, the wrong shape and a shape whose sides cross" do
      Widgets.correct?("geoboard", solution:, state: { "points" => [ [ 0, 0 ], [ 6, 0 ], [ 6, 2 ], [ 0, 2 ] ] }, params:).should be(false)
      Widgets.correct?("geoboard", solution:, state: { "points" => [ [ 0, 0 ], [ 4, 0 ], [ 5, 3 ], [ 1, 3 ] ] }, params:).should be(false)
      Widgets.correct?("geoboard", solution: { "shape" => "polygon", "area" => 4 }, state: { "points" => [ [ 0, 0 ], [ 2, 2 ], [ 2, 0 ], [ 0, 2 ] ] }, params:).should be(false)
      Widgets.correct?("geoboard", solution:, state: { "points" => [ [ 0, 0 ], [ 9, 0 ], [ 9, 3 ], [ 0, 3 ] ] }, params:).should be(false)
    end

    it "refuses a drawing that folds back on itself or goes round twice" do
      spike = [ [ 0, 0 ], [ 3, 0 ], [ 1, 0 ], [ 1, 2 ] ]
      Widgets.correct?("geoboard", solution: { "shape" => "right_triangle", "area" => 1 }, state: { "points" => spike }, params:).should be(false)

      twice = [ [ 0, 0 ], [ 3, 0 ], [ 0, 3 ] ] * 2
      Widgets.correct?("geoboard", solution: { "shape" => "polygon", "area" => 9 }, state: { "points" => twice }, params:).should be(false)

      bowtie_at_a_peg = [ [ 0, 0 ], [ 2, 2 ], [ 4, 0 ], [ 4, 4 ], [ 2, 2 ], [ 0, 4 ] ]
      Widgets.polygon_facts(bowtie_at_a_peg).should be_nil
    end

    it "gives up on more points than a board has, quickly" do
      flood = [ [ 0, 0 ], [ 3, 0 ], [ 0, 3 ] ] * 2_000
      started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      Widgets.correct?("geoboard", solution:, state: { "points" => flood }, params:).should be(false)
      (Process.clock_gettime(Process::CLOCK_MONOTONIC) - started).should be < 0.1
    end

    it "knows a right triangle" do
      right = { "shape" => "right_triangle", "area" => 6 }
      Widgets.correct?("geoboard", solution: right, state: { "points" => [ [ 0, 0 ], [ 3, 0 ], [ 0, 4 ] ] }, params:).should be(true)
      Widgets.correct?("geoboard", solution: right, state: { "points" => [ [ 0, 0 ], [ 4, 0 ], [ 2, 3 ] ] }, params:).should be(false)
    end

    it "describes the drawing and the rule" do
      Widgets.display("geoboard", state: { "points" => [ [ 0, 0 ], [ 4, 0 ], [ 4, 3 ], [ 0, 3 ] ] }, params:).
        should eq(I18n.t("widgets.geoboard_display", corners: 4, area: "12", perimeter: "14"))
      Widgets.solution_display("geoboard", solution:, params:).should include(I18n.t("widgets.geoboard_shapes.rectangle"))
    end
  end

  describe "unit_circle" do
    it "compares the angles as a set, modulo 360" do
      Widgets.correct?("unit_circle", solution: { "angles" => [ 30, 150 ] }, state: { "angles" => [ 150, 30 ] }).should be(true)
      Widgets.correct?("unit_circle", solution: { "angles" => [ 0 ] }, state: { "angles" => [ 360 ] }).should be(true)
      Widgets.correct?("unit_circle", solution: { "angles" => [ 30, 150 ] }, state: { "angles" => [ 30 ] }).should be(false)
      Widgets.correct?("unit_circle", solution: { "angles" => [ 30, 150 ] }, state: { "angles" => [ 30, 150, 210 ] }).should be(false)
    end
  end

  describe "find_mistake" do
    let(:params) { { "lines" => [ "2(x + 3) = 14", "2x + 3 = 14", "2x = 11", "x = 5,5" ] } }

    it "needs the line the mistake is made on, not one it carried into" do
      Widgets.correct?("find_mistake", solution: { "line" => 1 }, state: { "line" => 1 }, params:).should be(true)
      Widgets.correct?("find_mistake", solution: { "line" => 1 }, state: { "line" => 2 }, params:).should be(false)
      Widgets.correct?("find_mistake", solution: { "line" => 1 }, state: {}, params:).should be(false)
      Widgets.display("find_mistake", state: { "line" => 1 }, params:).should eq("2x + 3 = 14")
    end
  end

  describe "number_hops" do
    let(:params) { { "start" => 37, "change" => 25, "hops" => [ 1, 5, 10, 20 ] } }
    let(:solution) { { "value" => "62" } }

    it "needs hops on offer that add up, and the right landing number" do
      Widgets.correct?("number_hops", solution:, state: { "hops" => [ 20, 5 ], "value" => "62" }, params:).should be(true)
      Widgets.correct?("number_hops", solution:, state: { "hops" => [ 10, 10, 5 ], "value" => "62" }, params:).should be(true)
      Widgets.correct?("number_hops", solution:, state: { "hops" => [ 20, 5 ], "value" => "52" }, params:).should be(false)
      Widgets.correct?("number_hops", solution:, state: { "hops" => [ 25 ], "value" => "62" }, params:).should be(false)
      Widgets.correct?("number_hops", solution:, state: { "value" => "62" }, params:).should be(false)
    end

    it "takes hops backwards for a subtraction" do
      params = { "start" => 62, "change" => -25, "hops" => [ 1, 5, 10, 20 ] }
      Widgets.correct?("number_hops", solution: { "value" => "37" }, state: { "hops" => [ -20, -5 ], "value" => "37" }, params:).should be(true)
      Widgets.correct?("number_hops", solution: { "value" => "37" }, state: { "hops" => [ -30, 5 ], "value" => "37" }, params:).should be(false)
      Widgets.display("number_hops", state: { "hops" => [ -20, -5 ], "value" => "37" }, params:).should eq("62 − 20 − 5 = 37")
    end
  end

  describe "inequality_line" do
    let(:solution) { { "edge" => -2, "closed" => true, "direction" => "right" } }

    it "needs the edge, the kind of dot and the direction" do
      Widgets.correct?("inequality_line", solution:, state: { "edge" => -2, "closed" => true, "direction" => "right" }).should be(true)
      Widgets.correct?("inequality_line", solution:, state: { "edge" => "-2", "closed" => "true", "direction" => "right" }).should be(true)
      Widgets.correct?("inequality_line", solution:, state: { "edge" => -2, "closed" => false, "direction" => "right" }).should be(false)
      Widgets.correct?("inequality_line", solution:, state: { "edge" => -2, "closed" => true, "direction" => "left" }).should be(false)
      Widgets.correct?("inequality_line", solution:, state: { "edge" => -1, "closed" => true, "direction" => "right" }).should be(false)
    end

    it "writes the answer as an inequality" do
      Widgets.display("inequality_line", state: { "edge" => -2, "closed" => true, "direction" => "right" }).should eq("x ≥ −2")
      Widgets.display("inequality_line", state: { "edge" => 1.5, "closed" => false, "direction" => "left" }).should eq("x < 1,5")
    end
  end

  describe "masking item ids" do
    let(:params) { { "items" => [ { "id" => "s0", "label" => "1" }, { "id" => "s1", "label" => "2" }, { "id" => "s2", "label" => "3" } ] } }

    it "gives the page opaque ids that say nothing about the order, different on every question" do
      masked = Widgets.masked_params("ordering", params, 41)["items"].map { |item| item["id"] }

      masked.should_not include("s0", "s1", "s2")
      masked.uniq.size.should eq(3)
      masked.should_not eq(Widgets.masked_params("ordering", params, 42)["items"].map { |item| item["id"] })
    end

    it "grades an answer given in masked ids and stores it in the real ones" do
      question = create(:question, answer_type: :interactive,
                                   grading: { "widget" => "ordering", "params" => params, "solution" => { "order" => %w[s0 s1 s2] } })
      tokens = Widgets.masked_params("ordering", params, question.id)["items"].map { |item| item["id"] }

      result = Grading.grade(question: question, raw: { state: { "order" => tokens }.to_json })

      result.correct.should be(true)
      result.response.should eq("state" => { "order" => %w[s0 s1 s2] })
    end

    it "maps both sides of a matcher back" do
      matcher = { "left" => [ { "id" => "l0", "label" => "a" } ], "right" => [ { "id" => "r0", "label" => "b" } ] }
      masked = Widgets.masked_params("matcher", matcher, 7)
      state = { "pairs" => { masked["left"].first["id"] => masked["right"].first["id"] } }

      Widgets.unmask_state("matcher", state, matcher, 7).should eq("pairs" => { "l0" => "r0" })
    end

    it "leaves widgets without item ids alone" do
      Widgets.masked_params("number_line", { "min" => 0 }, 1).should eq("min" => 0)
    end
  end

  it "raises on unknown widgets" do
    expect { Widgets.find("marquee") }.to raise_error(ArgumentError)
  end
end
