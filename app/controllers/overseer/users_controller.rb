module Overseer
  class UsersController < BaseController
    def index
      @users = User.includes(:managed_by).order(created_at: :desc).page(params[:page])
    end
  end
end
