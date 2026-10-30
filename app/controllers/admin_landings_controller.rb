# „Отваряй приложението в" in the account menu: which side an admin who is
# also a parent opens on — see ApplicationController#admin_home_path.
class AdminLandingsController < AuthenticatedController
  def update
    return redirect_to(root_path) unless current_user.admin?

    landing = params[:admin_landing].to_s
    current_user.update!(admin_landing: landing) if User.admin_landings.key?(landing)
    redirect_back fallback_location: home_path_for(current_user), notice: t("admin_landing.saved")
  end
end
