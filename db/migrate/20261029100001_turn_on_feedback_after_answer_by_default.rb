# New students see the feedback card after every answer — the verdict and the
# worked explanation — unless they switch it off in Настройки. Existing
# accounts keep whatever they have.
class TurnOnFeedbackAfterAnswerByDefault < ActiveRecord::Migration[8.0]
  def change
    change_column_default :users, :feedback_after_answer, from: false, to: true
  end
end
