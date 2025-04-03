class QuestionsController < ApplicationController
  def start
    session[:current_question_index] = 0
    session[:score] = 0
    redirect_to question_path
  end

  def show
    @current_index = session[:current_question_index] || 0
    @score = session[:score] || 0

    @questions = KenguruQuestion.includes(:kenguru_answers).all
    @total_questions = @questions.count

    if @current_index >= @total_questions
      redirect_to results_path
    else
      @current_question = @questions[@current_index]
    end
  end

  def answer
    Rails.logger.debug "Answer action called with params: #{params.inspect}"

    @current_index = session[:current_question_index]
    @score = session[:score]

    @questions = KenguruQuestion.includes(:kenguru_answers).all
    @current_question = @questions[@current_index]
    @correct_answer = @current_question.kenguru_answers.find_by(correct: true)
    @correct = params[:answer].downcase.strip == @correct_answer.text.downcase

    Rails.logger.debug "Current question: #{@current_question.inspect}"
    Rails.logger.debug "Correct answer: #{@correct_answer.inspect}"
    Rails.logger.debug "User answer: #{params[:answer]}"
    Rails.logger.debug "Is correct: #{@correct}"

    if @correct
      session[:score] = @score + 1
    end

    # Store feedback in session with string keys
    session[:feedback] = {
      'correct' => @correct,
      'user_answer' => params[:answer],
      'correct_answer' => @correct_answer.text
    }

    session[:current_question_index] = @current_index + 1

    if @current_index + 1 >= @questions.count
      redirect_to results_path
    else
      redirect_to feedback_path
    end
  end

  def feedback
    Rails.logger.debug "Feedback action called"
    Rails.logger.debug "Session feedback: #{session[:feedback].inspect}"

    @feedback = session[:feedback]
    @current_index = session[:current_question_index]
    @score = session[:score]
    @questions = KenguruQuestion.includes(:kenguru_answers).all
    @total_questions = @questions.count
    @current_question = @questions[@current_index - 1]

    Rails.logger.debug "Current question: #{@current_question.inspect}"
    Rails.logger.debug "Feedback data: #{@feedback.inspect}"
  end

  def results
    @score = session[:score]
    @total_questions = KenguruQuestion.count
    session[:current_question_index] = nil
    session[:score] = nil
    session[:feedback] = nil
  end
end
