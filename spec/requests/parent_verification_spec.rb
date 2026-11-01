require "rails_helper"

describe "A new parent's unconfirmed email", type: :request do
  let(:parent) { create(:user, role: :parent, verified_at: nil) }

  before { allow(Mailing).to receive(:enabled?).and_return(true) }

  context "while signed in" do
    before { sign_in parent }

    it "does not stand in front of adding the first child" do
      get parents_children_path
      response.body.should include(new_parents_child_path)

      expect {
        post parents_children_path, params: { name: "Мира" }
      }.to change { parent.children.count }.by(1)
      parent.children.last.managed_by.should eq(parent)
    end

    it "lets the first run go on to step two for a managed child" do
      child = User.create_managed_child!(parent: parent, name: "Мира")

      patch parents_child_daily_minutes_path(child), params: { minutes: 15 }

      child.reload.daily_minutes_target.should eq(15)
    end

    it "still waits before linking somebody else's account by code, and says so on the form" do
      stranger = create(:user, name: "Ния")

      get new_parents_child_path(link: 1)
      response.body.should include(I18n.t("parents.children.link_verify", email: parent.email))

      post parents_children_path, params: { link_code: stranger.ensure_link_code! }

      parent.children.should_not include(stranger)
      flash[:alert].should eq(I18n.t("verification.required"))
    end

    it "still waits before inviting another parent" do
      User.create_managed_child!(parent: parent, name: "Мира")

      expect {
        post parents_family_invitations_path, params: { email: "tate@example.com" }
      }.not_to change(FamilyInvitation, :count)
    end

    it "is not asked about once confirmed" do
      parent.update!(verified_at: Time.current)
      get new_parents_child_path(link: 1)

      response.body.should_not include(I18n.t("parents.children.link_verify", email: parent.email))
    end
  end

  describe "the confirmation link" do
    let(:token) { parent.generate_token_for(:email_verification) }

    it "signs the parent in on first use and goes back to adding the child" do
      get "/verify-email/#{token}"

      parent.reload.verified_at.should be_present
      response.should redirect_to(new_parents_child_path)
      follow_redirect!
      response.should have_http_status(:ok)
    end

    it "goes home for a parent who already has a child" do
      User.create_managed_child!(parent: parent, name: "Мира")

      get "/verify-email/#{token}"

      response.should redirect_to(root_path)
    end

    it "does not sign in on a second use: the token lives two days" do
      parent.verify!

      get "/verify-email/#{token}"

      response.should redirect_to(sign_in_path)
      get parents_children_path
      response.should redirect_to(sign_in_path)
    end

    it "never swaps the account somebody is already signed in to" do
      other = create(:user, role: :parent)
      sign_in other

      get "/verify-email/#{token}"

      parent.reload.verified_at.should be_present
      response.should redirect_to(sign_in_path)
      get parents_children_path
      response.should have_http_status(:ok)
      controller.send(:current_user).should eq(other)
    end
  end
end
