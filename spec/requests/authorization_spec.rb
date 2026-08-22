require "rails_helper"

describe "Role authorization", type: :request do
  let(:student) { create(:user) }
  let(:teacher) { create(:user, role: :teacher, verified_at: Time.current) }
  let(:parent) { create(:user, role: :parent, verified_at: Time.current) }

  it "keeps students out of the teacher and parent areas" do
    sign_in student

    get "/teachers/classrooms"
    response.should redirect_to("/")

    get "/parents/children"
    response.should redirect_to("/")

    get "/overseer"
    response.should redirect_to("/")
  end

  it "lets a teacher manage classrooms but not the admin area" do
    sign_in teacher

    get "/teachers/classrooms"
    response.should have_http_status(:ok)

    get "/overseer"
    response.should redirect_to("/")
  end

  it "lets an unverified teacher work while email confirmation is off" do
    sign_in create(:user, role: :teacher)

    post "/teachers/classrooms", params: { classroom: { name: "5а" } }

    Classroom.count.should eq(1)
  end

  it "blocks unverified teachers from mutations but not from browsing, once confirmation is on" do
    allow(Mailing).to receive(:enabled?).and_return(true)
    sign_in create(:user, role: :teacher)

    get "/teachers/classrooms"
    response.should have_http_status(:ok)

    post "/teachers/classrooms", params: { classroom: { name: "5а" } }
    Classroom.count.should eq(0)
    flash[:alert].should be_present
  end

  it "scopes teacher resources to the owning teacher" do
    other = create(:user, role: :teacher)
    classroom = Classroom.create!(teacher: other, name: "чужда")

    sign_in teacher
    get "/teachers/classrooms/#{classroom.id}"

    response.should have_http_status(:not_found)
  end

  it "lets a parent see only linked children's homework" do
    other_parent = create(:user, role: :parent)
    child = create(:user)
    ParentLink.create!(parent: other_parent, child: child)
    create(:question, elo: child.elo)
    homework = HomeworkCreator.execute(assigner: other_parent, students: [ child ], title: "x", due_at: 1.day.from_now, auto_count: 1)

    sign_in parent
    get "/parents/homeworks/#{homework.id}"

    response.should have_http_status(:not_found)
  end
end

describe "Email verification and password reset", type: :request do
  it "sends no confirmation mail on sign-up while confirmation is off" do
    expect(UserMailer).not_to receive(:email_verification)

    post "/sign-up", params: { name: "Мария", email: "m@example.com", password: "secret123", role: "teacher" }

    User.find_by(email: "m@example.com").should be_present
  end

  it "verifies a user from a valid token and rejects garbage" do
    user = create(:user, role: :teacher)

    get "/verify-email/#{user.generate_token_for(:email_verification)}"
    user.reload.verified_at.should be_present

    get "/verify-email/garbage"
    response.should redirect_to("/sign-in")
  end

  it "closes the password reset flow while mail is off" do
    user = create(:user, email: "real@example.com")
    token = user.generate_token_for(:password_reset)
    expect(UserMailer).not_to receive(:password_reset)

    get "/password_resets/new"
    response.should redirect_to("/sign-in")

    post "/password_resets", params: { email: "real@example.com" }
    response.should redirect_to("/sign-in")

    patch "/password_resets/#{token}", params: { password: "brand-new-pass" }
    user.reload.authenticate("brand-new-pass").should be_falsey
  end

  it "keeps the forgotten-password link off the sign-in page while mail is off" do
    get "/sign-in"

    response.body.should_not include(I18n.t("password_reset.forgot"))
  end

  it "resets the password via the emailed token once mail is on" do
    allow(Mailing).to receive(:enabled?).and_return(true)
    user = create(:user)
    token = user.generate_token_for(:password_reset)

    patch "/password_resets/#{token}", params: { password: "brand-new-pass" }

    user.reload.authenticate("brand-new-pass").should be_truthy
  end

  it "responds identically whether the reset email exists or not" do
    allow(Mailing).to receive(:enabled?).and_return(true)
    create(:user, email: "real@example.com")

    post "/password_resets", params: { email: "real@example.com" }
    real_response = response.redirect_url
    post "/password_resets", params: { email: "fake@example.com" }

    response.redirect_url.should eq(real_response)
  end
end

describe "Classroom joining and homework flow", type: :request do
  it "runs a full classroom homework cycle" do
    teacher = create(:user, role: :teacher, verified_at: Time.current)
    student = create(:user)
    create_list(:question, 3, elo: student.elo)

    sign_in teacher
    post "/teachers/classrooms", params: { classroom: { name: "5а" } }
    classroom = Classroom.last

    sign_in student
    post "/classrooms/join", params: { invite_code: classroom.invite_code.downcase }
    classroom.students.should include(student)

    sign_in teacher
    post "/teachers/homeworks", params: {
      classroom_id: classroom.id,
      homework: { title: "Дроби", due_at: 3.days.from_now.iso8601, auto_count: 2 }
    }

    homework = Homework.last
    homework.assignments.map(&:user).should eq([ student ])
    homework.questions.count.should eq(2)

    sign_in student
    get "/calendar"
    response.body.should include("Дроби")
  end
end
