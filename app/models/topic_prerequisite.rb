class TopicPrerequisite < ApplicationRecord
  belongs_to :topic
  belongs_to :prerequisite, class_name: "Topic"

  validates :prerequisite_id, uniqueness: { scope: :topic_id }
  validate :not_self_referential

  private

  def not_self_referential
    errors.add(:prerequisite, :invalid) if topic_id == prerequisite_id
  end
end
