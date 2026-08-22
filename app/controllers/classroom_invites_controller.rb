# A classroom invite as a link. The six-letter code stays — a teacher reading it
# off a whiteboard is what it was built for — but a link is what gets pasted into
# a parents' chat, and it spares a seven-year-old typing a code they will
# transpose. The link carries the same code, so the two doors are one door: a
# revoked or mistyped code fails the same way in both.
#
# Public on purpose: a visitor who has never signed in can open the invite, see
# whose class it is, and come back to it after registering — the code is the
# secret, and knowing it is already all that joining by code requires.
class ClassroomInvitesController < ApplicationController
  layout :invite_layout

  rate_limit to: 20, within: 1.minute, only: :create

  before_action :load_classroom

  def show
    @member = current_user&.student? && @classroom.students.include?(current_user)
  end

  def create
    return redirect_to sign_in_path(invite: @classroom.invite_code), alert: t("auth.must_sign_in") if current_user.nil?
    return redirect_to classroom_invite_path(@classroom.invite_code), alert: t("classroom_invites.students_only") unless current_user.student?

    if @classroom.students.include?(current_user)
      redirect_to classrooms_path, notice: t("classrooms.already_member", name: @classroom.name)
    else
      @classroom.classroom_memberships.create!(user: current_user)
      redirect_to classrooms_path, notice: t("classrooms.joined", name: @classroom.name)
    end
  end

  private

  def load_classroom
    @classroom = Classroom.find_by_invite_code(params[:code])

    redirect_to root_path, alert: t("classrooms.invalid_code") if @classroom.nil?
  end

  def invite_layout
    current_user ? "application" : "simple"
  end
end
