# A reward a child has earned: one period of one goal, completed.
#
# `reward` is a copy of the goal's wording rather than a reference to it,
# because the promise was made in the words that stood at the time. A parent
# who changes "an hour of Minecraft" to "an ice cream" next week has not
# changed what they owe for last week.
class GoalAward < ApplicationRecord
  belongs_to :goal

  scope :unused, -> { where(used_at: nil) }
  scope :recent_first, -> { order(earned_at: :desc) }

  def used? = used_at.present?

  def use!
    update!(used_at: Time.current) unless used?
  end
end
