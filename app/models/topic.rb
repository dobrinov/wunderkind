# A topic of the curriculum tree. The tree is two levels deep on purpose: the
# roots are areas („Геометрия"), which group, and the leaves are topics
# („Площ"), which carry the questions, the skills, the prerequisites and the
# public page. The validations below keep it that shape.
class Topic < ApplicationRecord
  belongs_to :parent, class_name: "Topic", optional: true
  has_many :children, class_name: "Topic", foreign_key: :parent_id, dependent: :nullify, inverse_of: :parent
  has_many :skills, dependent: :destroy
  has_many :topic_prerequisites, dependent: :destroy
  has_many :unlocking_links, class_name: "TopicPrerequisite", foreign_key: :prerequisite_id, dependent: :destroy, inverse_of: :prerequisite
  has_many :practice_focus_topics, dependent: :destroy
  # Only areas are duel categories, and an area is deleted only once it is
  # empty; a finished duel that was „about" it then reads as having been about
  # anything, which is what an empty category list means.
  has_many :challenge_topics, dependent: :delete_all
  has_many :prerequisites, through: :topic_prerequisites, source: :prerequisite
  has_many :unlocks, through: :unlocking_links, source: :topic
  has_and_belongs_to_many :questions

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true
  # The tree's shape is the editor's to keep (`save(context: :editor)`), not
  # every caller's: the importer only ever builds two levels, and code that
  # walks the tree (PracticeFocuses.session_topic_groups) still copes with a
  # third.
  validate :parent_is_an_area, on: :editor
  validate :area_keeps_its_topics, on: :editor, if: :parent_id_changed?
  validate :topic_keeps_its_questions, on: :editor, if: :parent_id_changed?
  validate :prerequisites_without_cycle, unless: -> { @pending_prerequisite_ids.nil? }

  # Not `on: :create`/`on: :update`: those name the validation context, and the
  # editor saves in its own.
  before_validation :generate_slug, if: :new_record?
  before_validation :follow_name, if: -> { persisted? && name_changed? }
  after_save :write_pending_prerequisites

  scope :roots, -> { where(parent_id: nil) }
  scope :leaves, -> { where.not(parent_id: nil) }
  scope :ordered, -> { order(:position, :name) }

  # The topic whose public page used to live at this slug, for the 301.
  def self.find_by_previous_slug(slug)
    where("previous_slugs @> ARRAY[?]::varchar[]", slug.to_s).first
  end

  def area? = parent_id.nil?
  def leaf? = !area?

  # The editor's prerequisites, set as a whole and written only once the topic
  # itself saves. Assigning `prerequisite_ids=` on a saved record inserts the
  # join rows on the spot, before any validation could refuse a cycle.
  def pending_prerequisite_ids=(ids)
    @pending_prerequisite_ids = Array(ids).compact_blank.map(&:to_i).uniq
  end

  def pending_prerequisite_ids
    @pending_prerequisite_ids || prerequisite_ids
  end

  private

  def parent_is_an_area
    return if parent.nil?

    errors.add(:parent_id, :not_an_area) if parent == self || parent.parent_id.present?
  end

  def area_keeps_its_topics
    errors.add(:parent_id, :area_has_topics, count: children.count) if parent_id.present? && persisted? && children.exists?
  end

  def topic_keeps_its_questions
    errors.add(:parent_id, :topic_has_questions, count: questions.count) if parent_id.nil? && persisted? && questions.exists?
  end

  # A prerequisite that (however indirectly) requires this topic would make a
  # loop no student can enter: the frontier opens a topic once its
  # prerequisites are done, and in a loop each is waiting on the other.
  def prerequisites_without_cycle
    blocked = TopicPrerequisite.blocked_for(self)

    @pending_prerequisite_ids.each do |id|
      next unless blocked.key?(id)

      errors.add(:pending_prerequisite_ids, :cycle, topic: Topic.find_by(id: id)&.name, through: blocked[id].map { |name| "„#{name}“" }.join(" → "))
    end
  end

  def write_pending_prerequisites
    return if @pending_prerequisite_ids.nil?

    ids = @pending_prerequisite_ids
    @pending_prerequisite_ids = nil
    topic_prerequisites.where.not(prerequisite_id: ids).destroy_all
    (ids - topic_prerequisites.pluck(:prerequisite_id)).each { |id| topic_prerequisites.create!(prerequisite_id: id) }
    association(:prerequisites).reset
  end

  # Transliterated rather than parameterized: the slug is the public URL of the
  # topic's practice page, and `parameterize` folds a Cyrillic name to nothing.
  # Still unique-suffixed rather than trusted, because two topics may share a
  # name under different parents ("Площ" under Геометрия and under Стереометрия).
  def generate_slug
    self.slug ||= unique_slug(Slug.call(name) || SecureRandom.hex(4))
  end

  # A renamed topic's page moves with its name — /tema/drobi for „Дроби" was
  # the whole point of transliterating — and the address it leaves keeps
  # working through `previous_slugs`. Renaming back simply takes the old
  # address up again.
  def follow_name
    candidate = Slug.call(name)
    return if candidate.nil? || slug == candidate || slug.match?(/\A#{Regexp.escape(candidate)}-\d+\z/)

    fresh = unique_slug(candidate)
    self.previous_slugs = (previous_slugs + [ slug ]).uniq - [ fresh ]
    self.slug = fresh
  end

  # Taken neither by another topic's current address nor by one it used to
  # have, so an address once handed out keeps pointing where it did.
  def unique_slug(base)
    return base unless slug_taken?(base)

    suffix = 2
    suffix += 1 while slug_taken?("#{base}-#{suffix}")
    "#{base}-#{suffix}"
  end

  def slug_taken?(candidate)
    others = Topic.where.not(id: id)
    others.where(slug: candidate).exists? || others.where("previous_slugs @> ARRAY[?]::varchar[]", candidate).exists?
  end
end
