module Overseer
  class StatsController < BaseController
    def show
      @user = User.find_by(id: params[:user_id]) if params[:user_id].present?
      @stats = AnswerStats.new(days: AnswerStats.range(params[:days]), user: @user)
    end

    # One user's day only. Everybody's misses on a busy day is a list nobody
    # would read, and the question it answers — which problems trip students
    # up — is the reports queue's and the bank's, not this page's.
    def day
      @user = User.find(params[:user_id])
      @date = AnswerStats.date(params[:date])
      return redirect_to(overseer_stats_path(user_id: @user.id)) unless @date

      @answers = AnswerStats.misses(@user, @date)
    end
  end
end
