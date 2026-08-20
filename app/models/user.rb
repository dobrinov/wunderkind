class User < ApplicationRecord
  has_secure_password
  has_many :assignments, dependent: :destroy
  has_many :user_answers, dependent: :destroy
  has_many :skills, dependent: :destroy
  has_many :xp_events, dependent: :destroy
  has_many :badge_awards, dependent: :destroy
  has_many :authored_questions, class_name: "Question", foreign_key: :author_id, dependent: :nullify

  enum :role, { student: 0, teacher: 1, parent: 2, admin: 3 }, default: :student

  validates :name, presence: true
  validates :email, presence: true, uniqueness: { case_sensitive: false }, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, presence: true, length: { minimum: 6 }, if: -> { password.present? }

  def level
    Levels.level_for(total_xp)
  end

  def skill_for(topic)
    skills.find_or_create_by!(topic: topic) { |skill| skill.rating = elo }
  end
end
