require "rails_helper"

RSpec.describe PeopleHelper, type: :helper do
  describe "#person_avatar" do
    # „ Денис Есинов", typed with a leading space, drew an empty circle.
    it "takes the first letter of a name stored with a leading space" do
      user = User.new(name: "Денис Есинов")
      user[:name] = " Денис Есинов"

      expect(helper.person_avatar(user)).to include(">Д<")
    end
  end

  it "stores a name without the spaces around it" do
    expect(User.new(name: "  Денис   Есинов ").name).to eq("Денис Есинов")
  end
end
