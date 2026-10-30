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

  it "switches range and scope: everybody, one family, one user" do
    sibling = create(:user, name: "Ники")
    parent = create(:user, role: :parent, name: "Бойко")
    parent.parent_links.create!(child: student)
    parent.parent_links.create!(child: sibling)
    stranger = create(:user, name: "Чужд")
    student.update_column(:last_seen_at, 1.hour.ago)
    answer(days_ago: 1, correct: true)
    answer(days_ago: 3, correct: false)
    Assignment.create!(user: stranger).then do |assignment|
      UserAnswer.create!(user: stranger, value: "1", correct: true, response: { "value" => "1" },
                         assignment_question: assignment.assignment_questions.create!(question: create(:question), position: 1))
    end
    sign_in admin

    get overseer_stats_path(days: 7)
    response.should have_http_status(:ok)
    response.body.scan('class="chart-tip"').size.should eq(7)
    response.body.should include(I18n.t("overseer.stats.funnels.title"), I18n.t("overseer.stats.cohorts.title"))
    # The picker lists the recently seen: the family by its parent, the child by name.
    response.body.should include(%(value="f#{parent.id}"), %(value="u#{student.id}"))
    headline = ->(body) { body[/#{I18n.t("overseer.stats.headline.problems")}<\/span>\s*<span[^>]*>(\d+)</, 1] }
    headline.(response.body).should eq("3")

    get overseer_stats_path(who: "f#{parent.id}", days: 90)
    response.should redirect_to(overseer_stats_path(family: parent.id, days: 90))
    follow_redirect!
    response.body.should include(I18n.t("overseer.stats.title_for_family", name: "Бойко"))
    response.body.scan('class="chart-tip"').size.should eq(90)
    headline.(response.body).should eq("2")
    response.body.should include(I18n.t("overseer.stats.scoped_note"))
    response.body.should_not include(I18n.t("overseer.stats.cohorts.title"))
    # A family's days do not open: the day list is one user's.
    response.body.should_not include("/overseer/stats/20")

    get overseer_stats_path(who: "u#{stranger.id}")
    follow_redirect!
    response.body.should include(I18n.t("overseer.stats.title_for", name: "Чужд"))
    headline.(response.body).should eq("1")

    get overseer_stats_path(who: "")
    response.should redirect_to(overseer_stats_path)
  end

  it "leaves the admins' own answers out of everybody's numbers" do
    sign_in admin
    Assignment.create!(user: admin).then do |assignment|
      UserAnswer.create!(user: admin, value: "1", correct: true, response: { "value" => "1" },
                         assignment_question: assignment.assignment_questions.create!(question: create(:question), position: 1))
    end

    get overseer_stats_path
    response.body[/#{I18n.t("overseer.stats.headline.problems")}<\/span>\s*<span[^>]*>(\d+)</, 1].should eq("0")
  end

  it "is closed to students" do
    sign_in student
    get overseer_stats_path
    response.should redirect_to(root_path)
  end
end
