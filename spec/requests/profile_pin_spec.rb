require "rails_helper"

# A shared tablet: a parent's PIN guards the way out of a child's profile — to
# a sibling's or back to the parent's area — and never the way in.
describe "The parent's PIN on a shared tablet", type: :request do
  let(:parent) { create(:user, role: :parent, verified_at: Time.current) }
  let!(:vanya) { User.create_managed_child!(parent: parent, name: "Ваня") }
  let!(:boyan) { User.create_managed_child!(parent: parent, name: "Боян") }

  before do
    sign_in parent
    patch profile_pin_path, params: { pin: "2468" }
  end

  it "hands the tablet over without asking, and asks on the way out" do
    post switch_child_path(vanya)
    response.should redirect_to(home_path)

    post switch_child_path(boyan)
    response.body.should include(I18n.t("child_session.pin_title"))
    delete switch_back_path
    response.body.should include(I18n.t("child_session.pin_title"))

    post switch_child_path(boyan), params: { pin: "1111" }
    response.should have_http_status(:unprocessable_content)
    response.body.should include(I18n.t("child_session.pin_wrong"))

    post switch_child_path(boyan), params: { pin: "2468" }
    response.should redirect_to(home_path)
    get home_path
    response.body.should include(I18n.t("child_session.acting_as", name: "Боян"))

    delete switch_back_path, params: { pin: "2468" }
    response.should redirect_to(parents_children_path)
  end

  it "refuses a PIN that is not 4 to 6 digits, and can be removed" do
    patch profile_pin_path, params: { pin: "12" }
    flash[:alert].should eq(I18n.t("profile_pin.invalid"))
    parent.reload.profile_pin_matches?("2468").should be(true)

    delete profile_pin_path
    parent.reload.profile_pin?.should be(false)
    post switch_child_path(vanya)
    post switch_child_path(boyan)
    response.should redirect_to(home_path)
  end
end
