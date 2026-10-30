namespace :reminders do
  # See ChildReminder. Run daily by cron on the host (see CLAUDE.md,
  # Deployment); safe to run again — a parent once reminded is never a
  # recipient again.
  desc "Email parents who signed up a few days ago and have not added a child (once each)"
  task children: :environment do
    abort "Mail is not configured (SMTP_ADDRESS); nothing sent." unless Mailing.enabled?

    sent = failed = 0
    ChildReminder.recipients.find_each do |parent|
      ChildReminder.deliver(parent)
      sent += 1
    rescue StandardError => error
      failed += 1
      Rails.error.report(error, handled: true, source: "child_reminder", context: { parent_id: parent.id })
      warn "Parent #{parent.id}: #{error.class}: #{error.message}"
    end
    puts "Child reminders: #{sent} sent, #{failed} failed."
  end
end
