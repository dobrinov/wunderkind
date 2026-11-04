# /discord: the one address of ours the Discord invite is reached by.
#
# The invite is DISCORD_INVITE_URL in the environment (Community) and can move
# without a release; the static error pages in public/ cannot read the
# environment, so they link here. Discord is 13+, so a signed-in student is not
# sent on — they are told it is a place for grown-ups and sent back to the app.
# With no invite configured there is nowhere to go, so it is the home page.
class CommunityController < ApplicationController
  layout "simple"

  def show
    return redirect_to root_path unless Community.discord_url
    return render :grown_ups_only if current_user&.student?

    redirect_to Community.discord_url, allow_other_host: true
  end
end
