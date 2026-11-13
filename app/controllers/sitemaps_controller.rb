# robots.txt and sitemap.xml, served by the app rather than sat in public/.
#
# Both have to know which pages exist, and the public pages are generated from
# the topic tree and the grade ladder — a static file would go stale the first
# time a topic is added, silently, which is the worst way for a sitemap to be
# wrong. Serving them here also lets a staging host close itself to crawlers
# without a second file to remember.
class SitemapsController < ApplicationController
  CACHE_TTL = 12.hours

  def robots
    render plain: robots_body, content_type: "text/plain"
  end

  def sitemap
    @entries = Rails.cache.fetch("sitemap/entries", expires_in: CACHE_TTL) { dated(entries) }

    render formats: :xml, content_type: "application/xml"
  end

  private

  def crawlable?
    Seo.origin == Seo::DEFAULT_ORIGIN
  end

  def robots_body
    return "User-agent: *\nDisallow: /\n" unless crawlable?

    <<~ROBOTS
      User-agent: *
      Allow: /

      # Behind a login or of no use to a searcher — every one of these answers a
      # crawler with a redirect to the sign-in page, and a dozen copies of that
      # page is the entire crawl budget of a site this size.
      Disallow: /overseer
      Disallow: /sign-in
      Disallow: /sign-up
      Disallow: /password_resets
      Disallow: /verify-email
      Disallow: /profile
      Disallow: /home
      Disallow: /calendar
      Disallow: /assignments
      Disallow: /questions
      Disallow: /challenges
      Disallow: /suggestions
      Disallow: /competitions
      Disallow: /handbook
      Disallow: /leaderboard
      Disallow: /parents
      Disallow: /design-system
      Disallow: /switch-child

      # „Опитай без профил" (Trial): linked from every public page, noindex,
      # and each visit deals a fresh random set into a session — nothing a
      # search result could land on, and a query per crawler hit.
      Disallow: /opitay

      Sitemap: #{Seo.url("/sitemap.xml")}
    ROBOTS
  end

  # `content` is what the page is made from, in any form that reads the same
  # until the page changes: it is digested into the fingerprint SitemapPage
  # dates the entry by. An entry without one is dated the day it first appears.
  Entry = Struct.new(:path, :priority, :changefreq, :content, :lastmod, keyword_init: true)

  # <lastmod> for every entry (SitemapPage.stamp). The hub is made from the
  # list of pages itself, so a new page anywhere re-dates it.
  def dated(entries)
    hub = entries.find { |entry| entry.path == curriculum_path }
    hub.content = entries.map(&:path)
    dates = SitemapPage.stamp(entries.to_h { |entry| [ entry.path, Digest::SHA256.hexdigest(entry.content.inspect) ] })

    entries.each do |entry|
      entry.lastmod = dates.fetch(entry.path)
      entry.content = nil # not worth a place in the cache
    end
  end

  # The published problems behind each topic, as [count, sum of ids]: it moves
  # when a problem is imported, retired or retagged — and not when one is
  # answered, which a question's `updated_at` does.
  def bank
    @bank ||= Question.published.joins(:topics).group("topics.id").pluck(Arel.sql("topics.id, COUNT(*), SUM(questions.id)"))
                      .to_h { |id, count, sum| [ id, [ count, sum.to_i ] ] }
  end

  def entries
    [
      Entry.new(path: root_path, priority: "1.0", changefreq: "weekly"),
      Entry.new(path: curriculum_path, priority: "0.9", changefreq: "weekly"),
      Entry.new(path: curriculum_coverage_path, priority: "0.6", changefreq: "monthly"),
      *Curriculum.grades.map do |grade|
        Entry.new(path: curriculum_grade_path(grade.slug), priority: "0.8", changefreq: "weekly", content: grade_content(grade))
      end,
      *grade_entries,
      *topic_entries,
      *explainer_entries,
      *formula_entries,
      Entry.new(path: times_table_path, priority: "0.8", changefreq: "monthly"),
      *competition_entries
    ]
  end

  # The hub and every article. Monthly: an article changes when somebody
  # rewrites a sentence, not when the bank grows.
  def explainer_entries
    [
      Entry.new(path: explainers_path, priority: "0.8", changefreq: "monthly"),
      *Explainers.all.map do |article|
        Entry.new(path: explainer_path(article.slug), priority: "0.7", changefreq: "monthly",
                  content: Explainers::DIR.join("#{article.slug}.yml").read)
      end
    ]
  end

  # A grade's pages are made from its programme and the problems behind it.
  def grade_content(grade)
    [ grade.topic_names, grade.range, Curriculum.topic_ids(grade).sort.map { |id| bank[id] } ]
  end

  # Under each grade: its test, and a page for every topic the grade page
  # lists (Curriculum.topics_for already applies the programme and the
  # minimum, so nothing thin gets an address here).
  def grade_entries
    Curriculum.grades.flat_map do |grade|
      [
        (Entry.new(path: grade_test_path(grade.slug), priority: "0.7", changefreq: "monthly", content: grade_content(grade)) if Curriculum.test?(grade)),
        (Entry.new(path: curriculum_grade_worksheet_path(grade.slug), priority: "0.7", changefreq: "monthly", content: grade_content(grade)) if Curriculum.worksheet?(grade)),
        *Curriculum.topics_for(grade).flat_map do |topic, _|
          content = [ grade.range, bank[topic.id] ]
          [ Entry.new(path: curriculum_grade_topic_path(grade.slug, topic.slug), priority: "0.7", changefreq: "monthly", content: content),
            (Entry.new(path: curriculum_grade_topic_worksheet_path(grade.slug, topic.slug), priority: "0.6", changefreq: "monthly", content: content) if Curriculum.worksheet?(grade, topic: topic)) ]
        end
      ].compact
    end
  end

  # The formula hub and a sheet per grade and per exam. Monthly, like the
  # articles: a sheet changes when somebody corrects a formula.
  def formula_entries
    [
      Entry.new(path: formulas_path, priority: "0.8", changefreq: "monthly", content: Formulas.for(Formulas::ALL).map { |name, formulas| [ name, formulas.map(&:to_h) ] }),
      *Formulas::VIEWS.map do |view|
        Entry.new(path: formula_sheet_path(view.slug), priority: "0.7", changefreq: "monthly",
                  content: Formulas.for(view).map { |name, formulas| [ name, formulas.map(&:to_h) ] })
      end,
      *Calculators.all.map do |calculator|
        Entry.new(path: calculator_path(calculator.slug), priority: "0.8", changefreq: "monthly",
                  content: Calculators::DIR.join("#{calculator.slug}.yml").read)
      end
    ]
  end

  # The calendar and one page per competition and exam. Weekly, because a
  # date moves from „около" to published when the МОН calendar comes out, and
  # that is the change worth a recrawl.
  def competition_entries
    [
      Entry.new(path: competition_calendar_path, priority: "0.9", changefreq: "weekly"),
      *Competitions.dated.map do |event|
        Entry.new(path: helpers.event_page_path(event), priority: "0.8", changefreq: "weekly", content: event.to_h)
      end
    ]
  end

  # Only topics with enough published problems to be worth a visit: a sitemap
  # full of pages that say "nothing here yet" teaches Google to trust the rest
  # of it less.
  def topic_entries
    Topic.where.not(parent_id: nil).order(:position, :name).filter_map do |topic|
      next if bank.fetch(topic.id, [ 0 ]).first < Curriculum::MINIMUM_PER_TOPIC

      Entry.new(path: curriculum_topic_path(topic.slug), priority: "0.7", changefreq: "monthly", content: bank[topic.id])
    end
  end
end
