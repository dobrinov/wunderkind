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

  has_many :challenge_questions, -> { order(:position) }, dependent: :destroy, inverse_of: :challenge
  has_many :questions, through: :challenge_questions
  has_many :participants, class_name: "ChallengeParticipant", dependent: :destroy, inverse_of: :challenge
  has_many :users, through: :participants
  belongs_to :winner, class_name: "User", optional: true

  enum :status, { waiting: 0, active: 1, finished: 2, abandoned: 3 }, default: :waiting

  scope :open_lobbies, -> { waiting.where(created_at: LOBBY_TTL.ago..) }
  scope :in_progress, -> { where(status: [ statuses[:waiting], statuses[:active] ]) }

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

  def stale_lobby?
    waiting? && created_at < LOBBY_TTL.ago
  end
end
