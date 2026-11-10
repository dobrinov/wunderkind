# The duel-invitation switch (shared/_push_switch, push_controller.js): whether
# this device notifies the person whose profile is open. `current_user`, not
# `signed_in_user`, because a household tablet is passed between children and
# the invitation is for the child. Writes are refused while impersonating, like
# every other write (ApplicationController).
class PushSubscriptionsController < AuthenticatedController
  # Whether this person already has this device's endpoint — the browser knows
  # it is subscribed, but not for which of the children on it.
  def show
    render json: { subscribed: current_user.push_subscriptions.exists?(endpoint: params[:endpoint].to_s) }
  end

  def create
    subscription = current_user.push_subscriptions.find_or_initialize_by(endpoint: subscription_params[:endpoint].to_s)
    subscription.assign_attributes(
      p256dh: subscription_params.dig(:keys, :p256dh),
      auth: subscription_params.dig(:keys, :auth),
      user_agent: request.user_agent.to_s.first(255)
    )

    if subscription.save
      render json: { subscribed: true }
    else
      render json: { errors: subscription.errors.full_messages }, status: :unprocessable_content
    end
  end

  def destroy
    current_user.push_subscriptions.where(endpoint: params[:endpoint].to_s).delete_all
    render json: { subscribed: false }
  end

  private

  def subscription_params
    params.require(:subscription).permit(:endpoint, keys: [ :p256dh, :auth ])
  end
end
