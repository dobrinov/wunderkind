module Overseer
  class StatsController < BaseController
    # How many matches the scope search shows per group. It is a search, not a
    # list: a select of every recent account stopped being usable at forty.
    MATCHES = 10

    # Everybody, one family (a parent's children, `family=<parent id>`) or one
    # user (`user_id=`). The picker posts a single `who` field — „f12", „u5" —
    # which is folded into those two so a link to a scope reads the same
    # however it was reached.
    def show
      return redirect_to(overseer_stats_path(scope_params(params[:who]).merge(days: params[:days]))) if params.key?(:who)

      @days = AdminStats.range(params[:days])
      @family = User.parent.find_by(id: params[:family]) if params[:family].present?
      @user = User.where.not(role: :admin).find_by(id: params[:user_id]) if params[:user_id].present? && !@family
      user_ids = @family ? @family.children.where.not(role: :admin).ids : (@user && [ @user.id ])

      @admin_stats = AdminStats.new(days: @days, user_ids:)
      @stats = AnswerStats.new(days: @days, user_ids:)
      @query = params[:q].to_s.strip
      return if @query.blank?

      pattern = "%#{User.sanitize_sql_like(@query)}%"
      matching = "users.name ILIKE :q OR users.email ILIKE :q OR users.nickname ILIKE :q"
      @matching_students = User.student.where(matching, q: pattern).order(Arel.sql("last_seen_at DESC NULLS LAST")).limit(MATCHES)
      # A family by any of its grown-ups' names, or by a child's.
      @matching_families = User.where(role: %i[parent admin]).joins(:parent_links).distinct.
        where("users.id IN (:grownups) OR users.id IN (:of_children)",
              grownups: User.where(role: %i[parent admin]).where(matching, q: pattern).select(:id),
              of_children: ParentLink.where(child_id: User.student.where(matching, q: pattern).select(:id)).select(:parent_id)).
        order(:name).limit(MATCHES)
    end

    # One user's day only. Everybody's misses on a busy day is a list nobody
    # would read, and the question it answers — which problems trip students
    # up — is the reports queue's and the bank's, not this page's.
    def day
      @user = User.find(params[:user_id])
      @date = AnswerStats.date(params[:date])
      return redirect_to(overseer_stats_path(user_id: @user.id)) unless @date

      @answers = AnswerStats.misses(@user, @date)
    end

    private

    def scope_params(who)
      case who.to_s
      when /\Af(\d+)\z/ then { family: $1 }
      when /\Au(\d+)\z/ then { user_id: $1 }
      else {}
      end
    end
  end
end
