module ApplicationHelper
  def logo
    render "shared/logo"
  end

  # The one menu. A student gets the same four places on a desktop as on the
  # phone's tab bar, in the same words: the header and the tab bar used to list
  # different things („Предизвикателства" up top, „Двубой" below) and the
  # review list, friends and the leaderboard were each somewhere else. Friends
  # and the leaderboard are now tabs of the duel (see challenges/_tabs), where
  # they are used; settings, suggesting a problem and the changelog sit behind
  # the avatar (shared/_account_menu). A parent's one place is the family page.
  # `post:` is the practice item, which starts a daily session rather than
  # linking anywhere — what a child means when they press it.
  def nav_items
    if current_user.student?
      [
        { name: t("nav.calendar"), icon: "🏠", path: calendar_path, active: home_active? },
        { name: t("nav.practice"), icon: "✏️", path: daily_assignment_path, post: true, active: controller_name == "assignment_questions" },
        { name: t("nav.duel"), icon: "⚔️", path: challenges_path, active: duel_active?, count: duel_waiting_count },
        { name: t("nav.me"), icon: "🏅", path: profile_path, active: controller_name == "profiles" }
      ]
    elsif current_user.parent? || current_user.children.exists?
      [ { name: t("nav.children"), icon: "🏡", path: parents_children_path, active: controller_path.start_with?("parents/") } ]
    else
      []
    end
  end

  def home_active?
    controller_name.in?(%w[assignments calendars reviews stats])
  end

  def duel_active?
    controller_name.in?(%w[challenges challenge_answers friendships leaderboards])
  end

  # Somebody waiting on this student under „Двубой": a friend request to
  # answer or a friend's invitation to a duel. Both are things another child
  # is sitting in front of a screen for, so they ride on the nav item rather
  # than waiting to be found. A plain count rather than
  # ChallengeMatchmaker.invites_for, which sweeps expired rooms — a write this
  # runs on every page and must not.
  def duel_waiting_count
    Friendship.awaiting(current_user).count +
      Challenge.open_invites.where(invited_user_id: current_user.id).count
  end

  # Managed children the signed-in parent can hand the device to, for the
  # header's „Кой ще тренира?" switcher — a child without an email has no
  # login, so switching in is the only way they ever practise, and it should
  # be one tap from any screen rather than a button inside one card. Not while
  # a child's profile is already open: the child bar does that job there.
  def switchable_children
    return User.none if acting_as_child?

    signed_in_user.managed_children.order(:name)
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
        { name: t("overseer.nav.stats"), path: overseer_stats_path, active: controller_name.in?(%w[stats]) },
        { name: t("overseer.nav.design_system"), path: design_system_path, active: controller_name.in?(%w[design_system]) }
      ]
    # An admin can be somebody's parent too; the parent pages already let them in.
    items << { name: t("nav.children"), path: parents_children_path, active: controller_path.start_with?("parents/") } if current_user&.children&.exists?

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

  # How close another child's rating is to the viewer's, in the one word a
  # child is shown about it. Other children's bands are not shown at all — a
  # list of friends labelled „Начинаещ" and „Силен" is a ranking — so a lobby
  # says only when a room is a good match, and nothing when it is not.
  NEAR_LEVEL = 150

  def near_level?(other)
    (other.elo.to_i - current_user.elo.to_i).abs <= NEAR_LEVEL
  end

  # The byline on a suggested problem. Nickname when there is one, for the
  # same reason duels and the leaderboard use it; a parent has no
  # nickname and is credited by name.
  def suggester_display_name(user)
    user.nickname.presence || user.name
  end

  # What a suggester sees happened to their problem. Internally a rejection
  # parks the question in draft or the private library, but to the suggester
  # both just mean "not taken" — the internal statuses are not their business.
  def suggestion_status(question)
    case question.status
    when "in_review" then "waiting"
    when "published", "retired" then "accepted"
    else "returned"
    end
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

  # What a rung says under its medal: the date it was earned, the count still
  # to go, or — for a secret badge nobody should be told how to chase — that
  # there is a condition and no more than that.
  def badge_rung_note(rung)
    return l(rung.earned_at.to_date, format: :short) if rung.earned?
    return t("badges_page.secret_short") if rung.badge.secret?
    return rung.progress.to_s if rung.progress

    rung.badge.description
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
