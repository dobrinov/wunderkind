class QuestionAttachment < ApplicationRecord
  has_one :question
  belongs_to :attachable, polymorphic: true
end
