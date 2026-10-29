module Overseer
  # The hint ladder used to have a page of its own; it is a section of the
  # question editor now, saved with the question. The route stays for links
  # and bookmarks — the page sends them to that section — and an update posted
  # by an old form still saves.
  class HintsController < BaseController
    def show
      redirect_to edit_overseer_question_path(params[:question_id], anchor: "hints")
    end

    def update
      question = Question.find(params[:question_id])
      hint = question.hint || question.build_hint

      hint.assign_attributes(
        ladder: Array(params[:hint][:ladder]).map(&:to_s).compact_blank,
        wrong_answer_explanations: parse_wrong_answers.presence || hint.wrong_answer_explanations,
        reviewed_at: params[:approve] == "1" ? Time.current : nil
      )
      hint.save!

      redirect_to edit_overseer_question_path(question, anchor: "hints"), notice: t("hints.saved")
    end

    private

    # The old form submitted explanations as parallel answer/explanation arrays.
    def parse_wrong_answers
      answers = Array(params[:hint][:wrong_answer_keys])
      explanations = Array(params[:hint][:wrong_answer_values])
      answers.zip(explanations).reject { |key, _| key.blank? }.to_h
    end
  end
end
