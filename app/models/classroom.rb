class Classroom < ApplicationRecord
  # Unambiguous alphabet: no 0/O, 1/I/L — kids read these codes off a whiteboard.
  INVITE_CODE_ALPHABET = %w[2 3 4 5 6 7 8 9 A B C D E F G H J K M N P Q R S T U V W X Y Z].freeze

  belongs_to :teacher, class_name: "User"
  has_many :classroom_memberships, dependent: :destroy
  has_many :students, through: :classroom_memberships, source: :user
  has_many :homeworks, dependent: :destroy

  validates :name, presence: true
  validates :invite_code, presence: true, uniqueness: true

  before_validation :generate_invite_code, on: :create

  def self.find_by_invite_code(code)
    find_by(invite_code: code.to_s.strip.upcase)
  end

  def average_student_rating
    return 1200 if students.empty?

    (students.sum(&:elo).to_f / students.size).round
  end

  private

  def generate_invite_code
    self.invite_code ||= loop do
      code = Array.new(6) { INVITE_CODE_ALPHABET.sample }.join
      break code unless Classroom.exists?(invite_code: code)
    end
  end
end
