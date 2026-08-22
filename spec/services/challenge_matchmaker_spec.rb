require "rails_helper"

describe ChallengeMatchmaker do
  before { create_list(:question, Challenge::QUESTION_COUNT, elo: 1050) }

  let(:host) { create(:user) }
  let(:guest) { create(:user) }

  it "opens a lobby for the first player in" do
    challenge = ChallengeMatchmaker.call(user: host)

    challenge.should be_waiting
    challenge.users.should eq([ host ])
    challenge.challenge_questions.should be_empty
  end

  it "starts the match for the second player in" do
    lobby = ChallengeMatchmaker.call(user: host)
    challenge = ChallengeMatchmaker.call(user: guest)

    challenge.should eq(lobby)
    challenge.should be_active
    challenge.started_at.should be_present
    challenge.users.should match_array([ host, guest ])
    challenge.questions.count.should eq(Challenge::QUESTION_COUNT)
  end

  it "gives both players the same problems" do
    ChallengeMatchmaker.call(user: host)
    challenge = ChallengeMatchmaker.call(user: guest)

    challenge.challenge_questions.map(&:position).should eq((1..Challenge::QUESTION_COUNT).to_a)
  end

  it "returns the player to the match they are already in" do
    challenge = ChallengeMatchmaker.call(user: host)

    ChallengeMatchmaker.call(user: host).should eq(challenge)
    Challenge.count.should eq(1)
  end

  it "does not pair a player with a far stronger one" do
    ChallengeMatchmaker.call(user: host)
    mismatched = create(:user, elo: host.elo + ChallengeMatchmaker::MAX_GAP + 1)

    challenge = ChallengeMatchmaker.call(user: mismatched)

    challenge.should be_waiting
    challenge.users.should eq([ mismatched ])
  end

  it "pairs anyone once the other player has waited long enough" do
    lobby = ChallengeMatchmaker.call(user: host)
    lobby.update!(created_at: (ChallengeMatchmaker::PATIENCE + 5.seconds).ago)
    mismatched = create(:user, elo: host.elo + ChallengeMatchmaker::MAX_GAP + 1)

    ChallengeMatchmaker.call(user: mismatched).should eq(lobby.reload)
    lobby.should be_active
  end

  it "writes off a lobby nobody joined" do
    lobby = ChallengeMatchmaker.call(user: host)
    lobby.update!(created_at: (Challenge::LOBBY_TTL + 1.minute).ago)

    challenge = ChallengeMatchmaker.call(user: guest)

    lobby.reload.should be_abandoned
    challenge.should_not eq(lobby)
    challenge.should be_waiting
  end

  it "keeps duel problems away from topics the player has skipped" do
    topic = Topic.create!(name: "Дроби")
    create_list(:question, 2, elo: 1050).each { |question| question.topics << topic }
    host.skill_for(topic).update!(deferred_until: 2.weeks.from_now)

    ChallengeMatchmaker.call(user: host)
    challenge = ChallengeMatchmaker.call(user: guest)

    challenge.questions.joins(:topics).where(topics: { id: topic.id }).should be_empty
  end

  it "says so instead of opening a lobby that can never start" do
    Question.update_all(status: Question.statuses[:draft])

    expect { ChallengeMatchmaker.call(user: host) }.to raise_error(Dispatcher::NotEnoughQuestions)
  end
end
