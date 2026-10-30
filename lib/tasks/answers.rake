namespace :answers do
  # Once, after the grader learned to read answers the way school writes them
  # (thousands spaces, „x = 72", units, „40%"): every answer marked wrong that
  # the grader now reads as right is flipped, and the child is paid the XP —
  # see AnswerRegrade. DRY_RUN=1 counts without changing anything.
  desc "Re-grade wrong answers with the current grader and give back the ones that were right"
  task regrade: :environment do
    dry_run = ENV["DRY_RUN"].present?
    question_ids = UserAnswer.joins(:assignment_question).where(correct: false, skipped: false)
                             .distinct.pluck("assignment_questions.question_id")
    total = 0

    Question.where(id: question_ids).includes(:possible_answers).find_each do |question|
      count =
        if dry_run
          AnswerRegrade.wrong_answers(question).count { |answer| AnswerRegrade.correct_now?(question, answer) }
        else
          AnswerRegrade.question!(question)
        end
      next if count.zero?

      total += count
      puts "#{question.id}\t#{count}\t#{question.grading['expected'] || question.answer_type}\t#{question.body_text.to_s.truncate(60)}"
    end

    puts "#{dry_run ? 'Would regrade' : 'Regraded'} #{total} answers on #{question_ids.size} questions with wrong answers."
  end
end
