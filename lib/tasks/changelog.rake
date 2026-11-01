namespace :changelog do
  # See ChangelogAnnouncement. Run by /opt/apps/wunderkind/deploy.sh after the
  # healthcheck; safe to run again — an announced version is never posted twice.
  desc "Post new changelog releases to the Discord #новини channel"
  task announce: :environment do
    result = ChangelogAnnouncement.call
    case result
    when :disabled then puts "DISCORD_NEWS_WEBHOOK_URL is not set; nothing posted."
    when :primed then puts "First run: recorded #{Changelog.current_version}, posted nothing."
    else puts(result.empty? ? "No new releases." : "Announced #{result.join(', ')}.")
    end
  end
end
