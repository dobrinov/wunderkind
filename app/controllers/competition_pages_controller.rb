# The public calendar of maths competitions and exams: /sastezaniya, one page
# per competition at /sastezaniya/:slug and one per exam at /izpiti/:slug.
#
# These pages answer three different searches, and are built so each finds the
# part it came for first:
#
#   * „кога е кенгуру 2027", „математическа олимпиада дати" — the date, at the
#     top, with „около" in front of it when it is last year's pattern rather
#     than a published one.
#   * „задачи от кенгуру", „подготовка за матура" — worked problems of the
#     kind the paper asks, with the answers on the page, like /matematika.
#   * „какво е …", „за кой клас е …" — the format, the grades, the organiser
#     and a link to the official page and the past papers.
#
# Then, and only then, the reason to sign up: a student can say „ще участвам",
# and the app counts down to it on their home page and builds sessions for it.
#
# Open to a signed-in visitor too — a parent following a search result should
# land on the page — and a student sees the join and practice buttons in place
# of the sign-up ones.
class CompetitionPagesController < ApplicationController
  include CompetitionsHelper

  layout "landingpage"

  def index
    @today = Time.zone.today
    @schedule = Competitions.schedule(@today)
    @competitions = Competitions.calendar(@today).select(&:competition?)
    @exams = Competitions.calendar(@today).select(&:exam?)
    @season = Competitions.season_for(@today)

    seo title: t("seo.competitions.index.title", season: @season),
        description: t("seo.competitions.index.description"),
        canonical_path: competition_calendar_path,
        indexable: true,
        schema: [ breadcrumbs(t("competitions.breadcrumb") => competition_calendar_path), item_list_schema ]
  end

  def show
    @event = Competitions.find(params[:slug]) || not_found
    # One canonical address per event: the Kangaroo is not also an exam.
    return redirect_to(event_page_path(@event), status: :moved_permanently) if request.path != event_page_path(@event)

    @today = Time.zone.today
    @next_round = @event.next_round(@today)
    @samples = Curriculum.sample_questions(elo_range: @event.elo_range, within_topics: @event.topic_ids)
    @entry = current_user.competition_entries.find_by(competition_slug: @event.slug, season: @event.season(@today)) if current_user&.student?
    @others = Competitions.upcoming(@today).reject { |other| other.slug == @event.slug }.first(4)

    seo title: event_title,
        description: event_description,
        canonical_path: event_page_path(@event),
        indexable: true,
        schema: [ event_breadcrumbs, faq_schema, *event_schemas ].compact
  end

  private

  def event_title
    key = @event.exam? ? "exam_title" : "title"
    t("seo.competitions.show.#{key}", name: @event.name.to_s, year: (@next_round || @event.rounds.last).date.year)
  end

  def event_description
    round = @next_round || @event.rounds.last
    t("seo.competitions.show.description", name: @event.name.to_s, grades: event_grades(@event),
                                          date: round_date(round))
  end

  # The questions a parent actually types about a competition, answered from
  # the same data the page renders — the guidelines refuse FAQ markup for an
  # answer that is not on the page, so the view reads these same keys.
  def faq_schema
    { "@context" => "https://schema.org", "@type" => "FAQPage",
      "mainEntity" => event_faq.map do |question, answer|
        { "@type" => "Question", "name" => question, "acceptedAnswer" => { "@type" => "Answer", "text" => answer } }
      end }
  end
  helper_method :event_faq

  def event_faq
    @event_faq ||= begin
      round = @next_round || @event.rounds.last
      name = @event.name.to_s
      [
        [ t("competitions.faq.when.q", name: name),
          t(round.approximate? ? "competitions.faq.when.a_approximate" : "competitions.faq.when.a",
            name: name, round: round.name.to_s, date: l(round.date, format: :long)) ],
        [ t("competitions.faq.who.q", name: name),
          t("competitions.faq.who.a", name: name, grades: event_grades(@event), organizer: @event.organizer) ],
        [ t("competitions.faq.format.q", name: name), @event.format.to_s ],
        [ t("competitions.faq.prepare.q", name: name), t("competitions.faq.prepare.a_#{@event.style}", name: name) ]
      ]
    end
  end

  # An Event per round whose date is published. A round dated from last year's
  # pattern is left out of the markup — a rich result showing a guessed date as
  # fact is exactly the thing the „около" on the page exists to prevent.
  def event_schemas
    @event.rounds.reject(&:approximate?).reject { |round| round.past?(@today) }.map do |round|
      {
        "@context" => "https://schema.org",
        "@type" => "Event",
        "name" => "#{@event.name} — #{round.name}",
        "startDate" => round.date.iso8601,
        "eventStatus" => "https://schema.org/EventScheduled",
        "eventAttendanceMode" => "https://schema.org/OfflineEventAttendanceMode",
        "location" => { "@type" => "Place", "name" => t("competitions.location"),
                        "address" => { "@type" => "PostalAddress", "addressCountry" => "BG" } },
        "organizer" => { "@type" => "Organization", "name" => @event.organizer, "url" => @event.url }.compact,
        "description" => @event.description.to_s,
        "url" => Seo.url(event_page_path(@event)),
        "inLanguage" => "bg"
      }
    end
  end

  def item_list_schema
    {
      "@context" => "https://schema.org",
      "@type" => "ItemList",
      "itemListElement" => Competitions.calendar(@today).each_with_index.map do |event, index|
        { "@type" => "ListItem", "position" => index + 1, "name" => event.name.to_s, "url" => Seo.url(event_page_path(event)) }
      end
    }
  end

  def event_breadcrumbs
    breadcrumbs(t("competitions.breadcrumb") => competition_calendar_path, @event.name.to_s => event_page_path(@event))
  end

  def breadcrumbs(trail)
    items = trail.each_with_index.map do |(name, path), index|
      { "@type" => "ListItem", "position" => index + 1, "name" => name, "item" => Seo.url(path) }
    end

    { "@context" => "https://schema.org", "@type" => "BreadcrumbList", "itemListElement" => items }
  end

  def not_found
    raise ActionController::RoutingError, "No such page"
  end
end
