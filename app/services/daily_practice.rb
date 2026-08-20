# Sizes a practice session to the student's daily-minutes target using their
# real median answer time, then delegates to AssignmentCreator.
module DailyPractice
  extend self

  DEFAULT_MINUTES = 15
  DEFAULT_SECONDS_PER_QUESTION = 45
  MIN_QUESTIONS = 5
  MAX_QUESTIONS = 30

  def execute(user:)
    minutes = user.daily_minutes_target || DEFAULT_MINUTES
    count = (minutes * 60.0 / median_seconds_per_question(user)).round.clamp(MIN_QUESTIONS, MAX_QUESTIONS)

    AssignmentCreator.execute(user:, question_count: count, kind: :daily)
  end

  def median_seconds_per_question(user)
    durations = user.user_answers.where.not(duration_ms: nil).order(created_at: :desc).limit(100).pluck(:duration_ms).sort
    return DEFAULT_SECONDS_PER_QUESTION if durations.empty?

    (durations[durations.size / 2] / 1000.0).clamp(10, 300)
  end
end
