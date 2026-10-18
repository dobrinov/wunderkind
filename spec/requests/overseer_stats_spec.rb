require "rails_helper"

describe "The admin answer stats", type: :request do
  let(:admin) { create(:user, role: :admin) }
  let(:student) { create(:user, name: "Мими") }
  let(:assignment) { Assignment.create!(user: student) }

  def answer(days_ago:, correct:)
    assignment_question = assignment.assignment_questions.create!(
      question: create(:question), position: assignment.assignment_questions.count + 1
    )
    UserAnswer.create!(
      user: student, assignment_question:, value: "42", correct:,
      response: { "value" => "42" }, created_at: days_ago.days.ago
    )
  end

  it "draws the chart, for everybody and for one user, with a value on every day" do
    answer(days_ago: 3, correct: false)
    answer(days_ago: 0, correct: true)
    sign_in admin

    get overseer_stats_path
    response.should have_http_status(:ok)
    response.body.should include(I18n.t("stats.subtitle"))
    # Everybody's days are not clickable; one user's are.
    response.body.should_not include("/overseer/stats/")
    response.body.scan('class="chart-tip"').size.should eq(30)

    get overseer_stats_path(user_id: student.id, days: 90)
    response.body.should include(I18n.t("overseer.stats.title_for", name: "Мими"))
    response.body.scan('class="chart-tip"').size.should eq(90)
    day = 3.days.ago.to_date.iso8601
    response.body.should include(overseer_stats_day_path(date: day, user_id: student.id))

    get overseer_stats_day_path(date: day, user_id: student.id)
    response.should have_http_status(:ok)
    response.body.should include(I18n.t("stats.day_wrong"))
  end

  it "is closed to students" do
    sign_in student
    get overseer_stats_path
    response.should redirect_to(root_path)
  end
end
