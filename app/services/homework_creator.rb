# Builds a homework and materializes one resumable assignment per student.
# Questions come from hand-picked ids (the assigner's own library or the
# published pool) plus an optional auto-fill by topic near the group's level.
module HomeworkCreator
  extend self

  NoStudents = Class.new(StandardError)
  NoQuestions = Class.new(StandardError)

  def execute(assigner:, title:, due_at:, students:, classroom: nil, question_ids: [], auto_count: 0, topic_ids: [],
              hints_allowed: false)
    students = Array(students).uniq
    raise NoStudents if students.empty?

    questions = picked_questions(assigner, question_ids)
    questions += auto_questions(students, auto_count.to_i, topic_ids, excluding: questions)
    raise NoQuestions if questions.empty?

    homework = nil
    ActiveRecord::Base.transaction do
      homework = Homework.create!(assigner:, classroom:, title:, due_at:, hints_allowed:)
      questions.each_with_index do |question, index|
        homework.homework_questions.create!(question:, position: index + 1)
      end

      students.each do |student|
        assignment = Assignment.new(user: student, kind: :homework, homework:)
        questions.each_with_index do |question, index|
          assignment.assignment_questions.build(question:, position: index + 1)
        end
        assignment.save!
      end
    end

    homework
  end

  private

  def picked_questions(assigner, question_ids)
    return [] if question_ids.blank?

    Question.
      where(id: question_ids).
      where(Question.arel_table[:author_id].eq(assigner.id).or(Question.arel_table[:status].eq(Question.statuses[:published]))).
      to_a
  end

  def auto_questions(students, count, topic_ids, excluding:)
    return [] unless count.positive?

    target_rating = (students.sum(&:elo).to_f / students.size).round
    scope = Question.published.where.not(id: excluding.map(&:id))
    scope = scope.where(id: Question.joins(:topics).where(topics: { id: topic_ids }).select(:id)) if topic_ids.present?

    scope.
      order(Arel.sql("ABS(elo - #{target_rating.to_i})")).
      limit(count).
      to_a.
      shuffle
  end
end
