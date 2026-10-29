require "rails_helper"

describe "Two parents, one family", type: :request do
  let(:dad) { create(:user, role: :parent, name: "Деян Петров", verified_at: Time.current) }
  let(:mum) { create(:user, role: :parent, name: "Елена Петрова", email: "elena@example.com", verified_at: Time.current) }
  let!(:maya) { User.create_managed_child!(parent: dad, name: "Мая") }
  let!(:boyan) { User.create_managed_child!(parent: dad, name: "Боян") }

  def mails_to(address)
    ActionMailer::Base.deliveries.select { |mail| mail.to == [ address ] }
  end

  describe "a second parent of a managed child" do
    before do
      mum.parent_links.create!(child: maya)
      sign_in mum
    end

    it "switches into it, offers it in the header and the bar, and acts on it" do
      get "/parents/children"
      response.body.should include(switch_child_path(maya))
      response.body.should_not include(switch_child_path(boyan))

      post "/switch-child/#{maya.id}"
      response.should redirect_to("/home")
      get "/home"
      response.body.should include(I18n.t("child_session.switch_back"))

      patch "/profile", params: { user: { nickname: "мая" } }
      maya.reload.nickname.should eq("мая")
    end

    it "will not switch into a managed child they are not linked to" do
      post "/switch-child/#{boyan.id}"

      flash[:alert].should be_present
      get "/parents/children"
      response.should have_http_status(:ok)
    end

    it "loses the open profile the moment the link goes" do
      post "/switch-child/#{maya.id}"
      ParentLink.find_by!(parent: mum, child: maya).destroy!

      get "/parents/children"
      response.should have_http_status(:ok)
    end

    it "lets either parent allow leagues for the child" do
      patch "/parents/children/#{maya.id}/league_permission", params: { allowed: "1" }

      maya.reload.leagues_allowed.should be(true)
    end
  end

  describe "owed rewards" do
    let(:goal) do
      Goal.create!(parent: dad, child: maya, metric: :problems, mode: :total, period: :week, target: 1,
                   starts_on: 2.weeks.ago.to_date, reward: "час Minecraft")
    end
    let!(:award) do
      GoalAward.create!(goal: goal, period_start: 1.week.ago.to_date.beginning_of_week,
                        period_end: 1.week.ago.to_date.end_of_week, earned_at: 3.days.ago, reward: "час Minecraft")
    end

    before { mum.parent_links.create!(child: maya) }

    it "are the same list for both parents, credited, and cleared for both by either" do
      mum.update!(name_for_children: "Мама")

      sign_in mum
      get "/parents/children/#{maya.id}?tab=goals"
      response.body.should include("час Minecraft")
      response.body.should include(I18n.t("family.credit.promised_by", name: "Деян"))

      patch "/parents/rewards/#{award.id}"
      award.reload.should be_used

      delete "/sign-out"
      sign_in dad
      get "/parents/children/#{maya.id}?tab=goals"
      response.body.should include(I18n.t("goals.used_title"))
      response.body.should_not include(I18n.t("goals.mark_used"))
    end

    it "are not anybody else's to give" do
      stranger = create(:user, role: :parent, verified_at: Time.current)
      sign_in stranger

      patch "/parents/rewards/#{award.id}"
      response.should have_http_status(:not_found)
      award.reload.should_not be_used
    end

    it "tells the child who promised, by the name they use" do
      dad.update!(name_for_children: "Тате")
      Goal.create!(parent: mum, child: maya, metric: :problems, mode: :total, period: :week, target: 50,
                   starts_on: Time.zone.today, reward: "кино")
      mum.update!(name_for_children: "Мама")

      sign_in dad
      post "/switch-child/#{maya.id}"
      get "/home"

      response.body.should include(I18n.t("family.credit.child_promised", name: "Тате"))
      response.body.should include(I18n.t("family.credit.child_asks", name: "Мама"))
    end
  end

  describe "inviting by email" do
    before { sign_in dad }

    it "mails the invitation when mail is on" do
      allow(Mailing).to receive(:enabled?).and_return(true)

      perform_enqueued_jobs { post "/parents/family_invitations", params: { email: "Elena@Example.com" } }

      invitation = FamilyInvitation.sole
      invitation.email.should eq("elena@example.com")
      invitation.expires_at.should be_within(1.minute).of(7.days.from_now)
      mail = mails_to("elena@example.com").sole
      mail.text_part.decoded.should include(family_invitation_path(invitation.token))
      mail.text_part.decoded.should include(invitation.code)
    end

    it "offers the link to pass on when mail is off" do
      allow(Mailing).to receive(:enabled?).and_return(false)

      post "/parents/family_invitations", params: { email: "elena@example.com" }
      follow_redirect!

      ActionMailer::Base.deliveries.should be_empty
      invitation = FamilyInvitation.sole
      response.body.should include(family_invitation_url(invitation.token))
      response.body.should include(I18n.t("family.invite.waiting"))
    end

    it "is refused with no children to share" do
      lonely = create(:user, role: :parent, verified_at: Time.current)
      delete "/sign-out"
      sign_in lonely

      post "/parents/family_invitations", params: { email: "x@example.com" }
      FamilyInvitation.count.should eq(0)
    end
  end

  describe "accepting" do
    let(:invitation) { dad.sent_family_invitations.create!(email: "elena@example.com") }

    it "shows who is inviting into which children's family" do
      get "/family/invitations/#{invitation.token}"

      response.should have_http_status(:ok)
      response.body.should include(I18n.t("family.join.title", name: dad.name, children: "Боян и Мая"))
    end

    it "signs a new parent up from the link, linked to every child and confirmed by the email" do
      allow(Mailing).to receive(:enabled?).and_return(true)

      post "/sign-up", params: { role: "parent", family_token: invitation.token, name: "Елена", email: "elena@example.com",
                                 password: "secret123", name_for_children: "Мама" }

      elena = User.find_by!(email: "elena@example.com")
      elena.children.should contain_exactly(maya, boyan)
      elena.name_for_children.should eq("Мама")
      elena.verified_at.should be_present
      invitation.reload.accepted_by.should eq(elena)
      response.should redirect_to("/parents/children")
    end

    it "signs an existing parent in and brings them back to accept" do
      mum
      get "/family/invitations/#{invitation.token}"
      response.body.should include(sign_in_path(invitation: invitation.token))

      post "/sign-in", params: { email: mum.email, password: "secret123", invitation: invitation.token }
      response.should redirect_to(family_invitation_path(invitation.token))

      post "/family/invitations/#{invitation.token}/accept", params: { name_for_children: "Мама" }
      response.should redirect_to("/parents/children")
      mum.children.should contain_exactly(maya, boyan)
      mum.reload.name_for_children.should eq("Мама")

      # Spent: a second use finds nothing.
      get "/family/invitations/#{invitation.token}"
      response.should have_http_status(:gone)
    end

    it "lets an admin who is also a parent join" do
      admin = create(:user, role: :admin, verified_at: Time.current)
      sign_in admin

      post "/family/invitations/#{invitation.token}/accept"

      admin.children.should contain_exactly(maya, boyan)
    end

    it "refuses a student account and leaves the invitation open" do
      student = create(:user)
      sign_in student

      get "/family/invitations/#{invitation.token}"
      response.body.should include(I18n.t("family.join.refused.student"))

      post "/family/invitations/#{invitation.token}/accept"
      student.parent_links.should be_empty
      invitation.reload.should be_pending
    end

    it "refuses an expired or withdrawn invitation" do
      invitation
      sign_in mum
      travel_to(8.days.from_now) do
        post "/family/invitations/#{invitation.token}/accept"
        mum.children.should be_empty
      end

      invitation.revoke!
      post "/family/invitations/#{invitation.token}/accept"
      mum.children.should be_empty
      get "/family/invitations/#{invitation.token}"
      response.should have_http_status(:gone)
    end

    it "is never accepted from an impersonated session" do
      admin = create(:user, role: :admin, verified_at: Time.current)
      sign_in admin
      post "/impersonate/#{mum.id}"

      post "/family/invitations/#{invitation.token}/accept"

      mum.children.should be_empty
    end
  end

  describe "by code" do
    it "joins with the code read out, once" do
      sign_in dad
      post "/parents/family_invitations/code"
      code = FamilyInvitation.sole.code
      code.should match(/\A[#{User::LINK_CODE_ALPHABET.join}]{6}\z/o)
      delete "/sign-out"

      sign_in mum
      post "/parents/family_invitations/redeem", params: { code: " #{code.downcase} " }
      mum.children.should contain_exactly(maya, boyan)

      other = create(:user, role: :parent, verified_at: Time.current)
      delete "/sign-out"
      sign_in other
      post "/parents/family_invitations/redeem", params: { code: code }
      flash[:alert].should eq(I18n.t("family.join.invalid_code"))
      other.children.should be_empty
    end

    it "replaces the old code with „Нов код“ and joins at sign-up" do
      sign_in dad
      post "/parents/family_invitations/code"
      old = FamilyInvitation.sole
      post "/parents/family_invitations/code"
      old.reload.revoked_at.should be_present
      fresh = FamilyInvitation.pending.sole
      delete "/sign-out"

      post "/sign-up", params: { role: "parent", name: "Елена", email: "elena2@example.com", password: "secret123", family_code: old.code }
      response.should have_http_status(:unprocessable_entity)
      User.exists?(email: "elena2@example.com").should be(false)

      post "/sign-up", params: { role: "parent", name: "Елена", email: "elena2@example.com", password: "secret123", family_code: fresh.code }
      User.find_by!(email: "elena2@example.com").children.should contain_exactly(maya, boyan)
    end

    it "is refused to a student, who cannot reach the parents' area at all" do
      invitation = dad.sent_family_invitations.create!
      student = create(:user)
      sign_in student

      post "/parents/family_invitations/redeem", params: { code: invitation.code }

      student.parent_links.should be_empty
      invitation.reload.should be_pending
    end
  end

  describe "the „Родители“ card" do
    it "lists both parents and the pending invitations, which either parent can withdraw" do
      mum.parent_links.create!(child: maya)
      mum.parent_links.create!(child: boyan)
      invitation = dad.sent_family_invitations.create!(email: "baba@example.com")

      sign_in mum
      get "/parents/children"
      response.body.should include(dad.name)
      response.body.should include(mum.name)
      response.body.should include("baba@example.com")
      response.body.should include(I18n.t("family.parents.of_child", names: "Деян, Елена"))

      delete "/parents/family_invitations/#{invitation.token}"
      invitation.reload.revoked_at.should be_present
    end

    it "will not let an outsider withdraw an invitation" do
      invitation = dad.sent_family_invitations.create!(email: "baba@example.com")
      sign_in create(:user, role: :parent, verified_at: Time.current)

      delete "/parents/family_invitations/#{invitation.token}"

      response.should have_http_status(:not_found)
      invitation.reload.should be_pending
    end

    it "saves what the children call this parent" do
      sign_in dad
      patch "/parents/name_for_children", params: { name_for_children: " Тате " }

      dad.reload.name_for_children.should eq("Тате")
      dad.update!(name_for_children: "")
      dad.name_for_children.should eq("Деян")
    end
  end

  describe "deleting the parent who created a managed child" do
    it "hands the child, and the promises made to it, to the parent linked longest" do
      mum.parent_links.create!(child: maya)
      later = create(:user, role: :parent)
      later.parent_links.create!(child: maya)
      goal = Goal.create!(parent: dad, child: maya, metric: :problems, mode: :total, period: :week, target: 5,
                          starts_on: Time.zone.today, reward: "кино")

      dad.managed_children_lost_on_destroy.should eq([ boyan ])
      dad.destroy!

      maya.reload.managed_by.should eq(mum)
      goal.reload.parent.should eq(mum)
      User.exists?(boyan.id).should be(false)
    end
  end

  describe "emails" do
    before do
      mum.parent_links.create!(child: maya)
      allow(Mailing).to receive(:enabled?).and_return(true)
    end

    it "sends the weekly report to both parents" do
      week_start = WeeklyReport.last_week_start(Time.zone.today)
      assignment = Assignment.create!(user: maya)
      assignment_question = assignment.assignment_questions.create!(question: create(:question, answer: "5"), position: 1)
      UserAnswer.create!(user: maya, assignment_question:, value: "5", correct: true, response: { "value" => "5" },
                         duration_ms: 60_000, created_at: week_start.in_time_zone.change(hour: 12) + 1.day)

      WeeklyReport.recipients(week_start).should include(dad, mum)
      WeeklyReport.deliver(dad, week_start:)
      WeeklyReport.deliver(mum, week_start:)

      mails_to(dad.email).size.should eq(1)
      mails_to("elena@example.com").size.should eq(1)
    end

    it "tells both parents when the child reports a question" do
      question = create(:question, answer: "5")

      perform_enqueued_jobs { QuestionReport.file!(question: question, user: maya, reason: "wrong_answer") }

      mails_to(dad.email).size.should eq(1)
      mails_to("elena@example.com").size.should eq(1)
    end
  end
end
