# Badge definitions live in code; awards live in the badge_awards table.
# Badges.check! runs after answers and session completions and awards anything
# newly earned. Names and descriptions come from i18n (badges.<key>.*).
module Badges
  Badge = Struct.new(:key, :icon, :condition, keyword_init: true) do
    def name = I18n.t("badges.#{key}.name")
    def description = I18n.t("badges.#{key}.description")
  end

  DEFINITIONS = [
    Badge.new(key: "first_session", icon: "🎯", condition: ->(user, event) {
      event[:type] == :session_completed
    }),
    Badge.new(key: "sessions_10", icon: "🔟", condition: ->(user, event) {
      event[:type] == :session_completed && user.assignments.where.not(completed_at: nil).count >= 10
    }),
    Badge.new(key: "sessions_50", icon: "🏅", condition: ->(user, event) {
      event[:type] == :session_completed && user.assignments.where.not(completed_at: nil).count >= 50
    }),
    Badge.new(key: "streak_3", icon: "🔥", condition: ->(user, _event) { user.current_streak >= 3 }),
    Badge.new(key: "streak_7", icon: "⚡", condition: ->(user, _event) { user.current_streak >= 7 }),
    Badge.new(key: "streak_30", icon: "🌟", condition: ->(user, _event) { user.current_streak >= 30 }),
    Badge.new(key: "streak_100", icon: "💯", condition: ->(user, _event) { user.current_streak >= 100 }),
    Badge.new(key: "answers_100", icon: "✏️", condition: ->(user, event) {
      event[:type] == :answer_recorded && user.user_answers.attempted.count >= 100
    }),
    Badge.new(key: "answers_500", icon: "📚", condition: ->(user, event) {
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
    Badge.new(key: "level_5", icon: "🚀", condition: ->(user, _event) { user.level >= 5 }),
    Badge.new(key: "level_10", icon: "🌙", condition: ->(user, _event) { user.level >= 10 }),
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
    Badge.new(key: "topic_master_5", icon: "🧠", condition: ->(user, _event) {
      user.skills.where.not(mastered_at: nil).count >= 5
    })
  ].freeze

  module_function

  def all
    DEFINITIONS
  end

  def find(key)
    DEFINITIONS.find { |badge| badge.key == key.to_s }
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
