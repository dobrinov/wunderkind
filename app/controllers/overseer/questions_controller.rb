module Overseer
  class QuestionsController < Overseer::BaseController
    def index
      @questions = Question.includes(:topics).order(elo: :desc).page params[:page]
    end

    def new
      @type =
        case params[:type]
        when "image"
          :image
        when "script"
          :script
        else
          :basic
        end

      @question = Question.new
      @question.possible_answers.build
    end

    def create
      @question = Question.new(question_params)

      if params[:question][:image].present?
        @question.attachable = QuestionImage.new(file: params[:question][:image])
      elsif params[:question][:script].present?
        @question.attachable = QuestionScript.new(code: params[:question][:script])
      end

      if @question.save
        redirect_to overseer_questions_path, notice: "Въпросът беше създаден успешно."
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
      if @question.update(question_params)
        redirect_to overseer_questions_path, notice: "Въпросът беше актуализиран успешно."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def question_params
      params.require(:question).permit(:text, :answer, :explanation,
                                      possible_answers_attributes: [ :id, :value, :_destroy ],
                                      topic_ids: [])
    end
  end
end
