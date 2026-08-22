class CalendarsController < AuthenticatedController
  layout "application"

  def show
    @history = PracticeHistory.new(current_user)
    @trend = PerformanceTrend.new(current_user)
    @duel_record = ChallengeRecord.for(current_user)

    today = current_user.user_answers.attempted.where(created_at: Time.zone.today.all_day)
    @practised_today = today.exists?
    @minutes_progress = minutes_progress(today)
  end

  private

  # How far into today's minutes goal the student is, from the time they have
  # actually spent answering rather than from a question count — the goal is set
  # in minutes, so the bar has to be measured in minutes too.
  def minutes_progress(answers)
    target = (current_user.daily_minutes_target.presence || DailyPractice::DEFAULT_MINUTES) * 60_000.0
    spent = answers.where.not(duration_ms: nil).sum(:duration_ms)

    ((spent / target) * 100).clamp(0, 100).round
  end
end
