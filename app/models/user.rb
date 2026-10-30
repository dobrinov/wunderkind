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
  has_many :competition_entries, dependent: :destroy
  has_many :league_memberships, dependent: :destroy
  has_many :leagues, through: :league_memberships
  has_many :owned_leagues, class_name: "League", foreign_key: :owner_id, dependent: :destroy, inverse_of: :owner
  has_many :resolved_question_reports, class_name: "QuestionReport", foreign_key: :resolver_id, dependent: :nullify, inverse_of: :resolver

  # As a student
  has_many :child_links, class_name: "ParentLink", foreign_key: :child_id, dependent: :destroy
  has_many :parents, through: :child_links, source: :parent

  # As a parent
  has_many :parent_links, foreign_key: :parent_id, dependent: :destroy, inverse_of: :parent
  has_many :children, through: :parent_links, source: :child
  has_many :set_goals, class_name: "Goal", foreign_key: :parent_id, dependent: :destroy, inverse_of: :parent

  # As a child again: what has been asked of them, and what they have earned.
  has_many :goals, foreign_key: :child_id, dependent: :destroy, inverse_of: :child
  has_many :goal_awards, through: :goals, source: :awards
  # And what they have been asked to practise — see PracticeFocus.
  has_many :practice_focuses, foreign_key: :child_id, dependent: :destroy, inverse_of: :child
  has_many :set_practice_focuses, class_name: "PracticeFocus", foreign_key: :parent_id, dependent: :destroy, inverse_of: :parent

  # Accounts with no login of their own, and the parent who holds them. Being
  # managed is what makes switching into a profile legitimate at all; *who*
  # may switch in is every parent linked to the child (#switchable_children),
  # because two parents of one family are equals. `managed_by` only says whose
  # account the child's lives inside — the one who created it, or whoever it
  # was handed to when they left (#hand_over_managed_children).
  belongs_to :managed_by, class_name: "User", optional: true, inverse_of: :managed_children
  has_many :managed_children, class_name: "User", foreign_key: :managed_by_id, inverse_of: :managed_by
  before_destroy :hand_over_managed_children, prepend: true

  has_many :sent_family_invitations, class_name: "FamilyInvitation", foreign_key: :inviter_id,
           dependent: :delete_all, inverse_of: :inviter

  # 1 was teacher; the role was removed and its users migrated to parent, so
  # the value stays retired rather than being reused.
  enum :role, { student: 0, parent: 2, admin: 3 }, default: :student

  # Which side of the app an admin who is also a parent opens on: the one they
  # used last (remembered in a cookie — see ApplicationController#admin_home_path),
  # or always the same one. Meaningless for anybody else.
  enum :admin_landing, { last: "last", family: "family", admin: "admin" }, prefix: :opens_in

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

  # Optional, and only ever asked of a student: see SchoolGrade. The range is
  # loose on purpose — it refuses a typo, not an unusual child.
  validates :birth_year, numericality: { only_integer: true, greater_than: 1900, less_than_or_equal_to: ->(_) { Time.zone.today.year } }, allow_nil: true
  validates :grade_offset, inclusion: { in: SchoolGrade::OFFSETS.keys }

  # A new account starts caught up rather than greeted by every release it was
  # never around for. The opposite of a NULL column, which means „nobody has
  # ever told this person anything" — see Changelog.
  before_create :catch_up_on_changelog

  generates_token_for :email_verification, expires_in: 2.days do
    email
  end

  generates_token_for :password_reset, expires_in: 30.minutes do
    password_salt.last(10)
  end

  # The link in every optional email's footer (see EmailPreferences). No
  # expiry: an email read a month late must still turn that email off.
  generates_token_for :email_preferences

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
  def self.create_managed_child!(parent:, name:, email: nil, password: nil, birth_year: nil, grade_offset: 0)
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
        managed_by: parent,
        birth_year: birth_year,
        grade_offset: grade_offset
      )
      child.save!
      parent.parent_links.create!(child: child)
      child
    end
  end

  # The grade this student is probably in this school year, or nil when no
  # birth year was given — see SchoolGrade.
  def estimated_grade(on: Time.zone.today)
    SchoolGrade.estimate(birth_year, offset: grade_offset, on: on)
  end

  def managed?
    managed_by_id.present?
  end

  # The managed children this login can step into: every one linked to it
  # through parent_links, whoever created the account. The single answer for
  # the switch (ChildSessionsController), the door re-checked on every request
  # (ApplicationController#acting_child), the header's „Кой ще тренира?" and
  # the child bar — so unlinking a parent closes all four at once.
  def switchable_children
    children.where.not(managed_by_id: nil)
  end

  # Every grown-up who shares a child with this one, this one included: the
  # „Родители" card on the family page, and who may revoke whose invitation.
  def family_parents
    User.where(id: ParentLink.where(child_id: parent_links.select(:child_id)).select(:parent_id)).
      or(User.where(id: id))
  end

  # What a child calls this parent, for the lines a child reads („Мама те
  # помоли…"): the name they chose, or their first name.
  def name_for_children
    super.presence || name.to_s.split(/\s+/).first
  end

  # The managed children who would go with this account if it were deleted
  # now — the ones no other parent is linked to. Every other one is handed
  # over instead (#hand_over_managed_children); this is what an admin screen
  # deleting a parent should say it will take with it.
  def managed_children_lost_on_destroy
    managed_children.where.not(id: ParentLink.where.not(parent_id: id).select(:child_id))
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

  # The streak as a screen should show it: current_streak is only rewritten on
  # the next practice, so a child who stopped two weeks ago would otherwise
  # still read „🔥 5" until they answered something and it fell to 1. Every
  # view reads this; Streaks#record and the badge conditions, which run right
  # after a practice, read the column.
  def live_streak
    Streaks.current(self)
  end

  def skill_for(topic)
    skills.find_or_create_by!(topic: topic) { |skill| skill.rating = elo }
  end

  # Everything above the stamped version is what the dialog has left to say.
  def changelog_seen!(version)
    update!(last_changelog_version: version) if version.present?
  end

  # How long after a request a student still counts as „here".
  #
  # Generous on purpose: this is read as „is it worth inviting them", and a
  # child reading a question for three minutes has not left. Short enough that
  # a green dot is not a lie about somebody who shut the laptop.
  ONLINE_WINDOW = 5.minutes

  # One write a minute at most. Presence that cost a row update per request
  # would be the most written-to column in the app for the least information.
  PRESENCE_THROTTLE = 1.minute

  has_many :sent_friendships, class_name: "Friendship", foreign_key: :requester_id,
           dependent: :destroy, inverse_of: :requester
  has_many :received_friendships, class_name: "Friendship", foreign_key: :addressee_id,
           dependent: :destroy, inverse_of: :addressee

  def online? = last_seen_at.present? && last_seen_at > ONLINE_WINDOW.ago

  def seen!
    return if last_seen_at.present? && last_seen_at > PRESENCE_THROTTLE.ago

    # update_column, not touch: presence is not a change to the record and must
    # not bump updated_at, fire callbacks or invalidate anything that caches on
    # it. It is a side note about the browser, written on the way past.
    update_column(:last_seen_at, Time.current)
  end

  # update_column for the same reason as seen!: a sign-in is not an edit to the
  # account. See the migration that added the column for what counts as one.
  def logged_in!
    update_column(:last_login_at, Time.current)
  end

  # The friends this student actually has, each with their presence — one
  # query, because a list of friends is a list of little dots and N of them is
  # N queries for a page that is nothing else.
  def friends
    User.where(id: Friendship.accepted.involving(self).select(
      Arel.sql("CASE WHEN requester_id = #{id.to_i} THEN addressee_id ELSE requester_id END")
    ))
  end

  # How a friends' league shows this person: the first name and the first
  # letter of the surname, „Никола П.“ — enough for children who know each
  # other, short of a full name on a list a code can be passed around to.
  def short_name
    first, last = name.to_s.split(/\s+/, 2)
    last.present? ? "#{first} #{last.first}." : first.to_s
  end

  # A child whose account lives inside a parent's joins a league when the
  # parent has said so (Parents::LeaguePermissionsController) — or, until the
  # parent says anything, when the child has a login of their own: a child old
  # enough for an email and a password decides like any other student, unless
  # the parent switches it off. Every other student decides for themselves.
  def may_join_leagues?
    student? && (!managed? || leagues_on?)
  end

  # A parent's PIN for leaving a child's profile on a shared tablet — to a
  # sibling's, or back to the parent's own area — so a bored seven-year-old
  # cannot step into a brother's account or switch on their own leagues
  # (ChildSessionsController). Handing the tablet *to* a child never asks.
  PIN_FORMAT = /\A\d{4,6}\z/

  def profile_pin? = profile_pin_digest.present?

  def profile_pin=(pin)
    self.profile_pin_digest = pin.present? ? BCrypt::Password.create(pin.to_s) : nil
  end

  def profile_pin_matches?(pin)
    profile_pin? && pin.present? && BCrypt::Password.new(profile_pin_digest).is_password?(pin.to_s)
  end

  def leagues_on?
    leagues_allowed.nil? ? email.present? : leagues_allowed
  end

  def friends_with?(other) = Friendship.accepted.pick_between(self, other).present?

  # Short code another student types to become this one's friend. Separate from
  # link_code, and that is not tidiness: link_code makes the person who types
  # it a *parent* of this account, with a parent's view of everything. A child
  # handing a friend code to a classmate must not be handing that over.
  def ensure_friend_code!
    return friend_code if friend_code.present?

    update!(friend_code: loop do
      code = Array.new(6) { LINK_CODE_ALPHABET.sample }.join
      break code unless User.exists?(friend_code: code)
    end)
    friend_code
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

  private

  # A managed child outlives the parent who created it while another parent is
  # linked: the account passes to the one linked longest, and with it the
  # goals and focuses this parent set for children who still have someone —
  # a promise to a child does not lapse because one grown-up left. Only a
  # child left with no parent at all is deleted, since nobody could reach it.
  def hand_over_managed_children
    heir_for = lambda do |child|
      ParentLink.where(child_id: child.id).where.not(parent_id: id).order(:created_at, :id).first&.parent
    end

    managed_children.each do |child|
      heir = heir_for.call(child)
      heir ? child.update_columns(managed_by_id: heir.id) : child.destroy!
    end

    [ set_goals, set_practice_focuses ].each do |promises|
      promises.includes(:child).group_by(&:child).each do |child, rows|
        heir = heir_for.call(child)
        promises.where(id: rows.map(&:id)).update_all(parent_id: heir.id) if heir
      end
    end
  end

  def catch_up_on_changelog
    self.last_changelog_version ||= Changelog.current_version
  end
end
