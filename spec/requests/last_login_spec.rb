require "rails_helper"

describe "Last sign-in", type: :request do
  let(:admin) { create(:user, role: :admin) }

  it "is stamped by signing in, and a wrong password stamps nothing" do
    student = create(:user, role: :student)

    post "/sign-in", params: { email: student.email, password: "wrong" }
    student.reload.last_login_at.should be_nil

    sign_in student
    student.reload.last_login_at.should be_within(5.seconds).of(Time.current)
    student.sign_ins.pluck(:via).should eq(%w[password])
  end

  it "keeps every sign-in, and says how: signing up, a password, a switch into a child" do
    post "/sign-up", params: { name: "Рада", email: "rada@example.com", password: "secret123", role: "parent" }
    parent = User.find_by!(email: "rada@example.com")
    child = User.create_managed_child!(parent: parent, name: "Мими")
    post "/switch-child/#{child.id}"
    delete "/sign-out"
    sign_in parent

    parent.sign_ins.order(:id).pluck(:via).should eq(%w[signup password])
    child.sign_ins.pluck(:via).should eq(%w[switch])
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
    get "/overseer/users", params: { view: "all" }

    positions = [ admin.name, "Скоро", "Отдавна", "Никога" ].map { response.body.index(it) }
    positions.should eq(positions.sort)
  end
end
