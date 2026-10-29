module Overseer
  class QuestionsController < Overseer::BaseController
    PER_PAGE = 50

    # The browser: search and facets on the left, the result in the middle, the
    # selected question on the right. Choosing a row only swaps the preview
    # pane (a turbo-frame request for the same URL), so the list query is not
    # run again to show one question.
    def index
      @filter = QuestionFilter.new(params)
      @selected = Question.find_by(id: params[:selected]) if params[:selected].present?
      return render_pane(@selected) if turbo_frame_request? && turbo_frame_request_id == "question-pane"

      @questions = @filter.results.includes(:topics, :hint, :possible_answers, :suggested_by).page(params[:page]).per(PER_PAGE)
      ids = @questions.map(&:id)
      @stats = QuestionStats.for(ids)
      # So a flagged question is visible in the list an admin browses, not only
      # in the queue they have to remember to open.
      @open_reports = QuestionReport.active.where(question_id: ids).group(:question_id).count
      @selected ||= @questions.first
      @bank_total = Question.count
      @view_counts = @filter.view_counts
      @topic_counts = @filter.topic_counts
      @type_counts = @filter.answer_type_counts
      @histogram = @filter.histogram
      load_pane(@selected) if @selected
    end

    # Shows the question exactly as a student meets it, in the same focus
    # layout, with the answer controls inert — nothing here can be submitted
    # or graded.
    def preview
      @question = Question.find(params[:id])
      @hint = @question.hint

      render layout: "modal"
    end

    def new
      @question = Question.new(status: :published)
      copy_from(Question.find(params[:copy_of])) if params[:copy_of].present?
      @question.possible_answers.build if @question.possible_answers.empty?
      load_list
    end

    def create
      @question = Question.new(QuestionFormParams.build(params))
      @question.author = current_user
      load_list

      if save_question("created")
        redirect_to(@list ? overseer_questions_path(@list.to_params.merge(selected: @question.id)) : overseer_questions_path,
                    notice: t("overseer.questions.created"))
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      @question = Question.find params[:id]
      @question.possible_answers.build if @question.possible_answers.empty?
      load_list
      load_editor
    end

    def update
      @question = Question.find params[:id]
      load_list
      # Taken before the save: a question edited out of the list it came from
      # (retired, moved to another topic) still knows which one was next.
      following = @list&.position_of(@question.id)&.next_id
      before = QuestionRevision.snapshot(@question)
      @question.assign_attributes(QuestionFormParams.build(params, @question))

      if save_question("updated", before: before)
        redirect_to after_update_path(following), notice: t("overseer.questions.updated")
      else
        load_editor
        render :edit, status: :unprocessable_entity
      end
    end

    # Back to draft — the one status nothing practises from — without the
    # finality of retiring: the question is waiting for an edit.
    def hide
      question = Question.published.find(params[:id])
      change_status(question, :draft, "hidden")

      redirect_back fallback_location: edit_overseer_question_path(question), notice: t("overseer.questions.hidden")
    end

    # Out of practice and duels for good, while every answer already given to
    # it keeps its problem in the student's history and review lists.
    def retire
      question = Question.published.find(params[:id])
      change_status(question, :retired, "retired")

      redirect_back fallback_location: overseer_questions_path, notice: t("overseer.questions.retired")
    end

    def restore
      question = Question.retired.find(params[:id])
      change_status(question, :published, "restored")

      redirect_back fallback_location: overseer_questions_path, notice: t("overseer.questions.restored")
    end

    private

    def render_pane(question)
      load_pane(question) if question
      render partial: "pane", locals: { question: question }
    end

    def load_pane(question)
      @pane_split = QuestionStats.split(question)
      @pane_reports = question.reports.active.newest_first.includes(:user).to_a
    end

    # The list the editor was opened from, carried as `from[...]` so the bar
    # can say where in it this question is and walk to the next one.
    def load_list
      @list = QuestionFilter.new(params[:from]) if params[:from].present?
    end

    def load_editor
      @position = @list&.position_of(@question.id)
      @active_reports = @question.reports.active.newest_first.includes(:user).to_a
      @split = QuestionStats.split(@question)
      @common_wrong = QuestionStats.common_wrong(@question)
      @choosers = QuestionStats.option_choosers(@question)
      @revisions = @question.revisions.newest_first.includes(:author).limit(30)
      @template_count = template_count(@question)
      @topic_spread = topic_spread(@question)
    end

    # The question, its hint ladder and the revision that says what changed,
    # all or nothing. `topic_ids=` writes the join rows the moment it is
    # assigned, so a refused save has to be rolled back rather than merely
    # not saved.
    def save_question(action, before: nil)
      ladder = QuestionFormParams.hint_ladder(params)
      saved = false

      Question.transaction do
        valid = @question.valid?
        if ladder && (leak = QuestionFormParams.leaked_rung(@question, ladder))
          @question.errors.add(:base, t("overseer.questions.editor.hint_leaks", rung: leak))
          valid = false
        end
        raise ActiveRecord::Rollback unless valid

        @question.save!
        QuestionFormParams.save_hint!(@question.reload, ladder, approved: params[:approve_hints] == "1") if ladder
        QuestionRevision.record!(@question, author: current_user, action: action, before: before)
        saved = true
      end

      saved
    end

    def change_status(question, status, action)
      before = QuestionRevision.snapshot(question)
      Question.transaction do
        question.update!(status: status)
        QuestionRevision.record!(question, author: current_user, action: action, before: before)
      end
    end

    def after_update_path(following)
      # Opened from the report queue („Поправи"): back to the question's card
      # there, where the students are waiting for an answer.
      return helpers.internal_path(params[:return_to]) if helpers.internal_path(params[:return_to])
      return edit_overseer_question_path(following, from: @list.to_params) if params[:next].present? && following
      return overseer_questions_path(@list.to_params.merge(selected: @question.id)) if @list

      overseer_questions_path
    end

    # „Копирай като нова": everything but the picture, which a file field
    # cannot be pre-filled with, and the hint's approval, which was given to
    # the other question's words.
    def copy_from(source)
      @question.assign_attributes(
        body: source.body, explanation: source.explanation, answer_type: source.answer_type,
        grading: source.grading, elo: source.elo, topic_ids: source.topic_ids
      )
      source.possible_answers.each { |option| @question.possible_answers.build(value: option.value, correct: option.correct, position: option.position) }
      @copied_ladder = source.hint&.ladder
    end

    # How many questions share this one's template (its text with the numbers
    # blanked), counting itself — the size of „Целият шаблон".
    def template_count(question)
      shape = Question.where(id: question.id).pick(Arel.sql(SessionComposer::SHAPE_SQL))
      Question.where("#{SessionComposer::SHAPE_SQL} = :shape", shape: shape).count
    end

    # Where the other published questions of the same topics sit, so an Elo
    # typed by hand can be read against them: the middle 80%, and the extremes.
    def topic_spread(question)
      return if question.topic_ids.empty?

      low, p10, p90, high, count = Question.published.where.not(id: question.id).
        where("questions.id IN (SELECT question_id FROM questions_topics WHERE topic_id IN (?))", question.topic_ids).
        pick(Arel.sql("min(elo)"), Arel.sql("percentile_disc(0.1) WITHIN GROUP (ORDER BY elo)"),
             Arel.sql("percentile_disc(0.9) WITHIN GROUP (ORDER BY elo)"), Arel.sql("max(elo)"), Arel.sql("count(*)"))
      { min: low, p10: p10, p90: p90, max: high, count: count } if count.to_i.positive?
    end
  end
end
