class AnswersController < AuthenticatedController
  layout "modal"

  def show
    @assignment_question = AssignmentQuestion.joins(:assignment).where(assignments: { user: current_user }).find params[:question_id]
    @answer = @assignment_question.user_answer
    @assignment = @assignment_question.assignment
    @question = @assignment_question.question
  end

  def create
    assignment_question =
      AssignmentQuestion.
        joins(:assignment).
        where(assignments: { user: current_user }).
        find params[:question_id]

    assignment = assignment_question.assignment
    question = assignment_question.question
    raise "Answer already exists" if assignment_question.user_answer.present?

    answer = assignment_question.build_user_answer value: params[:answer], user: current_user

    new_user_elo, new_question_elo = Elo.calculate_ratings(
      current_user.elo,
      question.elo,
      player_won: answer.correct?,
      player_games: current_user.user_answers.where(created_at: 6.months.ago..).count,
      task_games: question.user_answers.where(created_at: 6.months.ago..).count
    )

    current_user.elo = new_user_elo
    question.elo = new_question_elo

    ActiveRecord::Base.transaction do
      current_user.save!
      question.save!
      answer.save!
    end

    if assignment.next_assignment_question
      redirect_to question_path(assignment_question)
    else
      assignment.update! completed_at: Time.current
      redirect_to assignment_summary_path(assignment)
    end
  end
end
