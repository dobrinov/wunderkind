# Badge definitions live in code; awards live in the badge_awards table.
# Badges.check! runs after answers and session completions and awards anything
# newly earned. Names and descriptions come from i18n (badges.<key>.*).
module Badges
  # The counts a progress lambda can read. Gathered once per page rather than
  # per badge, so showing "7/10" on every locked tile costs six queries and not
  # one per tile.
  Stats = Struct.new(:sessions, :answers, :streak, :level, :mastered_topics, :duel_wins, keyword_init: true)

  # :floor is where the count starts for a student who has done nothing yet.
  # It is 0 for everything counted from scratch — sessions, answers, streak —
  # but levels are 1-based, so a brand new account is already "level 1 of 5"
  # and a bar measured from zero would show a fifth of the way to the badge
  # before the first question. The label still reads the count a child
  # recognises; only the bar measures the distance actually travelled.
  Progress = Struct.new(:current, :target, :floor, keyword_init: true) do
    def fraction
      span = target - floor.to_i
      return 0.0 unless span.positive?

      ((current - floor.to_i).to_f / span).clamp(0.0, 1.0)
    end

    def to_s = "#{[ current, target ].min}/#{target}"
  end

  # :progress is optional and only set where the condition is a count a student
  # can watch climb. A one-shot badge ("solve a problem before 8am") gets none:
  # a progress bar that can only read 0/1 tells a child nothing.
  Badge = Struct.new(:key, :icon, :condition, :progress, keyword_init: true) do
    def name = I18n.t("badges.#{key}.name")
    def description = I18n.t("badges.#{key}.description")
    def countable? = !progress.nil?

    def progress_for(stats)
      return nil if progress.nil?

      current, target, floor = progress.call(stats)
      Progress.new(current: current, target: target, floor: floor)
    end
  end

  DEFINITIONS = [
    Badge.new(key: "first_session", icon: "🎯", condition: ->(user, event) {
      event[:type] == :session_completed
    }),
    Badge.new(key: "sessions_10", icon: "🔟", progress: ->(stats) { [ stats.sessions, 10 ] }, condition: ->(user, event) {
      event[:type] == :session_completed && user.assignments.where.not(completed_at: nil).count >= 10
    }),
    Badge.new(key: "sessions_50", icon: "🏅", progress: ->(stats) { [ stats.sessions, 50 ] }, condition: ->(user, event) {
      event[:type] == :session_completed && user.assignments.where.not(completed_at: nil).count >= 50
    }),
    Badge.new(key: "streak_3", icon: "🔥", progress: ->(stats) { [ stats.streak, 3 ] },
              condition: ->(user, _event) { user.current_streak >= 3 }),
    Badge.new(key: "streak_7", icon: "⚡", progress: ->(stats) { [ stats.streak, 7 ] },
              condition: ->(user, _event) { user.current_streak >= 7 }),
    Badge.new(key: "streak_30", icon: "🌟", progress: ->(stats) { [ stats.streak, 30 ] },
              condition: ->(user, _event) { user.current_streak >= 30 }),
    Badge.new(key: "streak_100", icon: "💯", progress: ->(stats) { [ stats.streak, 100 ] },
              condition: ->(user, _event) { user.current_streak >= 100 }),
    Badge.new(key: "answers_100", icon: "✏️", progress: ->(stats) { [ stats.answers, 100 ] }, condition: ->(user, event) {
      event[:type] == :answer_recorded && user.user_answers.attempted.count >= 100
    }),
    Badge.new(key: "answers_500", icon: "📚", progress: ->(stats) { [ stats.answers, 500 ] }, condition: ->(user, event) {
      event[:type] == :answer_recorded && user.user_answers.attempted.count >= 500
    }),
    Badge.new(key: "perfect_session", icon: "🏆", condition: ->(user, event) {
      event[:type] == :session_completed &&
        event[:assignment].graded_questions_count >= 5 &&
        event[:assignment].correct_answers.count == event[:assignment].graded_questions_count
    }),
    Badge.new(key: "upset_win", icon: "🗡️", condition: ->(_user, event) {
      event[:type] == :answer_recorded && event[:correct] &&
        event[:question_rating].to_i - event[:user_rating].to_i >= 300
    }),
    Badge.new(key: "level_5", icon: "🚀", progress: ->(stats) { [ stats.level, 5, 1 ] },
              condition: ->(user, _event) { user.level >= 5 }),
    Badge.new(key: "level_10", icon: "🌙", progress: ->(stats) { [ stats.level, 10, 1 ] },
              condition: ->(user, _event) { user.level >= 10 }),
    Badge.new(key: "comeback", icon: "💪", condition: ->(user, event) {
      event[:type] == :answer_recorded && event[:correct] &&
        user.user_answers.attempted.order(created_at: :desc).offset(1).limit(2).pluck(:correct) == [ false, false ]
    }),
    Badge.new(key: "early_bird", icon: "🌅", condition: ->(_user, event) {
      event[:type] == :answer_recorded && Time.current.hour < 8
    }),
    Badge.new(key: "topic_master", icon: "🎓", condition: ->(user, _event) {
      user.skills.where.not(mastered_at: nil).exists?
    }),
    Badge.new(key: "topic_master_5", icon: "🧠", progress: ->(stats) { [ stats.mastered_topics, 5 ] }, condition: ->(user, _event) {
      user.skills.where.not(mastered_at: nil).count >= 5
    }),
    Badge.new(key: "duel_win", icon: "⚔️", condition: ->(_user, event) {
      event[:type] == :challenge_finished && event[:won]
    }),
    Badge.new(key: "duel_wins_10", icon: "👑", progress: ->(stats) { [ stats.duel_wins, 10 ] }, condition: ->(user, event) {
      event[:type] == :challenge_finished && user.won_challenges.count >= 10
    })
  ].freeze

  module_function

  def all
    DEFINITIONS
  end

  def find(key)
    DEFINITIONS.find { |badge| badge.key == key.to_s }
  end

  def stats_for(user)
    Stats.new(
      sessions: user.assignments.where.not(completed_at: nil).count,
      answers: user.user_answers.attempted.count,
      streak: user.current_streak,
      level: user.level,
      mastered_topics: user.skills.where.not(mastered_at: nil).count,
      duel_wins: user.won_challenges.count
    )
  end

  # The locked badge a student is closest to earning — what the home page points
  # at instead of asking them to read a wall of seventeen tiles. Only countable
  # badges qualify: "you are 7/10 of the way to this" is an invitation, and
  # "solve one before 8am" is not something to be nearest to.
  def next_to_unlock(user, stats: stats_for(user), awarded_keys: user.badge_awards.pluck(:badge_key))
    DEFINITIONS.
      reject { |badge| awarded_keys.include?(badge.key) }.
      select(&:countable?).
      filter_map { |badge| [ badge, badge.progress_for(stats) ] }.
      reject { |_badge, progress| progress.fraction >= 1.0 }.
      max_by { |_badge, progress| progress.fraction }
  end

  # Returns the newly awarded badges.
  def check!(user, event)
    awarded_keys = user.badge_awards.pluck(:badge_key)

    DEFINITIONS.filter_map do |badge|
      next if awarded_keys.include?(badge.key)
      next unless badge.condition.call(user, event)

      user.badge_awards.create!(badge_key: badge.key)
      badge
    end
  end
end
