# Changing your own password from inside the app, where you are already signed
# in and so have already proved who you are once.
#
# It is the only door a forgotten password has while `Mailing` is off and
# `PasswordResetsController` with it, and that cuts both ways: it must not
# become a way to take over an account from a screen its owner walked away
# from — hence the current password — and a typo in the new one would be
# unrecoverable, hence the confirmation. Both are checked here rather than
# left to the model, which has no opinion about either.
class PasswordsController < AuthenticatedController
  before_action :require_own_account

  rate_limit to: 10, within: 1.minute, only: :update

  def update
    user = signed_in_user
    password = params[:password].to_s

    if !user.authenticate(params[:current_password].to_s)
      fail_with t("profile_password.wrong_current")
    elsif password.empty?
      fail_with t("profile_password.blank")
    elsif password.length < User::MINIMUM_PASSWORD_LENGTH
      fail_with t("profile_password.too_short", count: User::MINIMUM_PASSWORD_LENGTH)
    elsif password != params[:password_confirmation].to_s
      fail_with t("profile_password.mismatch")
    elsif user.update(password: password)
      # The credential changed, so the session id changes with it, and this
      # request's own session is signed straight back in. `reset_session`
      # would drop an open child profile too — there cannot be one here.
      reset_session
      session[:user_id] = user.id
      redirect_to profile_path, notice: t("profile_password.changed")
    else
      fail_with user.errors.full_messages.join(", ")
    end
  end

  private

  # The password you can change is the one you typed. While a child's profile
  # is open `current_user` is the child, whose own password — random, unused
  # and known to nobody — is not what a form on that screen could mean; and
  # the parent's password is not what that screen is about either.
  def require_own_account
    redirect_to profile_path, alert: t("profile_password.child_session") if acting_as_child?
  end

  def fail_with(message)
    redirect_to profile_path, alert: message
  end
end
