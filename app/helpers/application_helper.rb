module ApplicationHelper
  def logo
    render "shared/logo"
  end

  def main_menu_items(mobile: false)
    items = [
      { name: t("nav.calendar"), path: calendar_path, active: controller_name.in?(%w[assignments calendars]) }
    ]

    main_menu_for(items, mobile: mobile)
  end

  def admin_menu_items(mobile: false)
    items =
      [
        { name: t("overseer.nav.topics"), path: overseer_topics_path, active: controller_name.in?(%w[topics]) },
        { name: t("overseer.nav.questions"), path: overseer_questions_path, active: controller_name.in?(%w[questions]) },
        { name: t("overseer.nav.users"), path: overseer_users_path, active: controller_name.in?(%w[users]) },
        { name: t("overseer.nav.images"), path: overseer_question_images_path, active: controller_name.in?(%w[question_images]) },
        { name: t("overseer.nav.design_system"), path: design_system_path, active: controller_name.in?(%w[design_system]) }
      ]

    main_menu_for(items, mobile: mobile)
  end

  def main_menu_for(items, mobile: false)
    base_class =
      if mobile
        "block w-full text-left text-base font-medium text-gray-700 px-3 py-2 rounded-md border-0"
      else
        "inline-flex items-center px-3 py-1 text-sm font-medium text-gray-500 rounded-md"
      end

    normal_class = base_class + " hover:bg-gray-100 bg-transparent cursor-pointer"
    active_class = base_class + " bg-gray-100 cursor-default"

    items.select { |item| !item.key?(:when) || item[:when] }.map do |item|
      link_to item[:name], item[:path], class: item[:active] ? active_class : normal_class
    end
  end

  # Only accepts app-internal paths for redirect-style params (back_path,
  # close_path), so a crafted link can't smuggle in javascript: or external URLs.
  def internal_path(value, fallback = nil)
    return fallback if value.blank?

    value.to_s.match?(%r{\A/(?!/)}) ? value.to_s : fallback
  end

  def question_body(question, large: false)
    css = large ? "question-body question-body-large" : "question-body"
    content_tag :div, RichContent.render(question.body), class: css
  end

  def emoji_for_score(score)
    case score
    when 100 then "🏆"
    when 90..99 then "🎖️"
    when 80..89 then "🥇"
    when 70..79 then "🥈"
    when 60..69 then "🥉"
    when 50..59 then "😬"
    when 40..49 then "😕"
    when 30..39 then "😐"
    when 20..29 then "😳"
    when 10..19 then "😢"
    else "😭"
    end
  end

  def message_for_score(score)
    key =
      case score
      when 100 then :perfect
      when 90..99 then :excellent
      when 80..89 then :great
      when 70..79 then :good
      when 60..69 then :ok
      when 50..59 then :meh
      when 40..49 then :poor
      when 30..39 then :bad
      when 20..29 then :very_bad
      when 10..19 then :awful
      else :restart
      end

    t("summary.messages.#{key}")
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
