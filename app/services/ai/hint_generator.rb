# Generates a three-rung hint ladder (nudge → strategy → worked step, never the
# answer) plus explanations for the wrong answers students actually give.
# One-time cost per question; the result is stored, admin-reviewed, and then
# served to every student for free.
module Ai
  module HintGenerator
    COMMON_WRONG_ANSWERS_LIMIT = 5

    SYSTEM_PROMPT = <<~PROMPT.freeze
      Ти си търпелив учител по математика за български деца в начален и
      прогимназиален етап. Пишеш на български, кратко и окуражаващо, на "ти".
      Никога не издаваш крайния отговор.
    PROMPT

    module_function

    def call(question)
      payload = Client.complete_json(
        model: GENERATION_MODEL,
        system: SYSTEM_PROMPT,
        user: prompt_for(question)
      )

      hint = QuestionHint.find_or_initialize_by(question: question)
      hint.update!(
        ladder: Array(payload["hints"]).first(3).map(&:to_s),
        wrong_answer_explanations: payload["wrong_answers"].is_a?(Hash) ? payload["wrong_answers"] : {},
        model: GENERATION_MODEL,
        reviewed_at: nil
      )
      hint
    end

    def prompt_for(question)
      wrong_answers = common_wrong_answers(question)

      <<~PROMPT
        Задача: #{question.body_text}
        Верен отговор: #{Grading.correct_answer_display(question)}
        #{"Обяснение от автора: #{question.explanation}" if question.explanation.present?}

        Върни само JSON без друг текст, във формата:
        {
          "hints": ["подсказка 1", "подсказка 2", "подсказка 3"],
          "wrong_answers": { "<грешен отговор>": "<защо е грешен, без да издаваш верния>" }
        }

        Правила за подсказките:
        1. Първата е лек намек какво да забележи в условието.
        2. Втората назовава стратегията или правилото, което трябва да се приложи.
        3. Третата показва първата стъпка от решението, но НЕ и крайния отговор.
        #{"Обясни защо тези чести грешни отговори са грешни: #{wrong_answers.join(', ')}" if wrong_answers.any?}
      PROMPT
    end

    def common_wrong_answers(question)
      question.user_answers.
        where(correct: false).
        group(:value).
        order(count_all: :desc).
        limit(COMMON_WRONG_ANSWERS_LIMIT).
        count.
        keys.
        compact_blank
    end
  end
end
