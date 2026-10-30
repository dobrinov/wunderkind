require "rails_helper"

describe AnswerRegrade do
  let(:student) { create(:user, elo: 1000) }

  def answered(question, value:, kind: :practice)
    assignment = Assignment.create!(user: student, kind: kind)
    assignment_question = assignment.assignment_questions.create!(question: question, position: 1)
    assignment_question.create_user_answer!(user: student, value: value, correct: false, response: { "value" => value })
  end

  it "gives back an answer the grader now reads as right, with the XP it was owed" do
    question = create(:question, answer: "5152", elo: 1000)
    answer = answered(question, value: "5 152")

    expect { AnswerRegrade.question!(question).should eq(1) }
      .to change { student.reload.total_xp }.by(Xp.amount_for_answer(correct: true, user_rating: 1000, question_rating: 1000) - Xp::ATTEMPT_AMOUNT)

    answer.reload.correct.should be(true)
    answer.response["regraded_at"].should be_present
    student.xp_events.last.reason.should eq("regrade")
  end

  it "leaves a wrong answer wrong, and never takes a right one away" do
    question = create(:question, answer: "42")
    wrong = answered(question, value: "41")

    AnswerRegrade.question!(question).should eq(0)
    wrong.reload.correct.should be(false)
  end

  it "picks up a fixed answer when the team corrects the question" do
    question = create(:question, answer: "20306", elo: 1200)
    answer = answered(question, value: "20306,25")

    question.update!(grading: { "expected" => "20306,25" })
    AnswerRegrade.question!(question).should eq(1)
    answer.reload.correct.should be(true)
  end

  it "pays a mistakes session the whole amount, since its wrong answer paid nothing" do
    question = create(:question, answer: "8", elo: 1000)
    answered(question, value: "8 евро", kind: :mistakes)

    expect { AnswerRegrade.question!(question) }
      .to change { student.reload.total_xp }.by(Xp.amount_for_answer(correct: true, user_rating: 1000, question_rating: 1000))
  end
end
