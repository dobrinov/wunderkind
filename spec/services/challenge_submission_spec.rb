require "rails_helper"

describe ChallengeSubmission do
  before { create_list(:question, Challenge::QUESTION_COUNT, elo: 1050) }

  let(:host) { create(:user) }
  let(:guest) { create(:user) }
  let(:challenge) do
    ChallengeMatchmaker.call(user: host)
    ChallengeMatchmaker.call(user: guest)
  end
  let(:host_side) { challenge.participant_for(host) }
  let(:guest_side) { challenge.participant_for(guest) }

  # `served: false` skips the stamp the controller writes when it puts a problem
  # on screen, which is how a player forfeits the speed bonus — handy for
  # arranging an exact tie.
  def answer(participant, position, value: "42", served: true)
    challenge_question = challenge.challenge_questions.find_by!(position: position)
    ChallengeSubmission.serve(participant) if served

    ChallengeSubmission.call(participant: participant, challenge_question: challenge_question, raw: { value: value })
  end

  def play_all(participant, value: "42", served: true)
    (1..challenge.question_count).each { |position| answer(participant, position, value: value, served: served) }
  end

  it "scores a correct answer and pays XP for it" do
    outcome = answer(host_side, 1)

    outcome.result.correct.should be(true)
    outcome.points.should be > ChallengeScoring::CORRECT_POINTS
    host_side.reload.score.should eq(outcome.points)
    host_side.correct_count.should eq(1)
    host.reload.xp_events.where(reason: "challenge_answer").count.should eq(1)
  end

  it "scores a wrong answer at nothing but still counts as practice today" do
    outcome = answer(host_side, 1, value: "41")

    outcome.points.should eq(0)
    host_side.reload.score.should eq(0)
    host_side.correct_count.should eq(0)
    host.reload.current_streak.should eq(1)
    host.last_active_on.should eq(Date.current)
  end

  it "leaves every measurement alone: no rating, no question Elo, no calibration" do
    question = challenge.challenge_questions.find_by!(position: 1).question
    user_elo_before = host.elo
    question_elo_before = question.elo

    answer(host_side, 1)

    host.reload.elo.should eq(user_elo_before)
    host.skills.should be_empty
    question.reload.elo.should eq(question_elo_before)
    host.user_answers.count.should eq(0)
    Dispatcher.calibrating?(host).should be(true)
  end

  it "ignores the client's idea of how long an answer took" do
    ChallengeSubmission.serve(host_side)
    host_side.update!(question_started_at: 20.seconds.ago)

    outcome = answer(host_side, 1, served: false)

    outcome.answer.duration_ms.should be_within(1_000).of(20_000)
  end

  it "refuses a second answer to the same problem" do
    answer(host_side, 1)

    expect { answer(host_side, 1) }.to raise_error(ChallengeSubmission::AlreadyAnswered)
  end

  it "refuses a submission with nothing in it" do
    expect { answer(host_side, 1, value: "") }.to raise_error(ChallengeSubmission::BlankResponse)
  end

  it "ends the match when both players are done and pays the winner a bonus" do
    play_all(host_side)
    challenge.reload.should be_active

    play_all(guest_side, value: "41")

    challenge.reload.should be_finished
    challenge.winner_id.should eq(host.id)
    host.reload.xp_events.where(reason: "challenge_won").count.should eq(1)
    guest.reload.xp_events.where(reason: "challenge_played").count.should eq(1)
    host_side.reload.xp_earned.should be > guest_side.reload.xp_earned
  end

  it "awards the duel badge to the winner only" do
    play_all(host_side)
    play_all(guest_side, value: "41")

    host.reload.badge_awards.pluck(:badge_key).should include("duel_win")
    guest.reload.badge_awards.pluck(:badge_key).should_not include("duel_win")
  end

  it "calls a dead heat a draw" do
    play_all(host_side, served: false)
    play_all(guest_side, served: false)

    challenge.reload.should be_finished
    challenge.winner_id.should be_nil
    challenge.draw?.should be(true)
    host_side.reload.score.should eq(guest_side.reload.score)
  end

  it "settles a match whose clock ran out, without a winner if nobody scored" do
    challenge.update!(started_at: (challenge.time_limit_seconds + 1).seconds.ago)

    ChallengeSubmission.settle(challenge).should be(true)

    challenge.reload.should be_finished
    challenge.winner_id.should be_nil
    challenge.participants.map(&:finished_at).should all(be_present)
  end

  it "hands the win to whoever scored before the clock ran out" do
    answer(host_side, 1)
    challenge.update!(started_at: (challenge.time_limit_seconds + 1).seconds.ago)

    ChallengeSubmission.settle(challenge)

    challenge.reload.winner_id.should eq(host.id)
  end

  it "refuses an answer once the clock has run out" do
    challenge.update!(started_at: (challenge.time_limit_seconds + 1).seconds.ago)

    expect { answer(host_side, 1) }.to raise_error(ChallengeSubmission::OutOfTime)
  end

  it "settles a match only once" do
    play_all(host_side)
    play_all(guest_side, value: "41")

    ChallengeSubmission.settle(challenge.reload).should be(false)
    host.reload.xp_events.where(reason: "challenge_won").count.should eq(1)
  end
end
