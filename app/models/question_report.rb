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
  RESPONSE_LIMIT = 1000

  # The reasons a nine-year-old can tell apart, in the order they come up: the
  # condition doesn't make sense, the answer we accept is wrong, none of the
  # options is right, a typo, the figure, a widget that won't respond.
  enum :reason, { misleading: 0, wrong_answer: 1, missing_answer: 2, typo: 3, image: 4, broken: 5, other: 6 }
  enum :status, { open: 0, resolved: 1, dismissed: 2 }, default: :open

  validates :note, length: { maximum: NOTE_LIMIT }
  validates :response, length: { maximum: RESPONSE_LIMIT }

  scope :newest_first, -> { order(created_at: :desc) }

  # Reports the student has had an answer to: every closed one, with or without
  # a written response (a child who took the trouble to tell us is told what
  # came of it), and an open one an admin wrote back to without closing it.
  scope :answered, -> { where.not(status: :open).or(where.not(response: nil)) }
  scope :unseen_replies, -> { answered.where(response_seen_at: nil) }

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
      resolver: nil,
      response: nil,
      response_seen_at: nil,
      snapshot: snapshot_of(question)
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
  # open_questions for why the admin acts on the pile rather than the row. The
  # response is the admin's answer to every student in the pile: they all
  # reported the same question, and what was done about it is the same.
  #
  # Closing without a response keeps whatever the admin already wrote to each
  # student on their own (reply!), rather than wiping it.
  def self.close_pile!(question:, status:, by:, response: nil)
    response = clean_response(response)
    changes = {
      status: statuses.fetch(status.to_s),
      resolved_at: Time.current,
      resolver_id: by&.id,
      response_seen_at: nil,
      updated_at: Time.current
    }
    changes[:response] = response if response

    open.where(question: question).update_all(changes)
  end

  # What the student was looking at when they reported: everything an admin's
  # fix could change and a child could notice. Taken again on a re-report,
  # since that is the version the new complaint is about.
  def self.snapshot_of(question)
    {
      "body" => question.body,
      "options" => (question.possible_answers.map(&:value) if question.multiple_choice?),
      "answer" => Grading.correct_answer_display(question).to_s,
      "explanation" => question.explanation.to_s
    }.compact
  end

  # Which parts of the question differ from the reported version — what
  # „Моите сигнали" shows side by side. Empty when nothing changed, nil when
  # the report predates snapshots and there is nothing to compare against.
  def changes_since_report
    return if snapshot.blank?

    now = self.class.snapshot_of(question)
    snapshot.keys.select { |key| snapshot[key] != now[key] }
  end

  def self.clean_response(text)
    text.to_s.strip.presence&.truncate(RESPONSE_LIMIT)
  end

  # Answering one student without closing anything: what they misread, or that
  # the question is being looked at. The report stays in the queue; writing
  # again replaces the earlier reply and shows it to the student afresh.
  def reply!(text)
    update!(response: self.class.clean_response(text), response_seen_at: nil)
  end

  def mark_reply_seen!
    update!(response_seen_at: Time.current) if response_seen_at.nil?
  end
end
