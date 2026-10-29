# A student saying "something is wrong with this question" — not with their
# answer. Deliberately touches no measurement: a report grades nothing, moves no
# Elo, XP or streak, and does not stand in for an answer, so the child can still
# answer the question or shrug it off afterwards. The fix is always a human
# editing the question.
#
# It works like a ticket. Filed, it is `open`; once the team writes back it is
# `in_progress`, and stays so while the sides talk in its thread
# (QuestionReportMessage); it ends `resolved` or `dismissed`, closed either by
# the team or by the student confirming the fix worked. A student who says it
# did not — or writes on a closed report — reopens it. A parent of the student
# can follow the thread and write in it too (family_comment!). The student can archive
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

  # Somebody else — the team, or a parent — said something the student has not
  # read yet.
  scope :unread, -> {
    where(<<~SQL)
      EXISTS (SELECT 1 FROM question_report_messages m
              WHERE m.question_report_id = question_reports.id
                AND m.side <> 0
                AND m.created_at > COALESCE(question_reports.seen_at, '-infinity'))
    SQL
  }

  # Waiting on the team: nobody has answered yet, or the student or their
  # parent was the last to write.
  scope :awaiting_team, -> {
    where(status: :open).or(where(status: :in_progress).where(<<~SQL))
      (SELECT m.side FROM question_report_messages m
       WHERE m.question_report_id = question_reports.id
       ORDER BY m.created_at DESC, m.id DESC LIMIT 1) <> 1
    SQL
  }

  # Reporting twice is not two complaints. Re-reporting rewrites the student's
  # own report — reason, note, and the version of the question it is about —
  # and reopens it if it was closed, so a question that broke again after an
  # admin closed it comes back to the queue instead of disappearing.
  #
  # A new report, or one reopened this way, is emailed to the student's
  # parents — the child's report is something the family can follow and add
  # to. Rewriting a report still in play is not news, and sends nothing.
  def self.file!(question:, user:, reason:, note: nil)
    note = note.to_s.strip.presence&.truncate(NOTE_LIMIT)
    report = find_or_initialize_by(question: question, user: user)
    news = report.new_record? || report.closed?

    transaction do
      reopening = report.persisted? && report.closed?
      report.update!(reason: reason, note: note, snapshot: snapshot_of(question), archived_at: nil,
                     **(reopening ? { status: :open, resolved_at: nil, resolver: nil } : {}))
      report.messages.create!(author: user, side: :reporter, kind: :reopened, body: note) if reopening
    end
    report.email_parents_about_filing if news
    report
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
    open? || (in_progress? && !messages.last&.from_team?)
  end

  def team_has_written?
    messages.any?(&:from_team?)
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

  # The status dropdown on the ticket. In progress starts the work on a new
  # report or reopens a closed one; resolved and dismissed close it. The rules
  # on what has to come with each (a corrected version, an explanation) are the
  # controller's, because they are about what the student is owed, not about
  # what the row can hold.
  def team_set_status!(new_status, by:, body: nil, corrected_question: nil)
    case new_status.to_s
    when "resolved", "dismissed"
      team_close!(new_status.to_sym, by: by, body: body, corrected_question: corrected_question)
    when "in_progress"
      transaction do
        if closed?
          messages.create!(author: by, kind: :reopened, body: self.class.clean(body), corrected_question: corrected_question)
          update!(status: :in_progress, resolved_at: nil, resolver: nil, archived_at: nil)
        elsif open?
          messages.create!(author: by, kind: :started, body: self.class.clean(body), corrected_question: corrected_question)
          update!(status: :in_progress, archived_at: nil)
        elsif self.class.clean(body) || corrected_question
          team_reply!(by: by, body: body, corrected_question: corrected_question)
        end
      end
    else
      raise ArgumentError, "unknown status #{new_status.inspect}"
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
        messages.create!(author: user, side: :reporter, kind: :confirmed, body: body)
        update!(status: :resolved, resolved_at: Time.current, resolver: user)
      when "not_fixed"
        messages.create!(author: user, side: :reporter, kind: :not_fixed, body: body)
        update!(status: :in_progress, resolved_at: nil, resolver: nil, archived_at: nil)
      else
        if closed?
          messages.create!(author: user, side: :reporter, kind: :reopened, body: body)
          update!(status: :in_progress, resolved_at: nil, resolver: nil, archived_at: nil)
        else
          messages.create!(author: user, side: :reporter, kind: :comment, body: body)
        end
      end
      update!(seen_at: Time.current)
    end
    true
  end

  # --- A parent's side --------------------------------------------------------

  # A parent of the student writing in the thread: more detail, a question, or
  # „it is still wrong" on a closed report, which reopens it the way the
  # student's own message would. False for an empty message.
  def family_comment!(by:, body:)
    body = self.class.clean(body)
    return false if body.nil?

    transaction do
      if closed?
        messages.create!(author: by, side: :family, kind: :reopened, body: body)
        update!(status: :in_progress, resolved_at: nil, resolver: nil, archived_at: nil)
      else
        messages.create!(author: by, side: :family, kind: :comment, body: body)
      end
    end
    true
  end

  # --- Email -------------------------------------------------------------------

  # Who hears about this report by email: the student who filed it and every
  # parent linked to them, wherever there is a confirmed address that has not
  # switched these emails off. A managed child has no address, so for them it
  # is the parents alone.
  def people_to_email
    ([ user ] + user.parents.to_a).select do |person|
      person.email.present? && person.verified_at.present? && person.report_activity? &&
        EmailPreferences.for(person).any? { |kind| kind.key == :report_activity }
    end
  end

  def email_parents_about_filing
    return unless Mailing.enabled?

    people_to_email.excluding(user).each { |parent| UserMailer.report_filed(self, parent).deliver_later }
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

  # Whether a team message carries the corrected version — the thread then
  # draws it there, in the message, and not again above the conversation.
  def correction_in_thread?
    messages.any?(&:corrected_question_id)
  end

  def replaced?
    current_question.id != question_id
  end

  # Whether the thread shows the corrected question: something was done about
  # it — the team pointed to a corrected version, the question changed since
  # the report, or the team closed it as fixed (a fix the snapshot cannot
  # see, such as a hint, or a report filed before snapshots were kept).
  def fixed?
    replaced? || changes_since_report.present? || resolved?
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
