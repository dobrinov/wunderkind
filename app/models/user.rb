class User < ApplicationRecord
  has_secure_password
  has_many :assignments, dependent: :destroy
  has_many :user_answers, dependent: :destroy

  validates :name, presence: true
  validates :email, presence: true, uniqueness: { case_sensitive: false }, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, presence: true, length: { minimum: 6 }, if: -> { password.present? }
end
