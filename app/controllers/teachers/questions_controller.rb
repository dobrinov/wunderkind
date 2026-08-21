module Teachers
  class QuestionsController < BaseController
    # Teachers author into their private library; publishing goes through the
    # admin review queue (submit_for_review), never directly.
    ALLOWED_STATUSES = %w[draft private_library].freeze

    def index
      @questions = Question.where(author: current_user).order(created_at: :desc).page params[:page]
    end

    def new
      @question = Question.new(status: :private_library)
      @question.possible_answers.build
    end

    def create
      @question = Question.new(question_attributes)
      @question.author = current_user

      if @question.save
        redirect_to teachers_questions_path, notice: t("overseer.questions.created")
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      @question = Question.where(author: current_user).find(params[:id])
      @question.possible_answers.build if @question.possible_answers.empty?
    end

    def update
      @question = Question.where(author: current_user).find(params[:id])

      if @question.update(question_attributes)
        redirect_to teachers_questions_path, notice: t("overseer.questions.updated")
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def submit_for_review
      question = Question.where(author: current_user, status: [ :draft, :private_library ]).find(params[:id])
      question.update!(status: :in_review)
      redirect_to teachers_questions_path, notice: t("teachers.questions.submitted")
    end

    private

    # Same structured params as the admin controller, but status is clamped to
    # the private library — a teacher can't self-publish.
    def question_attributes
      attributes = QuestionFormParams.build(params, @question)
      attributes[:status] = "private_library" unless ALLOWED_STATUSES.include?(attributes[:status])
      attributes
    end
  end
end
