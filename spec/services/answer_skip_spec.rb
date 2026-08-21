require "rails_helper"

describe AnswerSubmission, ".skip" do
  let(:user) { create(:user, elo: 1200) }
  let(:topic) { Topic.create!(name: "Дроби") }

  def build_assignment_question(question)
    Assignment.create!(user:).assignment_questions.create!(question:, position: 1)
  end

  it "records the skip without grading the student" do
    question = create(:question, answer: "5", elo: 1200, topics: [ topic ])
    outcome = AnswerSubmission.skip(assignment_question: build_assignment_question(question), user:)

    outcome.answer.should be_skipped
    outcome.answer.correct.should eq(false)
    outcome.answer.response["skipped"].should eq(true)
  end

  it "leaves the student's rating and topic skill untouched" do
    question = create(:question, answer: "5", elo: 1200, topics: [ topic ])
    user.skill_for(topic).update!(rating: 1250, games_count: 2)

    AnswerSubmission.skip(assignment_question: build_assignment_question(question), user:)

    user.reload.elo.should eq(1200)
    skill = user.skills.find_by(topic:)
    skill.rating.should eq(1250)
    skill.games_count.should eq(2)
  end

  it "raises the question's rating, most for questions the student should have met" do
    easy = create(:question, answer: "5", elo: 1000)
    hard = create(:question, answer: "5", elo: 2000)

    AnswerSubmission.skip(assignment_question: build_assignment_question(easy), user:)
    AnswerSubmission.skip(assignment_question: build_assignment_question(hard), user:)

    easy_bump = easy.reload.elo - 1000
    hard_bump = hard.reload.elo - 2000

    easy_bump.should be > hard_bump
    hard_bump.should be >= Elo::MIN_RATING_CHANGE
    easy_bump.should be <= Elo::SKIP_K_FACTOR
  end

  it "pays no XP and does not touch the streak" do
    assignment = Assignment.create!(user:)
    skipped = assignment.assignment_questions.create!(question: create(:question, topics: [ topic ]), position: 1)
    assignment.assignment_questions.create!(question: create(:question), position: 2)

    outcome = AnswerSubmission.skip(assignment_question: skipped, user:)

    outcome.xp_earned.should eq(0)
    user.reload.total_xp.should eq(0)
    user.current_streak.should eq(0)
  end

  it "defers the topic so the composer stops offering it" do
    question = create(:question, answer: "5", elo: 1200, topics: [ topic ])

    AnswerSubmission.skip(assignment_question: build_assignment_question(question), user:)

    skill = user.skills.find_by(topic:)
    skill.deferred_until.should be_within(1.minute).of(AnswerSubmission::DEFERRAL_DAYS.days.from_now)
    skill.review_due_at.should be >= skill.deferred_until
  end

  it "leaves a well-practised topic in the rotation" do
    question = create(:question, answer: "5", elo: 1200, topics: [ topic ])
    user.skill_for(topic).update!(games_count: AnswerSubmission::DEFERRAL_MAX_GAMES)

    AnswerSubmission.skip(assignment_question: build_assignment_question(question), user:)

    user.skills.find_by(topic:).deferred_until.should be_nil
  end

  it "refuses to skip a question that is already answered" do
    question = create(:question, answer: "5", elo: 1200)
    assignment_question = build_assignment_question(question)
    AnswerSubmission.call(assignment_question:, user:, raw: { value: "5" })

    expect {
      AnswerSubmission.skip(assignment_question: assignment_question.reload, user: user.reload)
    }.to raise_error(AnswerSubmission::AlreadyAnswered)
  end

  it "withholds the session bonus when every question was skipped" do
    assignment = Assignment.create!(user:)
    assignment_question = assignment.assignment_questions.create!(question: create(:question), position: 1)

    outcome = AnswerSubmission.skip(assignment_question:, user:)

    outcome.assignment_completed.should eq(true)
    outcome.xp_earned.should eq(0)
    user.reload.total_xp.should eq(0)
  end

  it "still pays the session bonus when something was attempted" do
    assignment = Assignment.create!(user:)
    answered = assignment.assignment_questions.create!(question: create(:question, answer: "5"), position: 1)
    skipped = assignment.assignment_questions.create!(question: create(:question), position: 2)

    AnswerSubmission.call(assignment_question: answered, user:, raw: { value: "5" })
    outcome = AnswerSubmission.skip(assignment_question: skipped, user: user.reload)

    outcome.xp_earned.should eq(Xp::SESSION_BONUS)
    outcome.new_badges.map(&:key).should include("first_session")
  end

  it "keeps skips out of the score" do
    assignment = Assignment.create!(user:)
    right = assignment.assignment_questions.create!(question: create(:question, answer: "5"), position: 1)
    wrong = assignment.assignment_questions.create!(question: create(:question, answer: "5"), position: 2)
    skipped = assignment.assignment_questions.create!(question: create(:question), position: 3)

    AnswerSubmission.call(assignment_question: right, user:, raw: { value: "5" })
    AnswerSubmission.call(assignment_question: wrong, user: user.reload, raw: { value: "9" })
    AnswerSubmission.skip(assignment_question: skipped, user: user.reload)

    assignment.reload.graded_questions_count.should eq(2)
    assignment.score_percentage.should eq(50)
  end
end
