class Topic < ApplicationRecord
  belongs_to :parent, class_name: "Topic", optional: true
  has_many :children, class_name: "Topic", foreign_key: :parent_id, dependent: :nullify, inverse_of: :parent
  has_many :skills, dependent: :destroy
  has_and_belongs_to_many :questions

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true

  before_validation :generate_slug, on: :create

  scope :roots, -> { where(parent_id: nil) }
  scope :ordered, -> { order(:position, :name) }

  private

  def generate_slug
    self.slug ||= name.to_s.parameterize(separator: "-").presence || SecureRandom.hex(4)
  end
end
