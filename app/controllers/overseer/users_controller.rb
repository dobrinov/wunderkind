module Overseer
  # The people behind the app, by household. The list is families first —
  # parents with their children nested under them, two parents of one child
  # shown as one family (see Families) — then the students nobody is linked
  # to, then the old flat list of everybody, kept for sorting by sign-in.
  #
  # A person's page is one of two, by what they are to the app: a student's
  # (their practice, answers, topics, tickets, duels and settings) or a
  # grown-up's (their children, the goals they set, their emails). An admin
  # who is also somebody's parent gets the grown-up's, tagged as an admin.
  class UsersController < BaseController
    VIEWS = %w[families orphans all].freeze
    STUDENT_TABS = %w[overview answers skills tickets duels account].freeze
    PARENT_TABS = %w[overview children goals tickets emails account].freeze

    before_action :set_user, except: %i[index unlink]

    def index
      @view = VIEWS.include?(params[:view]) ? params[:view] : VIEWS.first
      @query = params[:q].to_s.strip.presence
      @filters = Array(params[:f]) & Families::FILTERS
      @family = params[:family].presence&.to_i
      @counts = {
        "families" => Families.count(query: @query, filters: @filters),
        "orphans" => Families.orphans(query: @query, filters: @filters).count
      }

      case @view
      when "families"
        @families = Families.page(query: @query, filters: @filters, family: @family, page: params[:page])
        @tickets = open_tickets(@families.flat_map { |family| family.parents + family.children })
      when "orphans"
        @users = Families.orphans(query: @query, filters: @filters).page(params[:page])
        @tickets = open_tickets(@users)
      else
        @users = Families.filter(User.includes(:managed_by), query: @query, filters: @filters).
          order(User.arel_table[:last_login_at].desc.nulls_last, created_at: :desc).page(params[:page])
      end
    end

    def show
      @family = Families.of(@user)
      if @user.student?
        @tabs = STUDENT_TABS
        @tab = @tabs.include?(params[:tab]) ? params[:tab] : @tabs.first
        load_student
        render :student
      else
        @tabs = PARENT_TABS
        @tab = @tabs.include?(params[:tab]) ? params[:tab] : @tabs.first
        load_parent
        render :parent
      end
    end

    # The link is the one a student or parent would have asked for themselves
    # on the sign-in page, sent the same way (PasswordResetsController): there
    # is no way to read a password and none to set one from here.
    def password_reset
      return refuse(t("overseer.people.actions.no_mail")) unless Mailing.enabled? && @user.email.present?

      UserMailer.password_reset(@user).deliver_later
      redirect_to overseer_user_path(@user, tab: "account"), notice: t("overseer.people.actions.reset_sent", email: @user.email)
    end

    def verification
      return refuse(t("overseer.people.actions.no_mail")) unless Mailing.enabled? && @user.email.present?
      return refuse(t("overseer.people.actions.already_verified")) if @user.verified_at.present?

      UserMailer.email_verification(@user).deliver_later
      redirect_to overseer_user_path(@user, tab: "account"), notice: t("overseer.people.actions.verification_sent", email: @user.email)
    end

    # Takes a child off one parent's account. A child whose account this
    # parent *holds* is a different matter: with no address of their own the
    # parent's login is the only way anybody reaches them, so that is refused;
    # with one, the child keeps their own login and stops being held.
    def unlink
      parent = User.find(params[:user_id])
      link = parent.parent_links.find_by!(child_id: params[:child_id])
      child = link.child

      if child.managed_by_id == parent.id && child.email.blank?
        return redirect_to overseer_user_path(parent, tab: "children"),
                           alert: t("overseer.people.actions.unlink_only_door", child: child.name, parent: parent.name)
      end

      ParentLink.transaction do
        child.update!(managed_by: nil) if child.managed_by_id == parent.id
        link.destroy!
      end
      redirect_to overseer_user_path(parent, tab: "children"),
                  notice: t("overseer.people.actions.unlinked", child: child.name, parent: parent.name)
    end

    def delete
      @deletion = AccountDeletion.new(@user)
      @refusal = @deletion.refusal(by: current_user)
    end

    # Typed confirmation of the name, because there is no undo: the answers,
    # the ratings and the children's accounts this one holds all go with it.
    def destroy
      deletion = AccountDeletion.new(@user)
      if (reason = deletion.refusal(by: current_user))
        return redirect_to(delete_overseer_user_path(@user), alert: t("overseer.people.delete.refused.#{reason}"))
      end
      if params[:confirm_name].to_s.strip != @user.name.strip
        return redirect_to(delete_overseer_user_path(@user), alert: t("overseer.people.delete.name_mismatch"))
      end

      deletion.call!
      redirect_to overseer_users_path, notice: t("overseer.people.delete.done", name: @user.name)
    end

    private

    def set_user
      @user = User.find(params[:id])
    end

    def refuse(message)
      redirect_to overseer_user_path(@user, tab: "account"), alert: message
    end

    # Open tickets per person on the page, in one query.
    def open_tickets(users)
      QuestionReport.active.where(user_id: users.map(&:id)).group(:user_id).count
    end

    def load_student
      @parents = @user.parents.order(:name).to_a
      @siblings = User.joins(:child_links).where(parent_links: { parent_id: @parents.map(&:id) }).
        where.not(id: @user.id).distinct.order(:name).to_a
      @active_tickets = @user.question_reports.active.includes(:question).order(updated_at: :desc).to_a
      @focus = PracticeFocuses.current(@user)

      case @tab
      when "overview"
        @trend = PerformanceTrend.new(@user)
        @record = StudentRecord.new(@user, trend: @trend)
        @skills = @user.skills.includes(:topic).order(games_count: :desc, rating: :desc).limit(8).to_a
        @skills_count = @user.skills.count
        @sessions = @record.recent_sessions
      when "answers"
        @answers = @user.user_answers.includes(assignment_question: [ :assignment, { question: :topics } ]).
          order(created_at: :desc).page(params[:page]).per(30)
      when "skills"
        @skills = @user.skills.includes(:topic).order(games_count: :desc, rating: :desc).to_a
      when "tickets"
        @reports = @user.question_reports.includes(:question).order(updated_at: :desc).to_a
      when "duels"
        @duel_record = ChallengeRecord.for(@user)
        @duels = ChallengeRecord.history(@user, limit: 20)
        @friends = Friends.list(@user)
        @pending_friends = Friendship.pending.involving(@user).count
        @leagues = @user.leagues.includes(:owner).order(:name).to_a
      end
    end

    def load_parent
      @children = @user.children.includes(:managed_by, :child_links).order(:name).to_a
      @co_parents = User.joins(:parent_links).where(parent_links: { child_id: @children.map(&:id) }).
        where.not(id: @user.id).distinct.order(:name).to_a
      @child_tickets = QuestionReport.where(user_id: @children.map(&:id)).includes(:question, :user).order(updated_at: :desc).to_a

      case @tab
      when "overview"
        @overviews = @children.map { |child| ChildOverview.new(child) }
        @first_steps = FirstSteps.new(@user, @children)
        load_promises
      when "children"
        @tickets = open_tickets(@children)
      when "goals"
        load_promises
        @used_awards = GoalAward.joins(:goal).where(goals: { parent_id: @user.id }).where.not(used_at: nil).
          includes(goal: :child).order(used_at: :desc).limit(30).to_a
        @archived_goals = @user.set_goals.where.not(archived_at: nil).includes(:child).order(archived_at: :desc).limit(30).to_a
      end
    end

    # What this parent asked of their children and promised for it, in their
    # own words, with where each stands — and what is owed, oldest first.
    def load_promises
      @standings = @children.flat_map do |child|
        Goals.standings(child).select { |standing| standing.goal.parent_id == @user.id }
      end
      @focuses = @children.filter_map do |child|
        focus = PracticeFocuses.current(child)
        focus if focus&.parent_id == @user.id && focus.active?
      end
      @owed_awards = GoalAward.joins(:goal).where(goals: { parent_id: @user.id }).unused.includes(goal: :child).order(:earned_at).to_a
      @owed_focuses = @user.set_practice_focuses.completed.where(reward_given_at: nil).where.not(reward: nil).
        includes(:child, :topics).order(:completed_at).to_a
    end
  end
end
