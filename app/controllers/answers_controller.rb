class AnswersController < AuthenticatedController
  layout "modal"

  def show
    @assignment_question = AssignmentQuestion.joins(:assignment).where(assignments: { user: current_user }).find params[:question_id]
    @answer = @assignment_question.user_answer
    @assignment = @assignment_question.assignment
    @question = @assignment_question.question
  end

  def create
    assignment_question = find_assignment_question
    assignment = assignment_question.assignment

    outcome =
      begin
        AnswerSubmission.call(
          assignment_question: assignment_question,
          user: current_user,
          raw: answer_params,
          duration_ms: duration_ms,
          hints_used: params[:hints_used].to_i
        )
      rescue AnswerSubmission::BlankResponse
        # Nothing to grade: send the student back to the question rather than
        # spending their Elo and XP on an answer that never arrived.
        flash[:alert] = t("answers.blank")
        return redirect_to question_path(assignment_question)
      end

    record_outcome(outcome)
    advance(assignment, assignment_question)
  end

  # "I haven't been taught this." Recorded rather than graded — see
  # AnswerSubmission.skip.
  def skip
    assignment_question = find_assignment_question
    outcome = AnswerSubmission.skip(
      assignment_question: assignment_question,
      user: current_user,
      duration_ms: duration_ms
    )

    record_outcome(outcome)
    advance(assignment_question.assignment, assignment_question)
  end

  private

  def find_assignment_question
    AssignmentQuestion.
      joins(:assignment).
      where(assignments: { user: current_user }).
      find params[:question_id]
  end

  def record_outcome(outcome)
    flash[:xp_earned] = outcome.xp_earned if outcome.xp_earned.positive?
    flash[:new_badges] = outcome.new_badges.map(&:key) if outcome.new_badges.any?
    flash[:mastered_topics] = outcome.mastered_topics.map(&:name) if outcome.mastered_topics.any?
  end

  def advance(assignment, assignment_question)
    next_assignment_question = assignment.next_assignment_question
    feedback_after_answer =
      if assignment.feedback_after_answer.nil?
        current_user.feedback_after_answer
      else
        assignment.feedback_after_answer
      end

    if next_assignment_question && feedback_after_answer
      redirect_to question_path(assignment_question)
    elsif next_assignment_question
      redirect_to question_path(next_assignment_question)
    else
      redirect_to assignment_summary_path(assignment)
    end
  end

  def answer_params
    params.permit(:value, :state, selected_ids: [])
  end

  def duration_ms
    started_at = Time.zone.parse(params[:started_at].to_s)
    return nil if started_at.nil?

    ((Time.current - started_at) * 1000).round.clamp(0, 30.minutes.in_milliseconds)
  rescue ArgumentError
    nil
  end
end
