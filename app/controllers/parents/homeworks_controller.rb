module Parents
  class HomeworksController < BaseController
    def new
      @child = current_user.children.find(params[:child_id])
      @homework = Homework.new(due_at: 1.week.from_now.end_of_day)
    end

    def create
      @child = current_user.children.find(params[:child_id])

      homework = HomeworkCreator.execute(
        assigner: current_user,
        students: [ @child ],
        title: homework_params[:title],
        due_at: homework_params[:due_at],
        auto_count: homework_params[:auto_count].to_i,
        topic_ids: Array(homework_params[:topic_ids]).reject(&:blank?)
      )

      redirect_to parents_homework_path(homework), notice: t("parents.homeworks.created")
    rescue HomeworkCreator::NoQuestions
      redirect_to new_parents_homework_path(child_id: @child.id), alert: t("teachers.homeworks.no_questions")
    end

    def show
      @homework = Homework.where(assigner: current_user).find(params[:id])
      @students = @homework.students
    end

    private

    def homework_params
      params.require(:homework).permit(:title, :due_at, :auto_count, topic_ids: [])
    end
  end
end
