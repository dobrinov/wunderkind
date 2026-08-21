# Switching profiles inside one login. A child too young for an email has no way
# to sign in, so the parent's account is the door: the session carries both
# identities — session[:user_id] is who signed in and is never changed here,
# session[:child_id] is who is playing — and only accounts the signed-in user
# manages can be stepped into.
class ChildSessionsController < AuthenticatedController
  def create
    child = signed_in_user.managed_children.find_by(id: params[:id])

    if child.nil?
      redirect_to home_path_for(signed_in_user), alert: t("child_session.unavailable")
    else
      session[:child_id] = child.id
      redirect_to calendar_path, notice: t("child_session.switched", name: child.name)
    end
  end

  def destroy
    session.delete(:child_id)
    redirect_to home_path_for(signed_in_user), notice: t("child_session.left")
  end
end
