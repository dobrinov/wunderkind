require "rails_helper"

describe "Answer stats for students and parents", type: :request do
  let(:student) { create(:user, name: "Мими") }
  let(:parent) { create(:user, role: :parent, verified_at: Time.current) }
  let(:assignment) { Assignment.create!(user: student) }

  def answer(text:, days_ago: 0, correct: false, skipped: false)
    assignment_question = assignment.assignment_questions.create!(
      question: create(:question, text: text, body: RichContent.text_to_doc(text)),
      position: assignment.assignment_questions.count + 1
    )
    UserAnswer.create!(
      user: student, assignment_question:, value: skipped ? "" : "42", correct:, skipped:,
      response: { "value" => "42" }, created_at: days_ago.days.ago
    )
  end

  before do
    answer(text: "Колко е 6 по 7?", days_ago: 1)
    answer(text: "Колко е 2 плюс 2?", days_ago: 1, correct: true)
    answer(text: "Какво е синус?", days_ago: 1, skipped: true)
    answer(text: "Колко е 3 по 3?", days_ago: 0, correct: true)
  end

  it "draws the charts on the student home page, clickable through to a day's misses" do
    sign_in student

    get profile_path(days: 90)
    response.should have_http_status(:ok)
    response.body.should include(I18n.t("stats.subtitle"))
    day = 1.day.ago.to_date
    response.body.should include(stats_day_path(date: day.iso8601))
    # Today was all right answers, but it still opens — for its sessions.
    response.body.should include(stats_day_path(date: Time.zone.today.iso8601))

    get stats_day_path(date: day.iso8601)
    response.should have_http_status(:ok)
    response.body.should include("Колко е 6 по 7?")
    response.body.should include("Какво е синус?")
    response.body.should_not include("Колко е 2 плюс 2?")
    response.body.should include(I18n.t("review.open"))
    response.body.should include(daily_assignments_calendar_path(date: day))
  end

  it "shows a parent their child's charts and days, and only their own child's" do
    parent.parent_links.create!(child: student)
    stranger = create(:user)
    sign_in parent

    get parents_child_path(student)
    response.body.should include(I18n.t("stats.subtitle"))

    get stats_day_parents_child_path(student, date: 1.day.ago.to_date.iso8601)
    response.should have_http_status(:ok)
    response.body.should include("Колко е 6 по 7?")
    # The feedback page is the student's alone; the parent reads the answer on the row.
    response.body.should_not include(I18n.t("review.open"))
    response.body.should include(I18n.t("stats.expected"))

    get stats_day_parents_child_path(stranger, date: 1.day.ago.to_date.iso8601)
    response.should have_http_status(:not_found)
  end

  it "sends a date that is not one back to the charts" do
    sign_in student
    get stats_day_path(date: "nope")
    response.should redirect_to(profile_path(anchor: "stats"))
  end
end
