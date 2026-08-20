class HomeworkQuestion < ApplicationRecord
  belongs_to :homework
  belongs_to :question

  validates :position, presence: true
end
