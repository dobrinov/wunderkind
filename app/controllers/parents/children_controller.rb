module Parents
  class ChildrenController < BaseController
    def index
      @overviews = current_user.children.order(:name).map { |child| ChildOverview.new(child) }
      load_family if @overviews.any?
    end

    TABS = %w[progress practice goals].freeze
    # „Сигнали" — the questions the child reported, and the conversation with
    # the team about each — is a tab only once there is one.
    REPORTS_TAB = "reports"

    # The parent's observation space, in three tabs: „Напредък" (how the child
    # is actually doing — the same charts the child sees on „Аз", because there
    # is no second way of drawing nine weeks of practice), „Какво упражнява"
    # (general practice or a focus, and how long a day's session is) and „Цели
    # и награди" (what has been asked and what was earned). Rewards still owed
    # sit above the tabs on all three: they are the one thing on the page a
    # parent has to act on.
    def show
      @child = current_user.children.find(params[:id])
      Goals.refresh!(@child)
      PracticeFocuses.refresh!(@child)

      @tabs = TABS + (@child.question_reports.exists? ? [ REPORTS_TAB ] : [])
      # Two parents promising things to one child need to see whose promise
      # each is, so neither gives a reward twice; one parent does not.
      @co_parented = @child.parents.count > 1
      @tab = @tabs.include?(params[:tab]) ? params[:tab] : TABS.first
      @band = RatingBand.new(@child.elo)
      @standings = Goals.standings(@child)
      @awards = GoalAward.joins(:goal).where(goals: { child_id: @child.id }).includes(goal: :parent).recent_first
      @focus = PracticeFocuses.current(@child)
      @owed_focuses = @child.practice_focuses.completed.where(reward_given_at: nil).where.not(reward: nil).includes(:parent, :topics).order(completed_at: :desc)

      case @tab
      when "progress"
        @trend = PerformanceTrend.new(@child)
        @stats = AnswerStats.new(days: AnswerStats.range(params[:days]), user: @child)
      when "practice"
        load_practice_tab
      when REPORTS_TAB
        @reports = @child.question_reports.includes(:question, messages: :author).order(updated_at: :desc)
      end
    end

    # The day behind a click on the child's stats: what they got wrong and what
    # they said they had not been taught.
    def stats_day
      @child = current_user.children.find(params[:id])
      @date = AnswerStats.date(params[:date])
      return redirect_to(parents_child_path(@child)) unless @date

      @answers = AnswerStats.misses(@child, @date)
    end

    def new
    end

    # Two paths in: link an existing student by their link code, or create a
    # fresh child account (the usual route for younger kids).
    def create
      if params[:link_code].present?
        link_existing_child
      else
        create_child_account
      end
    end

    private

    # The „Родители" card: every parent sharing a child with this one, which of
    # these children each is linked to (named only when it is not all of them),
    # and the invitations any of them still has out. Three queries, however
    # many parents and children.
    def load_family
      @family_parents = current_user.family_parents.order(:created_at).to_a
      names = @overviews.to_h { |overview| [ overview.child.id, overview.child.name ] }
      @shared_children = ParentLink.where(child_id: names.keys).pluck(:parent_id, :child_id).
        group_by(&:first).transform_values { |pairs| pairs.map { |(_, child_id)| names[child_id] }.sort }
      @invitations = FamilyInvitation.pending.where(inviter_id: @family_parents.map(&:id)).includes(:inviter).order(:created_at).to_a
    end

    def load_practice_tab
      active = @focus if @focus&.active?
      @offer = PracticeFocuses.offer(@child, keep: active ? active.topic_ids : [])
      return unless active

      @focus_progress = PracticeFocuses.progress(active)
      @thin_topics = PracticeFocuses.thin_topics(active)
      @skipped_count = PracticeFocuses.skipped_count(active)
    end

    def link_existing_child
      child = User.student.find_by(link_code: params[:link_code].to_s.strip.upcase)

      if child.nil?
        redirect_to new_parents_child_path, alert: t("parents.children.invalid_code")
      elsif current_user.children.include?(child)
        redirect_to parents_children_path, notice: t("parents.children.already_linked", name: child.name)
      else
        current_user.parent_links.create!(child: child)
        track :child_added, how: "linked"
        redirect_to parents_child_path(child, tab: "practice", welcome: 1), notice: t("parents.children.linked", name: child.name)
      end
    end

    # Email and password are optional: without them the child has no login of
    # their own and plays by switching profiles inside this parent's account,
    # which is the usual shape for a child too young for an email.
    def create_child_account
      child = User.create_managed_child!(
        parent: current_user,
        name: params[:name],
        email: params[:email],
        password: params[:password],
        birth_year: params[:birth_year].presence,
        grade_offset: params[:grade_offset].presence || 0
      )

      track :child_added, how: "created"
      # Straight on to step two of a parent's first run — how long and what —
      # rather than back to a list with one card on it.
      redirect_to parents_child_path(child, tab: "practice", welcome: 1), notice: t("parents.children.created", name: child.name)
    rescue ActiveRecord::RecordInvalid => error
      redirect_to new_parents_child_path, alert: error.record.errors.full_messages.join(", ")
    end
  end
end
