# The day a public page last changed, for the sitemap's <lastmod>.
#
# A search engine reads <lastmod> only for as long as it finds it true, so the
# date cannot be the deploy's (every file in the image is as old as the image)
# and cannot be a question's `updated_at` (which moves with every answer, as
# its Elo does). Instead each sitemap entry carries a fingerprint of what its
# page is made from — an article's file, a sheet's formulas, the ids of a
# topic's published problems — and the date here moves only when that does. A
# page first seen is dated that day, which is what gets a new page crawled
# without anybody resubmitting the sitemap.
class SitemapPage < ApplicationRecord
  # Dates the given { path => fingerprint } and returns { path => Date }.
  # Rows of pages that no longer exist are left: a page that comes back with
  # the same content has not changed.
  def self.stamp(fingerprints, today: Date.current)
    known = where(path: fingerprints.keys).index_by(&:path)
    changed = fingerprints.reject { |path, fingerprint| known[path]&.fingerprint == fingerprint }

    if changed.any?
      now = Time.current
      upsert_all(
        changed.map { |path, fingerprint| { path: path, fingerprint: fingerprint, changed_on: today, created_at: now, updated_at: now } },
        unique_by: :path, update_only: %i[fingerprint changed_on]
      )
    end

    fingerprints.to_h { |path, _| [ path, changed.key?(path) ? today : known.fetch(path).changed_on ] }
  end
end
