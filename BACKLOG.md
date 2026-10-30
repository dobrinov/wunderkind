# Backlog

Ideas agreed worth building, not yet started. Newest at the bottom. When one is
built, delete its entry — the commit and CLAUDE.md are the record from then on.

## Parent-set training focus: a topic until a level, then back to normal

*Asked for 2026-10-27.* A parent wants their child to train one kind of problem
— fractions, say — until they reach a certain level in it, and the engine should
pursue that first, then fall back to ordinary Elo matchmaking on its own.

**What exists to build on**
- `Goals` already lets a parent ask something of a child with a reward, but
  every metric is *effort* (minutes, problems, correct answers). This would
  be the first goal about *ability*, and it changes which problems are served.
- Ability per topic is already measured: `skills.rating` (user × topic), with
  mastery at `rating ≥ 1400` and `≥ 10` games (`mastered_at`).
- `SessionComposer` owns the mix of a session (review due, frontier, stretch,
  filler) and `Dispatcher` owns the difficulty. A focus is a new slot in the mix,
  not a new engine.

**Shape of it**
- A `focus` belongs to a child, set by a parent: a topic (a leaf, or a root to
  cover its leaves), a target level, and optionally a reward through the
  existing `Goals` / `goal_awards` path, so "reach Уверен in fractions and you
  get X" is one sentence.
- The target is chosen as a `RatingBand` (or "mastered"), never a raw Elo,
  because the parent's pages already speak in bands and grades.
- While a focus is open, `SessionComposer` gives it a fixed share of every
  practice and daily session (somewhere around 60%, to be tuned). Those
  problems are aimed by the dispatcher's usual target, worked out from the
  child's **topic** rating, not their overall `users.elo`. The rest of the session
  is the normal mix, so review and variety keep working. A share rather than the
  whole session, because a child given only one topic for a month stops coming
  back.
- The focus closes itself the first time a measured answer takes the topic
  rating past the target, checked in `AnswerSubmission`. Requiring a minimum
  number of games, as mastery does, stops one lucky streak from closing it.
  After that, sessions are exactly what they are today.
- The child sees it on the home page in the parent's words, like `home/_goals`,
  with progress drawn as the topic's rating against the target: "Мама иска да
  стигнеш до …".

**Questions to settle before building**
- **Not enough problems:** the bank is not square. Refuse a focus whose topic has
  too few problems around the child's rating, the way `DuelCategories` uses
  `MINIMUM` within `REACH`, and refuse or warn on a target the bank cannot
  reach.
- **Locked prerequisites:** if the topic's prerequisites
  (`topic_prerequisites`) are not unlocked, either serve the prerequisites first
  or simply allow it. The parent asked for it, so allowing is probably right,
  but say so on the setup screen.
- **Skips:** a „не съм го учил“ on a focus topic defers the topic and its
  template today. Probably keep the shape deferral but not the topic deferral
  while a focus is open, or the focus quietly does nothing.
- **More than one focus:** allow one at a time first.
- **Problem type, not just topic:** "a specific type of question" might mean a
  template (`SessionComposer::SHAPE_SQL`) rather than a topic. Topics come
  first; templates have no names a parent could pick from.
- **Mistakes sessions, duels and competition practice:** these stay outside the
  focus. Mistakes sessions and duels are unmeasured, so answers there must not
  close it.

## Public leaderboard (phase 2 of leaderboards)

*Asked for 2026-10-28; design on the „Public Leaderboard" canvas.* Phase 1 —
private leagues among friends (`Leagues`) — is built. Phase 2 is a public
weekly board at `/klasaciya` that visitors can see, merged with today's
in-app global board so there is one list, not two.

**Agreed so far**
- Opt-in, unticked by default, asked at sign-up and in Настройки; a parent
  decides for a managed child, as with leagues.
- Each person chooses a nickname or their real name; a real name is first
  name plus surname initial, never the full surname, and no grade beside it.
- Same weekly XP as everywhere, Monday reset; filters by school stage
  (1–2, 3–4, 5–7, 8–12) off the estimated grade, a child without a birth
  year only under „Всички".
- Top 10 plus your own place, not the whole list.

**Before it ships**
- **Consent:** Bulgaria's digital age of consent is believed to be 14 (check
  it). Under that, a real name needs a linked parent's consent; until then
  nickname only. A self-registered child has no parent on record at all.
- **Moderation:** a word filter on nicknames, an admin "hide this name" (the
  report queue), and a report link on the public page.
- **`noindex`** on the public page — children's names should not be in search
  results even when consented.
- **A floor:** show the public page only once at least ~20 students have
  opted in that week; an almost empty board advertises against us.
- **Existing students start off it.** Today's in-app board lists every
  student with a nickname without asking; after the merge, nobody is public
  until they (or their parent) opt in.
- **Linked (not managed) children:** their parent should also get the switch.
- Say on the page that the points are for practice, not a grade, so parents
  do not read it as a ranking of who is best at maths.

## The family field-test report: everything it found

*Asked for 2026-10-30.* Fifteen simulated people (two parents, a child in every
grade 1–12, and an admin) used a local copy with the production bank for two
days. The report, with findings by severity, quotes and ideas, is the artifact
https://claude.ai/artifact/8o2PpVCFVCPNLgp2vYmF1z (the per-agent diaries and
question ids were in the session's scratchpad, not the repo). Its items 9 and 10
— our own number pad and „Чернова" under every problem — are built. The rest,
in the order agreed:

**1. Right answers marked wrong** (the most damaging; do first)
- `ExactValue.parse` rejects thousands spaces (`5 152`), `x = 72`, `43°`,
  `8!`, a trailing unit (`8 евро`, `34 m/s`), and reads `40%` as 0.4 against an
  accepted 40. The number pad stops new ones being typed, but the duel, the
  text field and every past answer still go through the parser.
- Generators with wrong answers: `pct.two_discounts` (integer division,
  `tools/authoring/families/fractions.rb`), `rat.factor_trinomial` (the commuted
  right answer listed as a wrong option), Gauss pairs („при нечетно N" for even
  N, `interactive_puzzles.rb`), `prob.two_events` (false products in the
  explanation). `check.rb` should refuse two options that are the same answer.
- The admin editor cannot save an exact-value or interactive question (an empty
  option's hidden checkbox gets past `reject_if: :all_blank`); the tolerance
  field drops a decimal comma.
- No regrade: an upheld report leaves the wrong mark on „За преговор" and the
  rating and XP lost.
- The ordering widget can submit a different order from the one shown after a
  fast drag (lost pointer capture, nothing on `lostpointercapture`).
- `AnswerSubmission::AlreadyAnswered` is not rescued in `AnswersController`.

**2. Sessions that fit**
- Daily sessions of 30 for a 10-minute goal (sized from fast placement answers);
  cap near 12, resume an unfinished one instead of starting a new one.
- Placement leaves topic `skills` rows at the floor, so focus and exam prep serve
  1st-grade work to teenagers; set them to the placed rating.
- Exact repeats across days and templates that differ only by names or shapes
  (`SHAPE_SQL` blanks digits only).
- „Готово за днес" after placement alone, before the parent's goal is met.
- Topic mastery fired on a wrong answer.

**3. Game fairness**
- Mistakes sessions pay full XP and medals for recall (half XP the same day, a
  bonus for solving it again days later).
- Duels skip `held_topic_ids` and the template cap and aim between two ratings, so
  family duels across ages are unwinnable; leagues rank raw XP, which the
  youngest out-earn.
- No nickname shows as „Противник"; ask before any social feature.
- Children with their own login are still „managed" and need a parent to allow
  leagues.

**4. Parents**
- A goal's first period cannot be won (Thursday → a 4-day week for 5 days).
- The family page needs a „today" strip: who practised, whose streak ends
  tonight, who needs help, rewards owed, replies waiting.
- Twelve children overflow the header switcher (2006px at 1440) and fill half a
  phone with sibling chips; a shared tablet has no PIN between profiles.
- Exam presets (НВО 4/7/10, матура) in „Какво упражнява".

**5. Admin**
- Tickets do not show the child's answer; no „known bug" state, no
  comment-and-close, no whole-template fix; editing text detaches a question from
  its template; Табло should flag right-looking wrong answers, children far
  below 70% and error spikes.

**6. Bigger ideas** (each its own design first)
- „Слаби места" and a topic drill; an exam map and a timed mock scored on the
  real scale.
- Read-aloud and a mode for the youngest.
- Near-miss feedback („провери реда на цифрите"), partial credit in widgets.
- A grown-up mode from 8th grade; children as authors (credit for accepted
  suggestions and upheld reports); seasonal events and badges from the admin.
