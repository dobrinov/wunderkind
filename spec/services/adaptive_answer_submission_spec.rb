require "rails_helper"

describe AnswerSubmission, "adaptive behavior" do
  let(:user) { create(:user, elo: 1200) }
  let(:topic) { Topic.create!(name: "Дроби") }

  def build_assignment_question(question)
    assignment = Assignment.create!(user:)
    assignment.assignment_questions.create!(question:, position: 1)
  end

  it "halves XP for a hinted correct answer" do
    question = create(:question, answer: "5", elo: 1200)
    plain = AnswerSubmission.call(
      assignment_question: build_assignment_question(question), user:, raw: { value: "5" }
    )

    hinted_question = create(:question, answer: "5", elo: 1200)
    hinted_assignment_question = build_assignment_question(hinted_question)
    # Written by HintRevealsController as it serves each rung; the submission
    # reads it from the record, never from the request.
    hinted_assignment_question.update!(hints_revealed: 2)
    hinted = AnswerSubmission.call(
      assignment_question: hinted_assignment_question, user: user.reload, raw: { value: "5" }
    )

    hinted.answer.response["hints_used"].should eq(2)
    (hinted.xp_earned - Xp::SESSION_BONUS).should be < (plain.xp_earned - Xp::SESSION_BONUS)
  end

  it "schedules spaced review: growing intervals on success, reset on failure" do
    question = create(:question, answer: "5", elo: 1200, topics: [ topic ])
    AnswerSubmission.call(assignment_question: build_assignment_question(question), user:, raw: { value: "5" })

    skill = user.skills.find_by(topic:)
    skill.review_interval_days.should eq(3)
    skill.review_due_at.should be_within(1.minute).of(3.days.from_now)

    wrong_question = create(:question, answer: "5", elo: 1200, topics: [ topic ])
    AnswerSubmission.call(assignment_question: build_assignment_question(wrong_question), user: user.reload, raw: { value: "9" })

    skill.reload.review_interval_days.should eq(1)
  end

  it "marks a topic mastered at the threshold and pays the bonus" do
    user.update!(elo: 1395)
    skill = user.skills.create!(topic:, rating: 1395, games_count: 9)
    question = create(:question, answer: "5", elo: 1600, topics: [ topic ])

    outcome = AnswerSubmission.call(
      assignment_question: build_assignment_question(question), user:, raw: { value: "5" }
    )

    outcome.mastered_topics.should eq([ topic ])
    skill.reload.mastered_at.should be_present
    user.xp_events.where(reason: "topic_mastered").sum(:amount).should eq(AnswerSubmission::MASTERY_XP_BONUS)
    outcome.new_badges.map(&:key).should include("topic_master")
  end
end
