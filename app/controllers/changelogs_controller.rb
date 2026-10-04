# „Какво е новото" — the dialog a returning user is met by, and the page they
# can go back and read it on.
#
# `update` is what the dialog's one button does: it stamps the newest version
# there is, not the newest version the user happened to be shown. The two are
# the same in every ordinary case, and when they are not — a release shipped
# between the page rendering and the button being pressed — stamping the newest
# is the kinder of the two mistakes: a missed note beats a dialog that reopens
# on the same release the moment it is dismissed.
class ChangelogsController < AuthenticatedController
  layout "application"

  def show
    @entries = Changelog.entries
    # Reading the page *is* being told, so it answers the dialog too — nobody
    # should have to dismiss a dialog about what they have just finished reading.
    current_user.changelog_seen!(Changelog.current_version) unless impersonating?
  end

  def update
    current_user.changelog_seen!(Changelog.current_version)
    redirect_back fallback_location: home_path_for(current_user)
  end
end
