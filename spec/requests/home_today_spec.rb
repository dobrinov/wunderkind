require "rails_helper"

# „Готово за днес" is a promise that today is done. It used to be made after
# any one answer — the eight placement problems, or two problems of thirty —
# and a reluctant child read it as leave to stop.
describe "The day on „Днес“", type: :request do
  let(:student) { create(:user, elo: 1200, placed_at: 1.day.ago, toured_at: 1.day.ago, daily_minutes_target: 10) }

  def answer!(assignment, minutes:)
    row = assignment.assignment_questions.create!(question: create(:question), position: assignment.assignment_questions.count + 1)
    row.create_user_answer!(user: student, value: "42", correct: true, response: { "value" => "42" }, duration_ms: minutes * 60_000)
  end

  before { sign_in student }

  it "does not call the day done after a couple of answers" do
    answer!(Assignment.create!(user: student, kind: :daily), minutes: 1)

    get home_path
    response.body.should include(I18n.t("home.daily_title"))
    response.body.should_not include(I18n.t("home.daily_done_title"))
  end

  it "calls it done once the minutes are reached" do
    answer!(Assignment.create!(user: student, kind: :practice), minutes: 10)

    get home_path
    response.body.should include(I18n.t("home.daily_done_title"))
  end

  it "calls it done once a daily session is seen through" do
    session = Assignment.create!(user: student, kind: :daily)
    answer!(session, minutes: 2)
    session.update!(completed_at: Time.current)

    get home_path
    response.body.should include(I18n.t("home.daily_done_title"))
  end
end
