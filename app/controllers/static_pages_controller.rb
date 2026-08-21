class StaticPagesController < ApplicationController
  layout "landingpage"

  # The bank size is the one figure on the landing page that is not a constant,
  # and it is the one visitors care about most. Cached for a day and floored to a
  # round hundred: the exact count changes with every import and "19 500 задачи"
  # is no less true than 19 543.
  BANK_CACHE_TTL = 1.day
  BANK_MINIMUM = 500

  def landingpage
    return redirect_to home_path_for(current_user) if current_user

    @bank_size = bank_size
  end

  private

  def bank_size
    size = Rails.cache.fetch("landing/bank_size", expires_in: BANK_CACHE_TTL) do
      Question.published.count
    end

    size >= BANK_MINIMUM ? size - (size % 100) : nil
  rescue ActiveRecord::StatementInvalid
    # A landing page that 500s because a migration is mid-flight is worse than a
    # landing page missing one number.
    nil
  end
end
