module ApplicationHelper
  def logo
    render "shared/logo"
  end

  # The one menu, the same on every screen size: a student's four places in
  # the header from 640px and on the phone's tab bar below it, in the same
  # words — „Днес" · „Упражнения" · „Двубой" · „Аз". „Днес" is today's
  # session and whatever is waiting on the child; „Упражнения" is every way to
  # practise in one list (the daily session, „За преговор", competition
  # preparation), which used to be a POST that started a session and left
  # the review list and competitions reachable only from home-page cards.
  # „Двубой" joins the menu once the child plays (FeatureVisibility); before
  # that it is a row under „Упражнения" and „Аз", there to be found but not
  # pushed at a child on their first day.
  # Friends and the leaderboard are tabs of the duel (challenges/_tabs);
  # settings, suggesting a problem and the changelog sit behind the avatar
  # (shared/_account_menu). A parent's one place is the family page. Icons are
  # names for shared/_icon, not emoji.
  def nav_items
    return [] unless current_user

    if admin_workspace == :admin
      admin_nav_items
    elsif workspace_switch?
      # The family side of an admin's two places is one page, and the
      # workspace switch is already the way to it.
      []
    elsif current_user.student?
      [
        { key: :home, name: t("nav.home"), icon: :home, path: home_path, active: home_active? },
        { key: :practice, name: t("nav.practice"), icon: :practice, path: practice_path, active: practice_active? },
        duel_nav_item,
        { key: :me, name: t("nav.me"), icon: :me, path: profile_path, active: controller_name.in?(%w[profiles reports]),
          count: unseen_report_replies_count }
      ].compact
    elsif current_user.parent? || current_user.children.exists?
      [ { key: :family, name: t("nav.children"), icon: :family, path: parents_children_path, active: controller_path.start_with?("parents/") } ]
    else
      []
    end
  end

  # „Двубой" is in the menu once the child plays — or whenever somebody is
  # waiting on them there: a friend request or an invitation from another
  # child must not sit behind a tab the child has not been shown yet.
  def duel_nav_item
    waiting = duel_waiting_count
    return unless visibility.prominent?(:duel) || waiting.positive?

    { key: :duel, name: t("nav.duel"), icon: :duel, path: challenges_path, active: duel_active?, count: waiting }
  end

  # Reports with something from the team this student has not read yet. On
  # „Аз", because „Моите сигнали" is reached from there — and on the nav at all
  # because a reply the child never notices is a reply never sent.
  def unseen_report_replies_count
    @unseen_report_replies_count ||= current_user.question_reports.unread.count
  end

  def home_active?
    controller_name.in?(%w[home stats])
  end

  # The sessions themselves (assignments, the question screens) are the
  # practice flow's own full-screen layout and have no nav; their day lists
  # and summaries belong here.
  def practice_active?
    controller_name.in?(%w[practices reviews competitions assignments])
  end

  def duel_active?
    controller_name.in?(%w[challenges challenge_answers friendships leaderboards leagues])
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
    return User.none if acting_as_child? || signed_in_user.nil?

    signed_in_user.switchable_children.order(:name)
  end

  # The other profiles inside this login, for the picker in the child bar: a
  # household hands one device around, so switching child should be one tap
  # rather than a trip back through the parent's own screens.
  def other_child_profiles
    signed_in_user.switchable_children.where.not(id: current_user.id).order(:name)
  end

  # An admin is often somebody's parent as well, and the app is two places for
  # them: „Семейство" (the parents' pages) and „Администрация" (/overseer).
  # They share one header, with shared/_workspace_switch between them. Nil for
  # everybody else — and for an admin inside a child's profile, who is the
  # child for as long as the profile is open. A page that belongs to neither
  # (settings, the changelog) is :neither, so the switch shows with nothing
  # lit.
  def admin_workspace
    return @admin_workspace if defined?(@admin_workspace)

    @admin_workspace =
      if !current_user&.admin? || acting_as_child?
        nil
      elsif controller_path.start_with?("overseer/") || controller_name == "design_system"
        :admin
      elsif controller_path.start_with?("parents/")
        :family
      else
        :neither
      end
  end

  # The switch itself only for an admin who is a parent as well (or is on the
  # family side, adding their first child): for the rest of the team a
  # „Семейство" they have no use for would be a permanent piece of noise.
  def workspace_switch?
    admin_workspace.present? && (admin_workspace == :family || current_user.children.exists?)
  end

  # The admin area's places, in the order the work comes: the dashboard, what
  # is waiting on the team, then the bank and the people. The design system
  # lives in the account menu — it is a reference, not a place work happens.
  def admin_nav_items
    [
      { key: :dashboard, name: t("overseer.nav.dashboard"), icon: :home, path: overseer_root_path,
        active: controller_name == "dashboard" },
      { key: :inbox, name: t("overseer.nav.inbox"), icon: :inbox, path: overseer_question_reports_path,
        active: controller_name.in?(%w[question_reports reviews]), count: team_waiting_count },
      { key: :questions, name: t("overseer.nav.questions"), icon: :questions, path: overseer_questions_path,
        active: controller_name.in?(%w[questions hints]) },
      { key: :users, name: t("overseer.nav.users"), icon: :family, path: overseer_users_path,
        active: controller_name == "users" },
      { key: :topics, name: t("overseer.nav.topics"), icon: :topics, path: overseer_topics_path,
        active: controller_name == "topics" },
      { key: :stats, name: t("overseer.nav.stats"), icon: :chart, path: overseer_stats_path,
        active: controller_name == "stats" }
    ]
  end

  # Everything waiting on the team — see TeamInbox. Once per request: the
  # admin menu and the workspace switch both show it.
  def team_waiting_count
    @team_waiting_count ||= TeamInbox.waiting
  end

  # Rewards this admin's children have earned and not yet been given — the
  # one thing on the family side that is waiting on them, so it rides on
  # „Семейство" in the switch the way the team's count rides on
  # „Администрация".
  def family_owed_count
    @family_owed_count ||= begin
      ids = current_user.children.ids
      GoalAward.unused.joins(:goal).where(goals: { child_id: ids }).count +
        PracticeFocus.completed.where(child_id: ids, reward_given_at: nil).where.not(reward: nil).count
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

  # Widgets that are taller than they are wide. On a landscape tablet the
  # problem text beside them, instead of above, is what keeps „Провери" on
  # the screen — a coordinate plane or a balance under four lines of text
  # pushed the answer controls below the fold at 1024×768. A wide, short
  # widget (a number line, an ordering list) is better under its text.
  TALL_WIDGETS = %w[coordinate_plot balance_scale geoboard unit_circle clock_hands angle_dial grid_shade grid_fill equal_parts fraction_bars].freeze

  def split_prompt?(question)
    question.image.present? || (question.interactive? && TALL_WIDGETS.include?(question.grading.to_h["widget"]))
  end

  def question_body(question, large: false)
    css = large ? "question-body question-body-large" : "question-body"
    content_tag :div, RichContent.render(question.body), class: css
  end

  # A bare "3/4" that came out of a widget or a grading key, set the way the
  # question body would set it. Deliberately narrow: only a whole string that is
  # nothing but one fraction, so "0,75" and "1 1/2" are left as typed rather
  # than half-rendered.
  FRACTION = %r{\A\s*([-−]?\d+)\s*/\s*(\d+)\s*\z}

  # Whether math_value will typeset this as a stacked fraction — the callers that
  # strike a wrong answer through need to know, because a line across a fraction
  # crosses its own bar.
  def fraction_value?(value)
    FRACTION.match?(value.to_s)
  end

  def math_value(value)
    match = FRACTION.match(value.to_s)
    return math_text(value) if match.nil?

    render "shared/frac", numerator: match[1], denominator: match[2]
  end

  # Running text with its fractions stacked: an explanation, or an answer that
  # is more than one fraction („1/2 → 1/4", a widget's ordering). The question
  # above them sets every fraction stacked (RichContent), and the explanation
  # under it used to print „27/36" a few centimetres lower — two notations on
  # one card, for a child who is still learning the one. Same rule as the
  # question bodies, so `km/h`, `0,5/2` and `1/2/3` stay as typed. Escaped
  # first, then the fractions put back as markup.
  def math_text(text)
    escaped = ERB::Util.html_escape(text.to_s)
    escaped.gsub(RichContent::FRACTION) { render("shared/frac", numerator: $1, denominator: $2) }.html_safe
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
