require "rails_helper"

describe "A new parent's unconfirmed email", type: :request do
  let(:parent) { create(:user, role: :parent, verified_at: nil) }

  before do
    allow(Mailing).to receive(:enabled?).and_return(true)
    sign_in parent
  end

  it "is the first step on the empty family page, with a way to resend the link" do
    get parents_children_path

    response.body.should include(I18n.t("parents.welcome.verify_title"), parent.email)
    response.body.should include(email_verifications_path)
  end

  it "is said before the new-child form is filled in, not only after" do
    get new_parents_child_path

    response.body.should include(I18n.t("verification.pending"))
  end

  it "is not asked for once confirmed" do
    parent.update!(verified_at: Time.current)
    get parents_children_path

    response.body.should_not include(I18n.t("parents.welcome.verify_title"))
  end
end
