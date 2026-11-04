require "rails_helper"

describe "A parent editing a child's details", type: :request do
  let(:parent) { create(:user, role: :parent, verified_at: Time.current) }
  let(:child) { User.create_managed_child!(parent: parent, name: "Ния") }

  before { sign_in parent }

  it "asks for a missing birth year on the child's page and saves it" do
    get parents_child_path(child)
    response.body.should include(I18n.t("parents.child_profile.missing_title", name: "Ния"))

    patch parents_child_profile_path(child), params: { name: "Нини", birth_year: 2018, grade_offset: -1 }

    response.should redirect_to(parents_child_path(child))
    child.reload
    child.name.should eq("Нини")
    child.birth_year.should eq(2018)
    child.grade_offset.should eq(-1)

    get parents_child_path(child)
    response.body.should_not include(I18n.t("parents.child_profile.missing_title", name: "Нини"))
  end

  it "leaves the name of a child with their own login alone" do
    own = create(:user, name: "Борис")
    ParentLink.create!(parent: parent, child: own)

    patch parents_child_profile_path(own), params: { name: "Боби", birth_year: 2014 }

    own.reload.name.should eq("Борис")
    own.birth_year.should eq(2014)
  end

  it "refuses a birth year that is not one" do
    patch parents_child_profile_path(child), params: { birth_year: 1800 }

    response.should have_http_status(:unprocessable_content)
    child.reload.birth_year.should be_nil
  end

  it "is not for somebody else's child" do
    stranger = create(:user)

    patch parents_child_profile_path(stranger), params: { birth_year: 2015 }

    response.should have_http_status(:not_found)
    stranger.reload.birth_year.should be_nil
  end
end
