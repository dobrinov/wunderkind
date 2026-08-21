# Pairs a student with an opponent for a live duel.
#
# There is no queue service and no background worker: an unmatched player is a
# `waiting` challenge with one participant in it, and the next player to press
# the button joins the closest one and starts the match. Whoever arrives second
# pays for the pairing, which is exactly the request that is happy to wait.
module ChallengeMatchmaker
  extend self

  # How far apart two ratings can be and still make a duel worth playing. The
  # problems are picked at the midpoint of the two, so a wide gap means both
  # players get a match aimed at nobody.
  MAX_GAP = 400

  # ...unless the other player has been waiting this long already, at which
  # point any opponent beats no opponent.
  PATIENCE = 45.seconds

  # The challenge this student belongs in right now: one they are already in, a
  # peer's open lobby (started here and now), or a fresh lobby of their own.
  def call(user:)
    sweep!

    current(user) || join_open_lobby(user) || open_lobby(user)
  end

  # A student is only ever in one live match at a time, so a reload, a second
  # tab or a stray double-click lands back in the same room.
  def current(user)
    Challenge.in_progress.
      joins(:participants).
      where(challenge_participants: { user_id: user.id }).
      order(created_at: :desc).
      first
  end

  # Lobbies nobody joined in time. Written off lazily on the way in rather than
  # by a scheduled job — the only thing that cares is the next matchmaking run.
  def sweep!
    Challenge.waiting.where(created_at: ...Challenge::LOBBY_TTL.ago).
      update_all(status: Challenge.statuses[:abandoned], updated_at: Time.current)
  end

  private

  def join_open_lobby(user)
    candidates(user).each do |challenge|
      started = start(challenge, user)
      return started if started
    end

    nil
  end

  # Closest rating first among lobbies within MAX_GAP, then anyone who has been
  # waiting longer than PATIENCE, oldest first.
  def candidates(user)
    own = ChallengeParticipant.where(user_id: user.id).select(:challenge_id)
    open = Challenge.open_lobbies.where.not(id: own)

    near = open.where(target_elo: (user.elo - MAX_GAP)..(user.elo + MAX_GAP)).
      order(Arel.sql("ABS(challenges.target_elo - #{user.elo.to_i})")).to_a
    patient = open.where(created_at: ...PATIENCE.ago).order(:created_at).to_a

    (near + patient).uniq
  end

  # Locks the lobby before committing to it: two players pressing the button in
  # the same instant must not both think they joined the same room.
  def start(challenge, joining_user)
    challenge.with_lock do
      return nil unless challenge.reload.waiting?

      host = challenge.participants.first&.user
      return nil if host.nil? || host.id == joining_user.id

      questions = Dispatcher.pick_shared([ host, joining_user ], count: challenge.question_count)
      raise AssignmentCreator::NotEnoughQuestions, "Not enough questions for a challenge" if questions.size < challenge.question_count

      questions.shuffle.each_with_index do |question, index|
        challenge.challenge_questions.create!(question: question, position: index + 1)
      end
      challenge.participants.create!(user: joining_user)
      challenge.update!(status: :active, started_at: Time.current)
    end

    challenge
  end

  def open_lobby(user)
    # Checked here rather than when the second player arrives, so a bank too
    # thin to fill a match says so to the player who can still do something
    # else with their evening.
    if Dispatcher.pick_shared([ user ], count: Challenge::QUESTION_COUNT).size < Challenge::QUESTION_COUNT
      raise AssignmentCreator::NotEnoughQuestions, "Not enough questions for a challenge"
    end

    challenge = Challenge.create!(
      question_count: Challenge::QUESTION_COUNT,
      seconds_per_question: Challenge::SECONDS_PER_QUESTION,
      target_elo: user.elo
    )
    challenge.participants.create!(user: user)
    challenge
  end
end
