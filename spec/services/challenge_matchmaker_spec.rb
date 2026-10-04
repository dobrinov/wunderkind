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

  it "fills the lobby for the second player in, and starts nothing" do
    lobby = ChallengeMatchmaker.call(user: host)
    challenge = ChallengeMatchmaker.call(user: guest)

    challenge.should eq(lobby)
    challenge.should be_lobby
    challenge.paired_at.should be_present
    challenge.started_at.should be_nil
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
    lobby.should be_lobby
  end

  # The bug this rewrite exists for: matchmaking used to run only on the
  # button, and a student holding their own empty lobby was handed it straight
  # back — so two people who pressed a second apart, or whose ratings were too
  # far apart on the first try, each sat in a room of their own forever.
  it "brings two players who each opened their own lobby together" do
    far = create(:user, elo: host.elo + ChallengeMatchmaker::MAX_GAP + 200)

    mine = ChallengeMatchmaker.call(user: host)
    theirs = ChallengeMatchmaker.call(user: far)
    mine.should_not eq(theirs)

    # Nobody pressed anything; both lobbies simply waited past PATIENCE, which
    # is what the polling screens do.
    [ mine, theirs ].each { |lobby| lobby.update!(created_at: (ChallengeMatchmaker::PATIENCE + 5.seconds).ago) }

    paired = ChallengeMatchmaker.call(user: far)
    paired.should be_lobby
    paired.users.should match_array([ host, far ])

    # And the loser of the pair is not left advertising a player already in a
    # match, nor is the host sent back to their abandoned room.
    Challenge.waiting.count.should eq(0)
    ChallengeMatchmaker.call(user: host).should eq(paired)
  end

  it "has exactly one of two simultaneous lobbies do the joining" do
    mine = ChallengeMatchmaker.send(:open_lobby, host, [])
    theirs = ChallengeMatchmaker.send(:open_lobby, guest, [])

    # Both poll in the same instant. The id ceiling in `candidates` means only
    # the newer lobby's owner qualifies to join, so they cannot cross.
    first = ChallengeMatchmaker.call(user: host)
    second = ChallengeMatchmaker.call(user: guest)

    first.should eq(second)
    Challenge.paired.count.should eq(1)
    [ mine, theirs ].count { |lobby| lobby.reload.lobby? }.should eq(1)
    [ host, guest ].each { |user| paired_rooms(user).count.should eq(1) }
  end

  # The three-way version of the same race. Giving up your own lobby is how you
  # claim the right to join another, and it is a single conditional UPDATE — so
  # a player who loses that claim is already in somebody's match and must not
  # take a second seat in the one they were about to join.
  it "stops looking when a third player claimed its lobby mid-join" do
    target = ChallengeMatchmaker.call(user: host)
    mine = ChallengeMatchmaker.send(:open_lobby, guest, [])
    third = create(:user, elo: guest.elo)

    # Slipped in between choosing a candidate and committing to it.
    ChallengeMatchmaker.should_receive(:candidates).once.and_wrap_original do |original, user, topic_ids|
      ChallengeMatchmaker.send(:pair, mine, third)
      original.call(user, topic_ids)
    end

    ChallengeMatchmaker.call(user: guest).should eq(mine.reload)
    mine.users.should match_array([ guest, third ])
    target.reload.should be_waiting
    paired_rooms(guest).count.should eq(1)
  end

  def paired_rooms(user)
    Challenge.paired.joins(:participants).where(challenge_participants: { user_id: user.id })
  end

  it "writes off a lobby nobody joined" do
    lobby = ChallengeMatchmaker.call(user: host)
    lobby.update!(created_at: (Challenge::LOBBY_TTL + 1.minute).ago)

    challenge = ChallengeMatchmaker.call(user: guest)

    lobby.reload.should be_abandoned
    challenge.should_not eq(lobby)
    challenge.should be_waiting
  end

  # A room both players readied in and then walked away from. Starting it when
  # somebody finally looks would mean a match that is over before its first
  # paint, and a 0–0 draw paying both of them a bonus for a duel neither was at.
  it "writes off a countdown nobody came back for" do
    ChallengeMatchmaker.call(user: host)
    room = ChallengeMatchmaker.call(user: guest)
    room.participants.each { |participant| ChallengeLobby.ready!(room, participant) }
    room.update!(starts_at: (room.time_limit_seconds + 1.minute).ago)

    ChallengeLobby.begin!(room).should be(false)
    room.reload.should be_abandoned
    room.started_at.should be_nil
  end

  it "writes off a full lobby nobody readied in" do
    ChallengeMatchmaker.call(user: host)
    room = ChallengeMatchmaker.call(user: guest)
    room.update!(paired_at: (Challenge::READY_TIMEOUT + 10.seconds).ago)

    ChallengeMatchmaker.call(user: create(:user))

    room.reload.should be_abandoned
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
