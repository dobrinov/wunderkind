# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Wunderkind is a Rails 8 app (Ruby 3.4, PostgreSQL) for math practice: students receive assignments of questions matched to their skill via an Elo rating system, earn XP/levels/streaks/badges, and questions support rich content with math notation and interactive widgets. UI copy is in Bulgarian with full i18n extraction (`config/locales/app.bg.yml` / `app.en.yml`, default locale `:bg`).

## Commands

- `bin/dev` — run the app (foreman: Rails server + `yarn build --watch` for JS + `bin/rails tailwindcss:watch` for CSS)
- `bin/rails db:prepare` / `bin/rails db:seed` — set up the database (seeds create admin@example.com and student@example.com, password `password`)
- `bundle exec rspec` — run tests; single file: `bundle exec rspec spec/services/elo_spec.rb`; single example: append `:LINE`
- `bin/rubocop` — lint (rubocop-rails-omakase); CI runs this plus `bin/brakeman --no-pager` (ignore file: `config/brakeman.ignore`)
- `yarn build` — bundle JS with esbuild into `app/assets/builds` (yarn 4, `nodeLinker: node-modules`)

## Architecture

Core answer flow: `AnswersController#create` delegates to `AnswerSubmission.call` (app/services/answer_submission.rb), which grades the response (`Grading`), updates per-topic skill ratings and the question's Elo (`Elo` module — dynamic K-factor, upset bonuses), awards XP (`Xp`, difficulty-scaled via Elo expected score), records the daily streak (`Streaks`), and awards badges (`Badges` — definitions in code, awards in `badge_awards`). `AssignmentCreator` builds assignments from published questions near the user's Elo, widening in Fibonacci steps; supports a `topics:` filter.

Content model: `Question#body` is a restricted ProseMirror-style JSON document (paragraph/text/bold/italic/math/hardBreak) rendered server-side by `RichContent` (KaTeX renders math client-side via the `math` Stimulus controller); `body_text` is the plain-text projection. `answer_type` enum: `multiple_choice` (options in `possible_answers` with a `correct` flag), `exact_value` (graded by `ExactValue` — fractions/decimals/percent/BG-comma equivalence, tolerance), `interactive` (widget state graded server-side by `Widgets` registry: number_line, ordering, fraction_bars — the solution never reaches the client), `free_text` (reserved, Phase 3 AI grading). `grading` jsonb holds expected value/widget params+solution. `status` enum: draft/private_library/in_review/published — only published questions enter practice. Legacy `text`/`answer` columns remain nullable until grading parity is confirmed in production, then drop.

Users: `role` enum (student/teacher/parent/admin); role decides the landing page (`home_path_for`). Gamification state on users: `total_xp` (events in `xp_events`, level curve in `Levels`), `current_streak`/`longest_streak`/`streak_freezes` (logic in `Streaks`). Per-topic Elo lives in `skills` (user × topic); `users.elo` is the derived display value. Topics form a hierarchy via `parent_id`.

AI & adaptivity: every Claude API call goes through `Ai::Client` (`app/services/ai/`), which enforces a monthly budget cap (`Ai::Budget`, `AI_MONTHLY_BUDGET_CENTS`, default $5) and folds all failures into `Ai::Unavailable` so features degrade instead of erroring; without `ANTHROPIC_API_KEY` all AI features silently degrade. One-time generation (hint ladders via `Ai::HintGenerator` into `question_hints`, admin-reviewed at `/overseer/questions/:id/hint`; authoring assistant `Ai::AuthoringAssistant`; review pre-check `Ai::ReviewPrecheck` into `questions.ai_review`) uses `claude-opus-5`; per-answer free-text grading (`Ai::FreeTextGrader`, cached in `free_text_gradings`, per-student daily cap in `Grading::FREE_TEXT_DAILY_CAP`) uses `claude-haiku-4-5` — ungradable answers record `verdict: pending_review` for teacher override (`AnswerOverridesController`). Sessions are built by `SessionComposer` (spaced review due topics + frontier topics unlocked by `topic_prerequisites` + one stretch question + near-Elo filler); `AnswerSubmission` schedules spaced review (SM-2-ish intervals on `skills`), detects topic mastery (rating ≥ 1400, ≥ 10 games → `mastered_at`, XP bonus), and halves XP for hinted correct answers. The global weekly leaderboard (`/leaderboard`) is nickname-only, Sofia-time Monday reset.

Roles & social: teachers own `classrooms` (students join by `invite_code`; `Teachers::` namespace, application layout); parents link to children via `parent_links` (`users.link_code`, shown on the student profile; `Parents::` namespace). `HomeworkCreator` builds a `Homework` (+`homework_questions`) and materializes one resumable `kind: :homework` assignment per student — hand-picked from the assigner's library/published pool plus auto-fill near the group's Elo; results matrix via `Homework#completion_for`. `DailyPractice` sizes a `kind: :daily` session from `daily_minutes_target` and the student's median answer time. `Leaderboards.weekly_xp` is a pure query over `xp_events` (classroom boards, teacher-toggleable). Teacher questions are private by default; `submit_for_review` → admin queue at `Overseer::ReviewsController`. Email verification (`users.verified_at`, `generates_token_for`) gates teacher/parent mutations (`require_verified_email`); password reset via `PasswordResetsController`; mail through `UserMailer`.

Controllers: `AuthenticatedController` is the base for logged-in pages (session auth, `current_user` from `session[:user_id]`); auth endpoints are rate-limited. `Overseer::` is the admin area (`Overseer::BaseController` requires `current_user.admin?`, `admin` layout). Layouts: `application`, `modal` (answer flow), `landingpage`, `simple` (auth), all sharing `shared/_head`. `back_path`/`close_path` params must pass through the `internal_path` helper (XSS guard).

Frontend: Turbo + Stimulus (controllers in `app/javascript/controllers`, registered in `index.js`), esbuild, Tailwind v4 (design tokens in `@theme` in `app/assets/tailwind/application.css`). Authoring uses Tiptap with a custom inline `math` node (KaTeX-rendered, MathLive popover editing) in `editor_controller.js`; students type exact-value answers via MathLive (`math_input_controller.js`, fonts in `public/mathlive-fonts`). KaTeX CSS/fonts are vendored in `app/assets/stylesheets`. The design system lives at `/design-system` (open in development, admin-only in production). No system tests are generated for this app.

Database: schema format is SQL (`db/structure.sql`). Seed question generators live in `db/math_problems/`.

Deployment is via Kamal (`config/deploy.yml`) to wunderkind.bg; errors go to Sentry.

## Roadmap context

The product scoping doc (three phases: Foundation → Teachers/Classrooms/Homework → AI/adaptive path) is published as an artifact. All three phases are built: Phase 1 (content model v2, gamification core, design system, platform cleanup), Phase 2 (teacher/parent roles, classrooms, homework, daily-minutes mode, email verification/password reset), Phase 3 (adaptive session composer + spaced review + topic mastery, AI hint ladders, AI free-text grading, authoring assistant, review pre-check, global weekly leaderboard). Not configured in production yet: SMTP delivery (verification/reset emails only log in development) and `ANTHROPIC_API_KEY` (AI features degrade gracefully without it).
