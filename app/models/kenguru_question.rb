class KenguruQuestion < ApplicationRecord
  has_many :kenguru_answers, dependent: :destroy
  has_one :question, as: :questionable, dependent: :destroy
end
