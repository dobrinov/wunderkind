class User < ApplicationRecord
  LINK_CODE_ALPHABET = Classroom::INVITE_CODE_ALPHABET

  has_secure_password
  has_many :assignments, dependent: :destroy
  has_many :user_answers, dependent: :destroy
  has_many :skills, dependent: :destroy
  has_many :xp_events, dependent: :destroy
  has_many :badge_awards, dependent: :destroy
  has_many :authored_questions, class_name: "Question", foreign_key: :author_id, dependent: :nullify

  # As a teacher
  has_many :classrooms, foreign_key: :teacher_id, dependent: :destroy, inverse_of: :teacher

  # As a student
  has_many :classroom_memberships, dependent: :destroy
  has_many :joined_classrooms, through: :classroom_memberships, source: :classroom
  has_many :child_links, class_name: "ParentLink", foreign_key: :child_id, dependent: :destroy
  has_many :parents, through: :child_links, source: :parent

  # As a parent
  has_many :parent_links, foreign_key: :parent_id, dependent: :destroy, inverse_of: :parent
  has_many :children, through: :parent_links, source: :child

  enum :role, { student: 0, teacher: 1, parent: 2, admin: 3 }, default: :student

  validates :name, presence: true
  validates :email, presence: true, uniqueness: { case_sensitive: false }, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, presence: true, length: { minimum: 6 }, if: -> { password.present? }

  generates_token_for :email_verification, expires_in: 2.days do
    email
  end

  generates_token_for :password_reset, expires_in: 30.minutes do
    password_salt.last(10)
  end

  def verified?
    verified_at.present?
  end

  def verify!
    update!(verified_at: Time.current) unless verified?
  end

  def level
    Levels.level_for(total_xp)
  end

  def skill_for(topic)
    skills.find_or_create_by!(topic: topic) { |skill| skill.rating = elo }
  end

  # Short code a parent types to link to this student's account.
  def ensure_link_code!
    return link_code if link_code.present?

    update!(link_code: loop do
      code = Array.new(6) { LINK_CODE_ALPHABET.sample }.join
      break code unless User.exists?(link_code: code)
    end)
    link_code
  end
end
