require "rails_helper"

describe "Classroom invite links", type: :request do
  let(:teacher) { create(:user, role: :teacher, verified_at: Time.current) }
  let(:classroom) { teacher.classrooms.create!(name: "5а") }
  let(:student) { create(:user) }

  it "shows the invite to a visitor who is not signed in" do
    get "/join/#{classroom.invite_code}"

    response.should have_http_status(:ok)
    response.body.should include("5а")
    response.body.should include(teacher.name)
  end

  it "reads the code case-insensitively, like typing it does" do
    get "/join/#{classroom.invite_code.downcase}"

    response.should have_http_status(:ok)
  end

  it "sends an unknown code home rather than leaking whether it exists" do
    get "/join/ZZZZZZ"

    response.should redirect_to("/")
    flash[:alert].should be_present
  end

  it "joins a signed-in student" do
    sign_in student

    post "/join/#{classroom.invite_code}"

    classroom.students.reload.should include(student)
    response.should redirect_to("/classrooms")
  end

  it "does not stack a second membership" do
    sign_in student
    post "/join/#{classroom.invite_code}"
    post "/join/#{classroom.invite_code}"

    classroom.classroom_memberships.where(user: student).count.should eq(1)
  end

  it "refuses to sign a signed-out visitor into a class and sends them to sign in" do
    post "/join/#{classroom.invite_code}"

    classroom.students.reload.should be_empty
    response.should redirect_to("/sign-in?invite=#{classroom.invite_code}")
  end

  it "keeps a teacher out of their own class as a student" do
    sign_in teacher

    post "/join/#{classroom.invite_code}"

    classroom.students.reload.should be_empty
    flash[:alert].should be_present
  end

  # The point of carrying the code through the auth screens: a parent who gets
  # the link in a chat has no account yet, and must land back on the invite.
  it "returns a brand new account to the invite" do
    post "/sign-up", params: { name: "Мими", email: "mimi@example.com", password: "secret123", invite: classroom.invite_code }

    response.should redirect_to("/join/#{classroom.invite_code}")
  end

  it "returns a signing-in student to the invite" do
    post "/sign-in", params: { email: student.email, password: "secret123", invite: classroom.invite_code }

    response.should redirect_to("/join/#{classroom.invite_code}")
  end

  it "ignores an invite param that is not shaped like a code" do
    post "/sign-in", params: { email: student.email, password: "secret123", invite: "https://evil.example.com" }

    response.should redirect_to("/calendar")
  end

  it "gives the teacher the link to send" do
    sign_in teacher

    get "/teachers/classrooms/#{classroom.id}"

    response.body.should include("/join/#{classroom.invite_code}")
  end
end
