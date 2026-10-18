module Overseer
  class UsersController < BaseController
    def index
      @users = User.includes(:managed_by).order(User.arel_table[:last_login_at].desc.nulls_last, created_at: :desc).page(params[:page])
    end
  end
end
