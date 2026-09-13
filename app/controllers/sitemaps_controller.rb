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
    @entries = Rails.cache.fetch("sitemap/entries", expires_in: CACHE_TTL) { entries }

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
      Disallow: /calendar
      Disallow: /assignments
      Disallow: /questions
      Disallow: /challenges
      Disallow: /suggestions
      Disallow: /leaderboard
      Disallow: /parents
      Disallow: /design-system
      Disallow: /switch-child

      Sitemap: #{Seo.url("/sitemap.xml")}
    ROBOTS
  end

  Entry = Struct.new(:path, :priority, :changefreq, keyword_init: true)

  def entries
    [
      Entry.new(path: root_path, priority: "1.0", changefreq: "weekly"),
      Entry.new(path: curriculum_path, priority: "0.9", changefreq: "weekly"),
      *Curriculum.grades.map { |grade| Entry.new(path: curriculum_grade_path(grade.slug), priority: "0.8", changefreq: "weekly") },
      *topic_entries
    ]
  end

  # Only topics with enough published problems to be worth a visit: a sitemap
  # full of pages that say "nothing here yet" teaches Google to trust the rest
  # of it less.
  def topic_entries
    counts = Question.published.joins(:topics).group("topics.id").count

    Topic.where.not(parent_id: nil).order(:position, :name).filter_map do |topic|
      next if counts.fetch(topic.id, 0) < Curriculum::MINIMUM_PER_TOPIC

      Entry.new(path: curriculum_topic_path(topic.slug), priority: "0.7", changefreq: "monthly")
    end
  end
end
