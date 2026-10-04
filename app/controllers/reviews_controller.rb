# „Моите грешки" — the two lists a student can read their own record back from,
# and the button that turns one of them into a session.
#
# One screen with two tabs rather than two screens, because the two lists are
# the same shape and the question a child actually has is "what have I still
# not got right", which „сгреших" and „не съм учил" are two answers to.
#
# Not to be confused with Overseer::ReviewsController (the admin's queue of
# suggested questions) or with the spaced review `skills.review_due_at`
# schedules — this one is the student reading, not the app deciding.
class ReviewsController < AuthenticatedController
  layout "application"

  FILTERS = %w[wrong skipped].freeze

  def show
    @filter = FILTERS.include?(params[:filter]) ? params[:filter] : FILTERS.first
    @wrong_count = AnswerLog.wrong(current_user).count
    @skipped_count = AnswerLog.skipped(current_user).count
    @practisable_count = MistakePractice.available_count(current_user)

    scope = @filter == "wrong" ? AnswerLog.wrong(current_user) : AnswerLog.skipped(current_user)
    @answers = scope.includes(assignment_question: { question: :topics }).page(params[:page])
  end

  # Practice built from the student's own wrong answers. Never from the skips:
  # a skip means „I haven't been taught this", and serving it straight back is
  # the one response that ignores what was said. Those come round again on
  # their own when the deferral lapses.
  def practice
    assignment = MistakePractice.execute(user: current_user)
    track :session_started, kind: assignment.kind
    redirect_to question_path(assignment.next_assignment_question)
  rescue MistakePractice::NothingToPractise
    redirect_to review_path, alert: t("review.nothing_to_practise")
  end
end
