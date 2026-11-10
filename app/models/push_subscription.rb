# A browser's push endpoint, for one person (WebPushDelivery). The keys are the
# browser's, not ours: they encrypt the payload so only that browser reads it.
class PushSubscription < ApplicationRecord
  belongs_to :user

  validates :endpoint, presence: true, length: { maximum: 2000 }, format: { with: %r{\Ahttps://\S+\z}i }
  validates :p256dh, :auth, presence: true, length: { maximum: 255 }
  validates :endpoint, uniqueness: { scope: :user_id }
end
