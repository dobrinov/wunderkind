module ApplicationHelper
  def emoji_for_score(score)
    case score
    when 100
      "🏆"
    when 90..99
      "🎖️"
    when 80..89
      "🥇"
    when 70..79
      "🥈"
    when 60..69
      "🥉"
    when 50..59
      "😬"
    when 40..49
      "😕"
    when 30..39
      "😐"
    when 20..29
      "😳"
    when 10..19
      "😢"
    else
      "😭"
    end
  end

  def distance_in_time(from_time, to_time)
    distance = (to_time - from_time).to_i
    hours = distance / 3600
    minutes = (distance % 3600) / 60
    seconds = distance % 60

    parts = []
    parts << I18n.t("datetime.distance_format.hours", count: format("%d", hours)) if hours > 0
    parts << I18n.t("datetime.distance_format.minutes", count: format("%d", minutes)) if minutes > 0
    parts << I18n.t("datetime.distance_format.seconds", count: format("%d", seconds))

    parts.join(" ")
  end
end
