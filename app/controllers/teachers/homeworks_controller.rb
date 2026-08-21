module Teachers
  class HomeworksController < BaseController
    def new
      @classroom = current_user.classrooms.find(params[:classroom_id])
      @homework = Homework.new(due_at: 1.week.from_now.end_of_day)
      @library_questions = library_questions
    end

    def create
      @classroom = current_user.classrooms.find(params[:classroom_id])

      homework = HomeworkCreator.execute(
        assigner: current_user,
        classroom: @classroom,
        students: @classroom.students.to_a,
        title: homework_params[:title],
        due_at: homework_params[:due_at],
        question_ids: Array(homework_params[:question_ids]).reject(&:blank?),
        auto_count: homework_params[:auto_count].to_i,
        topic_ids: Array(homework_params[:topic_ids]).reject(&:blank?),
        hints_allowed: homework_params[:hints_allowed] == "1"
      )

      redirect_to teachers_homework_path(homework), notice: t("teachers.homeworks.created")
    rescue HomeworkCreator::NoStudents
      redirect_to teachers_classroom_path(@classroom), alert: t("teachers.homeworks.no_students")
    rescue HomeworkCreator::NoQuestions
      redirect_to new_teachers_homework_path(classroom_id: @classroom.id), alert: t("teachers.homeworks.no_questions")
    end

    def show
      @homework = Homework.joins(:classroom).where(classrooms: { teacher_id: current_user.id }).find(params[:id])
      @students = @homework.classroom.students.order(:name)
    end

    private

    def homework_params
      params.require(:homework).permit(:title, :due_at, :auto_count, :hints_allowed, question_ids: [], topic_ids: [])
    end

    def library_questions
      Question.where(author: current_user).order(created_at: :desc).limit(100)
    end
  end
end
