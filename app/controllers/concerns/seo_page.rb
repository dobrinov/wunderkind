# Lets a controller say what the crawler should make of the page.
#
#   seo title: "...", description: "...", canonical_path: foo_path, indexable: true
#
# Say nothing and the page is `noindex, nofollow` with the bare brand title —
# the right answer for every screen behind the login, which is most of them.
module SeoPage
  extend ActiveSupport::Concern

  included do
    helper_method :seo_page
  end

  def seo_page
    @seo_page ||= Seo.default_page
  end

  def seo(**attributes)
    @seo_page = Seo::Page.new(**Seo.default_page.to_h.merge(attributes))
  end
end
