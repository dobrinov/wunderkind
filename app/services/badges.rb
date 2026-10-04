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

  # The families a badge can belong to, and the silhouette each one is struck
  # in. The shape is the first thing read on a medal and it carries the family
  # — a child learns „shields are streaks" once and then recognises a locked
  # shield across the room without reading anything.
  #
  # `goals` is in the design and has no members yet: the badges that would fill
  # it are the proposed ones that hang off the parent-goals feature. A family
  # with nothing in it renders nothing, so it waits here rather than shipping
  # an empty row.
  FAMILIES = %w[practice streak answers level mastery duel special].freeze

  # Bronze, silver, gold, then legend for the far end of a ladder; `special` is
  # the one-off that is not on a ladder at all and wears a violet enamel face
  # inside a gold rim. All of them live inside the amber rule — a medal is a
  # reward, so a medal is warm.
  TIERS = %w[bronze silver gold legend special].freeze

  # :progress is optional and only set where the condition is a count a student
  # can watch climb. A one-shot badge ("solve a problem before 8am") gets none:
  # a progress bar that can only read 0/1 tells a child nothing.
  #
  # :family, :tier and :glyph are what the medal is struck from — shape, metal
  # and the engraving. :number is the figure engraved under the glyph where
  # there is one worth reading from across the room ("500"), and nil where the
  # badge is not a count. :icon stays: it is the medal's alt text, and the
  # fallback anywhere a medal would be too small to read.
  #
  # :secret hides the name and the glyph until it is earned — „???" under a
  # padlock. Only for badges whose charm is being surprised by them; a goal a
  # child could be working towards must never be secret.
  Badge = Struct.new(:key, :icon, :condition, :progress, :family, :tier, :glyph, :number, :secret,
                     keyword_init: true) do
    def name = I18n.t("badges.#{key}.name")
    def description = I18n.t("badges.#{key}.description")
    def countable? = !progress.nil?
    def secret? = secret.present?

    # What a locked medal says about itself. A secret one gives nothing away;
    # everything else names itself, because a badge nobody can see the shape of
    # is a badge nobody is working towards.
    def display_name(earned) = (earned || !secret?) ? name : "???"
    def display_glyph(earned) = (earned || !secret?) ? glyph : "lock"
    def display_number(earned) = (earned || !secret?) ? number : nil

    def progress_for(stats)
      return nil if progress.nil?

      current, target, floor = progress.call(stats)
      Progress.new(current: current, target: target, floor: floor)
    end
  end

  DEFINITIONS = [
    Badge.new(key: "first_session", family: "practice", tier: "bronze", glyph: "play", icon: "🎯", condition: ->(user, event) {
      event[:type] == :session_completed
    }),
    Badge.new(key: "sessions_10", family: "practice", tier: "silver", glyph: "pencil-line", number: 10, icon: "🔟", progress: ->(stats) { [ stats.sessions, 10 ] }, condition: ->(user, event) {
      event[:type] == :session_completed && user.assignments.where.not(completed_at: nil).count >= 10
    }),
    Badge.new(key: "sessions_50", family: "practice", tier: "gold", glyph: "pencil-line", number: 50, icon: "🏅", progress: ->(stats) { [ stats.sessions, 50 ] }, condition: ->(user, event) {
      event[:type] == :session_completed && user.assignments.where.not(completed_at: nil).count >= 50
    }),
    Badge.new(key: "streak_3", family: "streak", tier: "bronze", glyph: "flame", number: 3, icon: "🔥", progress: ->(stats) { [ stats.streak, 3 ] },
              condition: ->(user, _event) { user.current_streak >= 3 }),
    Badge.new(key: "streak_7", family: "streak", tier: "silver", glyph: "flame", number: 7, icon: "⚡", progress: ->(stats) { [ stats.streak, 7 ] },
              condition: ->(user, _event) { user.current_streak >= 7 }),
    Badge.new(key: "streak_30", family: "streak", tier: "gold", glyph: "flame", number: 30, icon: "🌟", progress: ->(stats) { [ stats.streak, 30 ] },
              condition: ->(user, _event) { user.current_streak >= 30 }),
    Badge.new(key: "streak_100", family: "streak", tier: "legend", glyph: "flame", number: 100, icon: "💯", progress: ->(stats) { [ stats.streak, 100 ] },
              condition: ->(user, _event) { user.current_streak >= 100 }),
    Badge.new(key: "answers_100", family: "answers", tier: "silver", glyph: "check-check", number: 100, icon: "✏️", progress: ->(stats) { [ stats.answers, 100 ] }, condition: ->(user, event) {
      event[:type] == :answer_recorded && user.user_answers.attempted.count >= 100
    }),
    Badge.new(key: "answers_500", family: "answers", tier: "gold", glyph: "check-check", number: 500, icon: "📚", progress: ->(stats) { [ stats.answers, 500 ] }, condition: ->(user, event) {
      event[:type] == :answer_recorded && user.user_answers.attempted.count >= 500
    }),
    Badge.new(key: "perfect_session", family: "special", tier: "special", glyph: "target", icon: "🏆", condition: ->(user, event) {
      event[:type] == :session_completed &&
        event[:assignment].graded_questions_count >= 5 &&
        event[:assignment].correct_answers.count == event[:assignment].graded_questions_count
    }),
    Badge.new(key: "upset_win", family: "special", tier: "special", glyph: "mountain-snow", secret: true, icon: "🗡️", condition: ->(_user, event) {
      event[:type] == :answer_recorded && event[:correct] &&
        event[:question_rating].to_i - event[:user_rating].to_i >= 300
    }),
    Badge.new(key: "level_5", family: "level", tier: "silver", glyph: "chevrons-up", number: 5, icon: "🚀", progress: ->(stats) { [ stats.level, 5, 1 ] },
              condition: ->(user, _event) { user.level >= 5 }),
    Badge.new(key: "level_10", family: "level", tier: "gold", glyph: "chevrons-up", number: 10, icon: "🌙", progress: ->(stats) { [ stats.level, 10, 1 ] },
              condition: ->(user, _event) { user.level >= 10 }),
    Badge.new(key: "comeback", family: "special", tier: "special", glyph: "trending-up", secret: true, icon: "💪", condition: ->(user, event) {
      event[:type] == :answer_recorded && event[:correct] &&
        user.user_answers.attempted.order(created_at: :desc).offset(1).limit(2).pluck(:correct) == [ false, false ]
    }),
    Badge.new(key: "early_bird", family: "special", tier: "special", glyph: "sunrise", icon: "🌅", condition: ->(_user, event) {
      event[:type] == :answer_recorded && Time.current.hour < 8
    }),
    Badge.new(key: "topic_master", family: "mastery", tier: "silver", glyph: "graduation-cap", icon: "🎓", condition: ->(user, _event) {
      user.skills.where.not(mastered_at: nil).exists?
    }),
    Badge.new(key: "topic_master_5", family: "mastery", tier: "gold", glyph: "graduation-cap", number: 5, icon: "🧠", progress: ->(stats) { [ stats.mastered_topics, 5 ] }, condition: ->(user, _event) {
      user.skills.where.not(mastered_at: nil).count >= 5
    }),
    Badge.new(key: "duel_win", family: "duel", tier: "bronze", glyph: "swords", icon: "⚔️", condition: ->(_user, event) {
      event[:type] == :challenge_finished && event[:won]
    }),
    Badge.new(key: "duel_wins_10", family: "duel", tier: "gold", glyph: "crown", number: 10, icon: "👑", progress: ->(stats) { [ stats.duel_wins, 10 ] }, condition: ->(user, event) {
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

  # Every glyph the medals can engrave, for the spec that checks each one has a
  # vendored file behind it. A badge whose glyph is missing renders a blank
  # medal, which looks like a bug in the medal rather than a missing file.
  def glyphs
    (DEFINITIONS.map(&:glyph) + [ "lock" ]).uniq.sort
  end

  # The collection, as one ladder per family: what the profile screen draws.
  #
  # A rung is a badge plus everything needed to strike its medal — whether it
  # has been earned, when, and how far along the student is if it has not.
  # Ordered by tier rather than by definition order, so a ladder reads bronze
  # to legend left to right the way a ladder should.
  Rung = Struct.new(:badge, :earned_at, :progress, keyword_init: true) do
    def earned? = earned_at.present?
    def fill = earned? ? 1.0 : (progress&.fraction || 0.0)
  end

  Ladder = Struct.new(:family, :rungs, keyword_init: true) do
    def earned_count = rungs.count(&:earned?)
    def size = rungs.size
    def name = I18n.t("badges.families.#{family}")
  end

  def collection_for(user, stats: stats_for(user))
    awarded = user.badge_awards.pluck(:badge_key, :created_at).to_h

    FAMILIES.filter_map do |family|
      rungs = DEFINITIONS.
        select { |badge| badge.family == family }.
        sort_by { |badge| TIERS.index(badge.tier) }.
        map { |badge| Rung.new(badge: badge, earned_at: awarded[badge.key], progress: badge.progress_for(stats)) }

      Ladder.new(family: family, rungs: rungs) if rungs.any?
    end
  end

  # The handful a student is nearest to, for the „Съвсем близо" band. Same rule
  # as next_to_unlock — countable only — and it is that method's plural.
  def closest_to_unlock(user, limit: 3, stats: stats_for(user), awarded_keys: user.badge_awards.pluck(:badge_key))
    DEFINITIONS.
      reject { |badge| awarded_keys.include?(badge.key) }.
      select(&:countable?).
      filter_map { |badge| [ badge, badge.progress_for(stats) ] }.
      reject { |_badge, progress| progress.fraction >= 1.0 }.
      sort_by { |_badge, progress| -progress.fraction }.
      first(limit)
  end

  # „19 от 19 · 4 злато, 5 сребро" — the line under the heading. Tiers in
  # descending rarity, and only the ones actually held.
  def tally_for(user, awarded_keys: user.badge_awards.pluck(:badge_key))
    held = DEFINITIONS.select { |badge| awarded_keys.include?(badge.key) }

    TIERS.reverse.filter_map do |tier|
      count = held.count { |badge| badge.tier == tier }
      [ tier, count ] if count.positive?
    end
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
