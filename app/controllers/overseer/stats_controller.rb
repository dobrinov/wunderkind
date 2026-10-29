module Overseer
  class StatsController < BaseController
    # How many accounts the scope picker lists per group: the ones seen most
    # recently, which is who an admin asking „how is this family doing" is
    # almost always asking about. Anyone else is reached from their row in
    # the users list, which links here with their id.
    PICKER_SIZE = 40

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
      @recent_students = User.student.where.not(last_seen_at: nil).order(last_seen_at: :desc).limit(PICKER_SIZE)
      @recent_families = User.parent.
        joins(parent_links: :child).
        group("users.id").
        order(Arel.sql("MAX(children_parent_links.last_seen_at) DESC NULLS LAST")).
        limit(PICKER_SIZE)
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
