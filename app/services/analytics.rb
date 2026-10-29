# What we measure about how the app is used, and what we refuse to measure.
#
# Plausible rather than Google Analytics, and not only for the cookie banner it
# saves: this is a site used by children, most of it behind a login, and the
# whole point is a product decision at the end — does a parent who lands on
# /matematika sign up, does a student who starts a session finish it. None of
# that needs a per-person profile, so none is collected. There is no user id, no
# nickname and no email in anything sent from here — Trace alone gets a keyed
# hash of the id, which counts a returning student without naming one (see
# `trace_identity`) — and `EVENTS` is a closed
# list of names whose properties are all low-cardinality enums already
# public in the schema (role, session kind, report reason, duel result) or in
# config/competitions.yml (a competition's slug). If an
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

  # Trace (tracetells.com) runs beside Plausible, under the same switch and fed
  # the same events. Plausible counts — visits, goals, where people came from —
  # and Trace watches how the pages are used (rage and dead clicks, errors,
  # scroll depth, form completion) and measures the KPIs in trace.json at the
  # root of the repository, which is the file that says what this site is for.
  # The key is a write key and public by nature: it is in the source of every
  # page. Trace knows each event by its key in EVENTS (`session_started`), which
  # lib/analytics.js derives from the Plausible name — so the two must stay in
  # step, and the spec checks that they do.
  TRACE_ORIGIN = "https://app.tracetells.com".freeze
  TRACE_KEY = "647a2f18f25c4cba9d91122db83bd99d".freeze

  # The paths whose variable segment is a token rather than a number. Numbers
  # fold to :id in Trace's collector on their own; a signed token does not, and
  # a page per token is a report nobody can read.
  TRACE_ROUTES = [ "/emails/:token", "/emails/:token/*", "/verify-email/:token", "/password_resets/:token/*" ].freeze

  # The things worth a goal in the dashboard, and the properties each one
  # carries. Named here rather than typed at the call sites because a goal in
  # Plausible is matched on the name character for character — "Session
  # Started" and "Session started" are two goals, one of which stays on zero
  # forever and nobody notices for a month.
  EVENTS = {
    signup: "Signup",                      # role: student | parent
    session_started: "Session Started",    # kind: practice | daily | mistakes | competition
    session_completed: "Session Completed", # kind: practice | daily | mistakes | competition
    duel_started: "Duel Started",          # matched: now | waiting
    duel_finished: "Duel Finished",        # result: win | loss | draw
    problem_reported: "Problem Reported",  # reason: <QuestionReport#reason>, from: practice | duel
    problem_suggested: "Problem Suggested", # answer_type: multiple_choice | exact_value
    competition_joined: "Competition Joined", # competition: <slug in config/competitions.yml>
    login: "Login",                        # role: student | parent, via: password | switch
    goal_created: "Goal Created",          # metric: minutes | problems | correct, mode: daily | total
    focus_set: "Focus Set",                # target: mastery | step
    league_joined: "League Joined",        # how: created | code
    # The first-run and gradual-introduction moments (FeatureVisibility), so
    # the thresholds that decide them can be set from data rather than guessed.
    tour_finished: "Tour Finished",        # how: done | skipped — from the browser
    introduction_answered: "Introduction Answered", # feature: <FeatureVisibility::FEATURES>, choice: try | later
    scratchpad_opened: "Scratchpad Opened", # from the browser, once per problem
    child_added: "Child Added",            # how: created | linked
    daily_minutes_set: "Daily Minutes Set", # minutes: <DailyPractice::MINUTES_OPTIONS>
    features_shown_all: "Features Shown All" # show_all: on | off
  }.freeze

  def script_url
    "#{ENV.fetch("PLAUSIBLE_ORIGIN", SCRIPT_ORIGIN)}/js/#{ENV.fetch("PLAUSIBLE_SCRIPT_ID", SCRIPT_ID)}.js"
  end

  def trace_key
    ENV.fetch("TRACE_KEY", TRACE_KEY)
  end

  def trace_script_url
    "#{ENV.fetch("TRACE_ORIGIN", TRACE_ORIGIN)}/d.js?k=#{trace_key}"
  end

  # Who is at the keyboard, as Trace sees it: an HMAC of the user's id under a
  # key derived from secret_key_base, cut to 32 hex characters. Trace is
  # cookieless, so an anonymous visitor is a stranger again every day; this is
  # what lets it count daily and monthly actives and who comes back a week
  # later. It is not a user id in disguise: without the key nobody — Trace
  # included — can get from the hash back to a row in users, and it is
  # different from anything any other service sees. A parent switched into a
  # child's profile is the child here, as everywhere else.
  def trace_identity(user)
    return nil if user.nil?

    key = Rails.application.key_generator.generate_key("trace identity", 32)
    OpenSSL::HMAC.hexdigest("SHA256", key, user.id.to_s)[0, 32]
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
