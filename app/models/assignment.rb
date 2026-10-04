class Assignment < ApplicationRecord
  belongs_to :user
  has_many :assignment_questions, -> { order(:position) }, dependent: :destroy, inverse_of: :assignment
  has_many :user_answers, through: :assignment_questions
  has_many :questions, through: :assignment_questions

  # 1 was homework; the feature was removed and its sessions migrated to
  # practice, so the value stays retired rather than being reused.
  enum :kind, { practice: 0, daily: 2, mistakes: 3, placement: 4 }, default: :practice

  # Whether a hint ladder is offered on this session, by kind. Practice and the
  # daily session are the student working alone, where a hint is the difference
  # between a stuck child and a child who carries on — a hinted correct answer
  # already pays half XP, which is the whole price.
  #
  # Duels are absent because they never reach this: a duel has no assignment,
  # and a hint would be worth points to whoever used it fastest.
  # Placement is absent: a hint on a question whose purpose is to find out
  # whether you can do it unaided measures the hint, not the student.
  HINTS_BY_KIND = { "practice" => true, "daily" => true, "mistakes" => true }.freeze

  def hints_allowed?
    return hints_allowed unless hints_allowed.nil?

    HINTS_BY_KIND.fetch(kind, false)
  end

  # Whether what happens in this session is evidence about the student.
  #
  # Everything ordinary is: an answer moves the student's rating, the
  # question's rating, the topic's skill row, its spaced-review date and its
  # mastery. A mistakes session is the exception, for the same reason a duel is
  # — what it measures would not be what it appears to measure. These are
  # questions the student has already answered, already got wrong, and already
  # read the worked explanation for; answering one correctly now is recall, and
  # recording it as ability would hand out rating for remembering an answer
  # while quietly telling the bank that a question only ever retried by
  # students who failed it is an easy one.
  #
  # So a mistakes session teaches and pays — grading, explanations, XP, the
  # streak, badges, the session bonus — and measures nothing.
  #
  # Placement is unmeasured for the opposite reason: it is *all* measurement,
  # but not this kind. Its whole job is to find a rating, and it does that by
  # bisecting the bank rather than by nudging a number eight times — see
  # Placement. Letting the per-answer Elo run as well would have the session
  # move the rating twice by two different methods, and would spend eight real
  # questions' difficulty on a student whose level is not known yet.
  # Named rather than asked twice: UserAnswer.measured has to exclude exactly
  # these kinds, and a list in two places is a list that eventually disagrees.
  UNMEASURED_KINDS = %w[mistakes placement].freeze

  def measured? = !kind.in?(UNMEASURED_KINDS)

  # „Не съм го учил" is an answer to „have you been taught this", and in a
  # mistakes session the student has already answered it by attempting the
  # question. The control is hidden rather than merely ignored, because a
  # button that does nothing is worse than no button.
  #
  # Placement keeps it, and wants it: a child who has not met a topic should be
  # able to say so instead of guessing, and a guess on a four-way choice is a
  # one-in-four chance of telling the search the wrong thing. Placement reads a
  # skip as „too hard for now", which is what it means.
  def skippable? = !mistakes?

  def next_assignment_question
    assignment_questions.left_joins(:user_answer).where(user_answers: { id: nil }).first
  end

  # Whether this session is over. For every other kind that is simply "nothing
  # left unanswered" — but a placement session is built one question at a time,
  # so that is its state after *every* answer, right from the first. It is over
  # when it has asked its full set.
  def complete?
    return false if placement? && assignment_questions.size < Placement::QUESTION_COUNT

    next_assignment_question.nil?
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
