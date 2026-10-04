class ApplicationController < ActionController::Base
  include SeoPage
  include TrackedEvents

  before_action :close_broken_impersonation
  before_action :refuse_writes_while_impersonating

  helper_method :current_user, :signed_in_user, :acting_as_child?, :impersonator, :impersonating?, :unseen_changelog

  private

  # Who typed the password. Only the account screens and profile switching care
  # about the difference; everything else wants current_user.
  #
  # An admin viewing the app as someone else is *not* an exception to that: the
  # whole point is that every line of the app reads the same user it would read
  # if that person had signed in themselves, so impersonation swaps the id in
  # this slot and parks the admin's own in session[:impersonator_id]. Nothing
  # below this line has to know, and the layers compose — an admin viewing a
  # parent can step into that parent's child profiles exactly as the parent can.
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

  # The admin behind an impersonated session, re-read and re-checked on every
  # request for the same reason acting_child is: the role is the whole of the
  # permission, so a demotion has to close the door on the next click rather
  # than whenever the browser is next closed.
  def impersonator
    return @impersonator if defined?(@impersonator)

    id = session[:impersonator_id]
    @impersonator = id.present? ? User.find_by(id: id, role: :admin) : nil
  end

  def impersonating?
    impersonator.present?
  end

  # Either end of a borrowed session can disappear while it is open, and
  # neither may be left to be discovered by a view calling `.name` on nothing.
  #
  # No admin behind it — deleted, or demoted — and there is no safe way to
  # carry on at all: the browser is signed in as someone it was lent, with
  # nobody left to hand it back to. So the session goes. No *target* is the
  # milder half: hand the browser back to the admin, who is still there.
  def close_broken_impersonation
    return if session[:impersonator_id].blank?

    if impersonator.nil?
      reset_session
      redirect_to sign_in_path, alert: t("impersonation.expired")
    elsif signed_in_user.nil?
      restore_impersonator
      redirect_to overseer_users_path, alert: t("impersonation.gone")
    end
  end

  # Shared with ImpersonationsController#destroy: an open child profile belongs
  # to whoever opened it and must not greet the identity coming back.
  def restore_impersonator
    session[:user_id] = session.delete(:impersonator_id)
    session.delete(:child_id)
  end

  # Impersonation is a window, not a seat. An admin looking at a child's screen
  # must not be able to answer a question from it: a graded answer moves that
  # child's rating, spends their XP-earning attempt and burns the question out
  # of their assignment, and none of it can be told apart afterwards from
  # something the child did. The app measures children; it must not measure the
  # adult looking over their shoulder.
  #
  # So every request that is not a read is refused. The three exceptions write
  # to the session and never to the database: signing out (which ends the
  # impersonation along with everything else), switching child profile (which
  # is part of the parent's view being looked at), and the stop button itself.
  SESSION_ONLY_CONTROLLERS = %w[impersonations sessions child_sessions].freeze

  def refuse_writes_while_impersonating
    return unless impersonating?
    return if request.get? || request.head?
    return if controller_name.in?(SESSION_ONLY_CONTROLLERS)

    # Not flash.now: the answer form posts by fetch and reloads when the post
    # is refused, so the message has to survive to the request after this one.
    flash[:alert] = t("impersonation.blocked")

    if request.format.json?
      head :forbidden
    else
      redirect_back fallback_location: root_path
    end
  end

  # The release notes this user has not been shown, for the dialog in the
  # `application` layout. Empty while an admin is viewing someone else's
  # account: the notes are addressed to that person, the dialog's only button
  # is a write an impersonated session refuses, and an unanswerable dialog over
  # the screen you came to look at is the opposite of a window onto it.
  def unseen_changelog
    return [] if impersonating?

    @unseen_changelog ||= Changelog.unseen_for(current_user)
  end

  # Where signing in or registering lands: the role's home screen.
  def post_auth_path(user)
    home_path_for(user)
  end

  def home_path_for(user)
    case user.role
    when "admin" then overseer_root_path
    when "parent" then parents_children_path
    else calendar_path
    end
  end
end
