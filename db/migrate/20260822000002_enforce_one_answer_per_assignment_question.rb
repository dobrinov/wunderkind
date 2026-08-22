# One assignment question takes exactly one answer. AnswerSubmission checks
# this in Ruby, but a double-click or a replayed request racing past that check
# used to create two rows — double-moving Elo and double-awarding XP. The duel
# side has had the equivalent unique index from the start
# (index_challenge_answers_on_participant_and_question); this brings the
# practice path, the hottest write path in the app, in line.
class EnforceOneAnswerPerAssignmentQuestion < ActiveRecord::Migration[8.0]
  def change
    remove_index :user_answers, :assignment_question_id
    add_index :user_answers, :assignment_question_id, unique: true
  end
end
