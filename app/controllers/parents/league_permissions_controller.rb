module Parents
  # Whether a child whose account the parent holds may be in friends'
  # leaderboards (Leagues), where they are shown by first name. Off by default,
  # and only for a managed child: a child with a login of their own decides for
  # themselves. Switching it off takes the child out of every league at once.
  class LeaguePermissionsController < BaseController
    def update
      child = current_user.switchable_children.find(params[:child_id])
      allowed = params[:allowed] == "1"

      User.transaction do
        child.update!(leagues_allowed: allowed)
        child.leagues.each { |league| Leagues.leave!(child, league) } unless allowed
      end

      redirect_to parents_child_path(child, tab: "goals"),
                  notice: t(allowed ? "leagues.parent.allowed" : "leagues.parent.stopped", name: child.name)
    end
  end
end
