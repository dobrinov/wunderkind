require "rails_helper"

describe "Goals a parent sets, and the rewards they pay", type: :request do
  let(:parent) { create(:user, role: :parent, verified_at: Time.current) }
  let(:child) { create(:user, name: "Мими") }

  before { parent.parent_links.create!(child: child) }

  # Parked midweek, because almost every example here practises on the first
  # few days of the current week and then asserts they counted. Goals.progress
  # only counts days that have actually happened, so on a real Monday those
  # days are in the future and nine examples fail — a suite that goes red one
  # day in seven is a suite people learn to scroll past. Thursday leaves three
  # days behind it and three ahead.
  around do |example|
    travel_to(Time.zone.today.beginning_of_week.in_time_zone + 3.days + 9.hours) { example.run }
  end

  # Practice on a given day, with a measured duration — which is what a goal
  # counting minutes reads.
  def practise!(on:, problems: 1, minutes: 20, correct: true)
    assignment = Assignment.create!(user: child, created_at: on)

    problems.times do |index|
      question = create(:question, status: :draft)
      assignment.assignment_questions.create!(question: question, position: index + 1).
        create_user_answer!(
          user: child, value: "42", correct: correct, response: { "value" => "42" },
          duration_ms: (minutes * 60_000 / problems), created_at: on
        )
    end
  end

  def set_goal(**overrides)
    Goal.create!({
      parent: parent, child: child, metric: :minutes, mode: :daily, period: :week,
      threshold: 15, target: 2, starts_on: 3.weeks.ago.to_date, reward: "1 час Minecraft"
    }.merge(overrides))
  end

  describe Goals do
    # Set on a Thursday, a weekly goal of five days had a first week of four:
    # lost the moment it appeared. The first period asks for its share.
    it "asks a shorter first period for its share" do
      # The around hook puts today on this week's Thursday.
      today = Time.zone.today
      week = set_goal(target: 5, starts_on: today)
      Goals.standings(child).first.progress.target.should eq(4)
      monday = today.next_week
      Goals.target_for(week, [ monday, monday.end_of_week ]).should eq(5)

      month = set_goal(mode: :total, metric: :problems, period: :month, threshold: nil, target: 150, starts_on: today)
      left = (today.end_of_month - today).to_i + 1
      Goals.target_for(month, Goals.current_period(month)).should eq((150 * left / today.end_of_month.day.to_f).ceil)
    end

    it "counts a daily goal in days that cleared the bar, not in minutes" do
      set_goal
      monday = Time.zone.today.beginning_of_week
      practise!(on: monday.in_time_zone + 9.hours, minutes: 20)
      practise!(on: (monday + 1).in_time_zone + 9.hours, minutes: 5)   # short of the bar
      practise!(on: (monday + 2).in_time_zone + 9.hours, minutes: 16)

      standing = Goals.standings(child).first
      standing.progress.done.should eq(2)
      standing.progress.target.should eq(2)
      standing.progress.should be_complete
    end

    it "adds a total goal up instead" do
      set_goal(mode: :total, metric: :problems, target: 5, threshold: nil)
      practise!(on: Time.zone.today.beginning_of_week.in_time_zone + 9.hours, problems: 3)
      practise!(on: Time.zone.today.in_time_zone - 1.hour, problems: 2)

      Goals.standings(child).last.progress.done.should eq(5)
    end

    it "pays a reward once, however many times anybody looks" do
      goal = set_goal
      2.times { |day| practise!(on: (Time.zone.today.beginning_of_week + day).in_time_zone + 9.hours) }

      Goals.refresh!(child).size.should eq(1)
      Goals.refresh!(child).should be_empty
      goal.awards.count.should eq(1)
      goal.awards.first.reward.should eq("1 час Minecraft")
    end

    it "keeps the words that were promised when the goal is reworded afterwards" do
      goal = set_goal
      2.times { |day| practise!(on: (Time.zone.today.beginning_of_week + day).in_time_zone + 9.hours) }
      Goals.refresh!(child)

      goal.update!(reward: "Сладолед")

      goal.awards.first.reward.should eq("1 час Minecraft")
    end

    it "pays a weekly goal again the next week" do
      goal = set_goal
      last_week = Time.zone.today.beginning_of_week - 7
      2.times { |day| practise!(on: (last_week + day).in_time_zone + 9.hours) }
      2.times { |day| practise!(on: (Time.zone.today.beginning_of_week + day).in_time_zone + 9.hours) }

      Goals.refresh!(child)

      goal.awards.pluck(:period_start).should contain_exactly(last_week, Time.zone.today.beginning_of_week)
    end

    it "counts a mistakes session, which is practice the child really did" do
      set_goal(metric: :problems, mode: :total, target: 1, threshold: nil)
      assignment = Assignment.create!(user: child, kind: :mistakes)
      assignment.assignment_questions.create!(question: create(:question, status: :draft), position: 1).
        create_user_answer!(user: child, value: "42", correct: true, response: { "value" => "42" })

      Goals.standings(child).first.progress.done.should eq(1)
    end

    it "refuses a goal of more days than the period has" do
      Goal.new(
        parent: parent, child: child, metric: :minutes, mode: :daily, period: :week,
        threshold: 15, target: 9, starts_on: Time.zone.today, reward: "x"
      ).should_not be_valid
    end
  end

  describe "the parent's view of a child" do
    it "shows the goal, the progress and the reward owed" do
      set_goal
      2.times { |day| practise!(on: (Time.zone.today.beginning_of_week + day).in_time_zone + 9.hours) }

      sign_in parent
      get "/parents/children/#{child.id}?tab=goals"

      response.should have_http_status(:ok)
      response.body.should include("Мими")
      response.body.should include("1 час Minecraft")
      response.body.should include(I18n.t("goals.mark_used"))
      response.body.should include(I18n.t("goals.archive"))
    end

    it "opens on the progress tab, with the owed reward still above it" do
      set_goal
      2.times { |day| practise!(on: (Time.zone.today.beginning_of_week + day).in_time_zone + 9.hours) }

      sign_in parent
      get "/parents/children/#{child.id}"

      response.body.should include(RatingBand.new(child.reload.elo).grades_label)
      response.body.should include(I18n.t("goals.mark_used"))
      response.body.should_not include(I18n.t("goals.archive"))
    end

    it "sets a goal through the form, keeping only the number its mode uses" do
      sign_in parent
      post "/parents/children/#{child.id}/goals", params: {
        goal: { metric: "minutes", mode: "daily", period: "week",
                threshold: "15", target: "5", total_target: "100", reward: "1 час Minecraft" }
      }

      goal = Goal.last
      goal.target.should eq(5)
      goal.threshold.should eq(15)
      goal.reward.should eq("1 час Minecraft")
      response.should redirect_to("/parents/children/#{child.id}?tab=goals")
    end

    # The form is the sentence: every choice is a radio (so it works with no
    # script), and under it is the child's own card, drawn by the home page's
    # partial, saying what they will read.
    it "writes the new goal as one sentence, with the child's card under it" do
      sign_in parent
      get new_parents_child_goal_path(child)

      response.body.should include(I18n.t("goals.form.lead", name: "Мими"))
      { metric: %w[minutes problems correct], mode: %w[daily total], period: %w[week month once] }.each do |name, values|
        values.each { |value| response.body.should match(/type="radio" value="#{value}"[^>]*name="goal\[#{name}\]"/) }
      end
      response.body.should include(%(<turbo-frame id="goal_preview"))
      response.body.should include(I18n.t("goals.child_title"))
      response.body.should include(I18n.t("goals.form.save"))
    end

    it "previews the goal in the words the child will read, without saving it" do
      sign_in parent

      expect {
        get preview_parents_child_goals_path(child), params: {
          goal: { metric: "problems", mode: "total", period: "once", ends_on: 3.days.from_now.to_date.iso8601,
                  threshold: "15", target: "5", total_target: "40", reward: "Кино в събота" }
        }
      }.not_to change(Goal, :count)

      response.should have_http_status(:ok)
      response.body.should include(%(<turbo-frame id="goal_preview"))
      response.body.should include("Кино в събота")
      response.body.should include(CGI.escapeHTML(I18n.t("goals.sentence.total", count: 40, unit: I18n.t("goals.metrics.problems"))))
    end

    it "says in the preview what would stop the goal saving" do
      sign_in parent
      get preview_parents_child_goals_path(child), params: {
        goal: { metric: "minutes", mode: "daily", period: "week", threshold: "15", target: "9", reward: "" }
      }

      response.body.should include(I18n.t("activerecord.errors.models.goal.attributes.target.too_many_days", count: 7))
      response.body.should_not include(I18n.t("goals.child_title"))
    end

    it "keeps what was typed when the goal is refused" do
      sign_in parent
      post "/parents/children/#{child.id}/goals", params: {
        goal: { metric: "minutes", mode: "daily", period: "week", threshold: "20", target: "9", reward: "Кино" }
      }

      response.should have_http_status(:unprocessable_entity)
      Goal.count.should eq(0)
      response.body.should include(%(value="Кино"))
      response.body.should include(%(value="20"))
      response.body.should include(I18n.t("activerecord.errors.models.goal.attributes.target.too_many_days", count: 7))
    end

    it "will not set a goal for an unconfirmed parent" do
      allow(Mailing).to receive(:enabled?).and_return(true)
      parent.update!(verified_at: nil)
      sign_in parent

      post "/parents/children/#{child.id}/goals", params: {
        goal: { metric: "minutes", mode: "daily", period: "week", threshold: "15", target: "5", reward: "Кино" }
      }

      Goal.count.should eq(0)
    end

    it "takes the total field when the total mode is chosen" do
      sign_in parent
      post "/parents/children/#{child.id}/goals", params: {
        goal: { metric: "problems", mode: "total", period: "month",
                threshold: "15", target: "5", total_target: "100", reward: "Кино" }
      }

      goal = Goal.last
      goal.target.should eq(100)
      goal.threshold.should be_nil
    end

    it "marks a reward used, and only the parent who set it can" do
      goal = set_goal
      2.times { |day| practise!(on: (Time.zone.today.beginning_of_week + day).in_time_zone + 9.hours) }
      Goals.refresh!(child)
      award = goal.awards.first

      stranger = create(:user, role: :parent, verified_at: Time.current)
      sign_in stranger
      patch "/parents/rewards/#{award.id}"
      response.should have_http_status(:not_found)
      award.reload.should_not be_used

      sign_in parent
      patch "/parents/rewards/#{award.id}"
      award.reload.should be_used
    end

    it "ends a goal without taking back what it already paid" do
      goal = set_goal
      2.times { |day| practise!(on: (Time.zone.today.beginning_of_week + day).in_time_zone + 9.hours) }
      Goals.refresh!(child)

      sign_in parent
      delete "/parents/goals/#{goal.id}"

      goal.reload.should be_archived
      goal.awards.count.should eq(1)
      Goals.standings(child).should be_empty
    end

    it "keeps one parent out of another's child" do
      stranger = create(:user, role: :parent, verified_at: Time.current)

      sign_in stranger
      get "/parents/children/#{child.id}"
      response.should have_http_status(:not_found)
    end
  end

  describe "the child's own screen" do
    it "shows the goal in the parent's own words, and the reward once earned" do
      set_goal
      2.times { |day| practise!(on: (Time.zone.today.beginning_of_week + day).in_time_zone + 9.hours) }

      sign_in child
      get "/home"

      response.body.should include(I18n.t("goals.child_title"))
      response.body.should include("1 час Minecraft")
      response.body.should include(I18n.t("goals.earned"))
    end

    it "says nothing at all when nobody has set a goal" do
      sign_in child
      get "/home"

      response.body.should_not include(I18n.t("goals.child_title"))
    end
  end

  describe "the children list" do
    # The list is where a parent checks in, so the week and the goals are on
    # the card; the detail page and the child's profile are a click further.
    it "shows this week's practice and the goals on the child's card" do
      set_goal
      practise!(on: Time.zone.today - 1, problems: 4, minutes: 20)

      sign_in parent
      get "/parents/children"

      response.body.should include(I18n.t("parents.children.last_practised", count: 1))
      response.body.should include("1 час Minecraft")
      response.body.should include(I18n.t("parents.children.this_week"))
      response.body.should include(%(href="#{new_parents_child_goal_path(child, return_to: "children")}"))
    end

    it "brings a goal set from the list back to the list" do
      sign_in parent
      post parents_child_goals_path(child), params: {
        return_to: "children",
        goal: { metric: "minutes", mode: "daily", period: "week", threshold: 15, target: 5, reward: "кино" }
      }

      response.should redirect_to(parents_children_path)
    end

    it "pays out a completed goal when the list is opened" do
      set_goal(target: 1)
      practise!(on: Time.zone.today - 1, minutes: 20)

      sign_in parent
      get "/parents/children"

      response.body.should include(I18n.t("goals.owed", count: 1))
    end
  end
end
