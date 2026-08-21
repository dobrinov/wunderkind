require "rails_helper"

# A hint ladder is offered by the *session*, not by the question: the same
# question carries the same hints into practice and into homework, and only
# practice shows them unless the teacher said otherwise.
describe "Hint availability", type: :request do
  let(:student) { create(:user, elo: 1200) }
  let(:teacher) { create(:user, :teacher) }

  def question_with_hint
    question = create(:question, answer: "5")
    question.create_hint!(ladder: [ "Раздели на две.", "Колко е половината от 10?" ], reviewed_at: Time.current)
    question
  end

  def session_of(kind, question, homework: nil, hints_allowed: nil)
    assignment = Assignment.create!(user: student, kind: kind, homework: homework, hints_allowed: hints_allowed)
    assignment.assignment_questions.create!(question: question, position: 1)
  end

  it "offers the ladder during practice" do
    assignment_question = session_of(:practice, question_with_hint)

    sign_in student
    get "/questions/#{assignment_question.id}"

    response.body.should include(I18n.t("hints.show"))
    response.body.should include("Раздели на две.")
    response.body.should include(I18n.t("hints.xp_note"))
  end

  it "offers it in the daily session too" do
    assignment_question = session_of(:daily, question_with_hint)

    sign_in student
    get "/questions/#{assignment_question.id}"

    response.body.should include(I18n.t("hints.show"))
  end

  it "withholds it in homework by default" do
    homework = Homework.create!(assigner: teacher, title: "Дроби", due_at: 1.week.from_now)
    assignment_question = session_of(:homework, question_with_hint, homework: homework)

    sign_in student
    get "/questions/#{assignment_question.id}"

    response.body.should_not include(I18n.t("hints.show"))
    response.body.should_not include("Раздели на две.")
  end

  it "offers it in homework the teacher opened up" do
    homework = Homework.create!(assigner: teacher, title: "Дроби", due_at: 1.week.from_now, hints_allowed: true)
    assignment_question = session_of(:homework, question_with_hint, homework: homework)

    sign_in student
    get "/questions/#{assignment_question.id}"

    response.body.should include(I18n.t("hints.show"))
  end

  it "lets a single session override the policy either way" do
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
    it "reads the policy off the kind, and the teacher's choice off the homework" do
      Assignment.new(kind: :practice).hints_allowed?.should eq(true)
      Assignment.new(kind: :daily).hints_allowed?.should eq(true)
      Assignment.new(kind: :homework).hints_allowed?.should eq(false)

      homework = Homework.create!(assigner: teacher, title: "Дроби", due_at: 1.week.from_now, hints_allowed: true)
      Assignment.new(kind: :homework, homework: homework).hints_allowed?.should eq(true)
      # The column wins over both, so one session can depart from the policy.
      Assignment.new(kind: :homework, homework: homework, hints_allowed: false).hints_allowed?.should eq(false)
      Assignment.new(kind: :practice, hints_allowed: false).hints_allowed?.should eq(false)
    end
  end
end
