# Serves the hint ladder one rung per request and counts the reveals
# server-side. The page never contains a rung the student hasn't asked for, and
# the count that halves a hinted answer's XP is written here, not reported by
# the client — the same stance the duel clock takes on its speed bonus.
class HintRevealsController < AuthenticatedController
  def create
    assignment_question = AssignmentQuestion.
      joins(:assignment).
      where(assignments: { user: current_user }).
      find(params[:question_id])
    hint = assignment_question.question.hint

    return head :not_found unless hint&.reviewed? && assignment_question.assignment.hints_allowed?
    # The answer is in: the ladder no longer costs anything, so it no longer
    # opens. (The review screen shows the explanation instead.)
    return head :conflict if assignment_question.user_answer.present?

    revealed = [ assignment_question.hints_revealed + 1, hint.ladder.size ].min
    assignment_question.update!(hints_revealed: revealed)

    render json: { rung: hint.ladder[revealed - 1], revealed: revealed, total: hint.ladder.size }
  end
end
