require "rails_helper"

describe "The admin people pages", type: :request do
  include ActiveJob::TestHelper

  let(:admin) { create(:user, name: "Деян Админов", role: :admin, verified_at: Time.current) }
  let(:mother) { create(:user, name: "Мария Петрова", role: :parent, verified_at: Time.current) }
  let(:father) { create(:user, name: "Иван Петров", role: :parent) }
  let(:nikola) { create(:user, name: "Никола Петров", nickname: "Ники") }
  let(:elena) { User.create_managed_child!(parent: mother, name: "Елена Петрова") }
  let(:topic) { Topic.create!(name: "Дроби", slug: "drobi") }

  before do
    ParentLink.create!(parent: mother, child: nikola)
    ParentLink.create!(parent: father, child: nikola)
    elena
  end

  def answer!(user, correct: true, skipped: false, kind: :practice, at: Time.current)
    assignment = Assignment.create!(user:, kind:, completed_at: at)
    question = create(:question, elo: 1100).tap { it.topics << topic }
    assignment.assignment_questions.create!(question:, position: 1).
      create_user_answer!(user:, value: "42", correct:, skipped:, response: { "value" => "42" }, created_at: at, duration_ms: 60_000)
  end

  describe "the list" do
    it "is closed to everyone who is not an admin" do
      sign_in mother
      get "/overseer/users"
      response.should redirect_to(root_path)
    end

    it "shows a family once, both parents over their children, and a lone parent where they stopped" do
      create(:user, name: "Георги Самотен", role: :parent)
      create(:user, name: "Сам Сирак")
      sign_in admin

      get "/overseer/users"

      response.should have_http_status(:ok)
      response.body.should_not include("translation_missing")
      body = response.body
      body.scan("Никола Петров").size.should eq(1)
      body.index("Мария Петрова").should be < body.index("Никола Петров")
      body.index("Иван Петров").should be < body.index("Никола Петров")
      body.should include(I18n.t("overseer.people.kinds.managed", name: "Мария"))
      body.should include(I18n.t("overseer.people.kinds.linked"))
      body.should include("Георги Самотен")
      body.should include(I18n.t("overseer.people.no_children_tag"))
      body.should_not include("Сам Сирак")
      body.should include(I18n.t("overseer.people.families_shown", shown: 2, total: 2))
    end

    it "lists the students nobody is linked to on their own tab" do
      create(:user, name: "Сам Сирак")
      sign_in admin

      get "/overseer/users", params: { view: "orphans" }

      response.body.should include("Сам Сирак")
      response.body.should_not include("Никола Петров")
    end

    it "keeps the flat list of everybody" do
      sign_in admin
      get "/overseer/users", params: { view: "all" }

      response.body.should include("<table")
      [ admin, mother, father, nikola, elena ].each { |user| response.body.should include(user.name) }
      response.body.should include(I18n.t("overseer.users.managed_by", name: mother.name))
    end

    it "searches and filters families by any member" do
      create(:user, name: "Георги Самотен", role: :parent, created_at: 1.month.ago)
      sign_in admin

      get "/overseer/users", params: { q: "ники" }
      response.body.should include("Мария Петрова")
      response.body.should_not include("Георги Самотен")

      get "/overseer/users", params: { f: %w[new] }
      response.body.should include("Мария Петрова")
      response.body.should_not include("Георги Самотен")

      QuestionReport.create!(question: create(:question), user: elena, reason: :typo)
      get "/overseer/users", params: { f: %w[tickets] }
      response.body.should include(I18n.t("overseer.people.open_tickets", count: 1))
      response.body.should include("Мария Петрова")

      get "/overseer/users", params: { f: %w[unverified] }
      response.body.should include("Иван Петров")

      get "/overseer/users", params: { family: mother.id }
      response.body.should include(I18n.t("overseer.people.one_family"))
    end

    it "offers to view as a parent or student, never as an admin" do
      ParentLink.create!(parent: admin, child: create(:user, name: "Дете на админа"))
      sign_in admin

      get "/overseer/users"

      response.body.should include(I18n.t("overseer.people.admin_you"))
      response.body.should include(impersonate_path(mother))
      response.body.should_not include(impersonate_path(admin))
    end
  end

  describe "a student's page" do
    before do
      answer!(nikola, at: 2.days.ago)
      answer!(nikola, correct: false, at: 1.day.ago)
      answer!(nikola, skipped: true, correct: false)
      answer!(nikola, kind: :mistakes)
      nikola.skills.create!(topic:, rating: 1260, games_count: 4, mastered_at: 3.days.ago)
      QuestionReport.create!(question: create(:question), user: nikola, reason: :typo)
      sign_in admin
    end

    it "names their parents and siblings, the way back to the family and the view-as button" do
      get "/overseer/users/#{nikola.id}"

      response.should have_http_status(:ok)
      response.body.should_not include("translation_missing")
      body = response.body
      body.should include(I18n.t("overseer.people.family_of", names: "Мария и Иван"))
      body.should include(overseer_user_path(mother))
      body.should include(overseer_user_path(father))
      body.should include(overseer_user_path(elena))
      body.should include(I18n.t("overseer.people.view_as", name: "Никола"))
      body.should include(I18n.t("overseer.people.session_kinds.mistakes"))
      body.should include(I18n.t("overseer.people.unmeasured"))
      body.should include("Дроби")
      body.should include(I18n.t("overseer.people.skill_states.mastered", date: I18n.l(3.days.ago.to_date, format: :short)))
    end

    it "reads 30 days of answers into the share of right answers and of skips" do
      get "/overseer/users/#{nikola.id}"

      # Three attempted (one wrong), one skip among four.
      response.body.should include("67%")
      response.body.should include("25%")
    end

    it "renders every tab" do
      Overseer::UsersController::STUDENT_TABS.each do |tab|
        get "/overseer/users/#{nikola.id}", params: { tab: }
        response.should have_http_status(:ok)
        response.body.should_not include("translation_missing")
      end

      get "/overseer/users/#{nikola.id}", params: { tab: "answers" }
      response.body.should include(I18n.t("overseer.people.verdicts.skipped"))
      response.body.should include(I18n.t("overseer.people.verdicts.wrong"))

      get "/overseer/users/#{nikola.id}", params: { tab: "tickets" }
      response.body.should include(overseer_question_report_path(nikola.question_reports.sole))
    end

    it "shows a student nobody is linked to, back to the orphans tab" do
      alone = create(:user, name: "Сам Сирак")
      get "/overseer/users/#{alone.id}"

      response.should have_http_status(:ok)
      response.body.should_not include("translation_missing")
      response.body.should include(overseer_users_path(view: "orphans"))
    end
  end

  describe "a parent's page" do
    before { sign_in admin }

    it "shows the children's week, the other parent, the first steps and every tab" do
      answer!(elena)
      Goal.create!(parent: mother, child: elena, metric: :problems, mode: :total, period: :week,
                   target: 20, starts_on: Time.zone.today.beginning_of_week, reward: "кино в събота")

      get "/overseer/users/#{mother.id}"

      response.should have_http_status(:ok)
      response.body.should_not include("translation_missing")
      body = response.body
      body.should include("Елена Петрова")
      body.should include("Иван Петров")
      body.should include(I18n.t("overseer.people.first_steps.title"))
      body.should include("кино в събота")
      body.should include(I18n.t("overseer.people.delete.takes_children", name: "Мария", children: "Елена Петрова"))

      Overseer::UsersController::PARENT_TABS.each do |tab|
        get "/overseer/users/#{mother.id}", params: { tab: }
        response.should have_http_status(:ok)
        response.body.should_not include("translation_missing")
      end
    end

    it "says where a parent with no children stopped" do
      lone = create(:user, name: "Георги Самотен", role: :parent)

      get "/overseer/users/#{lone.id}"

      response.body.should include(I18n.t("overseer.people.first_steps.stopped", step: 2, total: 4))
    end

    it "gives an admin who is a parent the parent page, tagged" do
      ParentLink.create!(parent: admin, child: create(:user, name: "Дете на админа"))

      get "/overseer/users/#{admin.id}"

      response.body.should include(I18n.t("overseer.people.admin_you"))
      response.body.should include("Дете на админа")
      response.body.should_not include(impersonate_path(admin))
    end

    it "shows only what is stored about emails" do
      mother.update!(weekly_report_sent_on: Date.new(2026, 10, 26))

      get "/overseer/users/#{mother.id}", params: { tab: "emails" }

      response.body.should include(I18n.l(Date.new(2026, 10, 26), format: :long))
      response.body.should include(I18n.t("email_preferences.kinds.weekly_report.title"))
    end
  end

  describe "actions" do
    before { sign_in admin }

    it "mails a password reset link and a fresh confirmation only while mail is on" do
      post "/overseer/users/#{father.id}/password_reset"
      flash[:alert].should eq(I18n.t("overseer.people.actions.no_mail"))

      allow(Mailing).to receive(:enabled?).and_return(true)
      get "/overseer/users/#{father.id}"
      response.body.should include(I18n.t("overseer.people.actions.reset"))
      response.body.should include(I18n.t("overseer.people.actions.verify"))

      perform_enqueued_jobs { post "/overseer/users/#{father.id}/password_reset" }
      ActionMailer::Base.deliveries.last.to.should eq([ father.email ])
      flash[:notice].should eq(I18n.t("overseer.people.actions.reset_sent", email: father.email))

      perform_enqueued_jobs { post "/overseer/users/#{father.id}/verification" }
      ActionMailer::Base.deliveries.last.subject.should eq(I18n.t("mailers.email_verification.subject"))

      post "/overseer/users/#{mother.id}/verification"
      flash[:alert].should eq(I18n.t("overseer.people.actions.already_verified"))
    end

    it "unlinks a child, but never the only door into a managed profile" do
      delete "/overseer/users/#{father.id}/children/#{nikola.id}"
      father.children.should be_empty
      mother.children.should include(nikola)

      delete "/overseer/users/#{mother.id}/children/#{elena.id}"
      flash[:alert].should eq(I18n.t("overseer.people.actions.unlink_only_door", child: elena.name, parent: mother.name))
      mother.reload.children.should include(elena)
    end

    it "releases a managed child with their own login when unlinking them" do
      own = User.create_managed_child!(parent: mother, name: "Голяма", email: "golyama@example.com", password: "secret123")

      delete "/overseer/users/#{mother.id}/children/#{own.id}"

      own.reload.managed_by.should be_nil
      mother.reload.children.should_not include(own)
    end

    it "refuses to delete an admin, yourself, or without the name typed back" do
      other_admin = create(:user, role: :admin)

      get "/overseer/users/#{other_admin.id}/delete"
      response.body.should include(I18n.t("overseer.people.delete.refused.admin"))
      delete "/overseer/users/#{other_admin.id}"
      User.exists?(other_admin.id).should be(true)

      delete "/overseer/users/#{admin.id}"
      User.exists?(admin.id).should be(true)

      delete "/overseer/users/#{father.id}", params: { confirm_name: "Иван" }
      flash[:alert].should eq(I18n.t("overseer.people.delete.name_mismatch"))
      User.exists?(father.id).should be(true)
    end

    it "deletes a parent with the children whose accounts they hold, and leaves the rest" do
      get "/overseer/users/#{mother.id}/delete"
      response.body.should include(I18n.t("overseer.people.delete.takes_children", name: "Мария", children: elena.name))
      response.body.should include(I18n.t("overseer.people.delete.children_stay", children: nikola.name))

      delete "/overseer/users/#{mother.id}", params: { confirm_name: mother.name }

      response.should redirect_to(overseer_users_path)
      User.exists?(mother.id).should be(false)
      User.exists?(elena.id).should be(false)
      nikola.reload.parents.should eq([ father ])
    end

    it "deletes a student whatever else points at them" do
      answer!(nikola)
      nikola.skills.create!(topic:, rating: 1100)
      XpEvent.create!(user: nikola, amount: 10, reason: "answer")
      QuestionReport.create!(question: create(:question), user: nikola, reason: :typo).
        messages.create!(author: admin, side: :team, body: "Поправихме я.")
      friend = create(:user, name: "Приятел")
      Friendship.create!(requester: nikola, addressee: friend, status: :accepted)
      league = Leagues.create!(nikola, name: "Клас", friend_ids: [ friend.id ]).league
      create(:question, status: :in_review, suggested_by: nikola)
      invite = Challenge.create!(question_count: 3, seconds_per_question: 30, target_elo: 1000, invited_user: nikola)
      invite.participants.create!(user: friend)
      finished = Challenge.create!(question_count: 3, seconds_per_question: 30, target_elo: 1000, status: :finished,
                                   winner: nikola, invited_user: nikola)
      finished.participants.create!(user: nikola)
      finished.participants.create!(user: friend)
      Goal.create!(parent: father, child: nikola, metric: :problems, mode: :total, period: :week, target: 5,
                   starts_on: Time.zone.today, reward: "кино")
      PracticeFocuses.set!(child: nikola, parent: father, topic_ids: [ topic.id ], target: :step)

      delete "/overseer/users/#{nikola.id}", params: { confirm_name: nikola.name }

      User.exists?(nikola.id).should be(false)
      league.reload.owner.should eq(friend)
      Challenge.exists?(invite.id).should be(false)
      finished.reload.invited_user_id.should be_nil
      finished.winner_id.should be_nil
    end
  end
end
