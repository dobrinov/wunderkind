class SessionsController < ApplicationController
  layout "simple"

  def create
    user = User.find_by(email: params[:email].downcase)
    if user&.authenticate(params[:password])
      session[:user_id] = user.id

      path =
        if user.admin?
          overseer_root_path
        else
          root_path
        end

      redirect_to path, notice: "Добре дошли!"
    else
      flash.now[:alert] = "Грешен имейл или парола"
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    session[:user_id] = nil
    redirect_to root_path, notice: "Успешно излизане!"
  end
end
