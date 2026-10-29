class HomeController < AuthenticatedController
  layout "application"

  # A student's page. A parent or an admin who typed /home, or followed an old
  # bookmark, got a practice hero and a streak of their own — send them to
  # the page that is theirs instead.
  before_action -> { redirect_to home_path_for(current_user) unless current_user.student? }

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
    load_focus

    # Offered to anyone who has not been placed — accounts that predate the
    # session, and children who closed it on the way in.
    @needs_placement = Placement.due?(current_user)

    # The tour waits until placement is done — it points at a page the child
    # is about to use, not one they are about to leave for eight problems —
    # and the „Ново за теб" sheets wait until the tour is.
    @show_tour = current_user.toured_at.nil? && !@needs_placement
    @introduction = visibility.pending_introduction unless @show_tour

    @history = PracticeHistory.new(current_user)
    @review_count = AnswerLog.wrong(current_user).count
    @practisable_count = MistakePractice.available_count(current_user)
    # The newest friend's invitation, if one is waiting — the duel card names
    # them. A plain read: ChallengeMatchmaker.invites_for sweeps, and the
    # duel page is where that belongs.
    @invite_host = Challenge.open_invites.where(invited_user_id: current_user.id).
      order(created_at: :desc).first&.participants&.first&.user

    # The nearest competition the student said they will enter, counting
    # down. The calendar of everything else lives under „Упражнения".
    @next_competition = CompetitionEntry.upcoming_for(current_user).first

    today = current_user.user_answers.attempted.where(created_at: Time.zone.today.all_day)
    @practised_today = today.exists?
    @minutes_progress = minutes_progress(today)
  end

  private

  # What a parent asked this child to practise (PracticeFocus): the focus in
  # play, or — once — the one just finished, so reaching the target is
  # celebrated where the child lands after the session that reached it. The
  # celebration is stamped as seen on the way out, except while an admin is
  # looking: it is the child's to see. A finished focus whose reward is still
  # owed stays on the card after that, the way an earned goal reward does.
  def load_focus
    @focus = PracticeFocuses.refresh!(current_user)
    finished = current_user.practice_focuses.current.completed.includes(:topics, :parent).order(completed_at: :desc).first
    return if @focus || finished.nil?

    if finished.celebrated_at.nil?
      @celebrate = true
      finished.update_column(:celebrated_at, Time.current) unless impersonating?
    end
    @finished_focus = finished if @celebrate || finished.reward_owed?
  end

  # How far into today's minutes goal the student is, from the time they have
  # actually spent answering rather than from a question count — the goal is set
  # in minutes, so the bar has to be measured in minutes too.
  def minutes_progress(answers)
    target = (current_user.daily_minutes_target.presence || DailyPractice::DEFAULT_MINUTES) * 60_000.0
    spent = answers.where.not(duration_ms: nil).sum(:duration_ms)

    ((spent / target) * 100).clamp(0, 100).round
  end
end
