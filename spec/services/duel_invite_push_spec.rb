require "rails_helper"

describe "Push notifications for duel invitations" do
  include ActiveJob::TestHelper

  before { create_list(:question, Challenge::QUESTION_COUNT, elo: 1050) }

  let(:host) { create(:user, nickname: "Лъчо") }
  let(:guest) { create(:user) }

  def with_vapid_keys
    key = WebPush.generate_key
    allow(WebPushDelivery).to receive_messages(public_key: key.public_key, private_key: key.private_key)
    yield
  end

  def subscribe(user, endpoint: "https://push.example.com/#{SecureRandom.hex(4)}")
    user.push_subscriptions.create!(endpoint: endpoint, p256dh: "p256dh", auth: "auth")
  end

  it "rings the invited friend once for a new invitation, not for pressing again" do
    expect { ChallengeMatchmaker.invite!(user: host, friend: guest) }.to have_enqueued_job(DuelInviteNotificationJob)
    expect { ChallengeMatchmaker.invite!(user: host, friend: guest) }.not_to have_enqueued_job(DuelInviteNotificationJob)
  end

  it "does not ring anybody when the friend accepts by inviting back" do
    ChallengeMatchmaker.invite!(user: host, friend: guest)

    expect { ChallengeMatchmaker.invite!(user: guest, friend: host) }.not_to have_enqueued_job(DuelInviteNotificationJob)
  end

  it "sends the invitation to each of the friend's devices, naming the host" do
    invite = ChallengeMatchmaker.invite!(user: host, friend: guest)
    2.times { subscribe(guest) }
    subscribe(host)
    sent = []
    allow(WebPush).to receive(:payload_send) { |**args| sent << args }

    with_vapid_keys { DuelInviteNotificationJob.perform_now(invite) }

    sent.size.should eq(2)
    payload = JSON.parse(sent.first[:message])
    payload["body"].should include("Лъчо")
    payload["url"].should eq("/challenges")
    payload["tag"].should eq("duel-invite-#{invite.id}")
    sent.first[:ttl].should be_between(60, Challenge::INVITE_TTL.to_i)
  end

  it "sends nothing for an invitation that is no longer open" do
    invite = ChallengeMatchmaker.invite!(user: host, friend: guest)
    subscribe(guest)
    invite.update!(created_at: (Challenge::INVITE_TTL + 1.minute).ago)
    allow(WebPush).to receive(:payload_send)

    with_vapid_keys { DuelInviteNotificationJob.perform_now(invite) }

    WebPush.should_not have_received(:payload_send)
  end

  it "sends nothing without VAPID keys" do
    invite = ChallengeMatchmaker.invite!(user: host, friend: guest)
    subscribe(guest)
    allow(WebPush).to receive(:payload_send)

    DuelInviteNotificationJob.perform_now(invite)

    WebPush.should_not have_received(:payload_send)
  end

  it "forgets a device the push service says is gone" do
    gone = subscribe(guest)
    response = instance_double(Net::HTTPGone, body: "", inspect: "410")
    allow(WebPush).to receive(:payload_send).and_raise(WebPush::ExpiredSubscription.new(response, "push.example.com"))

    with_vapid_keys do
      WebPushDelivery.deliver(guest, title: "t", body: "b", url: "/", tag: "x", ttl: 60).should eq(0)
    end

    PushSubscription.exists?(gone.id).should be(false)
  end
end
