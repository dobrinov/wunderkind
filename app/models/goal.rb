# Something a parent has asked of a child, and what they promised for it.
#
# The example that shaped the model: "fifteen minutes a day for a week, and you
# get an hour of Minecraft at the weekend." Three things come out of that
# sentence and each is a column — what is being counted (`metric`), whether it
# is counted a day at a time or added up (`mode`), and how often the whole
# thing comes round again (`period`).
#
# `mode: :daily` is the shape that sentence actually has: a bar to clear each
# day (`threshold`) and a number of days to clear it on (`target`). Target is a
# *count of days* and not "every day" on purpose — a goal a child loses for one
# bad Tuesday is a goal they stop trying for on Wednesday. A parent who means
# every day sets seven.
class Goal < ApplicationRecord
  belongs_to :parent, class_name: "User"
  belongs_to :child, class_name: "User"
  has_many :awards, class_name: "GoalAward", dependent: :destroy

  # What is counted. All three read the *effort* scopes rather than the
  # measured ones — a mistakes session is real work a child did, and a parent
  # promising a reward for practice means practice.
  enum :metric, { minutes: 0, problems: 1, correct: 2 }

  # Whether the target is days-that-counted or a running total.
  enum :mode, { daily: 0, total: 1 }

  # How often it comes round. A weekly goal is a standing arrangement that
  # earns its reward again every week, which is what a parent saying "weekly"
  # means; `once` is a single window with an end date.
  enum :period, { week: 0, month: 1, once: 2 }

  scope :active, -> { where(archived_at: nil) }

  validates :target, numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: 1000 }
  validates :threshold, numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: 1000 }, if: :daily?
  validates :reward, presence: true, length: { maximum: 200 }
  validates :ends_on, presence: true, if: :once?
  validate :ends_after_it_starts
  validate :days_fit_the_period

  def archived? = archived_at.present?

  def archive!
    update!(archived_at: Time.current)
  end

  private

  def ends_after_it_starts
    return if ends_on.nil? || starts_on.nil? || ends_on >= starts_on

    errors.add(:ends_on, :greater_than_or_equal_to)
  end

  # „20 дни в седмицата" is not a goal, it is a typo. Checked here rather than
  # left to produce a target nobody can ever reach.
  def days_fit_the_period
    return unless daily? && target.present?

    limit = Goals.period_length(self)
    errors.add(:target, :less_than_or_equal_to) if limit && target > limit
  end
end
