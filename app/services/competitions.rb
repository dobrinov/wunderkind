# The calendar of Bulgarian maths competitions and exams — the `competitions`,
# `competition_editions` and `competition_rounds` tables, edited at
# /overseer/competitions, shown at /sastezaniya and /izpiti/:slug, and inside
# the app on the home page and at /competitions.
#
# A competition has editions, one a year (СМТ 2026, СМТ 2027), each with its
# rounds and, when it differs, that year's format; a child enters an edition
# (by its season), a past paper belongs to one. Every date is something
# somebody looked up on mon.bg, smb.bg or an organiser's site, and a date is
# only as good as its source: one nobody has published yet is `approximate`,
# set from last year's, and says so on the page — a parent planning around a
# guess we presented as a fact stops believing the rest of the calendar.
# db/seeds/competitions.yml was the first import (`import!`) and still seeds a
# fresh database; after that the tables are the truth.
#
# Two kinds of event share the file because they are the same thing to a family:
# a date in the school year that a child sits a paper on and wants to be ready
# for. `competition` is the Kangaroo, the olympiad, the СМБ tournaments; `exam`
# is НВО and the матура, which are compulsory and have their own pages at
# /izpiti because „матура по математика" is its own query with its own season.
#
# Like Curriculum, this speaks in school grades, and like Curriculum it is read
# by no part of the answer flow: the grades say who an event is *for*, which is
# a fact about the event. Preparation (CompetitionPractice) never asks what
# grade the child is in — it takes the event's topics and aims them at the
# child's rating, which is what every other session does.
module Competitions
  SEED = Rails.root.join("db/seeds/competitions.yml")

  KINDS = %w[competition exam].freeze

  # How the paper is marked. It decides what the page can honestly promise:
  # Wunderkind checks an answer, not a written solution, so it prepares for a
  # multiple-choice paper far better than for an olympiad round marked on
  # proofs — and the page says which this one is.
  STYLES = %w[choice answer mixed proof].freeze

  # Competition problems sit above school problems of the same grade. A grade's
  # Curriculum window is what school asks; the samples on a competition page
  # reach this far past its top.
  SAMPLE_LIFT = 200

  # The current locale, else Bulgarian — the language every entry is written in.
  Localized = Struct.new(:by_locale) do
    def to_s = by_locale[I18n.locale.to_s] || by_locale[I18n.default_locale.to_s]
    def present? = to_s.present?
  end

  Round = Struct.new(:name, :date, :approximate, :note, keyword_init: true) do
    def approximate? = !!approximate
    def past?(today = Time.zone.today) = date < today
    def days_until(today = Time.zone.today) = (date - today).to_i
  end

  # One year of an event. `format` is that year's when it was different,
  # else the event's own.
  Edition = Struct.new(:year, :format, :note, :rounds, keyword_init: true) do
    def held?(today = Time.zone.today) = rounds.any? && rounds.all? { |round| round.past?(today) }
    def upcoming?(today = Time.zone.today) = rounds.any? { |round| !round.past?(today) }
    def approximate? = rounds.any?(&:approximate?)
    def season = Competitions.season_for(rounds.first&.date || Date.new(year, 1, 1))
  end

  Event = Struct.new(:slug, :kind, :short, :name, :organizer, :grade_min, :grade_max, :style,
                     :url, :archive_url, :topic_names, :description, :format, :editions, :grade_page,
                     keyword_init: true) do
    # Every round of every edition, by date — what the calendar reads.
    def rounds = editions.flat_map(&:rounds).sort_by(&:date)

    # The edition still to come, else the last one held.
    def current_edition(today = Time.zone.today)
      editions.find { |edition| edition.upcoming?(today) } || editions.reverse.find { |edition| edition.rounds.any? }
    end

    def edition(year) = editions.find { |edition| edition.year == year.to_i }

    def exam? = kind == "exam"
    def competition? = kind == "competition"
    def grades = grade_min..grade_max
    def proof? = style == "proof"

    # The next round still to come, or nil once the season is over.
    def next_round(today = Time.zone.today)
      rounds.find { |round| !round.past?(today) }
    end

    def upcoming?(today = Time.zone.today) = next_round(today).present?

    # What the calendar sorts on: the next round, else the last one, so a
    # finished event sinks to the bottom rather than vanishing.
    def sort_date(today = Time.zone.today)
      (next_round(today) || rounds.last)&.date || Date.new(1970)
    end

    # The school year an entry belongs to — of the next round, or of the
    # current year when the season has ended and next year's dates are not in.
    def season(today = Time.zone.today)
      Competitions.season_for(next_round(today)&.date || today)
    end

    # The bank's leaf topics a preparation session draws from.
    def topic_ids
      Topic.where.not(parent_id: nil).where(name: topic_names).ids
    end

    # The Elo span the public page samples from: the Curriculum windows of the
    # grades the event is for, and for a competition a step past the top.
    def elo_range
      windows = Curriculum.grades.select { |grade| grades.cover?(grade.number) }
      return (0..) if windows.empty?

      floor = windows.map(&:floor).min
      ceiling = windows.map(&:ceiling).max
      floor...(competition? ? ceiling + SAMPLE_LIFT : ceiling)
    end
  end

  module_function

  # The calendar, read once per request (Current).
  def all
    Current.competitions ||= Competition.includes(editions: :rounds).order(:id).map { |record| from_record(record) }.freeze
  end

  def competitions = all.select(&:competition?)
  def exams = all.select(&:exam?)

  def find(slug)
    all.find { |event| event.slug == slug.to_s }
  end

  # Upcoming events soonest first; finished ones after them, most recent first.
  def calendar(today = Time.zone.today)
    upcoming, past = all.partition { |event| event.upcoming?(today) }
    upcoming.sort_by { |event| event.next_round(today).date } + past.sort_by { |event| event.sort_date(today) }.reverse
  end

  def upcoming(today = Time.zone.today, limit: nil)
    events = all.select { |event| event.upcoming?(today) }.sort_by { |event| event.next_round(today).date }
    limit ? events.first(limit) : events
  end

  # Every round still to come, one row per round, for the month-by-month view.
  # A competition with three rounds is three dates on a calendar.
  def schedule(today = Time.zone.today)
    all.flat_map { |event| event.rounds.reject { |round| round.past?(today) }.map { |round| [ event, round ] } }
       .sort_by { |_, round| round.date }
  end

  # "2026/2027" for anything from 1 September 2026 to 31 August 2027.
  def season_for(date)
    start = date.month >= 9 ? date.year : date.year - 1
    "#{start}/#{start + 1}"
  end

  def from_record(record)
    localized = ->(value) { value.present? ? Localized.new(value) : nil }
    format = Localized.new(record.format)
    Event.new(
      slug: record.slug, kind: record.kind, short: record.short, name: Localized.new(record.name),
      organizer: record.organizer, grade_min: record.grade_min, grade_max: record.grade_max, style: record.style,
      url: record.url, archive_url: record.archive_url, grade_page: record.grade_page,
      topic_names: record.programme_from ? programme(record.programme_from, record.programme_to) : record.topic_names,
      description: Localized.new(record.description), format: format,
      editions: record.editions.map do |edition|
        Edition.new(year: edition.year, format: localized.(edition.format) || format, note: localized.(edition.note),
                    rounds: edition.rounds.map do |round|
                      Round.new(name: Localized.new(round.name), date: round.date, approximate: round.approximate,
                                note: localized.(round.note))
                    end)
      end
    )
  end

  # The seed file: what `import!` loads and its spec checks.
  def load
    YAML.load_file(SEED, permitted_classes: [ Date ], aliases: true).fetch("events").map { |row| build(row) }
  end

  # Writes the seed file into the tables — once, on the day the tables
  # arrived, and on a fresh database. A competition already there keeps its
  # editions; the file adds the edition its dates are in, and an edition of
  # every year a past paper is filed under (db/seeds/past), with no dates.
  def import!(path = SEED)
    rows = YAML.load_file(path, permitted_classes: [ Date ], aliases: true).fetch("events")
    Competition.transaction do
      rows.each do |row|
        record = Competition.find_or_initialize_by(slug: row.fetch("slug"))
        first, last = row["programme"]
        record.update!(kind: row.fetch("kind"), short: row["short"], name: row.fetch("name"), organizer: row.fetch("organizer"),
                       grade_min: row.fetch("grades").first, grade_max: row.fetch("grades").last, style: row.fetch("style"),
                       url: row["url"], archive_url: row["archive_url"], topic_names: row["topics"] || [],
                       programme_from: first, programme_to: last, description: row.fetch("description"),
                       format: row.fetch("format"), grade_page: row["grade_page"])
        rounds = row.fetch("rounds").sort_by { |round| to_date(round.fetch("date")) }
        edition = record.editions.find_or_create_by!(year: to_date(rounds.first.fetch("date")).year)
        if edition.rounds.none?
          rounds.each do |round|
            edition.rounds.create!(name: round.fetch("name"), date: to_date(round.fetch("date")),
                                   approximate: round["approximate"] || false, note: round["note"])
          end
        end
        past_editions(record)
      end
    end
    rows.size
  end

  # An edition for every year a past paper is filed under (db/seeds/past),
  # dated by the paper's own header (`paper.date`) when the edition has no
  # dates yet — a date already entered at /overseer is never overwritten.
  def past_editions(record)
    dates = Dir[PastPapers::ROOT.join(record.slug, "*", "[0-9][0-9][0-9][0-9].yml")].each_with_object({}) do |file, acc|
      date = YAML.safe_load_file(file, permitted_classes: [ Date ]).dig("paper", "date")
      acc[File.basename(file, ".yml").to_i] ||= date && to_date(date)
    end
    dates.each do |year, date|
      edition = record.editions.find_or_create_by!(year: year)
      next if date.nil? || edition.rounds.any?

      edition.rounds.create!(name: record.editions.where.not(id: edition.id).joins(:rounds).first&.rounds&.first&.name || { "bg" => "Състезание", "en" => "Competition" },
                             date: date, approximate: false)
    end
  end

  # One event from a row shaped like the seed file — the seed spec, and specs
  # that put their own competitions on the calendar.
  def build(row)
    Event.new(
      slug: row.fetch("slug"),
      kind: row.fetch("kind"),
      short: row["short"],
      name: Localized.new(row.fetch("name")),
      organizer: row.fetch("organizer"),
      grade_min: row.fetch("grades").first,
      grade_max: row.fetch("grades").last,
      style: row.fetch("style"),
      url: row["url"],
      archive_url: row["archive_url"],
      topic_names: topic_names(row),
      description: Localized.new(row.fetch("description")),
      format: Localized.new(row.fetch("format")),
      grade_page: row["grade_page"],
      editions: build_editions(row)
    )
  end

  def build_editions(row)
    rounds = row.fetch("rounds").map do |round|
      Round.new(name: Localized.new(round.fetch("name")), date: to_date(round.fetch("date")),
                approximate: round["approximate"], note: round["note"] && Localized.new(round["note"]))
    end.sort_by(&:date)
    past = Array(row["past_years"]).map { |year| Edition.new(year: year, format: Localized.new(row.fetch("format")), rounds: []) }
    past + [ Edition.new(year: rounds.first.date.year, format: Localized.new(row.fetch("format")), rounds: rounds) ]
  end

  # Either a list of the bank's topics, or `programme: [5, 7]` — the union of
  # the МОН programme for those grades, which is what an exam asks.
  def topic_names(row)
    return row.fetch("topics") if row.key?("topics")

    programme(*row.fetch("programme"))
  end

  def programme(first, last) = (first..last).flat_map { |grade| Curriculum::TOPICS.fetch(grade) }.uniq

  def to_date(value)
    value.is_a?(Date) ? value : Date.iso8601(value.to_s)
  end
end
