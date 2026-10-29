require "rails_helper"

# The switches in Настройки save as they are flipped, by fetch, against the
# same action the forms post to. These are the JSON half of that action.
describe "Instant settings", type: :request do
  let(:student) { create(:user, role: :student) }

  def flip(attributes)
    patch "/profile", params: { user: attributes }, as: :json
  end

  it "saves one switch and answers with what it wrote" do
    sign_in student

    flip(feedback_after_answer: "0")

    response.should have_http_status(:ok)
    response.parsed_body.should eq("feedback_after_answer" => false)
    student.reload.feedback_after_answer.should be(false)
  end

  it "writes the sound column the speaker button writes" do
    sign_in student

    flip(sound_effects: "0")

    response.parsed_body.should eq("sound_effects" => false)
    student.reload.sound_effects.should be(false)
  end

  it "saves the daily minutes as one tap" do
    sign_in student

    flip(daily_minutes_target: "20")

    response.parsed_body.should eq("daily_minutes_target" => 20)
    student.reload.daily_minutes_target.should eq(20)
  end

  # permit drops what this account may not set; a bare 204 would let the
  # page say „Запазено" about it.
  it "leaves out what it did not write, so the switch can be put back" do
    parent = create(:user, role: :parent)
    ParentLink.create!(parent: parent, child: student)
    student.update!(daily_minutes_target: 15)
    sign_in student

    flip(daily_minutes_target: "30")

    response.parsed_body.should_not have_key("daily_minutes_target")
    student.reload.daily_minutes_target.should eq(15)
  end

  it "only saves an email switch for whoever that email is for" do
    allow(Mailing).to receive(:enabled?).and_return(true)
    parent = create(:user, role: :parent)

    sign_in student
    flip(weekly_report: "0")
    response.parsed_body.should_not have_key("weekly_report")
    student.reload.weekly_report.should be(true)

    sign_in parent
    flip(weekly_report: "0")
    response.parsed_body.should eq("weekly_report" => false)
    parent.reload.weekly_report.should be(false)
  end

  it "answers a refused value with the reason and a failure status" do
    sign_in student

    flip(grade_offset: "7")

    response.should have_http_status(:unprocessable_entity)
    response.parsed_body["errors"].should be_present
  end

  # An admin looking at somebody's settings must not be told a switch saved.
  it "is refused while an admin is viewing the account" do
    admin = create(:user, role: :admin)
    sign_in admin
    post "/impersonate/#{student.id}"

    flip(feedback_after_answer: "0")

    response.should have_http_status(:forbidden)
    student.reload.feedback_after_answer.should be(true)
  end

  describe "the page" do
    it "draws the switches as switches wired to save themselves, with a save button for when they cannot" do
      sign_in student
      get "/settings"

      body = response.body
      body.should include(%(role="switch"), "settings-switches#toggle", "settings-switches#choose")
      body.should include(%(data-settings-switches-target="fallback"))
      %w[profile practice security about].each { |group| body.should include(I18n.t("settings.groups.#{group}")) }
    end

    it "offers a parent no daily goal of their own" do
      sign_in create(:user, role: :parent)
      get "/settings"

      response.body.should_not include(I18n.t("settings.daily_goal"))
      response.body.should include(I18n.t("profile.sound_effects"))
    end

    it "keeps the sign-out and the changelog in the last group" do
      sign_in student
      get "/settings"

      about = response.body[/id="settings-about".*\z/m]
      about.should include(changelog_path, sign_out_path, I18n.t("profile_link_code.title"))
    end

    it "leaves the password out while a child's profile is open" do
      parent = create(:user, role: :parent)
      child = User.create_managed_child!(parent: parent, name: "Ния")
      sign_in parent
      post "/switch-child/#{child.id}"

      get "/settings"
      response.body.should_not include(I18n.t("profile_password.title"))
      response.body.should include(I18n.t("profile.managed_account"))
    end
  end
end
