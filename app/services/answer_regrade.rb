# Gives children back the answers the app marked wrong when they were right.
#
# Run after the team fixes a question (Overseer::QuestionsController#update)
# and, once, over every answer after the grader learned to read the way school
# writes (`rake answers:regrade`). Before it existed, an upheld report fixed the
# question for the next child only: the one who reported it kept the red mark,
# the entry on „За преговор" and the XP they never got — and asked for their
# points back.
#
# Only ever wrong → right. A fix that makes an old answer wrong does not take
# anything away from a child who was told they were right. What changes is the
# answer's verdict (so it leaves the mistakes list, which reads the latest
# answer to each question) and the XP: the difference between what a correct
# answer pays and the attempt XP it was paid. The ratings are left where they
# are — an Elo game cannot be replayed out of order — and are a few points
# apart at most.
module AnswerRegrade
  REASON = "regrade"

  module_function

  # The wrong answers to these questions that are right now, flipped. Returns
  # how many were.
  def questions!(questions)
    Array(questions).sum do |question|
      wrong_answers(question).sum { |answer| correct_now?(question, answer) ? flip!(answer, question) : 0 }
    end
  end

  def question!(question)
    questions!([ question ])
  end

  def wrong_answers(question)
    UserAnswer.joins(:assignment_question)
              .where(assignment_questions: { question_id: question.id })
              .where(correct: false, skipped: false)
              .where("COALESCE(user_answers.response ->> 'verdict', '') <> 'pending_review'")
              .includes(:user, assignment_question: :assignment)
  end

  # Graded from what was stored — the response holds the answer as it was
  # read, with widget ids already unmasked — against the question as it is now.
  def correct_now?(question, answer)
    response = answer.response.to_h
    case question.answer_type
    when "exact_value"
      ExactValue.equivalent?(question.grading["expected"], response["value"].to_s, tolerance: question.grading["tolerance"])
    when "multiple_choice"
      chosen = Array(response["selected_ids"]).map(&:to_i).sort
      chosen.present? && chosen == question.correct_possible_answers.map(&:id).sort
    when "interactive"
      Widgets.correct?(question.widget_type, solution: question.grading["solution"],
                                             state: response["state"].to_h, params: question.grading["params"])
    else
      false
    end
  rescue StandardError
    false
  end

  def flip!(answer, question)
    user = answer.user
    UserAnswer.transaction do
      answer.update!(correct: true, response: answer.response.to_h.merge("regraded_at" => Time.current.iso8601))
      owed = owed_xp(answer, question, user)
      if owed.positive?
        Xp.award!(user, amount: owed, reason: REASON, source: answer)
        user.save!
      end
    end
    1
  end

  # What a correct answer would have paid, less what the wrong one did. A
  # mistakes session pays nothing for a wrong answer (see Xp), so it is owed the
  # whole amount; elsewhere the attempt XP was already paid.
  def owed_xp(answer, question, user)
    full = Xp.amount_for_answer(correct: true, user_rating: user.elo, question_rating: question.elo)
    paid = answer.assignment_question.assignment.mistakes? ? 0 : Xp::ATTEMPT_AMOUNT
    [ full - paid, 0 ].max
  end
end
