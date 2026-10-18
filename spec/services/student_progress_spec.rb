require "rails_helper"

describe StudentProgress do
  def trend_of(ratings, direction: :up)
    weeks = ratings.each_with_index.map do |rating, index|
      PerformanceTrend::Week.new(starts_on: Date.new(2026, 8, 3) + (index * 7), rating: rating, answers: rating ? 10 : 0, correct: rating ? 7 : 0)
    end
    instance_double(PerformanceTrend, weeks: weeks, enough?: weeks.count(&:solved?) >= 2, direction: direction)
  end

  let(:student) { build(:user, elo: 1037) }

  it "measures the gain against a month ago, not the first week on record" do
    progress = described_class.new(student, trend_of([ 700, 800, 850, nil, 900, 920, 980 ]))

    # The latest week (980) against the latest one at least four weeks before
    # it (850) — a gap week still counts as a week gone by.
    progress.gain.should eq([ 130, 4 ])
  end

  it "reports no number when the student has not climbed" do
    progress = described_class.new(student, trend_of([ 950, 900 ], direction: :down))

    progress.gain.should be_nil
    progress.mood.should eq(:harder_week)
  end

  it "has nothing to compare for a new student, and says so kindly" do
    progress = described_class.new(student, trend_of([ nil, 900 ]))

    progress.gain.should be_nil
    progress.mood.should eq(:keep_going)
  end

  it "cuts the rating into short steps" do
    progress = described_class.new(student, trend_of([]))

    progress.to_next_step.should eq(13)
    progress.step_fraction.should be_within(0.001).of(0.74)
  end
end
