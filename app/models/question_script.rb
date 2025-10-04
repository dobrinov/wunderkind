class QuestionScript < ApplicationRecord
  has_many :questions, as: :attachable
end
