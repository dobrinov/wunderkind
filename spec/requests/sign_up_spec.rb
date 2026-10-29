require "rails_helper"

describe "Signing up", type: :request do
  it "creates the account and signs the new user in on a fresh session" do
    session_key = Rails.application.config.session_options[:key]

    get "/sign-up"
    session_before = cookies[session_key]

    post "/sign-up", params: { name: "Нов Ученик", email: "new@example.com", password: "password" }

    # A new student is shown where they stand before anything else.
    response.should redirect_to("/placements/new")
    User.find_by(email: "new@example.com").should be_present
    # Same rule as signing in: a session fixed before the account existed must
    # not ride into it.
    cookies[session_key].should_not eq(session_before)
  end

  # „Кой си ти?" comes first, as two links, so it needs no JavaScript and the
  # back button returns to it.
  describe "the first step" do
    it "asks who is signing up before showing a form" do
      get "/sign-up"

      response.body.should include(I18n.t("registration.who_title"))
      response.body.should include(%(href="/sign-up?role=parent"), %(href="/sign-up?role=student"))
      response.body.should_not include(%(name="password"))
    end

    it "shows the short form for the role picked, which carries the role" do
      get "/sign-up", params: { role: "parent" }

      response.body.should include(I18n.t("registration.form.parent.title"))
      response.body.should include(%(type="hidden" name="role" id="role" value="parent"))
      response.body.should include(%(name="password"))
    end

    it "treats a role it does not offer as no role at all" do
      get "/sign-up", params: { role: "admin" }

      response.body.should include(I18n.t("registration.who_title"))
      response.body.should_not include(%(name="password"))
    end

    it "keeps a competition through the choice and promises the entry only to a student" do
      event = Competitions.all.first

      get "/sign-up", params: { competition: event.slug }
      response.body.should include(ERB::Util.html_escape(sign_up_path(role: "student", competition: event.slug)))

      get "/sign-up", params: { role: "student", competition: event.slug }
      response.body.should include(%(name="competition" id="competition" value="#{event.slug}"))

      get "/sign-up", params: { role: "parent", competition: event.slug }
      response.body.should_not include(%(name="competition"))
    end
  end

  it "takes a new parent to their own page, not to placement" do
    post "/sign-up", params: { name: "Ивана", email: "ivana@example.com", password: "secret123", role: "parent" }

    response.should redirect_to("/parents/children")
    User.find_by(email: "ivana@example.com").should be_parent
  end

  # A refused sign-up came back as the same form, empty and without a word,
  # which a parent reported as "the page just refreshed".
  it "says why it refused, keeps what was typed and points a returning parent to adding a child" do
    User.create!(name: "Родител", email: "parent@example.com", password: "secret123", role: :parent)

    post "/sign-up", params: { name: "Митачето", email: "Parent@example.com", password: "secret123", role: "student" }

    response.should have_http_status(:unprocessable_entity)
    response.body.should include("Имейл вече съществува")
    response.body.should include("Семейство")
    response.body.should include(%(value="Митачето"))
    response.body.should_not include("secret123")
  end

  it "names a password that is too short, on the form of the role that was picked" do
    post "/sign-up", params: { name: "Ива", email: "iva@example.com", password: "123", role: "parent" }

    response.should have_http_status(:unprocessable_entity)
    response.body.should include("Парола е твърде кратко")
    response.body.should include(I18n.t("registration.form.parent.title"))
    response.body.should include(%(type="hidden" name="role" id="role" value="parent"))
  end
end
