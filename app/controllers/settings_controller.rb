# The account forms — name and nickname, password, sound and feedback, the
# daily minutes, the parent link code. They post to ProfilesController#update
# and PasswordsController as before; only where they are shown moved.
class SettingsController < AuthenticatedController
  def show
    @user = current_user
  end
end
