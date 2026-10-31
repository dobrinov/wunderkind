# How loudly each secondary feature speaks to a student: the app used to show
# a brand-new child about ten feature surfaces on their first day — duels,
# friends, leagues, badges, competitions, the review list — before they had
# answered a problem. Now every feature is in one of three states:
#
#   :findable  — there if you look: a quiet row under „Още в Wunderkind" on
#                „Аз" (or in „Упражнения"), no tab, no home card, no counts.
#   :presented — the app has something to tell you about it: a one-time
#                „Ново за теб" sheet on the home page, and a row where it is
#                used. Still no tab.
#   :prominent — you use it: its own tab, a home card, counts on the nav.
#
# Nothing is ever locked away, because a curious child should always be able
# to find duels — the states only decide what the app pushes forward. Every
# trigger reads something the app already counts; the only new state is which
# introductions a person has seen (users.introduced_features). A parent can
# switch the whole thing off for a child who already knows the app
# (users.show_all_features), and someone else starting a feature — a friend's
# invitation — presents it early.
class FeatureVisibility
  FEATURES = %i[review badges duel friends leaderboards competitions suggest].freeze
  STATES = %i[findable presented prominent].freeze

  SESSIONS_FOR_DUEL = 5
  ANSWERS_FOR_DUEL = 100
  DUELS_FOR_TAB = 3
  REVIEW_CARD_AT = 5
  COMPETITION_LEVEL = 5
  EXAM_SEASON_DAYS = 30
  SUGGEST_LEVEL = 8

  def self.for(user) = new(user)

  def initialize(user)
    @user = user
  end

  # Accounts that existed before features started arriving one at a time knew
  # the app with everything in its place. Taking „Двубой" out of the menu of a
  # child who had it yesterday reads as a feature removed, not one held back
  # for later — the gradual introduction is for newcomers.
  GRADUAL_SINCE = Time.utc(2026, 10, 29, 10, 40)

  def state(feature)
    return :prominent if @user.show_all_features? || veteran?

    @states ||= {}
    @states[feature] ||= compute(feature)
  end

  def presented?(feature) = STATES.index(state(feature)) >= 1
  def prominent?(feature) = state(feature) == :prominent

  # The one introduction to show next, if any — oldest first, so a child who
  # earned two at once meets them on two visits rather than in a stack.
  def pending_introduction
    return if @user.show_all_features? || veteran?

    FEATURES.find { |feature| presented?(feature) && !@user.introduced_features.include?(feature.to_s) }
  end

  private

  def veteran? = @user.created_at.present? && @user.created_at < GRADUAL_SINCE

  def compute(feature)
    case feature
    when :review
      return :findable unless wrong_count.positive?
      practisable_count >= REVIEW_CARD_AT ? :prominent : :presented
    when :badges
      # The coin collection: presented once there is a coin in it.
      @user.badge_awards.exists? ? :presented : :findable
    when :duel
      return :prominent if duels_played >= DUELS_FOR_TAB || friends?
      experienced? || invited? ? :presented : :findable
    when :friends
      return :prominent if friends?
      duels_played.positive? || invited? ? :presented : :findable
    when :leaderboards
      return :prominent if @user.leagues.exists?
      friends? || duels_played >= DUELS_FOR_TAB ? :presented : :findable
    when :competitions
      return :prominent if CompetitionEntry.upcoming_for(@user).any?
      @user.level >= COMPETITION_LEVEL || exam_season? ? :presented : :findable
    when :suggest
      @user.level >= SUGGEST_LEVEL ? :presented : :findable
    else
      raise ArgumentError, "unknown feature #{feature.inspect}"
    end
  end

  def experienced?
    @user.assignments.finished.count >= SESSIONS_FOR_DUEL ||
      @user.user_answers.attempted.count >= ANSWERS_FOR_DUEL
  end

  def duels_played = @duels_played ||= ChallengeRecord.for(@user).played
  def friends? = @friends ||= Friendship.involving(@user).accepted.exists?
  def invited? = @invited ||= Challenge.open_invites.where(invited_user_id: @user.id).exists? || Friendship.awaiting(@user).exists?
  def wrong_count = @wrong_count ||= AnswerLog.wrong(@user).count
  def practisable_count = @practisable_count ||= MistakePractice.available_count(@user)

  # A month before an exam round (НВО, матура) everybody hears about it,
  # whatever their level: the exam is coming whether or not the app thinks
  # they are ready.
  def exam_season?
    horizon = Time.zone.today + EXAM_SEASON_DAYS
    Competitions.upcoming.any? { |event| event.exam? && event.next_round.date <= horizon }
  end
end
