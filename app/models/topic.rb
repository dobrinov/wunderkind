class Topic < ApplicationRecord
  belongs_to :parent, class_name: "Topic", optional: true
  has_many :children, class_name: "Topic", foreign_key: :parent_id, dependent: :nullify, inverse_of: :parent
  has_many :skills, dependent: :destroy
  has_many :topic_prerequisites, dependent: :destroy
  has_many :prerequisites, through: :topic_prerequisites, source: :prerequisite
  has_and_belongs_to_many :questions

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true

  before_validation :generate_slug, on: :create

  scope :roots, -> { where(parent_id: nil) }
  scope :ordered, -> { order(:position, :name) }

  private

  # Transliterated rather than parameterized: the slug is the public URL of the
  # topic's practice page, and `parameterize` folds a Cyrillic name to nothing.
  # Still unique-suffixed rather than trusted, because two topics may share a
  # name under different parents ("Площ" under Геометрия and under Стереометрия).
  def generate_slug
    self.slug ||= unique_slug(Slug.call(name) || SecureRandom.hex(4))
  end

  def unique_slug(base)
    return base unless Topic.where(slug: base).where.not(id: id).exists?

    suffix = 2
    suffix += 1 while Topic.where(slug: "#{base}-#{suffix}").where.not(id: id).exists?
    "#{base}-#{suffix}"
  end
end
