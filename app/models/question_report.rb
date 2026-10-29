# A student saying "something is wrong with this question" — not with their
# answer. Deliberately touches no measurement: a report grades nothing, moves no
# Elo, XP or streak, and does not stand in for an answer, so the child can still
# answer the question or shrug it off afterwards. The fix is always a human
# editing the question.
#
# It works like a ticket. Filed, it is `open`; once the team writes back it is
# `in_progress`, and stays so while the two sides talk in its thread
# (QuestionReportMessage); it ends `resolved` or `dismissed`, closed either by
# the team or by the student confirming the fix worked. A student who says it
# did not — or writes on a closed report — reopens it. The student can archive
# a report to put it out of sight; the next word from the team brings it back.
class QuestionReport < ApplicationRecord
  belongs_to :question
  belongs_to :user
  belongs_to :resolver, class_name: "User", optional: true
  has_many :messages, -> { order(:created_at, :id) }, class_name: "QuestionReportMessage", inverse_of: :question_report

  NOTE_LIMIT = 500
  MESSAGE_LIMIT = 1000

  # The reasons a nine-year-old can tell apart, in the order they come up: the
  # condition doesn't make sense, the answer we accept is wrong, none of the
  # options is right, a typo, the figure, a widget that won't respond.
  enum :reason, { misleading: 0, wrong_answer: 1, missing_answer: 2, typo: 3, image: 4, broken: 5, other: 6 }
  enum :status, { open: 0, resolved: 1, dismissed: 2, in_progress: 3 }, default: :open

  ACTIVE = %w[open in_progress].freeze

  validates :note, length: { maximum: NOTE_LIMIT }

  scope :newest_first, -> { order(created_at: :desc) }
  scope :active, -> { where(status: ACTIVE) }
  scope :closed, -> { where.not(status: ACTIVE) }
  scope :archived, -> { where.not(archived_at: nil) }
  scope :unarchived, -> { where(archived_at: nil) }

  # The team said something the student has not read yet. A message with no
  # author is the team's too (an admin account since deleted).
  scope :unread, -> {
    where(<<~SQL)
      EXISTS (SELECT 1 FROM question_report_messages m
              WHERE m.question_report_id = question_reports.id
                AND m.author_id IS DISTINCT FROM question_reports.user_id
                AND m.created_at > COALESCE(question_reports.seen_at, '-infinity'))
    SQL
  }

  # Waiting on the team: nobody has answered yet, or the student was the last
  # to write.
  scope :awaiting_team, -> {
    where(status: :open).or(where(status: :in_progress).where(<<~SQL))
      (SELECT m.author_id FROM question_report_messages m
       WHERE m.question_report_id = question_reports.id
       ORDER BY m.created_at DESC, m.id DESC LIMIT 1) = question_reports.user_id
    SQL
  }

  # Reporting twice is not two complaints. Re-reporting rewrites the student's
  # own report — reason, note, and the version of the question it is about —
  # and reopens it if it was closed, so a question that broke again after an
  # admin closed it comes back to the queue instead of disappearing.
  def self.file!(question:, user:, reason:, note: nil)
    note = note.to_s.strip.presence&.truncate(NOTE_LIMIT)
    report = find_or_initialize_by(question: question, user: user)

    transaction do
      reopening = report.persisted? && report.closed?
      report.update!(reason: reason, note: note, snapshot: snapshot_of(question), archived_at: nil,
                     **(reopening ? { status: :open, resolved_at: nil, resolver: nil } : {}))
      report.messages.create!(author: user, kind: :reopened, body: note) if reopening
    end
    report
  end

  # The queue is per question, not per report: three students reporting the same
  # broken question are one thing to look at and one edit to make. Questions
  # with somebody waiting on the team come first, newest activity first.
  def self.open_questions
    order_sql = sanitize_sql_array([
      "(SELECT MAX(CASE WHEN r.id IN (?) THEN 1 ELSE 0 END) FROM question_reports r " \
      "WHERE r.question_id = questions.id) DESC, " \
      "(SELECT MAX(r.updated_at) FROM question_reports r " \
      "WHERE r.question_id = questions.id AND r.status IN (?)) DESC",
      awaiting_team.select(:id), statuses.values_at(*ACTIVE)
    ])

    Question.where(id: active.select(:question_id)).order(Arel.sql(order_sql))
  end

  # What the student was looking at when they reported: everything an admin's
  # fix could change and a child could notice.
  def self.snapshot_of(question)
    {
      "body" => question.body,
      "options" => (question.possible_answers.map(&:value) if question.multiple_choice?),
      "answer" => Grading.correct_answer_display(question).to_s,
      "explanation" => question.explanation.to_s
    }.compact
  end

  def self.clean(text)
    text.to_s.strip.presence&.truncate(MESSAGE_LIMIT)
  end

  def closed?
    !status.in?(ACTIVE)
  end

  def awaiting_team?
    open? || (in_progress? && messages.last&.from_reporter?)
  end

  def team_has_written?
    messages.any? { |message| !message.from_reporter? }
  end

  def unread?
    messages.any? { |message| !message.from_reporter? && (seen_at.nil? || message.created_at > seen_at) }
  end

  # --- The team's side --------------------------------------------------------

  # A word to the student. Starts or continues the discussion; on a closed
  # report it stays closed — the team reopening it would be a different act.
  def team_reply!(by:, body:, corrected_question: nil)
    transaction do
      messages.create!(author: by, kind: :comment, body: self.class.clean(body), corrected_question: corrected_question)
      update!(status: open? ? :in_progress : status, archived_at: nil)
    end
  end

  def team_close!(status, by:, body: nil, corrected_question: nil)
    transaction do
      messages.create!(author: by, kind: status, body: self.class.clean(body), corrected_question: corrected_question)
      update!(status: status, resolved_at: Time.current, resolver: by, archived_at: nil)
    end
  end

  # Out of circulation while it is fixed: not closed, because the student is
  # still owed the answer to whether the fix worked.
  def team_withdraw!(by:, body: nil, corrected_question: nil)
    transaction do
      messages.create!(author: by, kind: :withdrawn, body: self.class.clean(body), corrected_question: corrected_question)
      update!(status: :in_progress, archived_at: nil)
    end
  end

  # --- The student's side -----------------------------------------------------

  # What the student can say now: a comment always (on a closed report it
  # reopens it), and a verdict on the fix once the team has answered.
  def student_kinds
    if closed?
      %w[comment] + (resolved? && team_has_written? ? %w[not_fixed] : [])
    elsif in_progress?
      %w[comment confirmed not_fixed]
    else
      %w[comment]
    end
  end

  # Returns false for a move this report does not allow (see student_kinds), or
  # a comment with nothing in it.
  def student_respond!(kind:, body:)
    kind = kind.to_s
    body = self.class.clean(body)
    return false unless kind.in?(student_kinds)
    return false if kind == "comment" && body.nil?

    transaction do
      case kind
      when "confirmed"
        messages.create!(author: user, kind: :confirmed, body: body)
        update!(status: :resolved, resolved_at: Time.current, resolver: user)
      when "not_fixed"
        messages.create!(author: user, kind: :not_fixed, body: body)
        update!(status: :in_progress, resolved_at: nil, resolver: nil, archived_at: nil)
      else
        if closed?
          messages.create!(author: user, kind: :reopened, body: body)
          update!(status: :in_progress, resolved_at: nil, resolver: nil, archived_at: nil)
        else
          messages.create!(author: user, kind: :comment, body: body)
        end
      end
      update!(seen_at: Time.current)
    end
    true
  end

  def mark_seen!
    update_column(:seen_at, Time.current)
  end

  def archive!
    update!(archived_at: Time.current)
  end

  def unarchive!
    update!(archived_at: nil)
  end

  # The version of the question the student should look at now: the latest
  # corrected question the team pointed to, or the reported one itself (fixed
  # in place, if it was fixed at all).
  def current_question
    messages.reverse.find(&:corrected_question_id)&.corrected_question || question
  end

  def replaced?
    current_question.id != question_id
  end

  # Whether the thread offers the corrected question to try: it is in
  # circulation and something was done about it — the team pointed to a
  # corrected version, the question changed since the report, or the team
  # closed it as fixed (a fix the snapshot cannot see, such as a hint, or a
  # report filed before snapshots were kept).
  def retryable?
    Dispatcher.practice_pool.exists?(current_question.id) &&
      (replaced? || changes_since_report.present? || resolved?)
  end

  # Which parts of the current version (current_question) differ from the
  # reported one — what the thread shows side by side. Empty when nothing changed, nil when the report
  # predates snapshots and there is nothing to compare against.
  def changes_since_report
    return if snapshot.blank?

    now = self.class.snapshot_of(current_question)
    snapshot.keys.select { |key| snapshot[key] != now[key] }
  end
end
