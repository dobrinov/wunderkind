class EmailVerificationsController < ApplicationController
  layout "simple"

  rate_limit to: 5, within: 1.minute, only: :create

  def show
    user = User.find_by_token_for(:email_verification, params[:token])

    if user
      first_answer = user.verified_at.nil?
      linked = user.verify!
      sign_in_from_link(user) if first_answer && session[:user_id].nil?
      return redirect_to_linked(user, linked) if linked

      redirect_to after_verification_path(user), notice: t("verification.verified")
    else
      redirect_to sign_in_path, alert: t("verification.invalid_token")
    end
  end

  # Nothing to resend to an account that already counts as verified — which,
  # while `Mailing` is off, is every account. Silent rather than
  # claiming to have sent a mail that never left.
  def create
    return redirect_back(fallback_location: root_path) if current_user.nil? || current_user.verified?

    UserMailer.email_verification(current_user).deliver_later
    redirect_back fallback_location: root_path, notice: t("verification.sent")
  end

  private

  # A confirmation link is mostly opened from a mail app, which on a phone is
  # a different browser from the one the account was made in — so it used to
  # end on the sign-in page, and the parents who left without adding a child
  # had all confirmed and then stopped there. The link proves the inbox, the
  # way a password reset link does, so its first use signs the person in: only
  # the first, since this token stays valid for two days, and only into a
  # browser nobody is signed in to, so it never swaps one account for another.
  def sign_in_from_link(user)
    reset_session
    session[:user_id] = user.id
    user.logged_in!
    track :login, role: user.role, via: "email_verification"
  end

  # A child's code typed before the address was confirmed is linked by
  # confirming it (User#claim_pending_child!): straight on to that child, as
  # linking does when the address was already confirmed.
  def redirect_to_linked(user, child)
    track :child_added, how: "linked"
    return redirect_to(sign_in_path, notice: t("parents.children.linked", name: child.name)) unless session[:user_id] == user.id

    redirect_to parents_child_path(child, tab: "practice", welcome: 1), notice: t("parents.children.linked", name: child.name)
  end

  # A parent with nobody in the account yet goes straight back to adding the
  # child, which is what they were doing when they went to find the email.
  def after_verification_path(user)
    return sign_in_path unless session[:user_id] == user.id

    user.parent? && !user.children.exists? ? new_parents_child_path : root_path
  end
end
