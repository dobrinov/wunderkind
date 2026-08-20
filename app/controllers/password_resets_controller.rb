class PasswordResetsController < ApplicationController
  layout "simple"

  rate_limit to: 5, within: 1.minute, only: :create

  def new
  end

  def create
    if (user = User.find_by(email: params[:email].to_s.downcase))
      UserMailer.password_reset(user).deliver_later
    end

    # The same response either way, so the form can't be used to probe emails.
    redirect_to sign_in_path, notice: t("password_reset.sent")
  end

  def edit
    @user = user_from_token
    redirect_to new_password_reset_path, alert: t("password_reset.invalid_token") if @user.nil?
  end

  def update
    @user = user_from_token
    return redirect_to new_password_reset_path, alert: t("password_reset.invalid_token") if @user.nil?

    if @user.update(password: params[:password])
      redirect_to sign_in_path, notice: t("password_reset.done")
    else
      flash.now[:alert] = @user.errors.full_messages.join(", ")
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def user_from_token
    User.find_by_token_for(:password_reset, params[:token])
  end
end
