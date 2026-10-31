# One coin: a rung (1–7) of a track (`badge_key`) reached — see Coins. `seen_at`
# is stamped once the child has been shown it.
class BadgeAward < ApplicationRecord
  belongs_to :user

  validates :badge_key, presence: true
  validates :rung, uniqueness: { scope: [ :user_id, :badge_key ] }

  def track = Coins.find(badge_key)
end
