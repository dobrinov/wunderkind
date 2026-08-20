# The student-facing side of classrooms: joining by invite code and seeing
# each classroom's weekly leaderboard.
class ClassroomsController < AuthenticatedController
  def index
    @classrooms = current_user.joined_classrooms.includes(:teacher, :students)
  end

  def join
    classroom = Classroom.find_by_invite_code(params[:invite_code])

    if classroom.nil?
      redirect_to classrooms_path, alert: t("classrooms.invalid_code")
    elsif classroom.students.include?(current_user)
      redirect_to classrooms_path, notice: t("classrooms.already_member", name: classroom.name)
    else
      classroom.classroom_memberships.create!(user: current_user)
      redirect_to classrooms_path, notice: t("classrooms.joined", name: classroom.name)
    end
  end
end
