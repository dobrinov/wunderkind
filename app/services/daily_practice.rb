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
  # Every child in the family field test (2026-10-30) quit somewhere between
  # problem 7 and 12 of a „1 от 30" session. A session a child finishes is the
  # one they come back to, and „Още една" is there for the ones who want more.
  MAX_QUESTIONS = 12
  # A child does not really answer a problem in ten seconds; the median used to
  # be floored there and a few quick taps made a ten-minute goal 30 problems.
  MIN_SECONDS_PER_QUESTION = 25

  # Today's unfinished daily session if there is one, else a new one. Pressing
  # „Още една" (or coming back after lunch) used to start a fresh session and
  # leave the half-done one behind, nine problems in.
  def execute(user:)
    unfinished_today(user) || compose(user)
  end

  def unfinished_today(user)
    user.assignments.daily.where(completed_at: nil, abandoned_at: nil, created_at: Time.zone.today.all_day)
        .order(created_at: :desc).detect(&:next_assignment_question)
  end

  def compose(user)
    minutes = user.daily_minutes_target || DEFAULT_MINUTES
    count = (minutes * 60.0 / median_seconds_per_question(user)).round.clamp(MIN_QUESTIONS, MAX_QUESTIONS)

    # A parent's focus, when there is one, decides which topics the session is
    # about — see PracticeFocuses. It is still a daily session in every other
    # respect: measured, hinted, skippable.
    SessionComposer.execute(user:, question_count: count, kind: :daily, focus: PracticeFocuses.session_topic_groups(user))
  end

  def median_seconds_per_question(user)
    # Not the placement: eight problems answered in the first rush of a new
    # account, many of them skipped, say nothing about a normal pace.
    durations = user.user_answers.attempted.where.not(duration_ms: nil)
                    .joins(assignment_question: :assignment).where.not(assignments: { kind: :placement })
                    .order(created_at: :desc).limit(100).pluck(:duration_ms).sort
    return DEFAULT_SECONDS_PER_QUESTION if durations.empty?

    (durations[durations.size / 2] / 1000.0).clamp(MIN_SECONDS_PER_QUESTION, 300)
  end
end
