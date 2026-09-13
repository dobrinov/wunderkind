# Topic slugs were `SecureRandom.hex(4)`, because `parameterize` folds a
# Cyrillic name to the empty string and the old rule fell back. Nothing linked
# to a topic then. Public topic pages do, so re-slug the tree through the
# transliteration table.
class ReslugTopicsForPublicUrls < ActiveRecord::Migration[8.0]
  def up
    taken = {}

    Topic.reset_column_information
    Topic.order(:id).each do |topic|
      base = Slug.call(topic.name) || "tema-#{topic.id}"
      taken[base] = taken.fetch(base, 0) + 1
      slug = taken[base] > 1 ? "#{base}-#{taken[base]}" : base

      topic.update_column(:slug, slug)
    end
  end

  def down
    # The hex slugs carried no meaning; there is nothing to restore them to.
    raise ActiveRecord::IrreversibleMigration
  end
end
