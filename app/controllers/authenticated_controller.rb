class AuthenticatedController < ApplicationController
  before_action :require_login
  before_action :record_presence

  private

  def require_login
    redirect_to sign_in_path, alert: t("auth.must_sign_in") unless current_user
  end

  # „Last seen" for the friends list, written on the way past every page.
  #
  # Never while impersonating, for the same reason a duel question is not
  # served then and analytics do not count it: the child is not at the screen,
  # and a green dot beside their name would be saying they are. It is also a
  # write, which an impersonated session is not allowed to make — the rule in
  # ApplicationController is on the verb and cannot see a GET that touches a
  # column, which is exactly the shape of this one.
  def record_presence
    return if impersonating? || current_user.nil?

    current_user.seen!
  end

  # Before a page that shows this student to other children: a student with no
  # nickname is asked for one first (NicknamesController). Not while an admin
  # is looking — the answer is the child's to give, and the session is
  # read-only anyway.
  def require_nickname
    return unless current_user&.student? && current_user.nickname.blank? && !impersonating?

    redirect_to new_nickname_path(return_to: request.get? ? request.fullpath : nil)
  end
end
