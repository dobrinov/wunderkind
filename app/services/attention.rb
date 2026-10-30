# What the team should look at this week that nobody filed a ticket about —
# the second half of „Табло". The family field test had a 1st-grader at 27%
# right and a third of her problems skipped for two days while the dashboard
# said „Нищо за правене", and children found broken problems long before they
# reported them. Two lists, both read off the answers, nothing stored:
#
# - students who are struggling: far below the TARGET_SUCCESS_RATE every
#   session is aimed at, or skipping much of what they are given — either says
#   the problems are not reaching them;
# - questions most children get wrong: a problem the dispatcher aims at ~70%
#   that hardly anyone gets right is more often broken than hard.
module Attention
  WINDOW = 7.days
  MIN_ANSWERS = 15
  STRUGGLING_ACCURACY = 0.5
  SKIPPING_SHARE = 0.3
  QUESTION_MIN_ANSWERS = 4
  QUESTION_MAX_ACCURACY = 0.25
  LIMIT = 8

  Student = Struct.new(:user, :answers, :accuracy, :skip_share, keyword_init: true)
  Hard = Struct.new(:question, :answers, :accuracy, keyword_init: true)

  module_function

  def struggling_students(since: WINDOW.ago)
    rows = UserAnswer.joins(:user).where(created_at: since.., users: { role: User.roles[:student] })
                     .group(:user_id)
                     .having("COUNT(*) >= ?", MIN_ANSWERS)
                     .pluck(:user_id, Arel.sql("COUNT(*)"),
                            Arel.sql("COUNT(*) FILTER (WHERE user_answers.correct)"),
                            Arel.sql("COUNT(*) FILTER (WHERE user_answers.skipped)"))
    flagged = rows.filter_map do |user_id, total, correct, skipped|
      attempted = total - skipped
      accuracy = attempted.positive? ? correct.to_f / attempted : 0.0
      skip_share = skipped.to_f / total
      next unless accuracy < STRUGGLING_ACCURACY || skip_share > SKIPPING_SHARE

      [ user_id, total, accuracy, skip_share ]
    end
    users = User.where(id: flagged.map(&:first)).index_by(&:id)
    flagged.sort_by { |_, _, accuracy, _| accuracy }.first(LIMIT).map do |user_id, total, accuracy, skip_share|
      Student.new(user: users[user_id], answers: total, accuracy: accuracy, skip_share: skip_share)
    end
  end

  def hard_questions(since: WINDOW.ago)
    rows = UserAnswer.joins(:assignment_question).where(created_at: since.., skipped: false)
                     .group("assignment_questions.question_id")
                     .having("COUNT(*) >= ?", QUESTION_MIN_ANSWERS)
                     .having("AVG(CASE WHEN user_answers.correct THEN 1.0 ELSE 0 END) < ?", QUESTION_MAX_ACCURACY)
                     .order(Arel.sql("COUNT(*) DESC"))
                     .limit(LIMIT)
                     .pluck(Arel.sql("assignment_questions.question_id"), Arel.sql("COUNT(*)"),
                            Arel.sql("AVG(CASE WHEN user_answers.correct THEN 1.0 ELSE 0 END)"))
    questions = Question.where(id: rows.map(&:first)).index_by(&:id)
    rows.map { |id, total, accuracy| Hard.new(question: questions[id], answers: total, accuracy: accuracy.to_f) }
  end
end
