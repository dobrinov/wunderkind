# A suggested problem becomes a ticket in the same inbox as a report: the
# suggester files it on the question their suggestion created, the team
# answers in its thread, and accepting or returning it closes it. `kind` tells
# the two apart; every row so far is a report.
#
# `reason` goes nullable because a suggestion has none — none of the seven
# reasons is true of it, and filing it under „Друго" would count it as a
# complaint everywhere reasons are counted. The model still requires a reason
# of a report.
#
# Every suggestion made before this gets its ticket, with its state read off
# the question (in review → open, published or retired → resolved, parked as a
# draft or in the library → dismissed) and a snapshot of the question as it is
# now — the closest thing to "as suggested" that is left. A closed one gets the
# one closing entry the report threads were given, written as read, so nobody
# is greeted by notices about suggestions they made months ago. A suggester
# who had already reported their own suggested question keeps that report:
# the (question, user) pair is unique, and the report is the row with words in
# it.
class AddKindToQuestionReports < ActiveRecord::Migration[8.0]
  class Row < ActiveRecord::Base
    self.table_name = "question_reports"
  end

  def up
    add_column :question_reports, :kind, :integer, null: false, default: 0
    change_column_null :question_reports, :reason, true
    add_index :question_reports, [ :kind, :status ]

    Row.reset_column_information
    backfill
  end

  def down
    execute "DELETE FROM question_reports WHERE kind = 1"
    remove_index :question_reports, [ :kind, :status ]
    change_column_null :question_reports, :reason, false
    remove_column :question_reports, :kind
  end

  # Public so a spec can run it against rows it made.
  def backfill
    Question.where.not(suggested_by_id: nil).includes(:possible_answers).find_each do |question|
      next if Row.exists?(question_id: question.id, user_id: question.suggested_by_id)

      status = case question.status
      when "in_review" then 0
      when "published", "retired" then 1
      else 2
      end
      closed_at = (question.updated_at unless status.zero?)
      row = Row.create!(question_id: question.id, user_id: question.suggested_by_id, kind: 1, reason: nil,
                        status: status, resolved_at: closed_at, seen_at: (Time.current if closed_at),
                        snapshot: snapshot_of(question), created_at: question.created_at, updated_at: question.updated_at)
      next unless closed_at

      # kind: 1 resolved, 2 dismissed — the same numbers as the statuses.
      execute <<~SQL
        INSERT INTO question_report_messages (question_report_id, kind, side, created_at, updated_at)
        VALUES (#{row.id}, #{status}, 1, #{connection.quote(closed_at)}, #{connection.quote(closed_at)})
      SQL
    end
  end

  private

  # QuestionReport.snapshot_of, written out so the migration does not move if
  # the model does.
  def snapshot_of(question)
    {
      "body" => question.body,
      "options" => (question.possible_answers.map(&:value) if question.multiple_choice?),
      "answer" => Grading.correct_answer_display(question).to_s,
      "explanation" => question.explanation.to_s
    }.compact
  end
end
