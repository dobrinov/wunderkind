module ApplicationHelper
  def logo
    render "shared/logo"
  end

  def main_menu_items(mobile: false)
    teacher_or_parent = current_user.teacher? || current_user.parent?
    items = [
      { name: t("nav.calendar"), path: calendar_path, active: controller_name.in?(%w[assignments calendars]), when: !teacher_or_parent },
      { name: t("nav.classrooms"), path: classrooms_path, active: controller_name == "classrooms" && controller_path == "classrooms", when: current_user.student? },
      { name: t("nav.challenges"), path: challenges_path, active: controller_name.in?(%w[challenges challenge_answers]), when: current_user.student? },
      { name: t("nav.leaderboard"), path: leaderboard_path, active: controller_name == "leaderboards", when: current_user.student? },
      { name: t("nav.my_classrooms"), path: teachers_classrooms_path, active: controller_path.start_with?("teachers/classrooms", "teachers/homeworks"), when: current_user.teacher? },
      { name: t("nav.library"), path: teachers_questions_path, active: controller_path == "teachers/questions", when: current_user.teacher? },
      { name: t("nav.children"), path: parents_children_path, active: controller_path.start_with?("parents/"), when: current_user.parent? }
    ]

    main_menu_for(items, mobile: mobile)
  end

  # The other profiles inside this login, for the picker in the child bar: a
  # household hands one device around, so switching child should be one tap
  # rather than a trip back through the parent's own screens.
  def other_child_profiles
    signed_in_user.managed_children.where.not(id: current_user.id).order(:name)
  end

  def admin_menu_items(mobile: false)
    items =
      [
        { name: t("overseer.nav.topics"), path: overseer_topics_path, active: controller_name.in?(%w[topics]) },
        { name: t("overseer.nav.questions"), path: overseer_questions_path, active: controller_name.in?(%w[questions]) },
        { name: t("overseer.nav.reviews"), path: overseer_reviews_path, active: controller_name.in?(%w[reviews]) },
        { name: reports_nav_label, path: overseer_question_reports_path, active: controller_name.in?(%w[question_reports]) },
        { name: t("overseer.nav.users"), path: overseer_users_path, active: controller_name.in?(%w[users]) },
        { name: t("overseer.nav.design_system"), path: design_system_path, active: controller_name.in?(%w[design_system]) }
      ]

    main_menu_for(items, mobile: mobile)
  end

  # The flagged-question queue carries its count in the label: a report that
  # nobody looks at is a report that was not worth asking for.
  def reports_nav_label
    open_reports = QuestionReport.open.count
    return t("overseer.nav.reports") if open_reports.zero?

    "#{t("overseer.nav.reports")} (#{open_reports})"
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
  # close_path), so a crafted link can't smuggle in javascript: or external
  # URLs. Backslashes are rejected outright: browsers normalize "\" to "/" in
  # URLs, so "/\evil.com" would leave the site as the protocol-relative
  # "//evil.com" the leading-slash check exists to block.
  def internal_path(value, fallback = nil)
    value = value.to_s
    return fallback if value.blank? || value.include?("\\")

    value.match?(%r{\A/(?!/)}) ? value : fallback
  end

  def question_body(question, large: false)
    css = large ? "question-body question-body-large" : "question-body"
    content_tag :div, RichContent.render(question.body), class: css
  end

  # A bare "3/4" that came out of a widget or a grading key, set the way the
  # question body would set it. Deliberately narrow: only a whole string that is
  # nothing but one fraction, so "0,75" and "1 1/2" are left as typed rather
  # than half-rendered.
  FRACTION = %r{\A\s*(-?\d+)\s*/\s*(\d+)\s*\z}

  # Whether math_value will typeset this as a stacked fraction — the callers that
  # strike a wrong answer through need to know, because a line across a fraction
  # crosses its own bar.
  def fraction_value?(value)
    FRACTION.match?(value.to_s)
  end

  def math_value(value)
    match = FRACTION.match(value.to_s)
    return value.to_s if match.nil?

    render "shared/frac", numerator: match[1], denominator: match[2]
  end

  # Opponents are shown by nickname only, like the leaderboard: a duel pairs a
  # child with a stranger, and the fact that they were matched is not a reason
  # to hand over their real name.
  def opponent_name(user)
    user.nickname.presence || t("challenges.anonymous_opponent")
  end

  def duel_clock(seconds)
    format("%d:%02d", seconds / 60, seconds % 60)
  end

  # How many correct answers in a row the student is on inside this session. A
  # feedback card that can say "4 верни отговора подред" tells them something;
  # one that only says "Вярно" tells them what they already knew.
  def correct_run_length(assignment)
    answers = assignment.assignment_questions.filter_map(&:user_answer)
    answers.reverse.take_while(&:correct?).size
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
