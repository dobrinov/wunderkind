# One row per person per device that asked to be told about duel invitations
# (WebPushDelivery). A device can carry several rows — a household passes one
# tablet between children — so the endpoint is unique per user, not globally.
class CreatePushSubscriptions < ActiveRecord::Migration[8.1]
  def change
    create_table :push_subscriptions do |t|
      t.references :user, null: false, foreign_key: { on_delete: :cascade }, index: false
      t.text :endpoint, null: false
      t.string :p256dh, null: false
      t.string :auth, null: false
      t.string :user_agent
      t.timestamps
    end
    add_index :push_subscriptions, [ :user_id, :endpoint ], unique: true
    add_index :push_subscriptions, :endpoint
  end
end
