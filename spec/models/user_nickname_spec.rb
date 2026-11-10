require "rails_helper"

# The one text a child writes that other children read (NicknameRules).
describe User, "nickname" do
  let(:student) { create(:user) }

  def problem_with(nickname)
    student.nickname = nickname
    student.valid?
    student.errors.details[:nickname].map { |detail| detail[:error] }
  end

  it "takes what children actually call themselves" do
    [ "Мечо", "Мечо_7", "super.niki", "Хлебар", "Куриер 2", "Ая" ].each { |nickname| problem_with(nickname).should be_empty, nickname }
  end

  it "refuses one that is too short, too long or made of markup" do
    problem_with("а").should eq([ :too_short ])
    problem_with("а" * 21).should eq([ :too_long ])
    problem_with("<b>Мечо</b>").should eq([ :invalid ])
  end

  it "refuses one that passes for the people who run the place, however it is spelled" do
    problem_with("Админ").should eq([ :reserved ])
    problem_with("adm1n").should eq([ :reserved ])
  end

  it "refuses an obscenity" do
    problem_with("Шибаняк").should eq([ :offensive ])
  end

  it "refuses another child's, whatever the capitals" do
    create(:user, nickname: "Мечо")

    problem_with("мечо").should eq([ :taken ])
  end

  # Nicknames chosen before there were rules stay, and must not stop the
  # account from being saved for any other reason — every answer saves the user.
  it "leaves a nickname from before the rules alone" do
    student.update_column(:nickname, "x")

    student.reload.update(total_xp: 5).should be(true)
  end
end
