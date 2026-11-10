# „Опитай без профил" (/opitay): Trial::LENGTH real problems for a visitor,
# on the real practice card, graded by the real Grading, with the real
# feedback card and its worked explanation — and at the end, the sign-up.
#
# The answering screens are the practice screen's (the modal layout, bare);
# the grade chooser and the result are public pages (the landing layout).
# Nothing is written to the database; see Trial.
class TrialsController < ApplicationController
  layout "landingpage"

  before_action :send_signed_in_home
  before_action :find_grade, except: :index
  before_action :find_run, only: [ :show, :answer, :result ]
  before_action :find_position, only: [ :show, :answer ]

  def index
    @grades = Curriculum.grades
    seo title: t("trial.index.seo_title"), description: t("trial.index.lede", count: Trial::LENGTH)
  end

  # Picks up an unfinished set for this grade, or deals a new one — which is
  # also what „Още задачи" on the result page is.
  def start
    run = Trial::Run.load(session, @grade)

    if run.nil? || run.finished? || run.empty?
      run = Trial::Run.start(session, @grade)
      return redirect_to trial_path, alert: t("trial.no_questions") if run.empty?

      track :trial_started, grade: @grade.number
    end

    redirect_to trial_question_path(@grade.slug, run.next_position)
  end

  def show
    @question = Question.includes(:possible_answers, :topics).find_by(id: @run.question_id(@position))
    # A problem retired or deleted while the set was open: deal a fresh set
    # rather than show a hole.
    return restart if @question.nil?

    @answer = @run.answer(@position)
    @numeric_answer = @question.exact_value? && ExactValue.parse(@question.grading["expected"]).present?
    render layout: "modal"
  end

  def answer
    question = Question.includes(:possible_answers).find_by(id: @run.question_id(@position))
    return restart if question.nil?
    # A double tap or a second tab: the first answer stands, as in practice.
    return redirect_to trial_question_path(@grade.slug, @position) if @run.answered?(@position)

    raw = params.permit(:value, :state, selected_ids: [])
    if Grading.blank_response?(question: question, raw: raw)
      return redirect_to trial_question_path(@grade.slug, @position), alert: t("answers.blank")
    end

    result = Grading.grade(question: question, raw: raw)
    @run.record(@position, correct: result.correct, value: result.display_value)
    @run.save(session)
    track :trial_finished, grade: @grade.number, correct: @run.correct_count if @run.finished?

    # The feedback card, always: the explanation is the thing being shown off.
    redirect_to trial_question_path(@grade.slug, @position)
  end

  def result
    return redirect_to trial_question_path(@grade.slug, @run.next_position) unless @run.finished?

    @questions = @run.questions
  end

  private

  # An account has the real thing, measured and remembered.
  def send_signed_in_home
    redirect_to home_path_for(current_user) if current_user
  end

  def find_grade
    @grade = Curriculum.grade(params[:grade]) || raise(ActionController::RoutingError, "No such grade")
  end

  # A link into the middle of a set this browser never started (shared, or
  # the cookie gone) starts one.
  def find_run
    @run = Trial::Run.load(session, @grade)
    redirect_to trial_grade_path(@grade.slug) if @run.nil? || @run.empty?
  end

  def find_position
    @position = params[:position].to_i
    redirect_to trial_grade_path(@grade.slug) unless @position.between?(1, @run.length)
  end

  def restart
    session.delete(:trial)
    redirect_to trial_grade_path(@grade.slug)
  end
end
