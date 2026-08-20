class AiUsage < ApplicationRecord
  def self.current
    find_or_create_by!(month: Date.current.beginning_of_month)
  end
end
