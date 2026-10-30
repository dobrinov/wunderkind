require "rails_helper"

describe ChildReminder do
  let(:now) { Time.zone.local(2026, 10, 30, 10) }

  around { |example| travel_to(now) { example.run } }

  before { allow(Mailing).to receive(:enabled?).and_return(true) }

  def parent(signed_up:, **attributes)
    create(:user, role: :parent, created_at: now - signed_up, **attributes)
  end

  it "picks parents a few days in with no child, once, and not the long-gone" do
    due = parent(signed_up: 4.days)
    parent(signed_up: 1.day)                                  # too soon
    parent(signed_up: 30.days)                                # signed up before the reminder existed
    parent(signed_up: 4.days, child_reminder_sent_at: 1.day.ago)
    with_child = parent(signed_up: 4.days)
    User.create_managed_child!(parent: with_child, name: "Ани", birth_year: 2018)
    create(:user, role: :student, created_at: now - 4.days)

    ChildReminder.recipients.should contain_exactly(due)

    expect { ChildReminder.deliver(due) }.to change { ActionMailer::Base.deliveries.size }.by(1)
    due.reload.child_reminder_sent_at.should be_present
    ChildReminder.recipients.should be_empty
  end
end

describe ParentMailer do
  before { allow(Mailing).to receive(:enabled?).and_return(true) }

  it "asks an unconfirmed parent to confirm first, with a working link, in Bulgarian" do
    parent = create(:user, role: :parent, name: "Мама", verified_at: nil)
    mail = I18n.with_locale(:en) { ParentMailer.child_reminder(parent) }

    mail.subject.should eq("Потвърди имейла си и добави детето си в Wunderkind")
    [ mail.html_part.decoded, mail.text_part.decoded ].each do |body|
      body.should include("Здравей, Мама!", "/verify-email/", "/parents/children/new")
    end
    token = mail.text_part.decoded[%r{/verify-email/(\S+)}, 1]
    User.find_by_token_for(:email_verification, token).should eq(parent)
  end

  it "asks a confirmed parent only for the child" do
    parent = create(:user, role: :parent, verified_at: Time.current)
    mail = ParentMailer.child_reminder(parent)

    mail.subject.should eq("Добави детето си в Wunderkind")
    mail.html_part.decoded.should_not include("/verify-email/")
  end
end
