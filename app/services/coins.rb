# Awards as coins: fifteen tracks, each a row of coins minted in better
# materials as the child goes — Дърво, Бронз, Желязо, Сребро, Злато, Платина,
# Диамант. They replaced nineteen medals that mostly arrived by accident on a
# first day and rewarded the clock, clicks and recall (see BACKLOG history and
# the design canvas). Every coin is for something a parent would praise:
# learning a mistake, getting better than last month, coming back, finding an
# error in the bank, keeping a promise.
#
# Nothing here is stored but the coins themselves: a track's count is a query
# over rows that already exist, like Goals and PracticeHistory, and
# `badge_awards` holds one row per rung reached (`badge_key` is the track,
# `rung` 1–7), with `seen_at` stamped once the child has been shown it. That is
# also why a launch can back-fill every track silently (`rake coins:backfill`).
#
# Everything that measures ability reads `UserAnswer.measured` — no placement,
# no mistakes session, no duel, no skip — so nothing can be won by recall or
# luck on day one.
module Coins
  MATERIALS = %w[wood bronze iron silver gold platinum diamond].freeze

  Track = Struct.new(:key, :symbol, :thresholds, keyword_init: true) do
    def rungs = thresholds.size

    # The material of rung `n` (1-based). A track with fewer rungs than
    # materials (Върнах се is one coin) is minted from the top: its coin is
    # worth what the last coin of a long track is.
    def material(rung) = MATERIALS[MATERIALS.size - rungs + rung - 1]
  end

  TRACKS = [
    Track.new(key: "learned", symbol: "bulb", thresholds: [ 1, 3, 5, 10, 25, 50, 100 ]),
    Track.new(key: "climb", symbol: "trend", thresholds: [ 25, 50, 100, 200, 300, 400, 500 ]),
    Track.new(key: "topic_up", symbol: "flag", thresholds: [ 1, 2, 3, 5, 10, 15, 25 ]),
    Track.new(key: "above_level", symbol: "mountain", thresholds: [ 1, 3, 5, 10, 25, 50, 100 ]),
    Track.new(key: "clean_run", symbol: "target", thresholds: [ 5, 8, 10, 15, 20, 30, 40 ]),
    Track.new(key: "full_week", symbol: "calendar", thresholds: [ 1, 2, 4, 8, 12, 26, 52 ]),
    Track.new(key: "finished", symbol: "finish", thresholds: [ 1, 5, 10, 25, 50, 100, 200 ]),
    Track.new(key: "came_back", symbol: "login", thresholds: [ 1 ]),
    Track.new(key: "detective", symbol: "search", thresholds: [ 1, 2, 3, 5, 10, 20, 30 ]),
    Track.new(key: "author", symbol: "pencil", thresholds: [ 1, 2, 3, 5, 10, 20, 30 ]),
    Track.new(key: "solved_mine", symbol: "users", thresholds: [ 1, 3, 10, 25, 50, 100, 250 ]),
    Track.new(key: "promise", symbol: "gift", thresholds: [ 1, 2, 3, 5, 10, 20, 30 ]),
    Track.new(key: "duels", symbol: "swords", thresholds: [ 1, 3, 5, 10, 25, 50, 100 ]),
    Track.new(key: "rematch", symbol: "rotate", thresholds: [ 1, 2, 3, 5, 10, 20, 30 ])
  ].freeze

  # How far above the student's rating a problem has to be for „Над нивото".
  # +200 was designed first; production had no correct answer that far up,
  # because every session aims below the student.
  ABOVE_LEVEL_GAP = 100
  # „Научих я!": the later correct answer has to come at least this long after
  # the mistake — a redo the same afternoon is still recall.
  LEARNED_AFTER = 3.days
  # „Тема напред": up this much from the topic's first measured rating, on at
  # least this many measured answers in it.
  TOPIC_UP_POINTS = 100
  TOPIC_UP_GAMES = 15
  # „Цяла седмица": days with practice in one Monday–Sunday week.
  WEEK_DAYS = 4
  # „Върнах се": away at least this long, then a finished session.
  AWAY_DAYS = 14

  Standing = Struct.new(:track, :count, :rungs_earned, keyword_init: true) do
    def complete? = rungs_earned >= track.rungs
    def next_threshold = track.thresholds[rungs_earned]
    def previous_threshold = rungs_earned.zero? ? 0 : track.thresholds[rungs_earned - 1]

    # How far between the last coin and the next, for the ring on the next slot.
    def fraction
      return 1.0 if complete?

      span = next_threshold - previous_threshold
      span.positive? ? ((count - previous_threshold).to_f / span).clamp(0.0, 1.0) : 0.0
    end
  end

  module_function

  def find(key) = TRACKS.find { |track| track.key == key.to_s }

  # The tracks a child can fill today. The ones that depend on somebody else
  # stay out of sight until they are possible: a promise needs a parent who
  # made one, „Решиха я" a published problem of the child's own, and the duel
  # tracks wait for duels that serve each player at their own level (BACKLOG).
  def visible_tracks(user)
    TRACKS.select do |track|
      case track.key
      when "promise" then user.goals.exists? || user.practice_focuses.exists?
      when "solved_mine" then Question.published.where(suggested_by_id: user.id).exists?
      when "duels", "rematch" then false
      else true
      end
    end
  end

  def standings(user, tracks: visible_tracks(user))
    earned = user.badge_awards.group(:badge_key).maximum(:rung)
    tracks.map do |track|
      Standing.new(track: track, count: count(user, track.key), rungs_earned: earned[track.key].to_i)
    end
  end

  # Mints every coin the counts have reached and nobody has been given. Safe
  # to call on any read. `silent` stamps them seen at once — the launch
  # back-fill, which must not greet a child with a dozen coins for last month.
  # Returns the new rows, oldest rung first.
  def refresh!(user, silent: false, tracks: visible_tracks(user))
    return [] unless user.student?

    held = user.badge_awards.pluck(:badge_key, :rung).to_set
    created = []
    tracks.each do |track|
      total = count(user, track.key)
      reached = track.thresholds.count { |threshold| total >= threshold }
      (1..reached).each do |rung|
        next if held.include?([ track.key, rung ])

        created << user.badge_awards.create!(badge_key: track.key, rung: rung, seen_at: (Time.current if silent))
      rescue ActiveRecord::RecordNotUnique
        next
      end
    end
    created
  end

  # After an answer only the tracks an answer can move are counted — the rest
  # (reports, suggestions, promises) are read on „Днес".
  ANSWER_TRACKS = %w[learned climb topic_up above_level clean_run full_week finished came_back].freeze

  def refresh_after_answer!(user)
    refresh!(user, tracks: TRACKS.select { |track| track.key.in?(ANSWER_TRACKS) })
  end

  def unseen(user) = user.badge_awards.where(seen_at: nil).order(:created_at, :rung)

  # Stamped by the child's own screen only — never while an admin is looking
  # through their eyes (the caller checks).
  def mark_seen!(awards)
    BadgeAward.where(id: Array(awards).map(&:id)).update_all(seen_at: Time.current)
  end

  # --- The counts -------------------------------------------------------------

  def count(user, key)
    case key.to_s
    when "learned" then learned(user)
    when "climb" then [ user.elo - (user.climb_base_elo || user.elo), 0 ].max
    when "topic_up" then user.skills.where("games_count >= ? AND base_rating IS NOT NULL AND rating - base_rating >= ?", TOPIC_UP_GAMES, TOPIC_UP_POINTS).count
    when "above_level" then above_level(user)
    when "clean_run" then clean_run(user)
    when "full_week" then full_weeks(user)
    when "finished" then finished_sessions(user).count
    when "came_back" then came_back?(user) ? 1 : 0
    when "detective" then user.question_reports.report.resolved.count
    when "author" then Question.published.where(suggested_by_id: user.id).count
    when "solved_mine" then solved_mine(user)
    when "promise" then user.goal_awards.count + user.practice_focuses.where.not(completed_at: nil).count
    when "duels" then Challenge.where(winner_id: user.id).count
    else 0
    end
  end

  # A question got wrong in a measured session and answered right in a later
  # measured session at least LEARNED_AFTER later. A redo in a mistakes session
  # is not measured, so it never counts here.
  def learned(user)
    attempts = UserAnswer.measured.where(user_id: user.id).joins(:assignment_question)
    wrong = attempts.where(correct: false).select("assignment_questions.question_id AS qid, user_answers.created_at AS at")
    right = attempts.where(correct: true).select("assignment_questions.question_id AS qid, user_answers.created_at AS at")
    sql = "SELECT COUNT(DISTINCT w.qid) FROM (#{wrong.to_sql}) w JOIN (#{right.to_sql}) r " \
          "ON r.qid = w.qid AND r.at >= w.at + interval '#{LEARNED_AFTER.to_i} seconds'"
    ActiveRecord::Base.connection.select_value(sql).to_i
  end

  # Right, measured, with no hint, after calibration, on a problem at least
  # ABOVE_LEVEL_GAP over the student's rating at that moment. Only answers
  # given since the ratings were recorded with them can count.
  def above_level(user)
    scope = UserAnswer.measured.where(user_id: user.id, correct: true)
                      .where.not(rating_before: nil).where.not(question_rating_before: nil)
                      .where("user_answers.question_rating_before - user_answers.rating_before >= ?", ABOVE_LEVEL_GAP)
                      .where("COALESCE((user_answers.response ->> 'hints_used')::int, 0) = 0")
    scope = scope.where(user_answers: { created_at: user.placed_at.. }) if user.placed_at
    scope.count
  end

  # The longest run of right answers in measured practice, each at or above the
  # difficulty the session aims at, with no hint and no skip between. A run
  # carries from one session to the next; a mistakes session neither extends
  # nor breaks it, because it is not part of the record.
  def clean_run(user)
    rows = UserAnswer.where(user_id: user.id).joins(assignment_question: :assignment)
                     .where.not(assignments: { kind: Assignment.kinds.values_at(*Assignment::UNMEASURED_KINDS) })
                     .order("user_answers.created_at")
                     .pluck(:correct, :skipped, :rating_before, :question_rating_before, Arel.sql("COALESCE((user_answers.response ->> 'hints_used')::int, 0)"))
    best = run = 0
    rows.each do |correct, skipped, rating, question_rating, hints|
      counts = correct && !skipped && hints.zero? && rating && question_rating &&
               question_rating >= Dispatcher.target_rating(rating)
      run = counts ? run + 1 : 0
      best = run if run > best
    end
    best
  end

  def practice_days(user)
    user.user_answers.attempted.pluck(:created_at).map { |time| time.in_time_zone.to_date }.uniq.sort
  end

  # Monday–Sunday weeks (Sofia) with practice on WEEK_DAYS days or more. They
  # add up and never reset: one bad Tuesday costs nothing.
  def full_weeks(user)
    practice_days(user).group_by(&:beginning_of_week).count { |_, days| days.size >= WEEK_DAYS }
  end

  # Sessions answered to the end, not walked away from. Placement and mistakes
  # sessions are not practice of the child's own, and a mock exam ends on the
  # clock rather than on the last answer.
  def finished_sessions(user)
    user.assignments.finished.where.not(kind: %w[placement mistakes mock])
  end

  # A second day of practice inside the first week, or a finished session after
  # AWAY_DAYS or more away.
  def came_back?(user)
    days = practice_days(user)
    return false if days.size < 2
    return true if days[1] <= days.first + 6

    finished_on = finished_sessions(user).pluck(:completed_at).map { |time| time.in_time_zone.to_date }.to_set
    days.each_cons(2).any? { |before, after| (after - before).to_i >= AWAY_DAYS && finished_on.include?(after) }
  end

  # Different students who answered one of this student's published problems
  # right.
  def solved_mine(user)
    UserAnswer.joins(assignment_question: :question)
              .where(questions: { suggested_by_id: user.id, status: Question.statuses[:published] })
              .where(correct: true).where.not(user_id: user.id)
              .distinct.count(:user_id)
  end
end
