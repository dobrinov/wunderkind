# The page an invitation link opens: „Деян те кани в семейството на Мая и
# Боян". Public, because the person opening it usually has no account yet —
# the sign-up form on it posts to UsersController#create with the token, and
# „Влез и приеми" goes through the sign-in form and comes back here. A parent
# who is already signed in accepts with one button.
#
# Not under /parents: the visitor is not a parent of anyone yet, and a student
# who opens the link has to be told why it is not for this account rather
# than bounced off a gate.
class FamilyInvitationsController < ApplicationController
  layout "simple"

  before_action :find_invitation

  def show
    @user = User.new(email: @invitation&.email)
    render status: :gone if @invitation.nil?
  end

  def accept
    return redirect_to(sign_in_path(invitation: params[:token]), alert: t("auth.must_sign_in")) if signed_in_user.nil?
    return redirect_to(family_invitation_path(params[:token]), alert: t("family.join.refused.child_profile")) if acting_as_child?
    return render(:show, status: :gone) if @invitation.nil?

    @invitation.accept!(current_user, name_for_children: params[:name_for_children])
    redirect_to parents_children_path, notice: t("family.join.joined", name: @invitation.inviter.name)
  rescue FamilyInvitation::Refused => refusal
    redirect_to family_invitation_path(params[:token]), alert: t("family.join.refused.#{refusal.reason}")
  end

  private

  # Nil for a link that is spent, withdrawn or out of date: the page says so
  # instead of a 404, since the person holding it did nothing wrong.
  def find_invitation
    @invitation = FamilyInvitation.find_pending_by_token(params[:token])
  end
end
