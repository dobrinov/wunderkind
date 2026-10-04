class AddLastChangelogVersionToUsers < ActiveRecord::Migration[8.0]
  # The newest release this user has already been shown the notes for. NULL
  # means "has never been told anything" rather than "is caught up" — every
  # account that predates the changelog gets the backlog once, which is the
  # only honest reading when nobody was ever shown it. See Changelog.
  def change
    add_column :users, :last_changelog_version, :string
  end
end
