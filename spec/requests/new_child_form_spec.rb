require "rails_helper"

describe "The parent's new-child form", type: :request do
  let(:parent) { create(:user, role: :parent) }

  before { sign_in parent }

  it "keeps the child's own login and linking by code folded away by default" do
    get new_parents_child_path

    page = Nokogiri::HTML(response.body)
    page.css("details.form-disclosure").size.should eq(2)
    page.css("details.form-disclosure[open]").should be_empty
  end

  it "opens the code form when the welcome screen's code link is followed" do
    get new_parents_child_path(link: 1)

    Nokogiri::HTML(response.body).at_css("details#link")["open"].should_not be_nil
  end

  it "comes back with what was typed when the account cannot be made" do
    create(:user, email: "taken@example.com")

    expect {
      post parents_children_path, params: { name: "Мира", email: "taken@example.com", password: "secret123", birth_year: "2018" }
    }.not_to change(User, :count)

    response.status.should eq(422)
    page = Nokogiri::HTML(response.body)
    page.at_css("input#name")["value"].should eq("Мира")
    page.at_css("input#email")["value"].should eq("taken@example.com")
    page.at_css("input#password")["value"].should be_blank
    page.at_css("select#birth_year option[selected]")["value"].should eq("2018")
    page.css("details.form-disclosure[open]").map { it["id"] }.should eq([ nil ])
  end

  it "comes back with the code and the code form open when the code leads nowhere" do
    post parents_children_path, params: { link_code: "nope42" }

    response.status.should eq(422)
    response.body.should include(I18n.t("parents.children.invalid_code"))
    page = Nokogiri::HTML(response.body)
    page.at_css("details#link")["open"].should_not be_nil
    page.at_css("input#link_code")["value"].should eq("nope42")
  end

  it "still lands on step two when the child is made" do
    post parents_children_path, params: { name: "Мира" }

    child = parent.children.last
    response.should redirect_to(parents_child_path(child, tab: "practice", welcome: 1))
  end
end
