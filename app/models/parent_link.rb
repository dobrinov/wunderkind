class ParentLink < ApplicationRecord
  belongs_to :parent, class_name: "User"
  belongs_to :child, class_name: "User"

  validates :child_id, uniqueness: { scope: :parent_id }
  validate :parent_is_a_parent
  validate :child_is_a_student

  private

  def parent_is_a_parent
    errors.add(:parent, :invalid) unless parent&.parent? || parent&.admin?
  end

  def child_is_a_student
    errors.add(:child, :invalid) unless child&.student?
  end
end
