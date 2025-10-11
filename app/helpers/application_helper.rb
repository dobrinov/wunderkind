module ApplicationHelper
  def main_menu_items(mobile: false)
    items = [
      { name: "Администрация", path: overseer_root_path, when: current_user.admin? },
      { name: "Календар", path: calendar_path, active: controller_name.in?(%w[assignments calendar]) }
    ]

    main_menu_for(items, mobile: mobile)
  end

  def admin_menu_items(mobile: false)
    items =
      [
        { name: "Въпроси", path: overseer_questions_path, active: controller_name.in?(%w[questions]) },
        { name: "Потребители", path: overseer_users_path, active: controller_name.in?(%w[users]) },
        { name: "Изображения", path: overseer_question_images_path, active: controller_name.in?(%w[question_images]) },
        { name: "Скриптове", path: overseer_question_scripts_path, active: controller_name.in?(%w[question_scripts]) }
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

    normal_class = base_class + " hover:bg-gray-200 bg-transparent cursor-pointer"
    active_class = base_class + " bg-gray-100 cursor-default"

    items.select { |item| !item.key?(:when) || item[:when] }.map do |item|
      link_to item[:name], item[:path], class: item[:active] ? active_class : normal_class
    end
  end

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
