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
      remember_admin_page
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
    back = session.delete(:admin_return_to)
    destination = params[:to] == "admin" && signed_in_user.admin? ? (back || overseer_root_path) : home_path_for(signed_in_user)
    redirect_to destination, notice: t("child_session.left")
  end

  private

  # An admin who is also a parent hands the tablet over from wherever they
  # were — often the middle of a ticket — and the child bar offers the way
  # back to exactly that page as well as to the family.
  def remember_admin_page
    return unless signed_in_user.admin?

    path = URI.parse(request.referer.to_s).path.to_s
    session[:admin_return_to] = helpers.internal_path(path) if path.start_with?("/overseer")
  rescue URI::InvalidURIError
    nil
  end
end
