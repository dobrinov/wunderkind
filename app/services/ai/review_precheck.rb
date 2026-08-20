# Annotates a submitted question for the admin review queue: is it correct,
# clear, and non-duplicate? The annotation never approves anything — it just
# gives the reviewing human a head start.
module Ai
  module ReviewPrecheck
    module_function

    def call(question)
      similar = similar_questions(question)

      payload = Client.complete_json(
        model: GENERATION_MODEL,
        system: "Ти си редактор на задачи по математика за български ученици. Отговаряш само с JSON.",
        user: <<~PROMPT
          Провери тази задача, предложена за публикуване:

          Условие: #{question.body_text}
          Тип отговор: #{question.answer_type}
          Верен отговор според автора: #{Grading.correct_answer_display(question)}
          #{"Възможни отговори: #{question.possible_answers.map(&:value).join(', ')}" if question.multiple_choice?}
          #{"Подобни съществуващи задачи: #{similar.join(' | ')}" if similar.present?}

          Върни само JSON:
          {
            "correct": true | false,
            "clear": true | false,
            "duplicate": true | false,
            "notes": "<до 2 изречения на български: проблеми или 'Няма забележки'>"
          }
          "correct" е false само ако посоченият верен отговор е математически грешен.
        PROMPT
      )

      question.update!(ai_review: payload.slice("correct", "clear", "duplicate", "notes").merge("checked_at" => Time.current.iso8601))
      question.ai_review
    end

    def similar_questions(question)
      Question.published.
        where.not(id: question.id).
        where("body_text % ?", question.body_text).
        limit(3).
        pluck(:body_text)
    end
  end
end
