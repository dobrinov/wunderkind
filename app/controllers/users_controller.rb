class UsersController < ApplicationController
  layout "simple"

  rate_limit to: 5, within: 1.minute, only: :create

  def new
    @user = User.new
  end

  def create
    @user = User.new name: params[:name], email: params[:email], password: params[:password]

    if @user.save
      session[:user_id] = @user.id
      redirect_to root_path, notice: t("auth.welcome")
    else
      render :new, status: :unprocessable_entity
    end
  end
end
