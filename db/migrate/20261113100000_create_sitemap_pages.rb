# When each page of the sitemap last changed (SitemapsController, SitemapPage):
# the sitemap's <lastmod>. Nothing else dates a page — most are generated from
# files and the bank, and in production every file is as old as the image.
class CreateSitemapPages < ActiveRecord::Migration[8.1]
  def change
    create_table :sitemap_pages do |t|
      t.string :path, null: false
      t.string :fingerprint, null: false
      t.date :changed_on, null: false
      t.timestamps
      t.index :path, unique: true
    end
  end
end
