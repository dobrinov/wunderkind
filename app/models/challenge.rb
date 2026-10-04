# A head-to-head match: two students, the same problems, one shared clock.
# Speed counts as well as accuracy — see ChallengeScoring.
class Challenge < ApplicationRecord
  QUESTION_COUNT = 5

  # The per-problem budget. It sets both the match clock (question_count of
  # these) and the window the speed bonus is measured against, so the whole
  # match is one number a child can hold in their head: half a minute a problem.
  SECONDS_PER_QUESTION = 30

  # How long an unmatched player's lobby stays joinable. Past this they are
  # almost certainly gone from the page, and matching someone into an empty
  # room is worse than making them wait for a live opponent.
  LOBBY_TTL = 3.minutes

  # Long enough to put your hands on the keyboard, short enough that nobody
  # wanders off during it. The match clock does not start until it runs out.
  COUNTDOWN_SECONDS = 5

  # An invited room waits far longer than a public one. A lobby in the queue is
  # held open while somebody is staring at a „searching" screen; an invite is
  # held open while a friend has not looked at their screen yet, which is a
  # different length of time entirely.
  INVITE_TTL = 15.minutes

  # A filled lobby where somebody never pressed „Готов съм". They opened the
  # page and left; the player who did ready should be told so rather than held
  # there, so the room is written off and they can look again.
  READY_TIMEOUT = 90.seconds

  has_many :challenge_questions, -> { order(:position) }, dependent: :destroy, inverse_of: :challenge
  has_many :questions, through: :challenge_questions
  has_many :challenge_topics, dependent: :destroy, inverse_of: :challenge
  has_many :topics, through: :challenge_topics
  has_many :participants, class_name: "ChallengeParticipant", dependent: :destroy, inverse_of: :challenge
  has_many :users, through: :participants
  belongs_to :winner, class_name: "User", optional: true
  # Set when this room was opened for one named friend. Null for everything in
  # the public queue, which is still how most duels start.
  belongs_to :invited_user, class_name: "User", optional: true

  # `waiting` is one player looking for an opponent; `lobby` is both of them
  # present and readying up. They were one status until the match began the
  # instant the second player arrived — which is the thing this phase exists to
  # stop.
  enum :status, { waiting: 0, active: 1, finished: 2, abandoned: 3, lobby: 4 }, default: :waiting

  # The public queue. Invited rooms are deliberately not in it: a room opened
  # for one friend must not be joinable by, or even visible to, a stranger —
  # which is also what keeps automatic matching from eating it.
  scope :open_lobbies, -> { waiting.where(invited_user_id: nil, created_at: LOBBY_TTL.ago..) }
  scope :open_invites, -> { waiting.where.not(invited_user_id: nil).where(created_at: INVITE_TTL.ago..) }
  scope :in_progress, -> { where(status: [ statuses[:waiting], statuses[:lobby], statuses[:active] ]) }
  # A room with both players in it, whether it has started or not.
  scope :paired, -> { where(status: [ statuses[:lobby], statuses[:active] ]) }

  # The leaf topics this room's categories stand for — what Dispatcher draws
  # from. Empty means anything, which is what every duel was before categories
  # existed and is still what most of them are.
  def question_topic_ids
    DuelCategories.topic_ids_for(topics.to_a)
  end

  def any_category? = topics.empty?

  def participant_for(user)
    participants.detect { |participant| participant.user_id == user.id }
  end

  def opponent_for(user)
    participants.detect { |participant| participant.user_id != user.id }
  end

  def time_limit_seconds
    question_count * seconds_per_question
  end

  def deadline
    started_at && started_at + time_limit_seconds
  end

  def seconds_left
    return time_limit_seconds unless deadline

    [ (deadline - Time.current).ceil, 0 ].max
  end

  # The clock is absolute and shared: whoever loads the page, the match is over
  # at the same instant for both players.
  def out_of_time?
    active? && seconds_left.zero?
  end

  def draw?
    finished? && winner_id.nil?
  end

  # Both phases before the match can go stale, for different reasons: a lobby
  # nobody joined, and a lobby nobody readied in.
  def invited? = invited_user_id.present?

  def stale?
    return created_at < (invited? ? INVITE_TTL : LOBBY_TTL).ago if waiting?
    return paired_at.present? && starts_at.nil? && paired_at < READY_TIMEOUT.ago if lobby?

    false
  end

  def everyone_ready?
    participants.size == 2 && participants.all?(&:ready?)
  end

  def counting_down? = lobby? && starts_at.present?

  # Seconds until the match begins, or nil while the room is still waiting on a
  # „Готов съм". Read off the server's own timestamp so both screens count the
  # same seconds down.
  def seconds_to_start
    return nil unless counting_down?

    [ (starts_at - Time.current).ceil, 0 ].max
  end
end
