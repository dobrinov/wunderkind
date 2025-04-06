class UsersController < ApplicationController
  def new
    @user = User.new
  end

  def create
    @user = User.new name: params[:name], email: params[:email], password: params[:password]

    if @user.save
      session[:user_id] = @user.id
      redirect_to root_path, notice: "Успешна регистрация!"
    else
      render :new, status: :unprocessable_entity
    end
  end
end
