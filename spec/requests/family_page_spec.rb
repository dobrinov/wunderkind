require "rails_helper"

# The family page on a phone: a big family is one row per child, and an owed
# reward says whose it is — a parent of twelve scrolled 10,000px of cards to
# find out.
describe "The family page", type: :request do
  let(:parent) { create(:user, role: :parent, verified_at: Time.current) }

  def children(count)
    Array.new(count) { |index| User.create_managed_child!(parent: parent, name: "Дете#{index} Петрово") }
  end

  it "lists a big family one row per child, with the way in" do
    kids = children(Parents::ChildrenController::ROWS_FROM + 1)
    sign_in parent
    get parents_children_path

    response.body.scan(I18n.t("parents.children.switch_short")).size.should be >= kids.size
    response.body.should_not include(I18n.t("goals.new"))
  end

  it "keeps full cards for a small family" do
    children(2)
    sign_in parent
    get parents_children_path

    response.body.should include(I18n.t("goals.new"))
  end

  it "names the child an owed reward is for" do
    first, = children(2)
    goal = Goal.create!(parent: parent, child: first, metric: :problems, mode: :total, period: :week, target: 1,
                        starts_on: 2.weeks.ago.to_date, reward: "Кино")
    GoalAward.create!(goal: goal, period_start: 1.week.ago.to_date.beginning_of_week,
                      period_end: 1.week.ago.to_date.end_of_week, earned_at: 3.days.ago, reward: "Кино")
    sign_in parent
    get parents_children_path

    response.body.should include(I18n.t("parents.today.owed_for", count: 1), "Дете0")
  end
end
