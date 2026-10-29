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
      user.logged_in!
      # After reset_session, or the flash the event rides on goes with it.
      track :login, role: user.role, via: "password"

      redirect_to invitation_return_path || post_auth_path(user), notice: t("auth.welcome")
    else
      flash.now[:alert] = t("auth.wrong_credentials")
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    reset_session
    redirect_to sign_in_path, notice: t("auth.signed_out")
  end

  private

  # „Влез и приеми" on a family invitation sends its token through the form,
  # and signing in returns to that invitation to accept it. Only a token that
  # is a pending invitation counts, so the parameter cannot send a sign-in
  # anywhere else.
  def invitation_return_path
    token = params[:invitation].presence
    family_invitation_path(token) if token && FamilyInvitation.find_pending_by_token(token)
  end
end
