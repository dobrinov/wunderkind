# „X те кани на двубой" on the invited child's devices, for a new invitation
# (ChallengeMatchmaker.invite!). Run after the request rather than in it, since
# a push service can take seconds to answer. An invitation that was accepted,
# declined or has lapsed by the time this runs sends nothing.
class DuelInviteNotificationJob < ApplicationJob
  queue_as :default
  discard_on ActiveJob::DeserializationError

  def perform(challenge)
    return unless WebPushDelivery.enabled?
    return unless Challenge.open_invites.exists?(challenge.id)

    invitee = challenge.invited_user
    host = challenge.participants.first&.user
    return if invitee.nil? || host.nil?

    name = host.nickname.presence || I18n.t("challenges.anonymous_opponent")
    WebPushDelivery.deliver(
      invitee,
      title: I18n.t("push.duel_invite.title"),
      body: I18n.t("push.duel_invite.body", name: name, minutes: Challenge::INVITE_TTL.in_minutes.to_i),
      url: Rails.application.routes.url_helpers.challenges_path,
      tag: "duel-invite-#{challenge.id}",
      ttl: (Challenge::INVITE_TTL - (Time.current - challenge.created_at)).clamp(60, Challenge::INVITE_TTL)
    )
  end
end
