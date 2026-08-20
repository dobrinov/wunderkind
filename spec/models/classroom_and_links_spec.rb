require "rails_helper"

describe Classroom do
  let(:teacher) { create(:user, role: :teacher) }

  it "generates a readable unique invite code" do
    classroom = Classroom.create!(teacher:, name: "5а")

    classroom.invite_code.length.should eq(6)
    classroom.invite_code.chars.should all(be_in(Classroom::INVITE_CODE_ALPHABET))
  end

  it "finds by code case-insensitively with whitespace" do
    classroom = Classroom.create!(teacher:, name: "5а")

    Classroom.find_by_invite_code(" #{classroom.invite_code.downcase} ").should eq(classroom)
  end
end

describe ParentLink do
  it "links a parent to a student" do
    link = ParentLink.new(parent: create(:user, role: :parent), child: create(:user))

    link.should be_valid
  end

  it "rejects non-parent parents and non-student children" do
    ParentLink.new(parent: create(:user), child: create(:user)).should_not be_valid
    ParentLink.new(parent: create(:user, role: :parent), child: create(:user, role: :teacher)).should_not be_valid
  end
end

describe User, "#ensure_link_code!" do
  it "generates once and keeps it stable" do
    user = create(:user)

    code = user.ensure_link_code!
    user.ensure_link_code!.should eq(code)
    code.length.should eq(6)
  end
end
