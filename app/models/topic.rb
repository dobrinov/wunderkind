class Topic < ApplicationRecord
  belongs_to :parent, class_name: "Topic", optional: true
  has_and_belongs_to_many :questions
end
