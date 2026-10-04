# What the app tells a returning user has changed since they were last here.
#
# The whole mechanism is one column and one file. `users.last_changelog_version`
# holds the newest version that user has already been *shown*; everything in
# config/changelog.yml above it is unseen, and the dialog lists it. Pressing
# „Разбрах" stamps the column with the newest version there is, so the dialog
# is answered once per release rather than once per entry.
#
# Three things worth being explicit about:
#
# * **A new account starts caught up.** `User` stamps `current_version` on
#   create, so a child signing up today is not greeted by a wall of releases
#   they were never around for. An account that predates this file has NULL,
#   which deliberately means the opposite — tell them everything, because
#   nobody has ever told them anything.
#
# * **Versions are compared, not counted.** Gem::Version, so "1.10.0" is newer
#   than "1.9.0" rather than alphabetically older, and a column holding a
#   version that has since been deleted from the file still resolves to "show
#   me what is above it" instead of to an index that no longer exists.
#
# * **The file is the only source.** No table, no admin screen, no seeds. A
#   release note is written in the same change that ships the thing it
#   describes, reviewed in the same diff, and deployed with it — which is the
#   only arrangement under which the two cannot drift apart.
module Changelog
  PATH = Rails.root.join("config/changelog.yml")

  Entry = Struct.new(:version, :date, :titles, :item_lists, keyword_init: true) do
    def title = localized(titles)
    def items = localized(item_lists)

    # The current locale, else Bulgarian — the app's default, and the locale
    # every entry is certain to have been written in. A half-translated release
    # should still be announced in the language it was written in rather than
    # leaving a blank card.
    def localized(by_locale)
      by_locale[I18n.locale.to_s] || by_locale[I18n.default_locale.to_s] || []
    end
  end

  module_function

  # Newest first — the order both the dialog and the page read in.
  def entries
    load_entries.reverse
  end

  def current_version
    load_entries.last&.version
  end

  # Everything the user has not been shown, newest first. A user with no
  # version stamped has been shown nothing, which is not the same as having
  # been shown everything: see the note above.
  def unseen_for(user)
    return [] if user.nil?

    seen = user.last_changelog_version
    return entries if seen.blank?

    entries.select { |entry| newer?(entry.version, seen) }
  end

  def newer?(version, than)
    Gem::Version.new(version) > Gem::Version.new(than)
  rescue ArgumentError
    # A column holding something that is not a version at all (hand-edited, or
    # written by a future scheme) must not take the dialog down with it. Treat
    # it as "no idea what they have seen" and say nothing, which is the quiet
    # failure rather than the loud one.
    false
  end

  # Parsed once per process in production, and on every call in development so
  # that editing the file shows up on reload like a view does.
  def load_entries
    return @entries if defined?(@entries) && @entries && !Rails.env.development?

    @entries = parse
  end

  # config/changelog.yml is written by hand, and this is read on every
  # authenticated page render and inside User's before_create. A missing
  # `items:` or a version that is not a dotted number must therefore cost a
  # release note and nothing else — raising here would take sign-up and every
  # signed-in page down together over a typo in a sentence addressed to
  # children. The spec asserts the file is non-empty, so a malformed one still
  # fails loudly in CI, which is where it should fail.
  def parse
    read
  rescue StandardError => error
    Rails.error.report(error, handled: true, source: "changelog")
    []
  end

  def read
    YAML.safe_load_file(PATH, permitted_classes: [ Date ]).map do |row|
      Entry.new(
        version: row.fetch("version").to_s,
        date: row.fetch("date"),
        titles: row.fetch("title"),
        item_lists: row.fetch("items")
      )
    end.sort_by { |entry| Gem::Version.new(entry.version) }
  end
end
