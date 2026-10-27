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
