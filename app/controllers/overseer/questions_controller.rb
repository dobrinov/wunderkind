module Overseer
  class QuestionsController < Overseer::BaseController
    def index
      @questions = Question.includes(:topics).order(elo: :desc).page params[:page]
    end

    def new
      @question = Question.new(status: :published)
      @question.possible_answers.build
    end

    def create
      @question = Question.new(question_attributes)
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

      if @question.update(question_attributes)
        redirect_to overseer_questions_path, notice: t("overseer.questions.updated")
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def question_attributes
      attributes = question_params.except(:body_json, :image)
      attributes[:body] = parse_body
      attributes[:grading] = build_grading

      if question_params[:image].present?
        attributes[:attachable] = QuestionImage.new(file: question_params[:image])
      end

      attributes
    end

    def question_params
      params.require(:question).permit(
        :body_json, :explanation, :answer_type, :status, :elo, :image,
        possible_answers_attributes: [ :id, :value, :correct, :_destroy ],
        topic_ids: []
      )
    end

    def parse_body
      JSON.parse(question_params[:body_json].to_s)
    rescue JSON::ParserError
      nil
    end

    def build_grading
      grading = params.require(:question).permit(
        :expected, :tolerance, :widget,
        :nl_min, :nl_max, :nl_step, :nl_solution, :nl_tolerance,
        :ordering_items, :fb_segments, :fb_shaded
      )

      case question_params[:answer_type]
      when "exact_value"
        {
          "expected" => grading[:expected].to_s.strip,
          "tolerance" => grading[:tolerance].presence&.to_f
        }.compact
      when "interactive"
        widget_grading(grading)
      else
        {}
      end
    end

    def widget_grading(grading)
      case grading[:widget]
      when "number_line"
        {
          "widget" => "number_line",
          "params" => {
            "min" => grading[:nl_min].to_f,
            "max" => grading[:nl_max].to_f,
            "step" => grading[:nl_step].presence&.to_f || 1
          },
          "solution" => {
            "value" => grading[:nl_solution].to_f,
            "tolerance" => grading[:nl_tolerance].presence&.to_f || 0
          }
        }
      when "ordering"
        items = grading[:ordering_items].to_s.split(/\r?\n/).map(&:strip).reject(&:blank?)
        {
          "widget" => "ordering",
          "params" => { "items" => items.each_with_index.map { |label, i| { "id" => "i#{i + 1}", "label" => label } } },
          "solution" => { "order" => items.each_index.map { |i| "i#{i + 1}" } }
        }
      when "fraction_bars"
        {
          "widget" => "fraction_bars",
          "params" => { "segments" => grading[:fb_segments].to_i },
          "solution" => { "shaded" => grading[:fb_shaded].to_i }
        }
      else
        {}
      end
    end
  end
end
