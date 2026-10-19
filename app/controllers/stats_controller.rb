# The day behind a click on the answer stats on the student home page: what
# the student got wrong that day and what they marked „не съм го учил". The
# charts themselves are drawn by CalendarsController; the same charts sit on
# the parent's child page and in /overseer — see AnswerStats.
class StatsController < AuthenticatedController
  layout "application"

  def day
    @date = AnswerStats.date(params[:date])
    return redirect_to(profile_path(anchor: "stats")) unless @date

    @answers = AnswerStats.misses(current_user, @date)
  end
end
