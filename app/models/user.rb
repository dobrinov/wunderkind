class User < ApplicationRecord
  # Unambiguous alphabet: no 0/O, 1/I/L — a child reads this code out loud.
  LINK_CODE_ALPHABET = %w[2 3 4 5 6 7 8 9 A B C D E F G H J K M N P Q R S T U V W X Y Z].freeze

  has_secure_password
  has_many :assignments, dependent: :destroy
  has_many :user_answers, dependent: :destroy
  has_many :skills, dependent: :destroy
  has_many :xp_events, dependent: :destroy
  has_many :badge_awards, dependent: :destroy
  has_many :challenge_participations, class_name: "ChallengeParticipant", dependent: :destroy
  has_many :challenges, through: :challenge_participations
  has_many :won_challenges, class_name: "Challenge", foreign_key: :winner_id, dependent: :nullify, inverse_of: :winner
  has_many :authored_questions, class_name: "Question", foreign_key: :author_id, dependent: :nullify
  has_many :question_reports, dependent: :destroy
  has_many :resolved_question_reports, class_name: "QuestionReport", foreign_key: :resolver_id, dependent: :nullify, inverse_of: :resolver

  # As a student
  has_many :child_links, class_name: "ParentLink", foreign_key: :child_id, dependent: :destroy
  has_many :parents, through: :child_links, source: :parent

  # As a parent
  has_many :parent_links, foreign_key: :parent_id, dependent: :destroy, inverse_of: :parent
  has_many :children, through: :parent_links, source: :child

  # Accounts this one created and holds the only door to. Linking to a child by
  # their code (`child_links`) says "let me watch this student"; managing one
  # says "this student has no login of their own", which is what makes
  # switching into the profile legitimate.
  belongs_to :managed_by, class_name: "User", optional: true, inverse_of: :managed_children
  has_many :managed_children, class_name: "User", foreign_key: :managed_by_id, dependent: :destroy, inverse_of: :managed_by

  # 1 was teacher; the role was removed and its users migrated to parent, so
  # the value stays retired rather than being reused.
  enum :role, { student: 0, parent: 2, admin: 3 }, default: :student

  normalizes :email, with: ->(email) { email.strip.presence }

  validates :name, presence: true
  # Everyone who signs in for themselves needs an address to sign in with. A
  # managed child does not sign in at all, so there is nothing to require and
  # nothing to verify.
  validates :email, presence: true, unless: :managed?
  validates :email, uniqueness: { case_sensitive: false }, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_nil: true
  # Named because the profile's change-password form has to say the number out
  # loud before the validation gets a chance to.
  MINIMUM_PASSWORD_LENGTH = 6

  validates :password, presence: true, length: { minimum: MINIMUM_PASSWORD_LENGTH }, if: -> { password.present? }

  generates_token_for :email_verification, expires_in: 2.days do
    email
  end

  generates_token_for :password_reset, expires_in: 30.minutes do
    password_salt.last(10)
  end

  # A new student has no rating we can trust and no school grade to borrow one
  # from, so they start near the bottom of the bank and Dispatcher's
  # calibration ladder carries them up — usually within a session or two.
  # Explicit rather than a callback so that a caller who knows the rating (a
  # transfer, a fixture, a test) simply passes it.
  def self.new_student(attributes)
    new(attributes.reverse_merge(elo: Dispatcher.starting_rating))
  end

  # A child account that lives inside a parent's: created by them, reached by
  # switching profiles there.
  def self.create_managed_child!(parent:, name:, email: nil, password: nil)
    # No email means no sign-in form to type a password into, so a random one
    # fills the column. With an email the parent picks the password and the
    # child can sign in for themselves as well as be switched into.
    password = SecureRandom.base58(24) if email.blank?

    transaction do
      child = new_student(
        name: name,
        email: email,
        password: password,
        role: :student,
        managed_by: parent
      )
      child.save!
      parent.parent_links.create!(child: child)
      child
    end
  end

  def managed?
    managed_by_id.present?
  end

  # No mail means no confirmation to answer, so an account counts as verified
  # whatever the column holds. The switch reads here rather than at each gate
  # because `verified?` is the one question all of them ask: the notice, the
  # resend button and both base controllers go quiet together.
  def verified?
    !Mailing.enabled? || verified_at.present?
  end

  # Stamps the column, not `verified?` — a link from before the switch flipped
  # should still record that the address answered.
  def verify!
    update!(verified_at: Time.current) if verified_at.nil?
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
