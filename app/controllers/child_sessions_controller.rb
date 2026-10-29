# Switching profiles inside one login. A child too young for an email has no way
# to sign in, so the parent's account is the door: the session carries both
# identities — session[:user_id] is who signed in and is never changed here,
# session[:child_id] is who is playing — and only managed accounts the signed-in
# user is linked to as a parent can be stepped into (User#switchable_children).
class ChildSessionsController < AuthenticatedController
  def create
    child = signed_in_user.switchable_children.find_by(id: params[:id])

    if child.nil?
      redirect_to home_path_for(signed_in_user), alert: t("child_session.unavailable")
    else
      session[:child_id] = child.id
      # A managed child has no sign-in of their own; this is it. Not while an
      # admin is looking on, though — the child did not come back, the admin did.
      child.logged_in! unless impersonating?
      # The managed child's sign-in, as far as analytics is concerned.
      track :login, role: child.role, via: "switch"
      redirect_to home_path, notice: t("child_session.switched", name: child.name)
    end
  end

  def destroy
    session.delete(:child_id)
    redirect_to home_path_for(signed_in_user), notice: t("child_session.left")
  end
end
