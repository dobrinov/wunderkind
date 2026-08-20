require "rails_helper"

describe AnswerSubmission do
  let(:user) { create(:user) }
  let(:topic) { Topic.create!(name: "Дроби") }
  let(:question) { create(:question, answer: "5", elo: user.elo, topics: [ topic ]) }
  let(:assignment) do
    Assignment.create!(user:).tap do |a|
      a.assignment_questions.create!(question:, position: 1)
    end
  end
  let(:assignment_question) { assignment.assignment_questions.first }

  it "records a graded answer with response payload and duration" do
    outcome = AnswerSubmission.call(assignment_question:, user:, raw: { value: "5" }, duration_ms: 4200)

    outcome.result.correct.should be(true)
    outcome.answer.should be_persisted
    outcome.answer.correct.should be(true)
    outcome.answer.response.should eq({ "value" => "5", "hints_used" => 0 })
    outcome.answer.duration_ms.should eq(4200)
  end

  it "updates the per-topic skill and the question Elo" do
    AnswerSubmission.call(assignment_question:, user:, raw: { value: "5" })

    skill = user.skills.find_by(topic:)
    skill.rating.should be > 1200
    skill.games_count.should eq(1)
    question.reload.elo.should be < 1200

    user.reload.elo.should eq(skill.rating)
  end

  it "seeds a new skill from the user's global Elo" do
    user.update!(elo: 1500)
    AnswerSubmission.call(assignment_question:, user:, raw: { value: "wrong" })

    user.skills.find_by(topic:).rating.should be < 1500
  end

  it "awards more XP for correct answers on harder questions" do
    hard_question = create(:question, answer: "5", elo: user.elo + 400, topics: [ topic ])
    assignment.assignment_questions.create!(question: hard_question, position: 2)

    easy = AnswerSubmission.call(assignment_question:, user:, raw: { value: "5" })
    hard = AnswerSubmission.call(
      assignment_question: assignment.assignment_questions.second, user: user.reload, raw: { value: "5" }
    )

    # The second answer also completes the assignment, so strip the session bonus.
    (hard.xp_earned - Xp::SESSION_BONUS).should be > (easy.xp_earned - Xp::SESSION_BONUS)
  end

  it "gives a small consolation XP for wrong answers" do
    outcome = AnswerSubmission.call(assignment_question:, user:, raw: { value: "wrong" })

    outcome.xp_earned.should eq(Xp::ATTEMPT_AMOUNT + Xp::SESSION_BONUS)
  end

  it "completes the assignment, pays the session bonus, and updates the streak" do
    outcome = AnswerSubmission.call(assignment_question:, user:, raw: { value: "5" })

    outcome.assignment_completed.should be(true)
    assignment.reload.completed_at.should be_present
    user.reload.current_streak.should eq(1)
    user.total_xp.should eq(outcome.xp_earned)
    user.xp_events.count.should eq(2)
  end

  it "awards badges" do
    outcome = AnswerSubmission.call(assignment_question:, user:, raw: { value: "5" })

    outcome.new_badges.map(&:key).should include("first_session")
    user.badge_awards.pluck(:badge_key).should include("first_session")
  end

  it "refuses a blank submission without spending the student's Elo or XP" do
    elo_before = user.elo

    expect {
      AnswerSubmission.call(assignment_question:, user:, raw: { value: "  " })
    }.to raise_error(AnswerSubmission::BlankResponse)

    assignment_question.reload.user_answer.should be_nil
    user.reload.elo.should eq(elo_before)
    user.total_xp.should eq(0)
    question.reload.elo.should eq(elo_before)
  end

  it "refuses double answers" do
    AnswerSubmission.call(assignment_question:, user:, raw: { value: "5" })

    expect {
      AnswerSubmission.call(assignment_question: assignment_question.reload, user:, raw: { value: "5" })
    }.to raise_error(AnswerSubmission::AlreadyAnswered)
  end
end
