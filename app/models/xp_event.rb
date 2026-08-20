class XpEvent < ApplicationRecord
  belongs_to :user
  belongs_to :source, polymorphic: true, optional: true

  validates :amount, presence: true
  validates :reason, presence: true
end
