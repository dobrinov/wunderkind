require "rails_helper"

# Private leaderboards among friends — see Leagues.
describe "Leagues", type: :request do
  let(:niki) { create(:user, name: "Никола Петров", role: :student) }
  let(:kali) { create(:user, name: "Калина Димова", role: :student) }
  let(:stranger) { create(:user, name: "Борис Георгиев", role: :student) }

  def befriend(a, b) = Friendship.create!(requester: a, addressee: b).tap(&:accept!)

  def earn(user, amount) = XpEvent.create!(user: user, amount: amount, reason: "answer")

  it "creates a league with the friends ticked, and nobody who is not a friend" do
    befriend(niki, kali)
    sign_in niki

    post "/leagues", params: { league: { name: "3 „Б“", friend_ids: [ kali.id, stranger.id ] } }

    league = League.sole
    response.should redirect_to("/leagues/#{league.id}")
    league.members.should contain_exactly(niki, kali)
    league.owner.should eq(niki)
  end

  it "ranks the week by first name and surname initial, and lists who has not practised without a place" do
    league = Leagues.create!(niki, name: "Клас").league
    Leagues.join!(kali, league.code)
    Leagues.join!(stranger, league.code)
    earn(niki, 40)
    earn(kali, 90)
    sign_in niki

    get "/leagues/#{league.id}"

    body = response.body
    body.should include("Никола П.", "Калина Д.", "Борис Г.")
    body.should_not include("Димова", "Георгиев")
    body.index("Калина Д.").should be < body.index("Никола П.")
    body.should include(I18n.t("leagues.not_yet"))
    body.should include(I18n.t("leagues.chase", xp: 51, name: "Калина Д."))
  end

  it "joins by code, and refuses a code that belongs to no league" do
    league = Leagues.create!(niki, name: "Клас").league
    sign_in stranger

    post "/leagues/join", params: { code: league.code.downcase }
    response.should redirect_to("/leagues/#{league.id}")
    league.reload.members.should include(stranger)

    post "/leagues/join", params: { code: "ZZZZZZ" }
    flash[:alert].should eq(I18n.t("leagues.errors.unknown_code"))
  end

  it "is visible only to its members" do
    league = Leagues.create!(niki, name: "Клас").league
    sign_in stranger

    get "/leagues/#{league.id}"

    response.should have_http_status(:not_found)
  end

  it "lets the owner change the code and take somebody out, and nobody else" do
    league = Leagues.create!(niki, name: "Клас").league
    Leagues.join!(kali, league.code)
    old_code = league.code

    sign_in kali
    patch "/leagues/#{league.id}/rotate_code"
    league.reload.code.should eq(old_code)
    delete "/leagues/#{league.id}/members/#{niki.id}"
    league.members.should include(niki)

    sign_in niki
    patch "/leagues/#{league.id}/rotate_code"
    league.reload.code.should_not eq(old_code)
    delete "/leagues/#{league.id}/members/#{kali.id}"
    league.reload.members.should_not include(kali)
  end

  it "hands the league on when its owner leaves, and the last one out takes it with them" do
    league = Leagues.create!(niki, name: "Клас").league
    Leagues.join!(kali, league.code)

    Leagues.leave!(niki, league)
    league.reload.owner.should eq(kali)

    Leagues.leave!(kali, league)
    League.exists?(league.id).should be(false)
  end

  describe "a child whose account a parent holds" do
    let(:parent) { create(:user, role: :parent, verified_at: Time.current) }
    let(:child) { User.create_managed_child!(parent: parent, name: "Мита Иванова") }

    it "stays out until the parent allows it, and switching it off takes them out of every league" do
      league = Leagues.create!(niki, name: "Клас").league
      Leagues.join!(child, league.code).error.should eq(:not_allowed)

      sign_in parent
      patch "/parents/children/#{child.id}/league_permission", params: { allowed: "1" }
      child.reload.leagues_allowed.should be(true)
      Leagues.join!(child, league.code).should be_ok

      patch "/parents/children/#{child.id}/league_permission", params: { allowed: "0" }
      child.reload.leagues.should be_empty
    end

    it "is not offered to a friend's league until then" do
      befriend(niki, child)
      sign_in niki

      get "/leagues/new"

      response.body.should include(I18n.t("leagues.friend_not_allowed"))
      post "/leagues", params: { league: { name: "Клас", friend_ids: [ child.id ] } }
      League.sole.members.should_not include(child)
    end
  end

  it "is for students only" do
    sign_in create(:user, role: :parent)

    get "/leagues"

    response.should be_redirect
  end

  it "lists the student's leagues, with their place, under the week's board" do
    niki.update!(nickname: "Комета")
    kali.update!(nickname: "Лиса")
    league = Leagues.create!(niki, name: "3 Б").league
    Leagues.join!(kali, league.code)
    earn(niki, 40)
    earn(kali, 90)
    sign_in niki

    get "/leaderboard"

    response.body.should include("3 Б", %(href="/leagues/#{league.id}"))
    response.body.should include(I18n.t("leagues.your_place", place: 2))
  end
end
