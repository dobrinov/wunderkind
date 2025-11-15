module AssignmentCreator
  extend self

  RANGE_STEPS = [ 55, 89, 144, 233, 377, 610, 987, 1597, 2584, 4181 ]

  def execute(user:, question_count:, topics: [])
    assignment = Assignment.build(user:)

    range_step_index = 0
    selected_questions = []

    while selected_questions.count < question_count
      range_step = RANGE_STEPS[range_step_index]

      questions =
        Question.
          where.not(id: selected_questions.map(&:id)).
          order("RANDOM()").
          limit(question_count - selected_questions.count)

      questions = questions.where(elo: (user.elo - range_step)..(user.elo + range_step))  if range_step.present?
      questions = questions.where(topics: topics) if topics.any?

      selected_questions += questions
      range_step_index += 1

      break if range_step.nil?
    end

    raise "Too many questions selected" if selected_questions.count > question_count
    raise "Not enough questions found" if selected_questions.count < question_count

    ActiveRecord::Base.transaction do
      assignment.questions << selected_questions
      assignment.save!
    end

    assignment
  end
end
