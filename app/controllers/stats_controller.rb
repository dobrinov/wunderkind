# A student's own answer stats: per day, the share they got wrong, the share
# they marked „не съм го учил" and how many they solved — and, a click on a
# day away, which problems those were. The same charts their parent sees on the
# child page and the admin sees in /overseer; see AnswerStats.
class StatsController < AuthenticatedController
  layout "application"

  def show
    @stats = AnswerStats.new(days: AnswerStats.range(params[:days]), user: current_user)
  end

  def day
    @date = AnswerStats.date(params[:date])
    return redirect_to(stats_path) unless @date

    @answers = AnswerStats.misses(current_user, @date)
  end
end
