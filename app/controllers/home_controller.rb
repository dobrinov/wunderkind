class HomeController < AuthenticatedController
  layout "application"

  def show
    # Paying out on read rather than on answer: a session ends on the summary
    # screen and then lands here, which is a better place to be told you have
    # earned something than the feedback card of whichever problem happened to
    # tip the total. Idempotent — see Goals.
    Goals.refresh!(current_user)
    # Not while an admin is looking: the session is somebody else's to leave.
    StaleSessions.close!(current_user) unless impersonating?
    @standings = Goals.standings(current_user)
    @rewards = GoalAward.joins(:goal).where(goals: { child_id: current_user.id }).unused.recent_first.to_a

    # Offered to anyone who has not been placed — accounts that predate the
    # session, and children who closed it on the way in.
    @needs_placement = Placement.due?(current_user)

    @history = PracticeHistory.new(current_user)
    @trend = PerformanceTrend.new(current_user)
    @duel_record = ChallengeRecord.for(current_user)
    @review_count = AnswerLog.wrong(current_user).count
    @practisable_count = MistakePractice.available_count(current_user)
    # The newest friend's invitation, if one is waiting — the duel card names
    # them. A plain read: ChallengeMatchmaker.invites_for sweeps, and the
    # duel page is where that belongs.
    @invite_host = Challenge.open_invites.where(invited_user_id: current_user.id).
      order(created_at: :desc).first&.participants&.first&.user

    # The nearest competition the student said they will enter, else the next
    # few on the home page — see home/_competitions.
    @next_competition = CompetitionEntry.upcoming_for(current_user).first
    @upcoming_competitions = Competitions.upcoming(limit: 3)

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
