# The calendar of Bulgarian maths competitions and exams — read from
# config/competitions.yml, shown at /sastezaniya and /izpiti/:slug, and inside
# the app on the home page and at /competitions.
#
# A file a person edits rather than a table, for the same reason as
# BankReview: every line of it is something somebody looked up on mon.bg, smb.bg
# or an organiser's site, and a date is only as good as the source it came
# from. A date nobody has published yet is in the file as `approximate: true`,
# set from last year's, and it says so on the page — a parent planning around a
# guess we presented as a fact stops believing the rest of the calendar.
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
  PATH = Rails.root.join("config/competitions.yml")

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

  Event = Struct.new(:slug, :kind, :short, :name, :organizer, :grade_min, :grade_max, :style,
                     :url, :archive_url, :topic_names, :description, :format, :rounds, :grade_page,
                     keyword_init: true) do
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
      (next_round(today) || rounds.last).date
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

  def all
    @all = nil if Rails.env.development?
    @all ||= load.freeze
  end

  def competitions = all.select(&:competition?)
  def exams = all.select(&:exam?)

  def find(slug)
    all.find { |event| event.slug == slug.to_s }
  end

  # Upcoming events soonest first; finished ones after them, most recent first.
  def calendar(today = Time.zone.today)
    upcoming, past = all.partition { |event| event.upcoming?(today) }
    upcoming.sort_by { |event| event.next_round(today).date } + past.sort_by { |event| event.rounds.last.date }.reverse
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

  def load
    YAML.load_file(PATH, permitted_classes: [ Date ], aliases: true).fetch("events").map { |row| build(row) }
  end

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
      rounds: row.fetch("rounds").map do |round|
        Round.new(name: Localized.new(round.fetch("name")), date: to_date(round.fetch("date")),
                  approximate: round["approximate"], note: round["note"] && Localized.new(round["note"]))
      end.sort_by(&:date)
    )
  end

  # Either a list of the bank's topics, or `programme: [5, 7]` — the union of
  # the МОН programme for those grades, which is what an exam asks.
  def topic_names(row)
    return row.fetch("topics") if row.key?("topics")

    first, last = row.fetch("programme")
    (first..last).flat_map { |grade| Curriculum::TOPICS.fetch(grade) }.uniq
  end

  def to_date(value)
    value.is_a?(Date) ? value : Date.iso8601(value.to_s)
  end
end
