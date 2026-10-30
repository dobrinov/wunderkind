require "rails_helper"

describe Families do
  let(:mother) { create(:user, name: "Мария", role: :parent, last_seen_at: 1.day.ago) }
  let(:father) { create(:user, name: "Иван", role: :parent) }
  let(:nikola) { create(:user, name: "Никола") }
  let(:elena) { User.create_managed_child!(parent: mother, name: "Елена") }

  before do
    ParentLink.create!(parent: mother, child: nikola)
    ParentLink.create!(parent: father, child: nikola)
    elena
    # Signed up a few days ago, so that activity rather than arrival orders them.
    [ mother, father, nikola, elena ].each_with_index { |user, index| user.update_column(:created_at, (4 - index).days.ago) }
  end

  def names(families) = families.map { |family| [ family.parents.map(&:name), family.children.map(&:name) ] }

  it "puts two parents of one child in one family, with every child under them once" do
    Families.page.to_a.size.should eq(1)
    names(Families.page).should eq([ [ %w[Мария Иван], %w[Елена Никола] ] ])
  end

  it "keeps a parent with no children as a family of one, and leaves an unlinked student out" do
    create(:user, name: "Георги", role: :parent, created_at: 1.hour.ago)
    create(:user, name: "Сам")

    names(Families.page).should eq([ [ %w[Георги], [] ], [ %w[Мария Иван], %w[Елена Никола] ] ])
    Families.page.first.should be_solo
    Families.orphans.map(&:name).should eq(%w[Сам])
  end

  it "joins families a chain of links connects" do
    step = create(:user, name: "Втори", role: :parent)
    half = create(:user, name: "Полубрат")
    ParentLink.create!(parent: father, child: half)
    ParentLink.create!(parent: step, child: half)

    Families.page.to_a.size.should eq(1)
    Families.page.first.parents.map(&:name).should contain_exactly("Мария", "Иван", "Втори")
  end

  it "orders families by their latest activity" do
    other = create(:user, name: "Стара", role: :parent, created_at: 1.year.ago)
    names(Families.page).first.first.should eq(%w[Мария Иван])

    other.update_column(:last_seen_at, 1.minute.ago)
    names(Families.page).first.first.should eq(%w[Стара])
  end

  it "paginates families, not people" do
    3.times { |index| create(:user, name: "Самотен #{index}", role: :parent) }

    first = Families.page(per: 2)
    first.size.should eq(2)
    first.total_count.should eq(4)
    Families.page(per: 2, page: 2).size.should eq(2)
  end

  describe "filters" do
    it "matches a family on any member: name, nickname, email, link code and friend code" do
      nikola.update!(nickname: "Ники", link_code: "K7P2Q9", friend_code: "ABC234")
      create(:user, name: "Друг", role: :parent)

      %w[ники k7p2q9 abc234].each do |query|
        names(Families.page(query:)).should eq([ [ %w[Мария Иван], %w[Елена Никола] ] ])
      end
      names(Families.page(query: father.email)).size.should eq(1)
      Families.page(query: "никой").should be_empty
    end

    it "narrows to families active this week, with an unconfirmed address, with an open ticket or new" do
      old = create(:user, name: "Стар", role: :parent, created_at: 1.month.ago, verified_at: 1.month.ago)

      Families.page(filters: %w[active]).map(&:id).should eq([ mother.id ])
      Families.page(filters: %w[unverified]).map(&:id).should eq([ mother.id ])
      Families.page(filters: %w[new]).map(&:id).should eq([ mother.id ])
      Families.page(filters: %w[tickets]).should be_empty

      QuestionReport.create!(question: create(:question), user: elena, reason: :typo)
      Families.page(filters: %w[tickets]).map(&:id).should eq([ mother.id ])
      old.update_column(:verified_at, nil)
      Families.page(filters: %w[unverified]).size.should eq(2)
    end
  end

  it "finds the family of one person" do
    Families.of(elena).parents.should eq([ mother, father ])
    Families.of(create(:user)).should be_nil
  end
end
