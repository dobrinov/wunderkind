# Grades free-text answers against the author's rubric with the small model.
# Normalized answers are cached per question, so repeated common answers cost
# nothing. Raises Ai::Unavailable when the key is missing or the budget is
# spent — the caller records the answer as pending teacher review.
module Ai
  module FreeTextGrader
    VERDICTS = %w[correct partial incorrect].freeze

    module_function

    def grade(question:, answer:)
      normalized = normalize(answer)
      cached = FreeTextGrading.find_by(question: question, answer_hash: digest(normalized))
      return { "verdict" => cached.verdict, "feedback" => cached.feedback } if cached

      payload = Client.complete_json(
        model: GRADING_MODEL,
        max_tokens: 500,
        system: "Ти си учител по математика. Оценяваш отговори на български ученици. Отговаряш само с JSON.",
        user: <<~PROMPT
          Задача: #{question.body_text}
          Критерии за верен отговор (рубрика): #{question.grading['rubric']}

          Отговор на ученика: #{answer}

          Върни само JSON: {"verdict": "correct" | "partial" | "incorrect", "feedback": "<едно кратко изречение на български към ученика>"}
          Оценявай съдържанието, не правописа.
        PROMPT
      )

      verdict = VERDICTS.include?(payload["verdict"]) ? payload["verdict"] : "incorrect"
      feedback = payload["feedback"].to_s

      FreeTextGrading.create_or_find_by!(question: question, answer_hash: digest(normalized)) do |record|
        record.verdict = verdict
        record.feedback = feedback
      end

      { "verdict" => verdict, "feedback" => feedback }
    end

    def normalize(answer)
      answer.to_s.strip.downcase.gsub(/\s+/, " ")
    end

    def digest(normalized)
      Digest::SHA256.hexdigest(normalized)
    end
  end
end
