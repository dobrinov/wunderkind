require "rails_helper"

describe "the time-spent chart on the student home page", type: :request do
  let(:student) { create(:user) }
  let(:assignment) { Assignment.create!(user: student) }

  def answer_days_ago(days, duration_ms:)
    assignment_question = assignment.assignment_questions.create!(
      question: create(:question, answer: "5"), position: assignment.assignment_questions.count + 1
    )
    UserAnswer.create!(
      user: student, assignment_question:, value: "5", correct: true, duration_ms:,
      response: { "value" => "5" }, created_at: days.days.ago
    )
  end

  before { sign_in student }

  it "is not drawn until two days carry a measured duration" do
    answer_days_ago(0, duration_ms: 120_000)
    answer_days_ago(3, duration_ms: nil) # active, but predates durations

    get calendar_path

    response.body.should_not include(I18n.t("home.time_spent"))
  end

  it "draws a bar per practised day and the daily goal line" do
    answer_days_ago(0, duration_ms: 120_000)
    answer_days_ago(3, duration_ms: 300_000)

    get calendar_path

    response.body.should include(I18n.t("home.time_spent"))
    response.body.should include(I18n.t("home.time_avg", minutes: 4)) # (2 + 5) / 2, rounded
    response.body.should include(I18n.t("home.time_goal", minutes: DailyPractice::DEFAULT_MINUTES))
    response.body.should include(I18n.t("home.time_point", date: I18n.l(Time.zone.today, format: :short), minutes: 2))
  end
end
