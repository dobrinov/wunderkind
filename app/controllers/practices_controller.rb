# „Упражнения": every way to practise, in one list. The nav item of the same
# name used to be a POST that started a daily session on the spot, which left
# „За преговор" reachable only from a home-page card and competition
# preparation only from another one. The daily session is still one tap away —
# it is the first row, and the home page's hero — and everything else that
# builds a session now has a place to be found.
class PracticesController < AuthenticatedController
  before_action :require_student

  def show
    @minutes = current_user.daily_minutes_target.presence || DailyPractice::DEFAULT_MINUTES
    @practised_today = current_user.user_answers.attempted.where(created_at: Time.zone.today.all_day).exists?
    @review_count = AnswerLog.wrong(current_user).count
    @practisable_count = MistakePractice.available_count(current_user)
    @entries = CompetitionEntry.upcoming_for(current_user)
  end

  private

  def require_student
    redirect_to home_path_for(current_user) unless current_user.student?
  end
end
