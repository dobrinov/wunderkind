# A student saying "something is wrong with this question" — not with their
# answer. Deliberately touches no measurement: a report grades nothing, moves no
# Elo, XP or streak, and does not stand in for an answer, so the child can still
# answer the question or shrug it off afterwards. The only consequence is a row
# in the admin queue, because the fix is always a human editing the question.
class QuestionReport < ApplicationRecord
  belongs_to :question
  belongs_to :user
  belongs_to :resolver, class_name: "User", optional: true

  NOTE_LIMIT = 500

  # The reasons a nine-year-old can tell apart, in the order they come up: the
  # condition doesn't make sense, the answer we accept is wrong, none of the
  # options is right, a typo, the figure, a widget that won't respond.
  enum :reason, { misleading: 0, wrong_answer: 1, missing_answer: 2, typo: 3, image: 4, broken: 5, other: 6 }
  enum :status, { open: 0, resolved: 1, dismissed: 2 }, default: :open

  validates :note, length: { maximum: NOTE_LIMIT }

  scope :newest_first, -> { order(created_at: :desc) }

  # Reporting twice is not two complaints. Re-reporting rewrites the student's
  # own row and reopens it, so a question that broke again after an admin closed
  # it comes back to the queue instead of disappearing.
  def self.file!(question:, user:, reason:, note: nil)
    report = find_or_initialize_by(question: question, user: user)
    report.update!(
      reason: reason,
      note: note.to_s.strip.presence&.truncate(NOTE_LIMIT),
      status: :open,
      resolved_at: nil,
      resolver: nil
    )
    report
  end

  # The queue is per question, not per report: three students reporting the same
  # broken question are one thing to look at and one edit to make. Newest
  # complaint first.
  def self.open_questions
    order_by_latest_open_report = sanitize_sql_array([
      "(SELECT MAX(created_at) FROM question_reports " \
      "WHERE question_reports.question_id = questions.id AND question_reports.status = ?) DESC",
      statuses[:open]
    ])

    Question.where(id: open.select(:question_id)).order(Arel.sql(order_by_latest_open_report))
  end

  # Closes every open report on one question in a single stroke — see
  # open_questions for why the admin acts on the pile rather than the row.
  def self.close_pile!(question:, status:, by:)
    open.where(question: question).update_all(
      status: statuses.fetch(status.to_s),
      resolved_at: Time.current,
      resolver_id: by&.id,
      updated_at: Time.current
    )
  end
end
