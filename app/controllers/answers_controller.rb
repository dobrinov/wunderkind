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
          duration_ms: duration_ms
        )
      rescue AnswerSubmission::BlankResponse
        # Nothing to grade: send the student back to the question rather than
        # spending their Elo and XP on an answer that never arrived.
        flash[:alert] = t("answers.blank")
        return advance_to(question_path(assignment_question), verdict: nil)
      end

    record_outcome(outcome)
    record_completion(assignment, outcome)
    advance_to(next_path(assignment, assignment_question), verdict: verdict_for(outcome.answer))
  end

  # "I haven't been taught this." Recorded rather than graded — see
  # AnswerSubmission.skip.
  def skip
    assignment_question = find_assignment_question

    # The view hides the button in a mistakes session; this is what makes it
    # true. A skip there would move a genuine mistake out of „Сгреших" and into
    # „Не съм го учил" — off the list it was put on to drain, and without even
    # the deferral that is normally the point of saying it.
    return redirect_to question_path(assignment_question) unless assignment_question.assignment.skippable?

    outcome = AnswerSubmission.skip(
      assignment_question: assignment_question,
      user: current_user,
      duration_ms: duration_ms
    )

    record_outcome(outcome)
    record_completion(assignment_question.assignment, outcome)
    # No cue: a skip is neither right nor wrong, and it is submitted by its own
    # button rather than by the answer form, so this stays a plain redirect.
    redirect_to next_path(assignment_question.assignment, assignment_question)
  end

  private

  def find_assignment_question
    AssignmentQuestion.
      joins(:assignment).
      where(assignments: { user: current_user }).
      find params[:question_id]
  end

  # The answer that finished the session is the only place this can be counted
  # exactly once: the summary screen it redirects to can be reopened from the
  # history all week. AnswerSubmission already worked out whether this answer
  # was the last one, so nothing here asks the database again. A session ended
  # by a skip counts too — the student sat down and got to the end of it.
  def record_completion(assignment, outcome)
    return unless outcome.assignment_completed

    track :session_completed, kind: assignment.kind
  end

  def record_outcome(outcome)
    flash[:xp_earned] = outcome.xp_earned if outcome.xp_earned.positive?
    flash[:new_badges] = outcome.new_badges.map(&:key) if outcome.new_badges.any?
    flash[:mastered_topics] = outcome.mastered_topics.map(&:name) if outcome.mastered_topics.any?
  end

  # Where the student goes once the answer is in: back to this question to read
  # the feedback card, straight on to the next one, or to the summary.
  def next_path(assignment, assignment_question)
    next_assignment_question = assignment.next_assignment_question
    feedback_after_answer =
      if assignment.feedback_after_answer.nil?
        current_user.feedback_after_answer
      else
        assignment.feedback_after_answer
      end

    if next_assignment_question && feedback_after_answer
      question_path(assignment_question)
    elsif next_assignment_question
      question_path(next_assignment_question)
    else
      assignment_summary_path(assignment)
    end
  end

  # Two ways to say the same thing. A plain form post gets the redirect it has
  # always got; the answer form's fetch gets the verdict as well, because it has
  # to sound the right/wrong cue *here*, on the page the student is still
  # looking at — Safari and Firefox will not let the page it is going to start
  # any audio of its own. See answer_form_controller.js.
  def advance_to(path, verdict:)
    respond_to do |format|
      format.html { redirect_to path }
      format.json { render json: { verdict: verdict, redirect: path } }
    end
  end

  # A skip is not a wrong answer and a free-text answer is not graded yet:
  # neither gets a sound.
  def verdict_for(answer)
    return nil if answer.skipped? || answer.pending_review?

    answer.correct? ? "correct" : "wrong"
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
