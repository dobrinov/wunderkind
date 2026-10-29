module Overseer
  class UsersController < BaseController
    def index
      @users = User.includes(:managed_by).order(User.arel_table[:last_login_at].desc.nulls_last, created_at: :desc).page(params[:page])
    end

    # Filled in by the users redesign; until then the person's statistics are
    # the closest thing to a page about them.
    def show
      redirect_to overseer_stats_path(user_id: User.find(params[:id]).id)
    end
  end
end
