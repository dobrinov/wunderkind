# What a parent has asked a child to practise: a few topics, until a target is
# reached, perhaps for a reward — „до събота упражнявай дробите, и отиваме на
# кино". While one is in play the daily session draws from those topics (see
# SessionComposer); once its target is reached it is stamped completed and the
# session quietly goes back to everything at the child's level.
#
# The same stance as Goal, for the same reason: a focus is a promise made in
# particular words, so it is never edited. Changing it archives this one and
# sets a new one (PracticeFocuses.set!), and archiving keeps the row — what was
# asked, and whether it was done, is history a parent may want to read back.
#
# Progress is not stored. It is read off the child's `skills` rows whenever
# anybody looks (PracticeFocuses.progress), and the only thing written when the
# target is reached is `completed_at`.
class PracticeFocus < ApplicationRecord
  # How many topics one focus may hold. A focus on everything is general
  # practice by a longer route, and a session spread over nine topics is not
  # focused on any of them.
  MAX_TOPICS = 5

  belongs_to :child, class_name: "User"
  belongs_to :parent, class_name: "User"
  has_many :focus_topics, class_name: "PracticeFocusTopic", dependent: :destroy, inverse_of: :practice_focus
  has_many :topics, through: :focus_topics

  # `mastery` is the app's own rule, the one that stamps skills.mastered_at
  # (AnswerSubmission::MASTERY_RATING over MASTERY_MIN_GAMES); `step` is the
  # topic's rating fifty points above where it stood when the focus was set —
  # the same step the child's own progress card counts in (StudentProgress).
  enum :target, { mastery: 0, step: 1 }

  # In play: neither finished nor replaced. At most one per child, which the
  # partial unique index on the table enforces.
  scope :active, -> { where(archived_at: nil, completed_at: nil) }
  # Still on the page: in play, or finished and not yet replaced — a finished
  # focus stays on the parent's tab until they set the next one, because „she
  # did it" is news, and the reward may still be owed.
  scope :current, -> { where(archived_at: nil) }
  scope :completed, -> { where.not(completed_at: nil) }

  validates :reward, length: { maximum: 200 }
  validate :topics_in_range
  validate :something_left_to_master, on: :create

  normalizes :reward, with: ->(reward) { reward.strip.presence }

  def active? = completed_at.nil? && archived_at.nil?
  def completed? = completed_at.present?
  def archived? = archived_at.present?

  # A reward is owed once the target is reached and until the parent says it
  # was given. Archiving a completed focus does not cancel it: the child did
  # the work.
  def reward_owed? = completed? && reward.present? && reward_given_at.nil?

  def archive!
    update!(archived_at: Time.current) unless archived?
  end

  def give_reward!
    update!(reward_given_at: Time.current) if reward_owed?
  end

  # The rating this topic stood at when the focus was set, which is what the
  # step target is measured from. A topic the child had never met starts where
  # their skill row will: at their overall rating (User#skill_for).
  def starting_rating(topic)
    starting_ratings[topic.id.to_s] || child.elo
  end

  private

  def topics_in_range
    count = focus_topics.reject(&:marked_for_destruction?).size
    errors.add(:topics, :blank) if count.zero?
    errors.add(:topics, :too_long, count: MAX_TOPICS) if count > MAX_TOPICS
  end

  # „До усвояване" on topics already mastered would be completed before the
  # child saw it, with the reward owed for nothing.
  def something_left_to_master
    return unless mastery? && focus_topics.any?

    topic_ids = focus_topics.map(&:topic_id)
    mastered = child.skills.where(topic_id: topic_ids).where.not(mastered_at: nil).count
    errors.add(:target, :already_mastered) if mastered == topic_ids.size
  end
end
