module Overseer
  class UsersController < BaseController
    def index
      @users = User.order(created_at: :desc).page(params[:page])
    end
  end
end
