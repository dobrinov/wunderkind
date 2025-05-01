class FileAttachment < ApplicationRecord
  has_many :question_attachments, as: :attachable
  has_one_attached :file
end
