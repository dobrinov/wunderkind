module Overseer
  class StatsController < BaseController
    def show
      range = params[:days].to_i.presence_in(AnswerStats::RANGES) || AnswerStats::RANGES.first
      @user = User.find_by(id: params[:user_id]) if params[:user_id].present?
      @stats = AnswerStats.new(days: range, user: @user)
    end
  end
end
