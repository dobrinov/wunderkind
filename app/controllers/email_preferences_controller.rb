# Which emails to receive, reached from the link in every optional email —
# without signing in, the token in the link being the proof, the way a
# password-reset link is (see EmailPreferences). Signed in, the same switches
# are in Настройки.
#
# Unsubscribing from one kind is two requests on one URL. The GET only shows a
# button, because mail scanners follow every link in a message and an
# unsubscribe that fired on a GET would unsubscribe everybody whose company
# scans mail. The POST is what that button and a mail client's one-click
# unsubscribe (RFC 8058) both send — and the client has no CSRF token to send.
class EmailPreferencesController < ApplicationController
  layout "simple"
  skip_forgery_protection only: :unsubscribe

  before_action :find_user
  before_action :find_kind, only: [ :confirm_unsubscribe, :unsubscribe ]

  def show
    @kinds = EmailPreferences.for(@user)
  end

  def update
    choices = EmailPreferences.for(@user).to_h do |kind|
      [ kind.key, params[:stop_all].blank? && params.dig(:emails, kind.key) == "1" ]
    end
    @user.update!(choices)

    redirect_to email_preferences_path(params[:token]), notice: t("email_preferences.saved")
  end

  def confirm_unsubscribe
  end

  def unsubscribe
    @user.update!(@kind.key => false)
    redirect_to email_preferences_path(params[:token]),
                notice: t("email_preferences.unsubscribed", name: t("email_preferences.kinds.#{@kind.key}.title"))
  end

  private

  def find_user
    @token = params[:token]
    @user = User.find_by_token_for(:email_preferences, @token)
    redirect_to sign_in_path, alert: t("email_preferences.invalid_link") if @user.nil?
  end

  # Only a kind this person can actually be sent: anything else in the URL was
  # typed or is stale.
  def find_kind
    @kind = EmailPreferences.find(params[:kind])
    raise ActiveRecord::RecordNotFound unless @kind && EmailPreferences.for(@user).include?(@kind)
  end
end
