# In-editor authoring help: variations, distractors, and difficulty/topic
# estimates. Everything lands in the author's draft for human review — the
# assistant never publishes anything itself.
module Ai
  module AuthoringAssistant
    KINDS = %w[variations distractors estimate].freeze

    SYSTEM_PROMPT = <<~PROMPT.freeze
      Ти си опитен автор на задачи по математика за български ученици
      (начален и прогимназиален етап). Пишеш на български, ясно и точно.
    PROMPT

    module_function

    def call(kind:, body_text:, answer: nil)
      raise ArgumentError, "Unknown assist kind: #{kind}" unless KINDS.include?(kind.to_s)

      Client.complete(
        model: GENERATION_MODEL,
        system: SYSTEM_PROMPT,
        user: public_send(:"#{kind}_prompt", body_text, answer)
      )
    end

    def variations_prompt(body_text, answer)
      <<~PROMPT
        Задача: #{body_text}
        #{"Верен отговор: #{answer}" if answer.present?}

        Предложи 5 вариации на тази задача със същата структура, но различни
        числа или контекст. За всяка дай условието и верния отговор, номерирани.
      PROMPT
    end

    def distractors_prompt(body_text, answer)
      <<~PROMPT
        Задача: #{body_text}
        Верен отговор: #{answer}

        Предложи 4 правдоподобни грешни отговора (дистрактори) за тази задача.
        Всеки трябва да отразява типична ученическа грешка. За всеки посочи
        отговора и в скоби каква грешка отразява.
      PROMPT
    end

    def estimate_prompt(body_text, answer)
      <<~PROMPT
        Задача: #{body_text}
        #{"Верен отговор: #{answer}" if answer.present?}

        Прецени: 1) за кой клас (1–7) е подходяща задачата; 2) трудност по
        Elo скала, където 1000 е лесна за втори клас, 1200 средна, 1500 трудна
        за шести клас; 3) към кои теми спада. Отговори в 3 кратки реда.
      PROMPT
    end
  end
end
