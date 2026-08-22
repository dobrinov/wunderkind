require "rails_helper"

# A hint ladder is offered by the *session*, not by the question: the same
# question carries the same hints into every kind of session, and the kind's
# policy decides — unless the single session says otherwise.
describe "Hint availability", type: :request do
  let(:student) { create(:user, elo: 1200) }

  def question_with_hint
    question = create(:question, answer: "5")
    question.create_hint!(ladder: [ "Раздели на две.", "Колко е половината от 10?" ], reviewed_at: Time.current)
    question
  end

  def session_of(kind, question, hints_allowed: nil)
    assignment = Assignment.create!(user: student, kind: kind, hints_allowed: hints_allowed)
    assignment.assignment_questions.create!(question: question, position: 1)
  end

  it "offers the ladder during practice" do
    assignment_question = session_of(:practice, question_with_hint)

    sign_in student
    get "/questions/#{assignment_question.id}"

    response.body.should include(I18n.t("hints.show"))
    # The offer, not the rungs: the ladder itself stays on the server until
    # each rung is asked for (and paid for) — see hint_reveals_spec.
    response.body.should include(question_hint_reveal_path(assignment_question))
    response.body.should_not include("Раздели на две.")
    response.body.should include(I18n.t("hints.xp_note"))
  end

  it "offers it in the daily session too" do
    assignment_question = session_of(:daily, question_with_hint)

    sign_in student
    get "/questions/#{assignment_question.id}"

    response.body.should include(I18n.t("hints.show"))
  end

  it "lets a single session override the policy" do
    quiet = session_of(:practice, question_with_hint, hints_allowed: false)

    sign_in student
    get "/questions/#{quiet.id}"
    response.body.should_not include(I18n.t("hints.show"))
  end

  it "still withholds an unreviewed ladder in practice" do
    question = create(:question, answer: "5")
    question.create_hint!(ladder: [ "Раздели на две." ])
    assignment_question = session_of(:practice, question)

    sign_in student
    get "/questions/#{assignment_question.id}"

    response.body.should_not include(I18n.t("hints.show"))
  end

  describe Assignment do
    it "reads the policy off the kind, with the column winning over it" do
      Assignment.new(kind: :practice).hints_allowed?.should eq(true)
      Assignment.new(kind: :daily).hints_allowed?.should eq(true)
      # The column wins over the policy, so one session can depart from it.
      Assignment.new(kind: :practice, hints_allowed: false).hints_allowed?.should eq(false)
    end
  end
end
