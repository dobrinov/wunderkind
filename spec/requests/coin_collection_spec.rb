require "rails_helper"

describe "The coin collection and the parent's praise line", type: :request do
  let(:parent) { create(:user, role: :parent, verified_at: Time.current) }
  let(:child) { User.create_managed_child!(parent: parent, name: "Ния Петрова") }

  it "shows a row per visible track on „Аз“, with a dialog each" do
    child.update!(climb_base_elo: child.elo - 60)
    sign_in parent
    post switch_child_path(child)
    get profile_path

    page = Nokogiri::HTML(response.body)
    page.css(".coin-row").size.should eq(Coins.visible_tracks(child).size)
    page.css("dialog.coin-dialog").size.should eq(Coins.visible_tracks(child).size)
    page.at_css("[aria-label='#{I18n.t("coins.materials.bronze")} · #{I18n.t("coins.tracks.climb.name")}']").should be_present
  end

  it "tells the parent who to praise today, and for what" do
    child.update!(climb_base_elo: child.elo - 30)
    sign_in parent
    get parents_children_path

    response.body.should include(I18n.t("parents.today.praise"))
    response.body.should include(I18n.t("coins.praise", name: "Ния", track: I18n.t("coins.tracks.climb.name")))
  end
end
