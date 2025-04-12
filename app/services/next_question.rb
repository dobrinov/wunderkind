module NextQuestion
  extend self

  def for(assignment)
    return if assignment.completed_at?
    return if assignment.questions.count >= assignment.question_count

    assignment.unanswered_questions.first if assignment.unanswered_questions.any?
    Question.where.not(id: assignment.question_ids).order("RANDOM()").first
  end
end
