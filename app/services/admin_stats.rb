# The database's view of how the app is doing, for /overseer/stats. Visits,
# sources and devices are Plausible's and Trace's; this is what only the
# tables know — who practised, how it went, who came back, what the bank is
# doing and whether duels find opponents.
#
# Every number covers the `days` ending today and is set against the same
# number of days before them, so a headline is never a figure without
# something to read it against. A scope narrows the answers to one family or
# one child (`user_ids`); the sections about sign-ups and the bank as a whole
# only make sense for everybody and are left nil under a scope.
#
# Admin accounts are out of everything, for the reason AnswerStats leaves them
# out: the owner is the heaviest user of this app and their testing would be
# most of every number. One query per section, each bounded by its range.
class AdminStats
  RANGES = [ 7, 30, 90, 365 ].freeze

  # A topic needs this many answers in the range before its skip share is
  # worth ranking — two skips out of three answers is a coin, not a topic.
  # A family or a child answers far less than everybody, hence the lower bar.
  MIN_TOPIC_ANSWERS = 20
  MIN_TOPIC_ANSWERS_SCOPED = 5
  SKIP_TOPICS = 5

  COHORTS = 6
  COHORT_WEEKS = 6

  Period = Struct.new(:solved, :correct, :skipped, :duration_ms, keyword_init: true) do
    def total = solved + skipped
    def minutes = (duration_ms.to_i / 60_000.0).round
    def correct_share = solved.zero? ? nil : correct * 100.0 / solved
    def skip_share = total.zero? ? nil : skipped * 100.0 / total
  end

  # A number now and the same number over the period before.
  Compared = Struct.new(:current, :previous) do
    # Relative change of a count, in whole percent; nil with nothing to compare.
    def change
      return nil if current.nil? || previous.nil? || previous.zero?

      ((current - previous) * 100.0 / previous).round
    end

    # Change of a share, in percentage points.
    def points
      return nil if current.nil? || previous.nil?

      (current - previous).round(1)
    end
  end

  Funnel = Struct.new(:steps, keyword_init: true) do
    def started = steps.first.last
    # Each step's share of everybody who started, so the bars all read
    # against the same 100%.
    def share(count) = started.zero? ? 0 : (count * 100.0 / started).round
  end

  Cohort = Struct.new(:week, :size, :weeks, keyword_init: true)
  SkipTopic = Struct.new(:topic_id, :name, :answers, :skipped, keyword_init: true) do
    def share = skipped * 100.0 / answers
  end

  attr_reader :days, :user_ids, :today

  def self.range(param) = param.to_i.presence_in(RANGES) || 30

  def initialize(days:, user_ids: nil, today: Time.zone.today)
    @days = days
    @user_ids = user_ids
    @today = today
  end

  def scoped? = !user_ids.nil?
  def first_day = today - (days - 1)
  def range = first_day.beginning_of_day..today.end_of_day
  def previous_range = (first_day - days).beginning_of_day..(first_day - 1).end_of_day

  def problems = Compared.new(*periods.map(&:solved))
  def minutes = Compared.new(*periods.map(&:minutes))
  def correct_share = Compared.new(*periods.map(&:correct_share))
  def skip_share = Compared.new(*periods.map(&:skip_share))
  def target_share = (Dispatcher::TARGET_SUCCESS_RATE * 100).round

  # How many weeks „per week" averages over: the whole weeks that fit in the
  # range, counted back from today, and at least one.
  def weeks = [ days / 7, 1 ].max

  # Students with at least one attempted answer in a seven-day window, averaged
  # over the range's whole weeks counted back from today — and over the same
  # number of weeks before them. A skip alone does not make a week active: a
  # child who opened a session and skipped everything did not practise.
  def active_per_week
    @active_per_week ||= begin
      counts = answers(today.beginning_of_day - (weeks * 14 - 1).days..today.end_of_day).
        where(skipped: false).
        group(Arel.sql(window_sql)).
        distinct.count(:user_id)
      average = ->(indexes) { indexes.sum { |index| counts.fetch(index, 0) } / weeks.to_f }
      Compared.new(average.(0...weeks).round, average.(weeks...weeks * 2).round)
    end
  end

  # New students who signed up in the range, and how far each got so far —
  # nested, so every step counts only those who also made the steps before
  # it. A session here is a finished one (not abandoned) that is not the
  # placement, which is its own step.
  def student_funnel
    return nil if scoped?

    @student_funnel ||= begin
      signups = User.student.where(created_at: range)
      sessions = Assignment.finished.where.not(kind: :placement).where(user_id: signups.select(:id)).
        group(:user_id).select("user_id, COUNT(*) AS n")
      row = signups.
        joins("LEFT JOIN (#{sessions.to_sql}) sessions ON sessions.user_id = users.id").
        pick(
          Arel.sql("COUNT(*)"),
          Arel.sql("COUNT(*) FILTER (WHERE users.placed_at IS NOT NULL)"),
          Arel.sql("COUNT(*) FILTER (WHERE users.placed_at IS NOT NULL AND sessions.n >= 1)"),
          Arel.sql("COUNT(*) FILTER (WHERE users.placed_at IS NOT NULL AND sessions.n >= 2)")
        )
      Funnel.new(steps: %i[signed_up placed first_session two_sessions].zip(row))
    end
  end

  # New parents who signed up in the range: added a child, handed over the
  # device (a managed child of theirs has been switched into — last_login_at
  # is stamped on the switch, since such a child has no login of their own),
  # and that child then finished a session. Nested like the student funnel.
  PARENT_LINKED = "EXISTS (SELECT 1 FROM parent_links WHERE parent_links.parent_id = users.id)".freeze
  PARENT_HANDED = "EXISTS (SELECT 1 FROM users children WHERE children.managed_by_id = users.id AND children.last_login_at IS NOT NULL)".freeze
  PARENT_PRACTISED = <<~SQL.squish.freeze
    EXISTS (SELECT 1 FROM users children JOIN assignments ON assignments.user_id = children.id
            WHERE children.managed_by_id = users.id AND children.last_login_at IS NOT NULL
              AND assignments.completed_at IS NOT NULL AND assignments.abandoned_at IS NULL
              AND assignments.kind <> :placement)
  SQL

  def parent_funnel
    return nil if scoped?

    @parent_funnel ||= begin
      row = User.parent.where(created_at: range).pick(
        Arel.sql("COUNT(*)"),
        Arel.sql("COUNT(*) FILTER (WHERE #{PARENT_LINKED})"),
        Arel.sql("COUNT(*) FILTER (WHERE #{PARENT_LINKED} AND #{PARENT_HANDED})"),
        Arel.sql(User.sanitize_sql_array([ "COUNT(*) FILTER (WHERE #{PARENT_LINKED} AND #{PARENT_HANDED} AND #{PARENT_PRACTISED})",
                                           { placement: Assignment.kinds[:placement] } ]))
      )
      Funnel.new(steps: %i[signed_up child_added handed_over child_practised].zip(row))
    end
  end

  # The last COHORTS whole Monday weeks of student sign-ups, and for each the
  # share who practised (an attempted answer) in their 1st..COHORT_WEEKS-th
  # week after signing up. A week is counted from each student's own sign-up
  # day — days 7–13 are week 1 — and a cell is only filled once that week is
  # over for the cohort's last sign-up, so a week still running never shows
  # as a drop. Not tied to the range picker: retention needs weeks of history
  # whatever range is being looked at.
  def cohorts
    return nil if scoped?

    @cohorts ||= begin
      start = today.beginning_of_week - COHORTS.weeks
      signups = User.student.where(created_at: start.beginning_of_day...today.beginning_of_week.beginning_of_day)
      sizes = signups.group(Arel.sql("DATE_TRUNC('week', users.created_at)::date")).count
      active = signups.
        joins(:user_answers).
        where(user_answers: { skipped: false, created_at: start.beginning_of_day.. }).
        group(Arel.sql("DATE_TRUNC('week', users.created_at)::date"),
              Arel.sql("(DATE(user_answers.created_at) - DATE(users.created_at)) / 7")).
        distinct.count("users.id")

      (0...COHORTS).map do |offset|
        week = start + offset.weeks
        size = sizes.fetch(week, 0)
        cells = (1..COHORT_WEEKS).map do |n|
          next nil unless week.end_of_week + (n * 7 + 6) < today
          next nil if size.zero?

          (active.fetch([ week, n ], 0) * 100.0 / size).round
        end
        Cohort.new(week:, size:, weeks: cells)
      end
    end
  end

  # The topics where the most answers in the range were „не съм го учил",
  # among topics with enough answers to say so.
  def skip_topics
    @skip_topics ||= answers(range).
      joins(assignment_question: { question: :topics }).
      group("topics.id", "topics.name").
      having("COUNT(*) >= ?", scoped? ? MIN_TOPIC_ANSWERS_SCOPED : MIN_TOPIC_ANSWERS).
      having("COUNT(*) FILTER (WHERE user_answers.skipped) > 0").
      order(Arel.sql("COUNT(*) FILTER (WHERE user_answers.skipped)::float / COUNT(*) DESC, COUNT(*) DESC")).
      limit(SKIP_TOPICS).
      pluck("topics.id", "topics.name", Arel.sql("COUNT(*)"), Arel.sql("COUNT(*) FILTER (WHERE user_answers.skipped)")).
      map { |topic_id, name, total, skipped| SkipTopic.new(topic_id:, name:, answers: total, skipped:) }
  end

  # Distinct questions that reached a screen in a practice session this range
  # — answered or skipped, since a skip was still read — against the
  # published bank.
  def questions_seen
    @questions_seen ||= answers(range).joins(:assignment_question).distinct.count("assignment_questions.question_id")
  end

  def published_bank = @published_bank ||= Question.published.count

  # New rows in the bank — imports and the editor alike — and suggestions
  # made in the range, with how many of those are published now. There is no
  # timestamp for when a suggestion was accepted, nor for when a question was
  # retired, so neither is counted by its own date.
  def questions_created
    return nil if scoped?

    @questions_created ||= Question.where(created_at: range).count
  end

  def suggestions
    return nil if scoped?

    @suggestions ||= Question.where(created_at: range).
      joins(:suggested_by).where.not(users: { role: :admin }).
      pick(Arel.sql("COUNT(*)"), Arel.sql(Question.sanitize_sql_array([ "COUNT(*) FILTER (WHERE questions.status = ?)", Question.statuses[:published] ])))
  end

  # Duels that finished in the range, how many of them a friend was invited
  # to, and the rooms opened in the range that never started — let expire or
  # backed out of, which the table cannot tell apart (both are `abandoned`).
  def duels
    @duels ||= begin
      finished = challenges.finished.where(finished_at: range).
        pick(Arel.sql("COUNT(*)"), Arel.sql("COUNT(*) FILTER (WHERE invited_user_id IS NOT NULL)"))
      opened = challenges.where(created_at: range).
        pick(Arel.sql("COUNT(*)"), Arel.sql(Challenge.sanitize_sql_array([ "COUNT(*) FILTER (WHERE status = ? AND started_at IS NULL)", Challenge.statuses[:abandoned] ])))
      { finished: finished[0], invited: finished[1], opened: opened[0], unplayed: opened[1] }
    end
  end

  # The median time a public room waited for its opponent, in seconds: from
  # the room opening to the second player being seated. Only rooms that were
  # paired — one nobody joined has no wait to measure, so this is the wait of
  # those who got a game — and only the queue: an invitation waits on a
  # friend noticing, which is a different thing.
  def median_wait
    @median_wait ||= challenges.where(invited_user_id: nil, paired_at: range).
      pick(Arel.sql("PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY EXTRACT(EPOCH FROM paired_at - created_at))"))&.round
  end

  private

  # This range and the one before it, in one query.
  def periods
    @periods ||= begin
      current = Arel.sql(ActiveRecord::Base.sanitize_sql_array([ "user_answers.created_at >= ?", range.begin ]))
      rows = answers(previous_range.begin..range.end).
        group(current).
        pluck(
          current,
          Arel.sql("COUNT(*) FILTER (WHERE NOT skipped)"),
          Arel.sql("COUNT(*) FILTER (WHERE NOT skipped AND correct)"),
          Arel.sql("COUNT(*) FILTER (WHERE skipped)"),
          Arel.sql("COALESCE(SUM(duration_ms) FILTER (WHERE NOT skipped), 0)")
        ).to_h { |current, *counts| [ current, counts ] }

      [ true, false ].map do |current|
        solved, correct, skipped, duration_ms = rows.fetch(current, [ 0, 0, 0, 0 ])
        Period.new(solved:, correct:, skipped:, duration_ms:)
      end
    end
  end

  # Which seven-day window back from today an answer falls in: 0 is the last
  # seven days.
  def window_sql = "('#{today.iso8601}'::date - DATE(user_answers.created_at)) / 7"

  def answers(within)
    scope = UserAnswer.where(created_at: within)
    scoped? ? scope.where(user_id: user_ids) : scope.joins(:user).where.not(users: { role: :admin })
  end

  def challenges
    if scoped?
      Challenge.where(id: ChallengeParticipant.where(user_id: user_ids).select(:challenge_id))
    else
      Challenge.where.not(id: ChallengeParticipant.joins(:user).where(users: { role: :admin }).select(:challenge_id))
    end
  end
end
