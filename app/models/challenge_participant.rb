# One player's side of a match: their answers, their points, their clock.
class ChallengeParticipant < ApplicationRecord
  belongs_to :challenge
  belongs_to :user
  has_many :challenge_answers, dependent: :destroy

  def answered_count
    challenge_answers.size
  end

  def next_challenge_question
    answered_ids = challenge_answers.map(&:challenge_question_id)
    challenge.challenge_questions.reject { |question| answered_ids.include?(question.id) }.first
  end

  def answer_for(challenge_question)
    challenge_answers.detect { |answer| answer.challenge_question_id == challenge_question.id }
  end

  def done?
    finished_at.present?
  end

  # Seconds this player has been looking at the problem in front of them. The
  # server stamps question_started_at when it serves a problem, so a player
  # cannot buy thinking time by reloading, and the speed bonus can't be forged
  # from the client.
  def seconds_on_current_question
    return 0 if question_started_at.nil?

    (Time.current - question_started_at).clamp(0, challenge.seconds_per_question)
  end
end
