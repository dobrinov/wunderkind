# Everything a crawler, a link preview and a sitemap read about a page.
#
# The app is almost entirely behind a login, so the default here is the strict
# one: a page is `noindex` until it says otherwise. That is not caution about
# leaking — the authenticated pages are unreachable without a session anyway —
# it is about what Google is left holding when it follows /calendar and gets a
# redirect to /sign-in. A dozen thin near-duplicate sign-in pages in the index
# is the whole of what a site like this one gets crawled for, and it crowds out
# the pages that are actually meant to rank.
#
# Public pages declare themselves with `seo ..., indexable: true` in the
# controller. There is exactly one origin (no www/bare or http/https pair), so
# every canonical, Open Graph URL and sitemap entry is built from `Seo.origin`.
module Seo
  module_function

  DEFAULT_ORIGIN = "https://wunderkind.bg".freeze

  # A title longer than this is truncated in the result, and a description
  # longer than that is. Neither is a ranking factor; both decide whether the
  # parent who saw the result clicks it.
  TITLE_LIMIT = 60
  DESCRIPTION_LIMIT = 158

  Page = Struct.new(:title, :description, :canonical_path, :indexable, :image_path, :schema, keyword_init: true) do
    def indexable? = !!indexable
    def canonical_url = canonical_path && Seo.url(canonical_path)
    def image_url = Seo.url(image_path || Seo::CARD_PATH)

    # "Задачи по математика за 3. клас | Wunderkind" — the brand goes last
    # because the result page truncates from the right and the keywords are
    # what the parent is scanning for.
    def full_title
      return I18n.t("seo.brand_title") if title.blank?

      "#{title} | #{I18n.t("app_name")}"
    end

    def robots
      return "noindex, nofollow" unless indexable?

      # max-snippet/max-image-preview are what let Google show the full
      # description and the card image rather than a clipped line.
      "index, follow, max-snippet:-1, max-image-preview:large, max-video-preview:-1"
    end
  end

  # The 1200x630 sharing card. Bulgarian parents pass links around in Viber and
  # Facebook groups far more than they tweet them, and both render og:image.
  CARD_PATH = "/og-card.png".freeze

  def origin
    ENV.fetch("APP_ORIGIN", DEFAULT_ORIGIN)
  end

  def url(path)
    return origin if path.blank? || path == "/"

    URI.join("#{origin}/", path.to_s.delete_prefix("/")).to_s
  end

  # The default every page starts from, and what an authenticated page keeps.
  def default_page
    Page.new(title: nil, description: nil, canonical_path: nil, indexable: false)
  end

  # Site-wide JSON-LD, emitted once on every indexable page: who publishes this
  # and what the site is called. `alternateName` is there because the brand is
  # typed both ways — "Wunderkind" and "Вундеркинд" — and only one of them is
  # on the page.
  def site_schema
    {
      "@context" => "https://schema.org",
      "@graph" => [
        {
          "@type" => "EducationalOrganization",
          "@id" => "#{origin}/#organization",
          "name" => I18n.t("app_name"),
          "alternateName" => I18n.t("seo.alternate_name"),
          "url" => origin,
          "logo" => url("/icon.png"),
          "description" => I18n.t("seo.organization_description"),
          "areaServed" => { "@type" => "Country", "name" => "Bulgaria" },
          "inLanguage" => "bg"
        },
        {
          "@type" => "WebSite",
          "@id" => "#{origin}/#website",
          "url" => origin,
          "name" => I18n.t("app_name"),
          "inLanguage" => "bg",
          "publisher" => { "@id" => "#{origin}/#organization" }
        }
      ]
    }
  end
end
