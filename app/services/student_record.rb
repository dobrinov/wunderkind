# The numbers at the top of a student's admin page, and the list of what they
# did lately. Grown-up framing on purpose — this is the team's view, so a dip
# is shown as a dip (StudentProgress, the child's own card, shows only gains).
class StudentRecord
  RECENT_DAYS = 30
  SESSIONS = 8
  DUELS = 4

  Session = Data.define(:at, :kind, :answered, :correct, :skipped, :minutes, :measured, :challenge, :assignment) do
    def duel? = kind == :duel
  end

  attr_reader :user, :trend

  def initialize(user, trend:)
    @user = user
    @trend = trend
  end

  # How much harder the problems they get right are now than about a month
  # ago, signed — the same baseline StudentProgress#gain uses — or nil while
  # there are not two weeks to compare.
  def trend_change
    solved = trend.weeks.each_with_index.select { |week, _| week.solved? }
    return nil if solved.size < 2

    latest, latest_index = solved.last
    base, = solved.reverse.find { |_, index| latest_index - index >= StudentProgress::BASELINE_WEEKS } || solved.first
    latest.rating - base.rating
  end

  # Right answers among those attempted, and skips among everything, over the
  # last RECENT_DAYS — one query. Nil when there is nothing to divide by.
  def recent
    @recent ||= user.user_answers.where(created_at: RECENT_DAYS.days.ago..).pick(
      Arel.sql("COUNT(*)"),
      Arel.sql("COUNT(*) FILTER (WHERE correct)"),
      Arel.sql("COUNT(*) FILTER (WHERE skipped)")
    )
  end

  def recent_total = recent[0].to_i

  def correct_share
    attempted = recent[0].to_i - recent[2].to_i
    attempted.positive? ? (recent[1] * 100.0 / attempted).round : nil
  end

  def skip_share = recent_total.positive? ? (recent[2] * 100.0 / recent_total).round : nil

  # Sessions and duels, newest first. A session's tallies come from one
  # grouped query; a mistakes or placement session is flagged as not
  # measured, because its answers moved no rating (Assignment#measured?).
  def recent_sessions
    assignments = user.assignments.order(created_at: :desc).limit(SESSIONS).to_a
    tallies = UserAnswer.joins(:assignment_question).
      where(assignment_questions: { assignment_id: assignments.map(&:id) }).
      group("assignment_questions.assignment_id").
      pluck(Arel.sql("assignment_questions.assignment_id"), Arel.sql("COUNT(*)"),
            Arel.sql("COUNT(*) FILTER (WHERE correct)"), Arel.sql("COUNT(*) FILTER (WHERE skipped)"),
            Arel.sql("COALESCE(SUM(duration_ms), 0)")).
      to_h { |id, *rest| [ id, rest ] }

    sessions = assignments.map do |assignment|
      answered, correct, skipped, duration = tallies.fetch(assignment.id, [ 0, 0, 0, 0 ])
      Session.new(at: assignment.created_at, kind: assignment.kind.to_sym, answered:, correct:, skipped:,
                  minutes: (duration / 60_000.0).round, measured: assignment.measured?, challenge: nil, assignment:)
    end

    duels = ChallengeRecord.history(user, limit: DUELS).map do |challenge|
      mine = challenge.participants.find { |participant| participant.user_id == user.id }
      Session.new(at: challenge.finished_at || challenge.created_at, kind: :duel, answered: challenge.question_count,
                  correct: mine&.correct_count.to_i, skipped: 0, minutes: (mine&.total_ms.to_i / 60_000.0).round,
                  measured: false, challenge:, assignment: nil)
    end

    (sessions + duels).sort_by(&:at).reverse.first(SESSIONS)
  end
end
