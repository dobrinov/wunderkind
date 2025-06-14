module Overseer
  class UsersController < ApplicationController
    def index
      @users = User.order(created_at: :desc).page(params[:page])
    end
  end
end
