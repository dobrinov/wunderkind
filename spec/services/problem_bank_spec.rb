require "rails_helper"

require Rails.root.join("db/problem_generators/base.rb")
Dir[Rails.root.join("db/problem_generators/*.rb")].sort.each { |file| require file }

# The generated bank is the product's content, so its calibration is tested
# like code: ratings must rise with grade, and a young student must never be
# served material far above their level.
describe ProblemGenerators do
  describe ".elo_for" do
    it "rises monotonically with grade and with tier" do
      (1..6).each do |grade|
        ProblemGenerators.elo_for(grade: grade, tier: :easy).
          should be < ProblemGenerators.elo_for(grade: grade + 1, tier: :easy)
      end

      ProblemGenerators::TIERS.each_cons(2) do |lower, higher|
        ProblemGenerators.elo_for(grade: 4, tier: lower).
          should be < ProblemGenerators.elo_for(grade: 4, tier: higher)
      end
    end

    it "keeps a grade-1 problem well below a grade-5 problem" do
      ProblemGenerators.elo_for(grade: 1, tier: :competition).
        should be < ProblemGenerators.elo_for(grade: 5, tier: :easy)
    end
  end

  describe "generated problems" do
    let(:problems) { ProblemGenerators::Importer.collect_problems }

    it "produces at least 2000 unique problems" do
      problems.size.should be >= 2000
      problems.map { |p| p[:text] }.uniq.size.should eq(problems.size)
    end

    it "covers every grade from 1 to 7 and every difficulty tier" do
      problems.map { |p| p[:grade] }.uniq.sort.should eq((1..7).to_a)
      problems.map { |p| p[:tier] }.uniq.sort_by { |t| ProblemGenerators::TIERS.index(t) }.
        should eq(ProblemGenerators::TIERS)
    end

    it "gives every problem an answer, a known topic, and a matching rating" do
      known_topics = ProblemGenerators::Importer::TREE.values.flatten

      problems.each do |problem|
        problem[:answer].to_s.should_not be_empty
        known_topics.should include(problem[:topic])
        problem[:elo].should eq(ProblemGenerators.elo_for(grade: problem[:grade], tier: problem[:tier]))
      end
    end

    it "keeps multiple-choice options containing exactly one correct answer" do
      problems.select { |p| p[:options] }.each do |problem|
        problem[:options].count { |option| option.to_s == problem[:answer] }.should eq(1)
      end
    end

    it "configures every interactive problem for a registered widget" do
      problems.select { |p| p[:widget] }.each do |problem|
        Widgets.keys.should include(problem[:widget]["widget"])
        problem[:widget]["solution"].should be_present
      end
    end
  end
end

describe User, "grade-based starting rating" do
  it "starts each grade at its own level" do
    create(:user, grade: 1).elo.should eq(700)
    create(:user, grade: 4).elo.should eq(1090)
    create(:user, grade: 7).elo.should eq(1480)
  end

  it "leaves the rating alone once the student has answered anything" do
    user = create(:user, grade: 1)
    question = create(:question, elo: 700)
    assignment = Assignment.create!(user:)
    AnswerSubmission.call(
      assignment_question: assignment.assignment_questions.create!(question:, position: 1),
      user:, raw: { value: question.grading["expected"] }
    )
    earned = user.reload.elo

    user.update!(grade: 7)

    user.reload.elo.should eq(earned)
  end

  it "rejects grades outside 1..7" do
    build(:user, grade: 9).should_not be_valid
    build(:user, grade: nil).should be_valid
  end
end
