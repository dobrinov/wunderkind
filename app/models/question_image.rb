class QuestionImage < ApplicationRecord
  has_many :questions, as: :attachable
  has_one_attached :file
end
