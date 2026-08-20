module Overseer
  class HintsController < BaseController
    def show
      @question = Question.find(params[:question_id])
      @hint = @question.hint || @question.build_hint
    end

    def create
      @question = Question.find(params[:question_id])
      Ai::HintGenerator.call(@question)
      redirect_to overseer_question_hint_path(@question), notice: t("hints.generated")
    rescue Ai::Unavailable => error
      redirect_to overseer_question_hint_path(@question), alert: t("hints.unavailable", reason: error.message)
    end

    def update
      question = Question.find(params[:question_id])
      hint = question.hint || question.build_hint

      hint.assign_attributes(
        ladder: Array(params[:hint][:ladder]).map(&:to_s).compact_blank,
        wrong_answer_explanations: parse_wrong_answers,
        reviewed_at: params[:approve] == "1" ? Time.current : nil
      )
      hint.save!

      redirect_to overseer_question_hint_path(question), notice: t("hints.saved")
    end

    private

    # The form submits explanations as parallel answer/explanation arrays.
    def parse_wrong_answers
      answers = Array(params[:hint][:wrong_answer_keys])
      explanations = Array(params[:hint][:wrong_answer_values])
      answers.zip(explanations).reject { |key, _| key.blank? }.to_h
    end
  end
end
