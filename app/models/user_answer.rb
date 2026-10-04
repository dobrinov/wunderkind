class UserAnswer < ApplicationRecord
  belongs_to :assignment_question
  belongs_to :user

  # Skipped answers ("I haven't been taught this") record a question being
  # passed over, not the student attempting it — they stay out of every count
  # meant to measure effort or ability.
  scope :attempted, -> { where(skipped: false) }

  # Answers that are evidence about the student, as opposed to merely effort by
  # them. The two came apart when mistakes sessions arrived: those are real
  # work, so they belong in the history card, the accuracy and the badges, but
  # they are questions whose worked explanation the student has already read,
  # so they say nothing about ability — see Assignment#measured?.
  #
  # Everything that reads an answer as a *measurement* reads this scope
  # instead: how far through calibration a student is, the K-factor both
  # ratings move by, and the difficulty trend on the home page. Without it the
  # exclusion would have been only half done — no rating would move, but the
  # progress chart would still rise on recall and calibration would end on
  # answers that never measured anything.
  scope :measured, -> {
    attempted.
      joins(assignment_question: :assignment).
      where.not(assignments: { kind: Assignment.kinds[:mistakes] })
  }

  # Free-text answers are graded by a person, so between submitting and being
  # marked they are neither right nor wrong — `correct` is false because it has
  # to be something, not because the student got it wrong.
  def pending_review? = response["verdict"] == "pending_review"

  validates :correct, inclusion: { in: [ true, false ] }
  validates :response, presence: true
  # The score treats skips as neither right nor wrong, which only holds if a
  # skip can never also be correct.
  validates :correct, exclusion: { in: [ true ] }, if: :skipped?
end
