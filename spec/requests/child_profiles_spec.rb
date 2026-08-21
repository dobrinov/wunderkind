require "rails_helper"

describe "Child profiles inside a parent's account", type: :request do
  let(:parent) { create(:user, role: :parent, verified_at: Time.current) }

  def create_child(name: "Мими", email: nil, password: nil)
    post "/parents/children", params: { name: name, email: email, password: password }.compact
    User.order(:id).last
  end

  it "creates a child who has no email at all" do
    sign_in parent
    child = create_child

    child.email.should be_nil
    child.managed_by.should eq(parent)
    child.should be_managed
    parent.children.should include(child)
    child.elo.should eq(Dispatcher.starting_rating)
  end

  it "creates two emailless children without them colliding" do
    sign_in parent
    create_child(name: "Мими")
    create_child(name: "Тошо")

    parent.managed_children.map(&:name).should contain_exactly("Мими", "Тошо")
  end

  it "gives a child their own login when an email and password are supplied" do
    sign_in parent
    child = create_child(email: "kid@example.com", password: "secret123")

    child.email.should eq("kid@example.com")
    child.authenticate("secret123").should be_truthy
  end

  it "refuses an email without a password rather than inventing one" do
    sign_in parent
    post "/parents/children", params: { name: "Мими", email: "kid@example.com" }

    User.exists?(email: "kid@example.com").should be(false)
    flash[:alert].should be_present
  end

  it "switches into the child and back again" do
    sign_in parent
    child = create_child

    post "/switch-child/#{child.id}"
    response.should redirect_to("/calendar")

    get "/calendar"
    response.body.should include(child.name)
    response.body.should include(I18n.t("child_session.switch_back"))

    # Everything the app does now belongs to the child, not the parent.
    patch "/profile", params: { user: { nickname: "мимиче" } }
    child.reload.nickname.should eq("мимиче")
    parent.reload.nickname.should be_nil

    # And the parent's own area is closed until they come back.
    get "/parents/children"
    response.should redirect_to("/")

    delete "/switch-child"
    response.should redirect_to("/parents/children")
    get "/parents/children"
    response.should have_http_status(:ok)
  end

  it "offers the switch on the children screen only for managed accounts" do
    linked = create(:user)
    ParentLink.create!(parent: parent, child: linked)

    sign_in parent
    create_child
    get "/parents/children"

    response.body.scan(I18n.t("parents.children.switch")).length.should eq(1)
    response.body.should include(I18n.t("parents.children.own_login_note"))

    get "/parents/children/new"
    response.should have_http_status(:ok)
  end

  it "explains the missing email on the child's own profile" do
    sign_in parent
    child = create_child
    post "/switch-child/#{child.id}"

    get "/profile"

    response.body.should include(I18n.t("profile.managed_account"))
  end

  it "names the managing account in the admin user list" do
    child = User.create_managed_child!(parent: parent, name: "Мими")
    sign_in create(:user, role: :admin, verified_at: Time.current)

    get "/overseer/users"

    response.body.should include(I18n.t("overseer.users.managed_by", name: parent.name))
    child.email.should be_nil
  end

  it "picks a sibling straight from the bar" do
    linked = create(:user, name: "Големия")
    ParentLink.create!(parent: parent, child: linked)

    sign_in parent
    nia = create_child(name: "Ния")
    mimi = create_child(name: "Мими")

    post "/switch-child/#{nia.id}"
    get "/calendar"

    # The sibling is offered; the profile already open is not, and neither is a
    # child who signs in for themselves.
    response.body.should include(I18n.t("child_session.switch_to_name", name: mimi.name))
    response.body.should_not include(I18n.t("child_session.switch_to_name", name: nia.name))
    response.body.should_not include(I18n.t("child_session.switch_to_name", name: linked.name))

    post "/switch-child/#{mimi.id}"
    patch "/profile", params: { user: { nickname: "мимиче" } }

    mimi.reload.nickname.should eq("мимиче")
    nia.reload.nickname.should be_nil
  end

  it "leaves the picker out when there is nowhere else to go" do
    sign_in parent
    child = create_child
    post "/switch-child/#{child.id}"

    get "/calendar"

    response.body.should include(I18n.t("child_session.switch_back"))
    response.body.should_not include(I18n.t("child_session.switch_to"))
  end

  it "will not switch into a child who has their own account" do
    linked = create(:user)
    ParentLink.create!(parent: parent, child: linked)

    sign_in parent
    post "/switch-child/#{linked.id}"

    response.should redirect_to("/parents/children")
    flash[:alert].should be_present
    get "/parents/children"
    response.should have_http_status(:ok)
  end

  it "will not switch into someone else's child" do
    other_parent = create(:user, role: :parent, verified_at: Time.current)
    stranger = User.create_managed_child!(parent: other_parent, name: "Чуждо")

    sign_in parent
    post "/switch-child/#{stranger.id}"

    flash[:alert].should be_present
    get "/parents/children"
    response.should have_http_status(:ok)
  end

  it "drops the open child profile when the parent signs out" do
    sign_in parent
    child = create_child
    post "/switch-child/#{child.id}"

    delete "/sign-out"
    sign_in parent

    get "/parents/children"
    response.should have_http_status(:ok)
  end

  it "closes the open profile the moment the account stops managing the child" do
    sign_in parent
    child = create_child
    post "/switch-child/#{child.id}"

    # The account was handed to the other parent, so this session's door shuts
    # on the next request rather than at the next sign-in.
    child.update!(managed_by: create(:user, role: :parent))

    get "/parents/children"
    response.should have_http_status(:ok)
  end

  it "keeps an emailless child reachable by refusing to unmanage them" do
    child = User.create_managed_child!(parent: parent, name: "Мими")

    child.update(managed_by: nil).should be(false)
  end

  it "cannot be signed into with a blank email, managed child or not" do
    parent
    User.create_managed_child!(parent: parent, name: "Мими")

    post "/sign-in", params: { email: "", password: "" }

    response.should have_http_status(:unprocessable_entity)
    session[:user_id].should be_nil
  end
end
