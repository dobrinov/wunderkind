class ScriptAttachment < ApplicationRecord
  has_many :question_attachments, as: :attachable
end
