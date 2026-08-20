module Teachers
  class ClassroomsController < BaseController
    def index
      @classrooms = current_user.classrooms.includes(:students).order(:name)
    end

    def show
      @classroom = current_user.classrooms.find(params[:id])
      @students = @classroom.students.order(:name)
      @homeworks = @classroom.homeworks.includes(:questions, assignments: [ :user, { assignment_questions: :user_answer } ]).order(due_at: :desc)
      @leaderboard = Leaderboards.weekly_xp(@students) if @classroom.leaderboard_enabled?
    end

    def new
      @classroom = Classroom.new
    end

    def create
      @classroom = current_user.classrooms.build(classroom_params)

      if @classroom.save
        redirect_to teachers_classroom_path(@classroom), notice: t("teachers.classrooms.created")
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      @classroom = current_user.classrooms.find(params[:id])
    end

    def update
      @classroom = current_user.classrooms.find(params[:id])

      if @classroom.update(classroom_params)
        redirect_to teachers_classroom_path(@classroom), notice: t("teachers.classrooms.updated")
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      classroom = current_user.classrooms.find(params[:id])
      classroom.destroy!
      redirect_to teachers_classrooms_path, notice: t("teachers.classrooms.deleted")
    end

    private

    def classroom_params
      params.require(:classroom).permit(:name, :leaderboard_enabled)
    end
  end
end
