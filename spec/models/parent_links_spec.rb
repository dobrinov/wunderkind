require "rails_helper"

describe ParentLink do
  it "links a parent to a student" do
    link = ParentLink.new(parent: create(:user, role: :parent), child: create(:user))

    link.should be_valid
  end

  it "rejects non-parent parents and non-student children" do
    ParentLink.new(parent: create(:user), child: create(:user)).should_not be_valid
    ParentLink.new(parent: create(:user, role: :parent), child: create(:user, role: :parent)).should_not be_valid
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

describe User, "managed children" do
  let(:parent) { create(:user, role: :parent) }

  it "creates a child with no email and links them to the parent" do
    child = User.create_managed_child!(parent: parent, name: "Мими")

    child.email.should be_nil
    child.should be_managed
    child.should be_student
    parent.children.should eq([ child ])
    parent.managed_children.should eq([ child ])
  end

  it "still demands an email from anyone who signs in for themselves" do
    User.new(name: "Никой", password: "secret123").should_not be_valid
    create(:user).should be_managed.!
  end

  it "goes with the parent account when it is deleted" do
    child = User.create_managed_child!(parent: parent, name: "Мими")

    parent.destroy!

    User.exists?(child.id).should be(false)
  end
end
