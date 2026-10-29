# One entry in a report's thread: something somebody wrote, or a change of
# state with an optional word attached — the team closing it, the student
# saying the fix worked or did not. Kept in one list so the history reads top
# to bottom the way it happened. `author` is nil only for a team member whose
# account has since been deleted; it is still the team speaking.
class QuestionReportMessage < ApplicationRecord
  belongs_to :question_report, touch: true
  belongs_to :author, class_name: "User", optional: true

  # resolved and dismissed share their numbers with the report statuses, which
  # the migration that introduced threads relies on.
  enum :kind, {
    comment: 0, resolved: 1, dismissed: 2, reopened: 3, withdrawn: 4, confirmed: 5, not_fixed: 6
  }, prefix: true

  validates :body, length: { maximum: QuestionReport::MESSAGE_LIMIT }
  validates :body, presence: true, if: :kind_comment?

  def from_reporter?
    author_id.present? && author_id == question_report.user_id
  end
end
