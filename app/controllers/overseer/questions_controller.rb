module Overseer
  class QuestionsController < Overseer::BaseController
    def index
      @filter = QuestionFilter.new(params)
      @questions = @filter.results.page(params[:page]).per(50)
      @total = @questions.total_count
      # So a flagged question is visible in the list an admin browses, not only
      # in the queue they have to remember to open.
      @open_reports = QuestionReport.active.where(question: @questions).group(:question_id).count
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
      @active_reports = @question.reports.active.count
      @question.possible_answers.build if @question.possible_answers.empty?
    end

    def update
      @question = Question.find params[:id]

      if @question.update(QuestionFormParams.build(params, @question))
        # Opened from the report queue („Поправи"): back to the question's
        # card there, where the students are waiting for an answer.
        back = helpers.internal_path(params[:return_to], overseer_questions_path)
        redirect_to back, notice: t("overseer.questions.updated")
      else
        @active_reports = @question.reports.active.count
        render :edit, status: :unprocessable_entity
      end
    end

    # Out of practice and duels for good, while every answer already given to
    # it keeps its problem in the student's history and review lists.
    def retire
      question = Question.published.find(params[:id])
      question.retire!

      redirect_back fallback_location: overseer_questions_path, notice: t("overseer.questions.retired")
    end

    def restore
      question = Question.retired.find(params[:id])
      question.update!(status: :published)

      redirect_back fallback_location: overseer_questions_path, notice: t("overseer.questions.restored")
    end
  end
end
