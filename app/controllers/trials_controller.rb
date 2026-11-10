# „Опитай без профил" (/opitay): Trial::LENGTH real problems for a visitor,
# on the real practice card, graded by the real Grading, with the real
# feedback card and its worked explanation — and at the end, the sign-up.
#
# What is dealt is a Trial::Deck named in the URL — a grade, a topic or a
# competition — so each public page can offer its own problems. The answering
# screens are the practice screen's (the modal layout, bare); the choosers and
# the result are public pages (the landing layout). Nothing is written to the
# database; see Trial.
class TrialsController < ApplicationController
  include CompetitionsHelper

  layout "landingpage"

  before_action :send_signed_in_home
  before_action :find_deck, except: :index
  before_action :find_run, only: [ :show, :answer, :result ]
  before_action :find_position, only: [ :show, :answer ]

  helper_method :trial_origin_path

  def index
    @grades = Curriculum.grades
    # Only the ones with something to deal: its topics or its own papers.
    @events = Competitions.calendar.select { |event| event.topic_ids.any? || PastPapers.grades(event.slug).any? }
    seo title: t("trial.index.seo_title"), description: t("trial.index.lede", count: Trial::LENGTH)
  end

  # Picks up an unfinished set from this deck, or deals a new one — which is
  # also what „Още задачи" on the result page is. A competition whose papers
  # the bank holds asks for the grade first.
  def start
    # НВО 4 has papers for one grade: no question to ask.
    if @deck.grade_choices.one?
      return redirect_to trial_deck_path(Trial::Deck.for_event(@deck.event, @deck.grade_choices.first).key)
    elsif @deck.grade_choices.any?
      seo title: t("trial.choose.title", name: @deck.name)
      return render :choose
    end

    run = Trial::Run.load(session, @deck)

    if run.nil? || run.finished? || run.empty?
      run = Trial::Run.start(session, @deck)
      return redirect_to trial_origin_path(@deck), alert: t("trial.no_questions") if run.empty?

      track :trial_started, **@deck.props
    end

    redirect_to trial_question_path(@deck.key, run.next_position)
  end

  def show
    @question = Question.published.includes(:possible_answers, :topics).find_by(id: @run.question_id(@position))
    # A problem retired or deleted while the set was open: deal a fresh set
    # rather than show a hole.
    return restart if @question.nil?

    @answer = @run.answer(@position)
    @numeric_answer = @question.numeric_answer?
    render layout: "modal"
  end

  def answer
    question = Question.published.includes(:possible_answers).find_by(id: @run.question_id(@position))
    return restart if question.nil?
    # A double tap or a second tab: the first answer stands, as in practice.
    return redirect_to trial_question_path(@deck.key, @position) if @run.answered?(@position)

    raw = params.permit(:value, :state, selected_ids: [])
    if Grading.blank_response?(question: question, raw: raw)
      return redirect_to trial_question_path(@deck.key, @position), alert: t("answers.blank")
    end

    result = Grading.grade(question: question, raw: raw)
    @run.record(@position, correct: result.correct, value: result.display_value)
    @run.save(session)
    track :trial_finished, **@deck.props, correct: @run.correct_count if @run.finished?

    # The feedback card, always: the explanation is the thing being shown off.
    redirect_to trial_question_path(@deck.key, @position)
  end

  def result
    return redirect_to trial_question_path(@deck.key, @run.next_position) unless @run.finished?

    @questions = @run.questions
  end

  private

  # The public page a deck belongs to: where ✕ goes, and where a deck with
  # nothing to deal sends the visitor back.
  def trial_origin_path(deck)
    if deck.event then event_page_path(deck.event)
    elsif deck.topic then curriculum_topic_path(deck.topic.slug)
    else trial_path
    end
  end

  # An account has the real thing, measured and remembered.
  def send_signed_in_home
    redirect_to home_path_for(current_user) if current_user
  end

  def find_deck
    @deck = Trial::Deck.find(params[:deck]) || raise(ActionController::RoutingError, "No such trial")
  end

  # A link into the middle of a set this browser never started (shared, or
  # the cookie gone) starts one.
  def find_run
    @run = Trial::Run.load(session, @deck)
    redirect_to trial_deck_path(@deck.key) if @run.nil? || @run.empty?
  end

  def find_position
    @position = params[:position].to_i
    redirect_to trial_deck_path(@deck.key) unless @position.between?(1, @run.length)
  end

  def restart
    session.delete(:trial)
    redirect_to trial_deck_path(@deck.key)
  end
end
