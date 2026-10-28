# A private leaderboard: a few friends, the same weekly points as everywhere
# else, visible only to its members (see Leagues). Members are shown by their
# real first name and surname initial — the people in it chose to be there
# with each other, which is the difference from the public board.
class League < ApplicationRecord
  MAX_MEMBERS = 40
  MAX_OWNED = 10
  NAME_LENGTH = 40

  belongs_to :owner, class_name: "User"
  has_many :memberships, class_name: "LeagueMembership", dependent: :delete_all
  has_many :members, through: :memberships, source: :user

  validates :name, presence: true, length: { maximum: NAME_LENGTH }
  validates :code, presence: true, uniqueness: true

  before_validation :assign_code, on: :create

  def owned_by?(user) = owner_id == user.id

  def member?(user) = memberships.exists?(user_id: user.id)

  def full? = memberships.count >= MAX_MEMBERS

  # A fresh code, for when the old one has gone further than it should. Those
  # already in stay in.
  def rotate_code!
    update!(code: self.class.unused_code)
  end

  def self.unused_code
    loop do
      code = Array.new(6) { User::LINK_CODE_ALPHABET.sample }.join
      break code unless exists?(code: code)
    end
  end

  private

  def assign_code
    self.code ||= self.class.unused_code
  end
end
