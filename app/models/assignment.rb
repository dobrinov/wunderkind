class Assignment < ApplicationRecord
  belongs_to :user
  has_many :assignment_questions, -> { order(:position) }, dependent: :destroy, inverse_of: :assignment
  has_many :user_answers, through: :assignment_questions
  has_many :questions, through: :assignment_questions

  # 1 was homework; the feature was removed and its sessions migrated to
  # practice, so the value stays retired rather than being reused.
  enum :kind, { practice: 0, daily: 2 }, default: :practice

  # Whether a hint ladder is offered on this session, by kind. Practice and the
  # daily session are the student working alone, where a hint is the difference
  # between a stuck child and a child who carries on — a hinted correct answer
  # already pays half XP, which is the whole price.
  #
  # Duels are absent because they never reach this: a duel has no assignment,
  # and a hint would be worth points to whoever used it fastest.
  HINTS_BY_KIND = { "practice" => true, "daily" => true }.freeze

  def hints_allowed?
    return hints_allowed unless hints_allowed.nil?

    HINTS_BY_KIND.fetch(kind, false)
  end

  def next_assignment_question
    assignment_questions.left_joins(:user_answer).where(user_answers: { id: nil }).first
  end

  def next_question
    next_assignment_question&.question
  end

  def unanswered_questions
    questions.merge(assignment_questions.left_joins(:user_answer).where(user_answers: { id: nil }))
  end

  def answered_questions
    Question.joins(assignment_questions: :user_answer).where(assignment_questions: { assignment: self })
  end

  def correct_answers
    answered_questions.where(user_answers: { correct: true })
  end

  def skipped_questions
    answered_questions.where(user_answers: { skipped: true })
  end

  # Questions the student actually took on. A skip means "I haven't been taught
  # this", so it leaves the score rather than counting as a miss — otherwise
  # honesty would cost the student the same as guessing wrong.
  def graded_questions_count
    questions.count - skipped_questions.count
  end

  # nil when every question was skipped: there is no score to show, not a zero.
  def score_percentage
    graded = graded_questions_count
    return nil if graded.zero?

    (correct_answers.count.to_f / graded * 100).floor
  end
end
