# Sizes a practice session to the student's daily-minutes target using their
# real median answer time, then delegates to SessionComposer.
module DailyPractice
  extend self

  # Short on purpose: a child who finishes wants to come back tomorrow, one
  # who runs out of patience halfway does not. A parent raises it from the
  # child's page (Parents::DailyMinutesController) once the habit is there.
  DEFAULT_MINUTES = 10
  # What a parent can choose from — a few sensible lengths rather than a
  # number field, which invited 120.
  MINUTES_OPTIONS = [ 5, 10, 15, 20, 30 ].freeze
  DEFAULT_SECONDS_PER_QUESTION = 45
  MIN_QUESTIONS = 5
  MAX_QUESTIONS = 30

  def execute(user:)
    minutes = user.daily_minutes_target || DEFAULT_MINUTES
    count = (minutes * 60.0 / median_seconds_per_question(user)).round.clamp(MIN_QUESTIONS, MAX_QUESTIONS)

    # A parent's focus, when there is one, decides which topics the session is
    # about — see PracticeFocuses. It is still a daily session in every other
    # respect: measured, hinted, skippable.
    SessionComposer.execute(user:, question_count: count, kind: :daily, focus: PracticeFocuses.session_topic_groups(user))
  end

  def median_seconds_per_question(user)
    durations = user.user_answers.attempted.where.not(duration_ms: nil).order(created_at: :desc).limit(100).pluck(:duration_ms).sort
    return DEFAULT_SECONDS_PER_QUESTION if durations.empty?

    (durations[durations.size / 2] / 1000.0).clamp(10, 300)
  end
end
