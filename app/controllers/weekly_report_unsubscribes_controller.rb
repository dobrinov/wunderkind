# Turning the weekly report off from the email itself, without signing in —
# the token in the link is the proof, the way a password-reset link is. The
# GET only shows a button, because mail scanners follow every link in a
# message and an unsubscribe that fires on a GET unsubscribes everybody whose
# company scans mail. The POST is what a person's button and a mail client's
# one-click unsubscribe both send; the client has no CSRF token to send.
class WeeklyReportUnsubscribesController < ApplicationController
  layout "simple"
  skip_forgery_protection only: :create

  def show
    @user = user_from_token
    @token = params[:token]
    redirect_to sign_in_path, alert: t("weekly_report.invalid_link") if @user.nil?
  end

  def create
    user = user_from_token
    return redirect_to(sign_in_path, alert: t("weekly_report.invalid_link")) if user.nil?

    user.update!(weekly_report: false)
    redirect_to weekly_report_unsubscribe_path(params[:token]), notice: t("weekly_report.unsubscribed")
  end

  private

  def user_from_token
    User.find_by_token_for(:weekly_report_unsubscribe, params[:token])
  end
end
