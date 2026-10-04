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

  # The challenge this student belongs in right now: a room they are already
  # paired in, a peer's open lobby (filled here and now), or a lobby of their
  # own to wait in.
  #
  # Called on the button *and* on every poll of a waiting screen, which is the
  # fix for the bug that outlived the original: matchmaking only ever ran on
  # the button, and `current` handed a student their own empty lobby straight
  # back, so two people who pressed within a second of each other — or whose
  # ratings were more than MAX_GAP apart on the first try — each sat in a room
  # of their own forever. PATIENCE could never rescue them, because nothing
  # looked again.
  def call(user:)
    sweep!

    paired_match(user) || join_open_lobby(user) || own_lobby(user)
  end

  # Any live room this student is in, their own empty lobby included — what the
  # index links to when it says "you have a duel open".
  def current(user)
    Challenge.in_progress.
      joins(:participants).
      where(challenge_participants: { user_id: user.id }).
      order(created_at: :desc).
      first
  end

  # Rooms nobody turned up to, written off lazily on the way in rather than by
  # a scheduled job: a lobby nobody joined inside LOBBY_TTL, and a filled lobby
  # nobody readied in inside READY_TIMEOUT.
  def sweep!
    abandon(Challenge.waiting.where(created_at: ...Challenge::LOBBY_TTL.ago))
    abandon(Challenge.lobby.where(starts_at: nil).where(paired_at: ...Challenge::READY_TIMEOUT.ago))
  end

  private

  def abandon(scope)
    scope.update_all(status: Challenge.statuses[:abandoned], updated_at: Time.current)
  end

  # A room with an opponent in it. Deliberately *not* the student's own empty
  # lobby: that is a request for an opponent, not a match, and treating it as
  # one is what stopped `call` from ever looking again.
  def paired_match(user)
    Challenge.paired.
      joins(:participants).
      where(challenge_participants: { user_id: user.id }).
      order(created_at: :desc).
      first
  end

  def own_lobby(user)
    own_open_lobby(user) || open_lobby(user)
  end

  def own_open_lobby(user)
    Challenge.open_lobbies.
      joins(:participants).
      where(challenge_participants: { user_id: user.id }).
      order(created_at: :desc).
      first
  end

  def join_open_lobby(user)
    candidates(user).each do |challenge|
      paired = pair(challenge, user)
      return paired if paired
    end

    # A seat may have been taken *for* this player while they were looking: a
    # third player pairing into the lobby they were sitting in. See `pair`.
    paired_match(user)
  end

  # Closest rating first among lobbies within MAX_GAP, then anyone who has been
  # waiting longer than PATIENCE, oldest first.
  #
  # The id ceiling is what keeps two waiting players from joining *each other*
  # at the same instant and ending up in two full rooms. Both poll, both look,
  # and a row lock on one lobby cannot see a lock on the other — so the tie is
  # broken before either of them takes it: a student who already holds a lobby
  # only ever joins an older one. In any pair exactly one side qualifies, which
  # settles it without a lock spanning two rows.
  def candidates(user)
    own = ChallengeParticipant.where(user_id: user.id).select(:challenge_id)
    open = Challenge.open_lobbies.where.not(id: own)

    mine = own_open_lobby(user)
    open = open.where(id: ...mine.id) if mine

    near = open.where(target_elo: (user.elo - MAX_GAP)..(user.elo + MAX_GAP)).
      order(Arel.sql("ABS(challenges.target_elo - #{user.elo.to_i})")).to_a
    patient = open.where(created_at: ...PATIENCE.ago).order(:created_at).to_a

    (near + patient).uniq
  end

  # Fills the lobby: picks the problems and seats the second player, and stops
  # there. The match itself begins when both have pressed „Готов съм" and the
  # countdown has run out — see ChallengeLobby.
  #
  # Locks the lobby before committing to it, so two players arriving in the
  # same instant cannot both think they took the last seat.
  def pair(challenge, joining_user)
    seated = false

    challenge.with_lock do
      next unless challenge.reload.waiting?

      host = challenge.participants.first&.user
      next if host.nil? || host.id == joining_user.id

      # Both players' rows, taken in id order, and this is what makes "at most
      # one match per player" actually hold. Pairing is the one operation that
      # commits somebody who is not the one asking — the host — so two pairings
      # can involve the same person through different lobbies: A(10), B(20),
      # C(30) all waiting, B takes a seat in 10 while C takes a seat in 20, and
      # B is in two matches at once with C's opponent somewhere else. A lock on
      # the lobby cannot see that; a lock on the players can, because every
      # pairing either of them is part of has to contend for it. Sorting by id
      # keeps it deadlock-free, and nothing waits on a lobby while holding one
      # of these.
      [ host, joining_user ].sort_by(&:id).each(&:lock!)
      next if paired_match(joining_user) || paired_match(host)

      questions = Dispatcher.pick_shared([ host, joining_user ], count: challenge.question_count)
      raise Dispatcher::NotEnoughQuestions, "Not enough questions for a challenge" if questions.size < challenge.question_count

      questions.shuffle.each_with_index do |question, index|
        challenge.challenge_questions.create!(question: question, position: index + 1)
      end
      challenge.participants.create!(user: joining_user)
      challenge.update!(status: :lobby, paired_at: Time.current)
      seated = true
    end

    return nil unless seated

    # Tidiness rather than correctness now: the lock above already stops anyone
    # pairing into a room whose owner is in a match. But a lobby left open
    # still advertises a player who has gone, and the sweep would not reach it
    # for three minutes.
    abandon(Challenge.waiting.where(id: own_open_lobby(joining_user)&.id))
    challenge
  end

  def open_lobby(user)
    # Checked here rather than when the second player arrives, so a bank too
    # thin to fill a match says so to the player who can still do something
    # else with their evening.
    if Dispatcher.pick_shared([ user ], count: Challenge::QUESTION_COUNT).size < Challenge::QUESTION_COUNT
      raise Dispatcher::NotEnoughQuestions, "Not enough questions for a challenge"
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
