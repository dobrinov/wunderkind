class SessionsController < ApplicationController
  layout "simple"

  rate_limit to: 10, within: 1.minute, only: :create

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

      redirect_to path, notice: t("auth.welcome")
    else
      flash.now[:alert] = t("auth.wrong_credentials")
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    session[:user_id] = nil
    redirect_to sign_in_path, notice: t("auth.signed_out")
  end
end
