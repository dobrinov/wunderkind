# Setting or clearing the parent's PIN for the shared tablet (User#profile_pin),
# from Настройки. A parent's own setting: refused while a child's profile is
# open, since the child is the one it keeps out.
class ProfilePinsController < AuthenticatedController
  before_action :require_parent

  def update
    pin = params[:pin].to_s.strip
    return redirect_to settings_path(anchor: "settings-tablet"), alert: t("profile_pin.invalid") unless pin.match?(User::PIN_FORMAT)

    current_user.update!(profile_pin: pin)
    redirect_to settings_path(anchor: "settings-tablet"), notice: t("profile_pin.saved")
  end

  def destroy
    current_user.update!(profile_pin: nil)
    redirect_to settings_path(anchor: "settings-tablet"), notice: t("profile_pin.cleared")
  end

  private

  def require_parent
    redirect_to settings_path if acting_as_child? || !current_user.switchable_children.exists?
  end
end
