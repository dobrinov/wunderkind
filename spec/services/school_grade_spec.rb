require "rails_helper"

describe SchoolGrade do
  it "puts a child in first grade in the school year of the calendar year they turn seven" do
    SchoolGrade.estimate(2019, on: Date.new(2026, 9, 15)).should eq(1)
    SchoolGrade.estimate(2019, on: Date.new(2027, 6, 1)).should eq(1)
    SchoolGrade.estimate(2019, on: Date.new(2027, 9, 1)).should eq(2)
  end

  it "moves the estimate by the offset — a year early is a grade up" do
    SchoolGrade.estimate(2018, offset: 1, on: Date.new(2026, 10, 1)).should eq(3)
    SchoolGrade.estimate(2018, offset: -1, on: Date.new(2026, 10, 1)).should eq(1)
  end

  it "says preschool and past school age rather than grade 0 or 13" do
    SchoolGrade.estimate(2021, on: Date.new(2026, 10, 1)).should eq(:preschool)
    SchoolGrade.estimate(2006, on: Date.new(2026, 10, 1)).should eq(:finished)
  end

  it "has nothing to say without a birth year" do
    SchoolGrade.estimate(nil).should be_nil
    SchoolGrade.label(nil).should be_nil
  end
end
