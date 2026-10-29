# The addresses a topic's public page used to have. A slug comes from the
# topic's name, so renaming a topic (or merging one into another) moves its page
# — and a moved page whose old address 404s loses whatever a search engine and
# a parent's bookmark had learned about it. CurriculumController answers an old
# slug with a 301 to the current one.
#
# An array on the row rather than a table of its own: a topic is renamed a
# handful of times in its life, and the only question ever asked of the list is
# "which topic used to be called this".
class AddPreviousSlugsToTopics < ActiveRecord::Migration[8.1]
  def change
    add_column :topics, :previous_slugs, :string, array: true, null: false, default: []
    add_index :topics, :previous_slugs, using: :gin
  end
end
