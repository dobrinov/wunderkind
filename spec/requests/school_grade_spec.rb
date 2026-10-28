require "rails_helper"

# The optional birth year: set by a student in settings or by a parent when
# creating a child, and read back as an estimated grade on the parent's pages.
describe "Birth year and estimated grade", type: :request do
  around { |example| travel_to(Date.new(2026, 10, 27)) { example.run } }

  it "is optional and saved from a student's settings" do
    student = create(:user)
    sign_in student

    get "/settings"
    response.body.should include(I18n.t("school_grade.birth_year"))

    put "/profile", params: { user: { name: student.name, birth_year: 2018, grade_offset: -1 } }
    student.reload.estimated_grade.should eq(1)

    put "/profile", params: { user: { name: student.name, birth_year: "" } }
    student.reload.birth_year.should be_nil
  end

  it "refuses an offset off the menu" do
    student = create(:user)
    sign_in student

    put "/profile", params: { user: { name: student.name, grade_offset: 7 } }

    response.should have_http_status(:unprocessable_entity)
    student.reload.grade_offset.should eq(0)
  end

  it "is not asked of a grown-up and not saved for one" do
    parent = create(:user, role: :parent)
    sign_in parent

    get "/settings"
    response.body.should_not include(I18n.t("school_grade.birth_year"))

    put "/profile", params: { user: { name: parent.name, birth_year: 2018 } }
    parent.reload.birth_year.should be_nil
  end

  it "can be given when a parent creates a child, and shows on the family page" do
    parent = create(:user, role: :parent)
    sign_in parent

    post "/parents/children", params: { name: "Мими", birth_year: 2019, grade_offset: 0 }
    child = User.order(:id).last
    child.birth_year.should eq(2019)

    get "/parents/children"
    response.body.should include(I18n.t("school_grade.grade", grade: 1))
  end

  it "leaves a child created without one without one" do
    parent = create(:user, role: :parent)
    sign_in parent

    post "/parents/children", params: { name: "Мими", birth_year: "" }

    User.order(:id).last.birth_year.should be_nil
  end
end
