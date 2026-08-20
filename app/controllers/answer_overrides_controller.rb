# Lets a homework assigner overrule an AI verdict on a free-text answer.
# Flips only the recorded correctness (for reporting) — Elo and XP already
# applied are left alone deliberately.
class AnswerOverridesController < AuthenticatedController
  def update
    answer = UserAnswer.
      joins(assignment_question: { assignment: :homework }).
      where(homeworks: { assigner_id: current_user.id }).
      find(params[:id])

    answer.update!(
      correct: params[:correct] == "1",
      response: answer.response.merge("verdict" => params[:correct] == "1" ? "correct" : "incorrect", "overridden" => true)
    )

    redirect_back fallback_location: root_path, notice: t("overrides.saved")
  end
end
