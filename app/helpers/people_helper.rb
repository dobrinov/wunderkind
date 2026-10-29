# The admin's people pages: the family list and a person's page share these
# few words about an account — what kind it is, when they were last here —
# so the list and the page cannot describe one person two ways.
module PeopleHelper
  TAG_TONES = {
    parent: "bg-reward-100 text-reward-800",
    admin: "bg-primary-50 text-primary-700",
    managed: "bg-ink-100 text-ink-700",
    own: "bg-green-50 text-green-700",
    linked: "bg-sky-50 text-sky-800",
    warn: "bg-red-50 text-red-700",
    quiet: "bg-ink-100 text-ink-600"
  }.freeze

  def person_tag(tone, text)
    tag.span(text, class: "inline-flex h-6 items-center whitespace-nowrap rounded-full px-2.5 text-caption font-extrabold #{TAG_TONES.fetch(tone)}")
  end

  # A child's kind of account, as the list and the page both name it: a
  # profile inside a parent's account (no login of its own), its own login,
  # or a student who signed up alone and was linked by code.
  def account_kind(user)
    if user.managed? && user.email.blank?
      [ :managed, t("overseer.people.kinds.managed", name: first_name(user.managed_by)) ]
    elsif user.managed?
      [ :own, t("overseer.people.kinds.own") ]
    else
      [ :linked, t("overseer.people.kinds.linked") ]
    end
  end

  def account_kind_tag(user) = person_tag(*account_kind(user))

  def first_name(user) = user.name.to_s.split(/\s+/).first

  # „днес 7:40", „вчера", „12 окт" — a list of people is read for recency, and
  # a timestamp to the second is not how anybody thinks about it.
  def when_words(time)
    return t("overseer.people.never") if time.nil?

    time = time.in_time_zone
    case time.to_date
    when Time.zone.today then t("overseer.people.today_at", time: l(time, format: "%-H:%M"))
    when Time.zone.yesterday then t("overseer.people.yesterday")
    else l(time.to_date, format: time.year == Time.zone.today.year ? "%-d %b" : "%-d %b %Y")
    end
  end

  # The same for a day, with no time to give: users.last_active_on.
  def day_words(date)
    case date
    when nil then t("overseer.people.never")
    when Time.zone.today then t("overseer.people.today")
    when Time.zone.yesterday then t("overseer.people.yesterday")
    else l(date, format: date.year == Time.zone.today.year ? "%-d %b" : "%-d %b %Y")
    end
  end

  def last_seen(user)
    [ user.last_seen_at, user.last_login_at ].compact.max
  end

  # Somebody the signed-in admin may look at the app as — never an admin and
  # never themselves (ImpersonationsController refuses both anyway).
  def impersonable?(user) = !user.admin? && user != current_user

  # The session length and who set it, as far as that is knowable: a student
  # with a linked parent cannot change it themselves (ProfilesController drops
  # the field), so a number on such an account is the parent's; without a
  # parent it is the student's own. No number at all is the default.
  def daily_minutes_fact(user, parents)
    minutes = user.daily_minutes_target
    return t("overseer.people.facts.minutes_default", minutes: DailyPractice::DEFAULT_MINUTES) if minutes.nil?

    t(parents.any? ? "overseer.people.facts.minutes_by_parent" : "overseer.people.facts.minutes_own", minutes:)
  end

  # Which of the secondary features this student has been shown (see
  # FeatureVisibility): all of them for an account older than the gradual
  # introduction or one a parent opened up, otherwise the sheets seen so far.
  def features_fact(user)
    if user.show_all_features?
      t("overseer.people.facts.features_all_parent")
    elsif user.created_at < FeatureVisibility::GRADUAL_SINCE
      t("overseer.people.facts.features_all_veteran")
    else
      t("overseer.people.facts.features_seen", count: user.introduced_features.size, total: FeatureVisibility::FEATURES.size)
    end
  end

  def duel_result(challenge, user)
    if challenge.winner_id.nil? then :draw
    elsif challenge.winner_id == user.id then :won
    else :lost
    end
  end

  def on_off(value) = t(value ? "overseer.people.on" : "overseer.people.off")

  def person_avatar(user, size: "size-11 text-lg")
    tag.span(first_name(user).to_s.first.to_s.upcase, class: "avatar shrink-0 #{size}", "aria-hidden": true)
  end

  # The filter chips keep the search and the other chips; a chip toggles
  # itself.
  def people_filter_path(filter)
    filters = @filters.include?(filter) ? @filters - [ filter ] : @filters + [ filter ]
    overseer_users_path(view: @view, q: @query, f: filters.presence)
  end
end
