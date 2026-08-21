# Design review brief — Wunderkind

*Paste this into Claude Design together with the images in `screenshots/`.
`screenshots/MANIFEST.md` maps every file to the route it came from.*

---

## What you're looking at

Wunderkind is a Bulgarian web app for maths practice, aged roughly 7–14 (grades 1–7).
A student gets short sessions of problems matched to their skill by an Elo rating, and earns
XP, levels, streaks and badges for doing them. Teachers run classrooms and set homework;
parents follow their child's progress; an admin authors and approves the question bank.

All UI copy is Bulgarian (Cyrillic). It is a Rails app: server-rendered ERB, Turbo + Stimulus,
Tailwind v4. Not a native app, but phone and tablet use is the common case for students.

The 49 screenshots are grouped by audience:

| Folder | What it covers |
| --- | --- |
| `01-public/` | Landing page and the auth screens |
| `02-student/` | Student home (calendar), profile, leaderboard, classrooms |
| `03-practice/` | The answering flow — one screen per answer type, plus feedback and the session summary |
| `04-teacher/` | Classrooms, roster, homework creation and results, question authoring |
| `05-parent/` | Linked children, linking a child, assigning homework |
| `06-admin/` | Question bank, question editor, hint authoring, topics, and the existing `/design-system` page |
| `07-mobile/` | The student journey at 390×844 |

Start with `06-admin/09-design-system.png` — it is the app's own design-system page and the
fastest way to see the whole component vocabulary at once.

The screenshots are of the real running app against seeded demo data: five students in one
classroom with genuine practice history, XP, streaks and Elo ratings, four homework
assignments in varying states of completion, and a question bank of ~8,300 problems. So the
populated states are real, not mocked — but the numbers are a few days of activity, not a year's.

---

## Please stay close to what's there

**This is a refinement job, not a redesign.** The current look — light, calm, rounded, a lot
of white space, one saturated indigo for actions, amber reserved for reward — is deliberate
and I want to keep it. I am asking you to make it better at what it is already trying to be,
not to replace it with a different aesthetic. Concretely, keep:

- **Typeface** — Nunito. It has to carry Cyrillic and Latin, and it sets the friendly tone.
- **Palette** — the tokens below, unchanged in hue. Adding intermediate steps or a neutral
  ramp is welcome; swapping the brand colour is not.
  ```
  primary (indigo-violet, all navigation and actions)
    50 #f0f1ff  100 #e2e4ff  200 #c9cdff  300 #a5aaff  400 #7f7ff7
    500 #6366f1  600 #5048e5  700 #4038ca  800 #3730a3  900 #312e81
  reward (amber, ONLY for XP, streaks, levels and badges)
    100 #fef3c7  400 #fbbf24  500 #f59e0b  600 #d97706  800 #92400e
  surfaces: white cards on gray-50 page, gray-200 hairline borders, gray-900 ink
  semantic: green-600 correct, red-600 wrong
  ```
- **The reward/action colour split.** Amber means "you earned something". Indigo means
  "you can do something". Please don't blur that rule — it is what keeps the gamification
  from swallowing the interface.
- **Component set** — `.card` (white, rounded-xl, hairline ring, divided header/section/footer),
  `.stat-tile`, `.choice-button`, `.xp-pill`, `.button-{primary,secondary,success,danger}`,
  the four alert styles. Refine these in place; I'd rather have ten well-tuned primitives than
  thirty new ones.
- **Bulgarian copy.** If you propose new or reworded strings, give them in Bulgarian
  (English gloss in a comment is fine). Cyrillic runs longer than English — layouts need the
  slack.
- **Two layout shells.** `application` (sticky header with nav + streak/XP/name, scrolling
  body) for every management screen, and `modal` (thin header holding only a progress bar and
  a close ✕, no nav) for the answering flow. The answering flow is deliberately distraction-free
  and should stay that way.

Tone: kid-friendly but *not* babyish. These are children doing real maths, some of them
preparing for competitive exams. It should feel like a good tool, not a cartoon.

---

## What I'd like you to work on

### 1. The answering screen is mostly empty (highest priority)

Look at `03-practice/01-01-exact-value.png`, `03-practice/03-03-widget-number-line.png` and
`03-practice/08-feedback-wrong.png` on desktop. The question sits vertically centred, the
answer control is pinned to the bottom, and 400–600px of nothing sits between them. On the
number-line question the prompt and the actual number line are separated by half a screen —
the two things a child needs to connect are as far apart as the layout can put them.

This is the screen a student spends nearly all their time on. I'd like a composition that
holds question, input and feedback as one unit at a comfortable reading distance, and that
doesn't fall apart between a 390px phone and a 1440px laptop. Compare the mobile versions in
`07-mobile/04-*` — they're tighter, and arguably the desktop layout should behave more like a
centred column than a full-bleed stretch.

One inconsistency to fix while you're here: maths in a question *body* is KaTeX-rendered
(see the notation row on the design-system page), but maths inside the interactive widgets is
plain text — `07-mobile/04-question-04-widget-ordering.png` asks a child to order fractions
shown as "3/4", "1/4", "1/2" rather than as stacked fractions. The ordering, number-line and
fraction-bar widgets should speak the same typographic language as the question above them.

### 2. Feedback could carry more weight

`03-practice/07-feedback-correct.png` and `08-feedback-wrong.png`. Right now a correct answer
and a wrong answer differ by a tinted bar and an icon. Getting something right is the moment
the whole XP/streak system is supposed to pay off, and it currently reads as a status message.
The wrong-answer case matters just as much: your answer, the correct answer, and the
explanation are stacked in one flat gray panel with no visual hierarchy between "here's what
you missed" and "here's why".

Also: the *Следващ* button carries a heavy red focus ring from `autofocus` that reads as a
double border. Worth solving properly rather than removing the focus style — it's keyboard
navigation that depends on it.

### 3. The student home page is a wall of empty boxes

`02-student/01-home-calendar.png`. Three things stack up and fight: a homework list that can be
any length, a five-tile stat strip, and a month grid built from `aspect-square` cells that is
~1160px tall on a 1440px window. Only the homework card is above the fold; the calendar — the
page's largest element — is mostly empty cells carrying the least information, and the stat
tiles (streak / XP / level / rating) get a thin band between the two. The "Дневна тренировка"
call to action is styled as a stat tile, so the one button on the page doesn't look like a
button.

I'd like the hierarchy inverted: what do I do now, how am I doing, and *then* history. The
month grid probably shouldn't be sized by cell aspect ratio at all — say what you'd do with it.

### 4. Numbers without meaning

Across `02-student/01-home-calendar.png`, `02-student/03-profile.png` and
`04-teacher/02-classroom.png`, students and teachers see a "РЕЙТИНГ" of 1114 or 1697. That's a
raw Elo number. Nobody outside the app knows whether 1114 is good, or what would move it.
Same for the badge grid on the profile: all 17 badges are near-identical white tiles, and earned
vs. locked is signalled only by emoji saturation and a slightly darker label and border. At a
glance the wall reads as absence rather than progress, and nothing tells a child what any locked
badge needs in order to unlock.

While you're on `02-student/03-profile.png`: the first and widest card on a child's own profile
is their parent-linking code — a one-time setup step outranking their level, XP and streak. And
the bottom row pairs a tall "Лични данни" card with a short "Настройки" card, leaving a large
void on the right.

### 5. The homework form dumps the whole curriculum on the teacher

`04-teacher/04-homework-new.png`. The topic picker renders all 55 topics as one flat, ragged
field of chips — no hierarchy, even though topics *are* a tree (13 roots with children), and no
filtering by the class's grade. A teacher setting homework for a 3rd-grade class is offered
"Логаритмична функция", "Производна" and "Стереометрия" with the same weight as "Събиране и
изваждане". The three fields that matter (title, due date, how many questions) are visually
identical to each other and then buried above this wall.

Teachers aren't the primary design target, but they decide whether a class uses the app at all.

For contrast, `06-admin/01-questions-index.png` is the same kind of screen done well — compact
filter row, paginated table, clear hierarchy. Worth keeping as the pattern. Its only weak spot
is the row actions: two bare emoji (👁 / 💡) next to a text link, three different affordances
for three actions of equal weight, all small targets.

### 6. Mobile
`07-mobile/`. The student flow works, but the header spends its width on a streak pill, an XP
pill and a name; question stems are set very large relative to the answer controls; and the
profile is a 2310px scroll. Phone is where a lot of the practice actually happens.

---

## One known bug in the screenshots

**The colour swatches on `/design-system` render blank.** They're generated as
`bg-primary-<%= shade %>`, which Tailwind's scanner never sees, so the classes are purged.
The palette itself is fine — only its documentation is broken. Mentioned so you don't read
the empty swatches as the real palette.

*(A second bug — the pending-homework card collapsing to zero height on desktop — was found
while these screenshots were taken and has since been fixed; the shots here already show the
corrected behaviour. Worth knowing because it shapes point 3 below: the home page now has to
carry a homework list of arbitrary length **and** a month grid, and the two are competing.)*

---

## What would help me most

1. **A diagnosis first.** Before any pixels, tell me what you think is actually wrong, ranked,
   and which problems are one-line fixes versus real rework. If you disagree with my list above,
   say so — I'd rather be corrected than flattered.
2. **Redesigned artboards for the screens that matter**, in this order:
   the answering screen (all six answer types), the correct/wrong feedback states, the student
   home, the profile. Desktop 1440 and mobile 390 for each. Show the empty state as well as the
   populated one for the home page.
3. **Token and component deltas as a diff, not a new system** — "add `primary-25`", "tighten
   `.card` header padding to `py-4`", "here's a `.stat-tile` variant that reads as a button".
   I have to implement this in `app/assets/tailwind/application.css`, so changes I can apply
   incrementally are worth far more than a beautiful clean-sheet system.
4. **Say what to leave alone.** If a screen is fine, tell me it's fine.

Where a choice is genuinely a toss-up, pick one, ship it, and note the alternative in a line —
I'd rather see a decision than a menu.
