class SessionsController < ApplicationController
  layout "simple"

  # Ten a minute from one address is already generous for a person and tight
  # for a script, which is the point. Locally it guards against nobody — the
  # browser suite signs in a dozen times a run and a developer signing in
  # repeatedly is not an attack — and a bodyless 429 is invisible to Turbo,
  # which leaves the form sitting there looking broken. So the ceiling is
  # lifted where there is nothing to protect, and unchanged where there is.
  rate_limit to: Rails.env.local? ? 1000 : 10, within: 1.minute, only: :create

  def create
    email = params[:email].to_s.strip.downcase
    user = User.find_by(email: email) if email.present?

    if user&.authenticate(params[:password])
      # A fresh session, so a stale profile switch can't outlive a sign-in.
      reset_session
      session[:user_id] = user.id

      redirect_to post_auth_path(user), notice: t("auth.welcome")
    else
      flash.now[:alert] = t("auth.wrong_credentials")
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    reset_session
    redirect_to sign_in_path, notice: t("auth.signed_out")
  end
end
