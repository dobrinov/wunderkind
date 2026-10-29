# One parent asking another grown-up into the family: „Деян те кани в
# семейството на Мая и Боян". Two ways to hand it over — a link (mailed when
# Mailing is on, otherwise copied by the inviter) or a six-character code read
# out loud — and both are the same row, so either one spends it.
#
# Accepting links the invitee as a parent of every child the inviter has *at
# that moment* (#accept!), managed or not, and from then on the two are
# equals: either can switch into a managed child (User#switchable_children),
# set goals, give rewards and invite a third. A child added later by either
# one is linked to that one only; inviting again is how it is shared.
class FamilyInvitation < ApplicationRecord
  LIFETIME = 7.days
  CODE_LENGTH = 6

  # Why an invitation could not be accepted, for the page to say so.
  class Refused < StandardError
    attr_reader :reason

    def initialize(reason)
      @reason = reason
      super(reason.to_s)
    end
  end

  belongs_to :inviter, class_name: "User"
  belongs_to :accepted_by, class_name: "User", optional: true

  has_secure_token :token, length: 32

  normalizes :email, with: ->(email) { email.strip.downcase.presence }
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_nil: true

  before_validation :assign_code, on: :create
  before_validation -> { self.expires_at ||= LIFETIME.from_now }, on: :create

  scope :pending, -> { where(accepted_at: nil, revoked_at: nil).where("expires_at > ?", Time.current) }

  # Typed by a person, so forgiving about case and stray spaces, and only ever
  # an invitation still waiting — a spent or stale code is simply not a code.
  def self.find_by_code(code)
    pending.find_by(code: code.to_s.gsub(/\s+/, "").upcase.presence)
  end

  def self.find_pending_by_token(token)
    pending.find_by(token: token.to_s)
  end

  def pending?
    accepted_at.nil? && revoked_at.nil? && expires_at.future?
  end

  def expired?
    accepted_at.nil? && revoked_at.nil? && !expires_at.future?
  end

  def days_left
    [ ((expires_at - Time.current) / 1.day).ceil, 0 ].max
  end

  # The children this invitation would bring, for the page that offers it.
  def children
    inviter.children.order(:name)
  end

  def revoke!
    update!(revoked_at: Time.current) if pending?
  end

  # Links `user` to every child the inviter has now and spends the invitation.
  #
  # Parents only — and an admin, who can be somebody's parent too. A student
  # account is refused rather than quietly promoted: a child's login turning
  # into a parent's would hand that child a parent's view of their siblings.
  # `name_for_children` is the „Как да те наричат децата?" field the accepting
  # page asks, kept only when it was filled in.
  def accept!(user, name_for_children: nil)
    raise Refused, :student unless user.parent? || user.admin?
    raise Refused, :own if user == inviter

    transaction do
      lock!
      raise Refused, :expired unless pending?

      inviter.children.each do |child|
        user.parent_links.find_or_create_by!(child: child)
      end
      update!(accepted_by: user, accepted_at: Time.current)
      user.update!(name_for_children: name_for_children.strip) if name_for_children.present?
    end
  end

  private

  def assign_code
    self.code ||= loop do
      candidate = Array.new(CODE_LENGTH) { User::LINK_CODE_ALPHABET.sample }.join
      break candidate unless FamilyInvitation.exists?(code: candidate)
    end
  end
end
