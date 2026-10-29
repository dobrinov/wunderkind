require "rails_helper"

describe FeatureVisibility do
  let(:student) { create(:user) }

  def finish_sessions(count)
    count.times { Assignment.create!(user: student, completed_at: Time.current) }
  end

  it "starts a new student with everything findable and nothing to introduce" do
    visibility = FeatureVisibility.for(student)

    FeatureVisibility::FEATURES.each { |feature| visibility.state(feature).should eq(:findable) }
    visibility.pending_introduction.should be_nil
  end

  it "presents duels after a few sessions, and gives them a tab once the child plays" do
    finish_sessions(FeatureVisibility::SESSIONS_FOR_DUEL)
    FeatureVisibility.for(student).state(:duel).should eq(:presented)
    FeatureVisibility.for(student).pending_introduction.should eq(:duel)

    allow(ChallengeRecord).to receive(:for).and_return(ChallengeRecord::Record.new(played: FeatureVisibility::DUELS_FOR_TAB, won: 1, drawn: 0, lost: 2))
    FeatureVisibility.for(student).state(:duel).should eq(:prominent)
  end

  it "makes duels and friends prominent for a child with a friend" do
    friend = create(:user)
    Friendship.create!(requester: student, addressee: friend).tap(&:accept!)

    visibility = FeatureVisibility.for(student)
    visibility.state(:duel).should eq(:prominent)
    visibility.state(:friends).should eq(:prominent)
    visibility.state(:leaderboards).should eq(:presented)
  end

  it "presents a feature somebody else started: a friend request" do
    Friendship.create!(requester: create(:user), addressee: student)

    FeatureVisibility.for(student).state(:duel).should eq(:presented)
  end

  it "introduces one feature at a time, oldest first, and not again" do
    finish_sessions(FeatureVisibility::SESSIONS_FOR_DUEL)
    BadgeAward.create!(user: student, badge_key: "first_session")

    FeatureVisibility.for(student).pending_introduction.should eq(:badges)
    student.update!(introduced_features: %w[badges])
    FeatureVisibility.for(student).pending_introduction.should eq(:duel)
    student.update!(introduced_features: %w[badges duel])
    FeatureVisibility.for(student).pending_introduction.should be_nil
  end

  it "shows everything at once when a parent says so, with nothing to introduce" do
    student.update!(show_all_features: true)
    visibility = FeatureVisibility.for(student)

    FeatureVisibility::FEATURES.each { |feature| visibility.state(feature).should eq(:prominent) }
    visibility.pending_introduction.should be_nil
  end
end
