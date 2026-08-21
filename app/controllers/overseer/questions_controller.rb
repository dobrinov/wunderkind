module Overseer
  class QuestionsController < Overseer::BaseController
    def index
      @filter = QuestionFilter.new(params)
      @questions = @filter.results.page(params[:page]).per(50)
      @total = @questions.total_count
    end

    # Shows the question exactly as a student meets it, in the same focus
    # layout, with the answer controls inert — nothing here can be submitted
    # or graded.
    def preview
      @question = Question.find(params[:id])
      @hint = @question.hint

      render layout: "modal"
    end

    def new
      @question = Question.new(status: :published)
      @question.possible_answers.build
    end

    def create
      @question = Question.new(QuestionFormParams.build(params))
      @question.author = current_user

      if @question.save
        redirect_to overseer_questions_path, notice: t("overseer.questions.created")
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      @question = Question.find params[:id]
      @question.possible_answers.build if @question.possible_answers.empty?
    end

    def update
      @question = Question.find params[:id]

      if @question.update(QuestionFormParams.build(params, @question))
        redirect_to overseer_questions_path, notice: t("overseer.questions.updated")
      else
        render :edit, status: :unprocessable_entity
      end
    end
  end
end
