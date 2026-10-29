# Private leaderboards among friends — see Leagues. Students only, like
# friends. A league's page is for its members and nobody else: the id in the
# URL is looked up among the student's own leagues, never all of them.
class LeaguesController < AuthenticatedController
  before_action :require_student
  before_action :require_permission, except: :index
  before_action :find_league, only: [ :show, :destroy, :leave, :rotate_code, :remove_member ]
  before_action :require_owner, only: [ :destroy, :rotate_code, :remove_member ]

  # The leagues are a section of „Класация" now rather than a second row of
  # tabs under it (see LeaderboardsController); the address stays for links
  # and bookmarks.
  def index
    redirect_to leaderboard_path(anchor: "leagues")
  end

  def new
    @league = League.new
    @friends = Friends.list(current_user)
  end

  def create
    result = Leagues.create!(current_user, name: params.dig(:league, :name), friend_ids: params.dig(:league, :friend_ids))

    if result.ok?
      track :league_joined, how: "created"
      redirect_to league_path(result.league), notice: t("leagues.created")
    elsif result.error == :invalid
      @league = result.league
      @friends = Friends.list(current_user)
      render :new, status: :unprocessable_entity
    else
      redirect_to leaderboard_path(anchor: "leagues"), alert: t("leagues.errors.#{result.error}")
    end
  end

  def show
    @standings = Leagues.standings(@league)
    @me = @standings.find { |standing| standing.user == current_user }
    @ahead = @standings.select { |s| s.rank && @me&.rank && s.rank == @me.rank - 1 }.first
  end

  def join
    result = Leagues.join!(current_user, params[:code])

    if result.ok?
      track :league_joined, how: "code"
      redirect_to league_path(result.league), notice: t("leagues.joined", name: result.league.name)
    elsif result.error == :already_member
      redirect_to league_path(result.league)
    else
      redirect_to leaderboard_path(anchor: "leagues"), alert: t("leagues.errors.#{result.error}")
    end
  end

  def leave
    Leagues.leave!(current_user, @league)
    redirect_to leaderboard_path(anchor: "leagues"), notice: t("leagues.left", name: @league.name)
  end

  def destroy
    @league.destroy!
    redirect_to leaderboard_path(anchor: "leagues"), notice: t("leagues.deleted", name: @league.name)
  end

  def rotate_code
    @league.rotate_code!
    redirect_to league_path(@league), notice: t("leagues.code_rotated")
  end

  def remove_member
    member = @league.members.find(params[:user_id])
    Leagues.remove!(current_user, @league, member)
    redirect_to league_path(@league), notice: t("leagues.removed", name: member.short_name)
  end

  private

  def find_league
    @league = current_user.leagues.find(params[:id])
  end

  def require_owner
    redirect_to league_path(@league) unless @league.owned_by?(current_user)
  end

  def require_student
    redirect_to home_path_for(current_user) unless current_user.student?
  end

  # A managed child whose parent has not switched leagues on sees the list
  # page, which says so, and nothing else.
  def require_permission
    redirect_to leaderboard_path(anchor: "leagues") unless current_user.may_join_leagues?
  end
end
