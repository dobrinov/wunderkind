# One entry in a report's thread: something somebody wrote, or a change of
# state with an optional word attached — the team closing it, the student
# saying the fix worked or did not — and, from the team, optionally the
# corrected version of the question when that is a different question. Kept in
# one list so the history reads top to bottom the way it happened.
#
# Three sides talk in it: the student who reported the question, their family
# (a parent linked to that student), and the team. `author` is nil only for an
# account since deleted; the side still says who was speaking.
class QuestionReportMessage < ApplicationRecord
  belongs_to :question_report, touch: true
  belongs_to :author, class_name: "User", optional: true
  # The fixed version, when the fix is another question rather than an edit of
  # this one (QuestionReport#current_question).
  belongs_to :corrected_question, class_name: "Question", optional: true

  # resolved and dismissed share their numbers with the report statuses, which
  # the migration that introduced threads relies on.
  enum :kind, {
    comment: 0, resolved: 1, dismissed: 2, reopened: 3, withdrawn: 4, confirmed: 5, not_fixed: 6, started: 7, edited: 8
  }, prefix: true
  enum :side, { reporter: 0, team: 1, family: 2 }, prefix: :from, default: :team

  validates :body, length: { maximum: QuestionReport::MESSAGE_LIMIT }
  validates :body, presence: true, if: -> { kind_comment? && corrected_question_id.nil? }

  after_create_commit :email_the_family, if: :from_team?

  # Who hears about this by email: the student who reported the question and
  # their parents (QuestionReport#people_to_email).
  def email_recipients
    question_report.people_to_email
  end

  private

  def email_the_family
    return unless Mailing.enabled?

    email_recipients.each { |recipient| UserMailer.report_activity(self, recipient).deliver_later }
  end
end
