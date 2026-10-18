require "rails_helper"

describe "Last sign-in", type: :request do
  let(:admin) { create(:user, role: :admin) }

  it "is stamped by signing in, and a wrong password stamps nothing" do
    student = create(:user, role: :student)

    post "/sign-in", params: { email: student.email, password: "wrong" }
    student.reload.last_login_at.should be_nil

    sign_in student
    student.reload.last_login_at.should be_within(5.seconds).of(Time.current)
  end

  it "is stamped on a managed child when a parent switches into them, but not by an admin looking on" do
    parent = create(:user, role: :parent)
    child = User.create_managed_child!(parent: parent, name: "Мими")

    sign_in admin
    post "/impersonate/#{parent.id}"
    post "/switch-child/#{child.id}"
    child.reload.last_login_at.should be_nil

    delete "/impersonate"
    sign_in parent
    post "/switch-child/#{child.id}"
    child.reload.last_login_at.should be_present
  end

  it "orders the admin users list by it, most recent first, never-signed-in last" do
    create(:user, name: "Никога")
    create(:user, name: "Отдавна", last_login_at: 3.days.ago)
    create(:user, name: "Скоро", last_login_at: 1.hour.ago)

    sign_in admin
    get "/overseer/users"

    positions = [ admin.name, "Скоро", "Отдавна", "Никога" ].map { response.body.index(it) }
    positions.should eq(positions.sort)
  end
end
