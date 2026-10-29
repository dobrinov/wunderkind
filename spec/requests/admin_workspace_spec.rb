require "rails_helper"

# An admin is often somebody's parent too. The app is two places for them —
# „Семейство" and „Администрация" — under one header with a switch between
# them, a dashboard that glances at both, a choice of which one the app opens
# on, and a child bar that leads back to either.
describe "The admin's two places", type: :request do
  let(:admin) { create(:user, role: :admin, name: "Деян Добринов") }
  let!(:child) { User.create_managed_child!(parent: admin, name: "Мая") }

  before { sign_in admin }

  def file_report(user: create(:user), reason: :typo)
    QuestionReport.file!(question: create(:question), user: user, reason: reason)
  end

  describe "the header" do
    it "carries the workspace switch and the admin menu with what is waiting" do
      report = file_report
      QuestionReport.file_suggestion!(question: create(:question, status: :in_review), user: create(:user))

      get overseer_root_path

      response.body.should include(%(class="workspace-switch))
      response.body.should include(I18n.t("overseer.nav.inbox"))
      response.body.should include(%(<span class="nav-count">2</span>))
      response.body.should_not include(I18n.t("overseer.nav.reviews"))
      report.should be_present
    end

    it "shows the same switch on the family side, with the team's count on „Администрация“" do
      file_report

      get parents_children_path

      response.body.should include(%(class="workspace-switch))
      response.body.should include(I18n.t("nav.waiting", count: 1))
    end

    it "is the ordinary header for a parent who is not an admin" do
      delete sign_out_path
      sign_in create(:user, role: :parent)
      get parents_children_path

      response.body.should_not include(%(class="workspace-switch))
    end
  end

  describe "the dashboard" do
    it "lists what is waiting and the admin's own children" do
      file_report(user: child, reason: :wrong_answer)

      get overseer_root_path

      response.body.should include(I18n.t("overseer.dashboard.reports_waiting", count: 1))
      response.body.should include(I18n.t("overseer.dashboard.from_my_child", name: "Мая"))
      response.body.should include(I18n.t("overseer.dashboard.hand_over", name: "Мая"))
    end

    it "leaves the family out for an admin who has no children" do
      delete sign_out_path
      sign_in create(:user, role: :admin)
      get overseer_root_path

      response.body.should_not include(%(class="workspace-switch))
      response.body.should_not include(I18n.t("overseer.dashboard.family"))
      response.body.should include(I18n.t("overseer.nav.inbox"))
    end

    it "marks a reward given and comes back to the dashboard" do
      goal = Goal.create!(child: child, parent: admin, metric: :problems, mode: :total, period: :week, target: 5, reward: "кино", starts_on: Time.zone.today)
      award = goal.awards.create!(period_start: Time.zone.today.beginning_of_week, period_end: Time.zone.today.end_of_week,
                                  earned_at: Time.current, reward: "кино")

      get overseer_root_path
      response.body.should include("кино")

      patch parents_reward_path(award, return_to: overseer_root_path)
      response.should redirect_to(overseer_root_path)
      award.reload.should be_used
    end
  end

  describe "where the app opens" do
    it "opens wherever the admin was last, by default" do
      get parents_children_path
      delete sign_out_path
      sign_in admin
      response.should redirect_to(parents_children_path)

      get overseer_questions_path
      delete sign_out_path
      sign_in admin
      response.should redirect_to(overseer_root_path)
    end

    it "always opens the chosen side once one is chosen" do
      patch admin_landing_path, params: { admin_landing: "family" }
      admin.reload.should be_opens_in_family

      get overseer_questions_path
      delete sign_out_path
      sign_in admin
      response.should redirect_to(parents_children_path)
    end

    it "ignores a value that is not on offer, and refuses anybody who is not an admin" do
      patch admin_landing_path, params: { admin_landing: "elsewhere" }
      admin.reload.should be_opens_in_last

      delete sign_out_path
      parent = create(:user, role: :parent)
      sign_in parent
      patch admin_landing_path, params: { admin_landing: "admin" }
      parent.reload.should be_opens_in_last
    end
  end

  describe "handing the device over" do
    it "leads back to the very admin page it was handed over from" do
      report = file_report
      post switch_child_path(child), headers: { "Referer" => "http://www.example.com#{overseer_question_report_path(report)}" }

      get home_path
      response.body.should include(I18n.t("child_session.back_to"))

      delete switch_back_path(to: "admin")
      response.should redirect_to(overseer_question_report_path(report))
    end

    it "leads back to the family when that is the way chosen" do
      get parents_children_path
      post switch_child_path(child)
      delete switch_back_path

      response.should redirect_to(parents_children_path)
    end

    it "remembers only admin pages, and only their path" do
      post switch_child_path(child), headers: { "Referer" => "https://elsewhere.example/home" }
      delete switch_back_path(to: "admin")

      response.should redirect_to(overseer_root_path)
    end
  end
end
