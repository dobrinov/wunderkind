require "rails_helper"

describe TaughtFrom do
  it "reads an arithmetic fact off its own numbers" do
    TaughtFrom.fact_grade("Колко е 23 + 14?").should eq(1)
    TaughtFrom.fact_grade("Колко е 27 + 15?").should eq(2)
    TaughtFrom.fact_grade("Колко е 58 − 23?").should eq(1)
    TaughtFrom.fact_grade("Колко е 97 − 8?").should eq(2)
    TaughtFrom.fact_grade("Колко е 7 · 8?").should eq(2)
    TaughtFrom.fact_grade("Мая има 12 стикера").should be_nil
  end

  it "gives a family its grade, rung by rung where its numbers grow out of a grade" do
    rungs = [ 660, 740, 820, 910, 1000, 1100 ]

    TaughtFrom.for_row({ "family" => "numbers.compare", "elo" => 660 }, rungs: rungs).should eq(1)
    TaughtFrom.for_row({ "family" => "numbers.compare", "elo" => 1000 }, rungs: rungs).should eq(4)
    TaughtFrom.for_row({ "family" => "sortbins.temperature_compare", "elo" => 1050 }).should eq(6)
  end

  it "stretches a list over a family with a different number of rungs" do
    TaughtFrom.family_grade("numbers.compare", nil, 0, 3).should eq(1)
    TaughtFrom.family_grade("numbers.compare", nil, 2, 3).should eq(4)
  end

  it "falls back to the first grade that lists the family's topic" do
    TaughtFrom.for_row({ "family" => "unlisted.family", "topic" => "Дроби" }).should eq(3)
  end

  it "puts a past paper's problem in the grade the paper was set for" do
    TaughtFrom.for_row({ "family" => "numbers.compare", "source" => { "grade" => 3 } }).should eq(3)
  end

  it "names only families the corpus has, each with grades from 1 to 12" do
    families = Dir[Rails.root.join("db/seeds/ladders/*.yml")].flat_map do |file|
      YAML.safe_load_file(file).fetch("problems").filter_map { |problem| problem["family"] }
    end.to_set

    (TaughtFrom.map.keys - families.to_a).should be_empty
    TaughtFrom.map.values.flat_map { |value| Array(value) }.should all(be_between(1, 12))
  end

  describe "the grade hold" do
    def in_grade(grade)
      year = (1990..Time.zone.today.year).find { |y| SchoolGrade.estimate(y) == grade }
      create(:user, birth_year: year, elo: 800)
    end

    let!(:taught) { create(:question, elo: 800, taught_from_grade: 2) }
    let!(:ahead) { create(:question, elo: 800, taught_from_grade: 6) }
    let!(:ungraded) { create(:question, elo: 800, taught_from_grade: nil) }

    it "keeps a second-grader to problems school reaches within a year" do
      pool = Dispatcher.available_pool(in_grade(2))

      pool.should include(taught, ungraded)
      pool.should_not include(ahead)
    end

    it "lets a rating that has reached those grades have them" do
      child = in_grade(2)
      child.update!(elo: Curriculum.grades.find { |g| g.number == 6 }.floor)

      Dispatcher.available_pool(child).should include(ahead)
    end

    it "holds nothing back when nobody gave a birth year" do
      Dispatcher.available_pool(create(:user, elo: 800)).should include(ahead)
    end

    it "steps aside for a competition or a problem type the child chose" do
      Dispatcher.available_pool(in_grade(2), beyond_grade: true).should include(ahead)
    end

    it "holds a duel to what both players have been taught" do
      picked = Dispatcher.pick_shared([ in_grade(2), create(:user, elo: 800) ], count: 3)

      picked.should_not include(ahead)
    end
  end
end
