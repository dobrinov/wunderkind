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
    parent(signed_up: 4.days, child_reminder_sent_at: 1.day.ago, child_reminders_sent: 1)
    with_child = parent(signed_up: 4.days)
    User.create_managed_child!(parent: with_child, name: "Ани", birth_year: 2018)
    create(:user, role: :student, created_at: now - 4.days)

    ChildReminder.recipients.should contain_exactly(due)

    expect { ChildReminder.deliver(due) }.to change { ActionMailer::Base.deliveries.size }.by(1)
    due.reload.child_reminder_sent_at.should be_present
    due.child_reminders_sent.should eq(1)
    ChildReminder.recipients.should be_empty
  end

  it "writes once more about a week in, worded as the last, and never a third time" do
    second = parent(signed_up: 9.days, child_reminder_sent_at: now - 6.days, child_reminders_sent: 1)
    parent(signed_up: 9.days, child_reminder_sent_at: now - 2.days, child_reminders_sent: 1) # the first was only just sent
    parent(signed_up: 6.days, child_reminder_sent_at: now - 4.days, child_reminders_sent: 1) # not a week in yet
    parent(signed_up: 12.days, child_reminder_sent_at: now - 3.days, child_reminders_sent: 2)

    ChildReminder.recipients.should contain_exactly(second)

    ChildReminder.deliver(second)
    ActionMailer::Base.deliveries.last.subject.should eq(I18n.t("mailers.child_reminder.second_subject", locale: :bg))
    second.reload.child_reminders_sent.should eq(2)
    ChildReminder.recipients.should be_empty
  end
end

describe ParentMailer do
  before { allow(Mailing).to receive(:enabled?).and_return(true) }

  it "gives an unconfirmed parent a confirmation link as the one button, in Bulgarian" do
    parent = create(:user, role: :parent, name: "Мама", verified_at: nil)
    mail = I18n.with_locale(:en) { ParentMailer.child_reminder(parent) }

    mail.subject.should eq("Добави детето си в Wunderkind")
    [ mail.html_part.decoded, mail.text_part.decoded ].each do |body|
      body.should include("Здравей, Мама!", "/verify-email/")
      body.should_not include("/parents/children/new")
    end
    token = mail.text_part.decoded[%r{/verify-email/(\S+)}, 1]
    User.find_by_token_for(:email_verification, token).should eq(parent)
  end

  it "asks a confirmed parent only for the child" do
    parent = create(:user, role: :parent, verified_at: Time.current)
    mail = ParentMailer.child_reminder(parent)

    mail.subject.should eq("Добави детето си в Wunderkind")
    mail.html_part.decoded.should_not include("/verify-email/")
    mail.html_part.decoded.should include("/parents/children/new")
  end
end
