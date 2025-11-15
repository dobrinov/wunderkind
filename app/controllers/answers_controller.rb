class AnswersController < AuthenticatedController
  layout "modal"

  def create
    assignment = Assignment.find(params[:assignment_id])

    assignment_question = assignment.assignment_questions.find_by!(question_id: params[:question_id])
    question = assignment_question.question
    raise "Answer already exists" if assignment_question.user_answer.present?

    answer = assignment_question.build_user_answer value: params[:answer], user: current_user

    answer_is_correct = answer.value == question.answer

    user_games = current_user.user_answers.where(created_at: 6.months.ago..).count
    task_games = question.user_answers.where(created_at: 6.months.ago..).count

    new_user_elo, new_question_elo = Elo.calculate_ratings(
      current_user.elo,
      question.elo,
      player_won: answer_is_correct,
      player_games: user_games,
      task_games: task_games
    )

    current_user.elo = new_user_elo
    question.elo = new_question_elo

    ActiveRecord::Base.transaction do
      current_user.save!
      question.save!
      answer.save!
    end

    next_question = assignment.next_question

    if next_question
      redirect_to assignment_question_path(assignment, next_question)
    else
      assignment.update! completed_at: Time.current
      redirect_to completion_summary_assignment_path(assignment)
    end
  end

  def show
    @assignment = Assignment.find(params[:assignment_id])
    @assignment_question = @assignment.assignment_questions.find_by!(question_id: params[:question_id])
    @question = @assignment_question.question
    @is_correct = @assignment_question.user_answer.value == @question.answer
  end
end
