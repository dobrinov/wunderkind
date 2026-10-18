require "rails_helper"

describe AnswerStats do
  let(:student) { create(:user) }
  let(:assignment) { Assignment.create!(user: student) }

  def answer(user: student, days_ago: 0, correct: false, skipped: false, verdict: nil, duration_ms: nil)
    assignment_question = assignment.assignment_questions.create!(
      question: create(:question), position: assignment.assignment_questions.count + 1
    )
    UserAnswer.create!(
      user:, assignment_question:, value: "42", correct:, skipped:, duration_ms:,
      response: { "value" => "42", "verdict" => verdict }.compact, created_at: days_ago.days.ago
    )
  end

  it "counts solved problems and the shares of wrong and skipped answers per day" do
    answer(correct: true)
    answer(correct: true)
    answer
    answer(skipped: true)

    today = described_class.new.days.last

    today.solved.should eq(3)
    today.wrong_rate.should eq(25.0)
    today.skipped_rate.should eq(25.0)
  end

  it "times the answered problems and not the skips" do
    answer(correct: true, duration_ms: 90_000)
    answer(skipped: true, duration_ms: 600_000)

    stats = described_class.new
    stats.days.last.minutes.should eq(1.5)
    stats.accuracy.should eq(100)
  end

  it "does not count an answer waiting for a grader as wrong" do
    answer(verdict: "pending_review")

    described_class.new.days.last.wrong.should eq(0)
  end

  it "leaves a day nobody answered on as a gap rather than a zero" do
    answer(days_ago: 2)

    described_class.new.days.last.wrong_rate.should be_nil
  end

  it "leaves admins out of everybody's numbers, but not out of their own" do
    admin = create(:user, role: :admin)
    answer(user: admin)

    described_class.new.days.last.solved.should eq(0)
    described_class.new(user: admin).days.last.solved.should eq(1)
  end
end
