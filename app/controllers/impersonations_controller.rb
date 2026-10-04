# Looking at the app as somebody else. A parent writes in to say the duel
# button does nothing, or a child's session is composed of problems that look
# wrong for them, and the only way to see what they are describing is to stand
# where they are standing — their rating, their topics, their unlocked
# frontier, their screen.
#
# Two rules keep it honest, and both live here rather than in a policy object
# because there are only two.
#
#   * Only an admin may start one, and never on another admin. Not for
#     privilege reasons — admin is already the top role, so nothing escalates —
#     but because the admin area is the one place a second impersonation could
#     be started, and a stack two deep has no obvious way back. Refusing the
#     one case keeps "the way out is always the admin who began" true.
#   * It is read-only. ApplicationController refuses every write while a
#     session is impersonated; see the comment there for why a graded answer in
#     particular must never be given from this seat.
#
# Note what this controller does *not* touch: session[:user_id] becomes the
# target, so the rest of the app reads them as the signed-in user without a
# single conditional, and the admin's own id waits in session[:impersonator_id]
# for the way back.
class ImpersonationsController < AuthenticatedController
  def create
    return refuse(t("impersonation.not_allowed")) unless current_user.admin? && !impersonating?

    target = User.find_by(id: params[:id])

    return refuse(t("impersonation.unavailable")) if target.nil? || target == current_user
    return refuse(t("impersonation.no_admins")) if target.admin?

    session[:impersonator_id] = current_user.id
    session[:user_id] = target.id
    # A profile switch belongs to whoever made it; it must not greet the next
    # identity still open.
    session.delete(:child_id)

    redirect_to home_path_for(target), notice: t("impersonation.started", name: target.name)
  end

  def destroy
    return redirect_to(root_path) unless impersonating?

    admin = impersonator
    restore_impersonator

    redirect_to overseer_users_path, notice: t("impersonation.stopped", name: admin.name)
  end

  private

  def refuse(message)
    redirect_back fallback_location: root_path, alert: message
  end
end
