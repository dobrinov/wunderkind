require "net/http"

# Posts each new release in config/changelog.yml to the Discord server's
# #новини, through the channel's webhook (DISCORD_NEWS_WEBHOOK_URL in
# /opt/apps/wunderkind/.env). Run by `rake changelog:announce` from the host's
# deploy.sh once the new container is healthy, so a release is announced only
# when it is actually live and a failed deploy announces nothing.
#
# What has been announced is one version string in a file on the persistent
# storage volume — not a table, because it is a note about one outside
# channel, and not Discord itself, because a webhook can post but not read.
# The first run only writes the current version down: the channel should not
# open with every release since August. Several new versions post one message
# each, oldest first, and the file moves after each, so a failure halfway
# resumes where it stopped instead of posting the first ones twice.
#
# The entries are the Bulgarian ones, as written for a child and a parent.
module ChangelogAnnouncement
  STATE_PATH = Rails.root.join("storage/changelog_announced_version")
  MESSAGE_LIMIT = 2000

  module_function

  def webhook_url
    ENV["DISCORD_NEWS_WEBHOOK_URL"].presence
  end

  # Returns :disabled, :primed, or the versions it posted (possibly none).
  def call(url: webhook_url, state_path: STATE_PATH, post: method(:post))
    return :disabled unless url

    current = Changelog.current_version
    announced = state_path.exist? ? state_path.read.strip.presence : nil
    unless announced
      state_path.write(current.to_s)
      return :primed
    end

    fresh = Changelog.entries.reverse.select { |entry| Changelog.newer?(entry.version, announced) }
    fresh.each do |entry|
      post.call(url, message_for(entry))
      state_path.write(entry.version)
    end
    fresh.map(&:version)
  end

  def message_for(entry)
    I18n.with_locale(:bg) do
      lines = [ "🆕 **#{entry.title}** · #{date_words(entry.date)}", "" ]
      lines += entry.items.map { |item| "• #{item}" }
      lines += [ "", "Всички промени: <https://wunderkind.bg/changelog>" ]
      text = lines.join("\n")
      text.length > MESSAGE_LIMIT ? text.truncate(MESSAGE_LIMIT) : text
    end
  end

  def date_words(date)
    month = I18n.t("date.month_names", locale: :bg)[date.month].to_s.downcase
    "#{date.day} #{month} #{date.year}"
  end

  # No mentions ever (an entry is not allowed to ping @everyone by accident)
  # and no link previews; Discord answers 204 on success.
  def post(url, content)
    uri = URI(url)
    response = Net::HTTP.post(uri, { content: content, allowed_mentions: { parse: [] }, flags: 4 }.to_json,
                              "Content-Type" => "application/json")
    raise "Discord webhook answered #{response.code}: #{response.body}" unless response.is_a?(Net::HTTPSuccess)
  end
end
