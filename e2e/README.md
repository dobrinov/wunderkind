# Browser tests

RSpec covers what the server decides. These cover what the browser does with
it: Turbo navigations, Stimulus controllers, the duel screen that only moves
because a poll came back, a `<dialog>` that needs `showModal`, and a red frame
drawn over five different layouts. Nine specs, under thirty seconds.

```bash
yarn e2e:prepare     # once: create the e2e database and load the schema
yarn e2e             # run the suite
yarn e2e --headed    # watch it
yarn e2e --ui        # pick through it
```

`yarn e2e` boots its own Rails server on port 3101 against its own database
(`wunderkind_e2e`, via `DATABASE_URL`) and reseeds the fixture before every
run, so a run never touches development data and never fights the server you
have open. A failure leaves a screenshot, an accessibility snapshot and a trace
under `tmp/e2e/` — `yarn playwright show-trace tmp/e2e/<test>/trace.zip`.

## The fixture

`lib/tasks/e2e.rake` builds it: one topic, sixty published problems and an
account per journey. **One account per journey** is the rule that matters — the
calendar hero reads „Започни" the first time today and „Още една" after, so two
specs sharing a student is how the second one starts finding a page the first
one already changed.

| account | for |
| --- | --- |
| `student@e2e.test` | practice, and backing out of a duel lobby |
| `feedback@e2e.test` | the feedback card (`feedback_after_answer` on) |
| `skip@e2e.test` | „не съм го учил" |
| `wrong@e2e.test` | /review — has one wrong answer, filed through AnswerSubmission |
| `duel-a@`, `duel-b@e2e.test` | the two sides of a duel |
| `parent@e2e.test` | goals and rewards, manages Ния |
| `admin@e2e.test` | impersonation |
| `behind@e2e.test` | the „Какво е новото" dialog |

Password for all of them: `e2epassword`.

## Writing one

`support/helpers.mjs` has `signIn`, `startPractice` and `answerQuestion`.
`answerQuestion` waits for the answer's POST response and nothing more, which
is deliberate: with `feedback_after_answer` on the URL does not change (the
same question's page re-renders with the feedback card), and with sound on the
form posts by fetch and navigates from JavaScript only after the cue has
finished. The POST response is the one signal that means the same thing in all
four combinations. Everything after it is a question of what the screen says,
which Playwright's retrying expects already handle — so assert on the screen,
never `goto` into a race.

## What this deliberately does not cover

* **MathLive.** The fixture is all multiple choice. An exact-value answer is
  typed into a custom element with its own keyboard handling, and a suite meant
  to run after every change has to be boring. `answerQuestion` still handles
  typed and MathLive inputs, so a fixture that grows one later will not break
  the specs — but nothing asserts on it today.
* **The widgets.** Twelve of them, each with its own pointer handling. They are
  demoed at `/design-system`; a spec per widget is a separate job.
* **Sound.** The cue is synthesised in an AudioContext; a browser test can
  confirm the fetch path ran, not that anything was audible.
