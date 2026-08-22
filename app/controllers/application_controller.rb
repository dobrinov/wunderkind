class ApplicationController < ActionController::Base
  helper_method :current_user, :signed_in_user, :acting_as_child?

  private

  # Who typed the password. Only the account screens and profile switching care
  # about the difference; everything else wants current_user.
  def signed_in_user
    @signed_in_user ||= User.find_by(id: session[:user_id])
  end

  # Who the app is for on this request. A parent who has switched into a child's
  # profile *is* that child from here on — the practice, the rating, the XP and
  # the streak all belong to the child — and gets back to their own account only
  # through ChildSessionsController#destroy.
  def current_user
    acting_child || signed_in_user
  end

  # Re-read from the session on every request rather than trusted once at the
  # switch: if the account stops managing the child, the door closes at once.
  def acting_child
    return @acting_child if defined?(@acting_child)

    id = session[:child_id]
    @acting_child = id.present? ? signed_in_user&.managed_children&.find_by(id: id) : nil
  end

  def acting_as_child?
    acting_child.present?
  end

  # Where signing in or registering lands. Normally the role's home screen — but
  # a visitor who arrived from a classroom invite link and had to make an account
  # first came here to join a class, so they go back to the invite rather than to
  # a home screen that says nothing about it. The code is checked against its own
  # shape, so a hand-edited `invite` param cannot become an arbitrary redirect.
  INVITE_CODE = /\A[A-Za-z0-9]{4,12}\z/

  def post_auth_path(user)
    code = params[:invite].to_s.strip
    code.match?(INVITE_CODE) ? classroom_invite_path(code) : home_path_for(user)
  end

  def home_path_for(user)
    case user.role
    when "admin" then overseer_root_path
    when "teacher" then teachers_classrooms_path
    when "parent" then parents_children_path
    else calendar_path
    end
  end
end
