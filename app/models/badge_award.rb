class BadgeAward < ApplicationRecord
  belongs_to :user

  validates :badge_key, presence: true, uniqueness: { scope: :user_id }

  def badge
    Badges.find(badge_key)
  end
end
