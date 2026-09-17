# What we measure about how the app is used, and what we refuse to measure.
#
# Plausible rather than Google Analytics, and not only for the cookie banner it
# saves: this is a site used by children, most of it behind a login, and the
# whole point is a product decision at the end — does a parent who lands on
# /matematika sign up, does a student who starts a session finish it. None of
# that needs a per-person profile, so none is collected. There is no user id, no
# nickname and no email in anything sent from here, and `EVENTS` is a closed
# list of seven names whose properties are all low-cardinality enums already
# public in the schema (role, session kind, report reason, duel result). If an
# event ever wants to carry something that identifies a child, the answer is no.
#
# Two rules decide whether the script renders at all:
#
#   * Production only. The script is a third party's, and localhost is noise —
#     Plausible would ignore it anyway (`captureOnLocalhost` defaults false),
#     but not loading it at all is cheaper and quieter in development.
#   * Not for admins. The owner is by a wide margin the heaviest user of this
#     app, and on a site with a few hundred real visits a day their own
#     sessions would be most of the dashboard. Every /overseer page is noise on
#     top of that. Signing out is how you verify the script is live in
#     production — the landing page is where the funnel starts anyway.
#
# Pageviews need no help: the script hooks `history.pushState`, which is what
# Turbo Drive navigates with, so a Turbo visit is counted like a full load.
# What it does need is `Analytics.path_normalizer` — see below.
module Analytics
  module_function

  # The site's script, served from our own subdomain rather than plausible.io.
  # A first-party host is not a trick to dodge blockers so much as the only way
  # the numbers mean anything: a good fraction of parents run one, and a
  # dashboard that silently omits them is worse than no dashboard.
  SCRIPT_ORIGIN = "https://stats.aparatnata.com".freeze
  SCRIPT_ID = "pa-HK_eGphrxrYClIKCx1937".freeze

  # The seven things worth a goal in the dashboard, and the properties each one
  # carries. Named here rather than typed at the call sites because a goal in
  # Plausible is matched on the name character for character — "Session
  # Started" and "Session started" are two goals, one of which stays on zero
  # forever and nobody notices for a month.
  EVENTS = {
    signup: "Signup",                      # role: student | parent
    session_started: "Session Started",    # kind: practice | daily
    session_completed: "Session Completed", # kind: practice | daily
    duel_started: "Duel Started",          # matched: now | waiting
    duel_finished: "Duel Finished",        # result: win | loss | draw
    problem_reported: "Problem Reported",  # reason: <QuestionReport#reason>, from: practice | duel
    problem_suggested: "Problem Suggested" # answer_type: multiple_choice | exact_value
  }.freeze

  def script_url
    "#{ENV.fetch("PLAUSIBLE_ORIGIN", SCRIPT_ORIGIN)}/js/#{ENV.fetch("PLAUSIBLE_SCRIPT_ID", SCRIPT_ID)}.js"
  end

  def enabled?(user = nil)
    return false unless Rails.env.production?

    !user&.admin?
  end

  # Resolves a key from EVENTS to the name the dashboard knows it by. Raises on
  # anything else, so a mistyped event is a failing request in development
  # rather than a goal that never fires in production.
  def event_name(key)
    EVENTS.fetch(key.to_sym)
  end

  # A path like /questions/8412 is a different page to Plausible than
  # /questions/8413, and this app has thirty thousand questions — left alone,
  # the Top Pages report would be thirty thousand rows of one visit each, and
  # the one number it should be showing (how much practice is happening) would
  # not appear at all. So every path segment that is nothing but digits becomes
  # `:id` before the event is sent.
  #
  # Only bare digits, which is why the public pages survive it: /matematika/3-klas
  # and /matematika/tema/drobi keep their own rows, and those are precisely the
  # rows worth reading, since they are the only pages a stranger can reach.
  #
  # The query string is kept as it is. Plausible reads utm_source and friends
  # off it for the acquisition report, and this product is shared by parents
  # pasting links into Facebook groups and Viber — throwing the campaign away
  # to tidy up `?date=` would cost the one report that says where they came from.
  PATH_NORMALIZER = <<~JS.freeze
    function (payload) {
      payload.u = location.origin +
        location.pathname.replace(/\\/\\d+(?=\\/|$)/g, "/:id") +
        location.search;
      return payload;
    }
  JS

  def path_normalizer = PATH_NORMALIZER
end
