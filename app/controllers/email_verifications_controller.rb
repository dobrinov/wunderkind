class EmailVerificationsController < ApplicationController
  layout "simple"

  rate_limit to: 5, within: 1.minute, only: :create

  def show
    user = User.find_by_token_for(:email_verification, params[:token])

    if user
      user.verify!
      redirect_to after_verification_path(user), notice: t("verification.verified")
    else
      redirect_to sign_in_path, alert: t("verification.invalid_token")
    end
  end

  def create
    if current_user && !current_user.verified?
      UserMailer.email_verification(current_user).deliver_later
    end
    redirect_back fallback_location: root_path, notice: t("verification.sent")
  end

  private

  def after_verification_path(user)
    session[:user_id] == user.id ? root_path : sign_in_path
  end
end
