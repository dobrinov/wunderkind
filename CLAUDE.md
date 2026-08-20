# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Wunderkind is a Rails 8 app (Ruby 3.4, PostgreSQL) for math practice: students receive assignments of questions matched to their skill via an Elo rating system. UI copy and the default locale are Bulgarian (`config.i18n.default_locale = :bg`).

## Commands

- `bin/dev` — run the app (foreman: Rails server + `yarn build --watch` for JS + `bin/rails tailwindcss:watch` for CSS)
- `bin/rails db:prepare` / `bin/rails db:seed` — set up the database (seeds create admin@example.com and student@example.com, password `1`)
- `bundle exec rspec` — run tests; single file: `bundle exec rspec spec/services/elo_spec.rb`; single example: append `:LINE`
- `bin/rubocop` — lint (rubocop-rails-omakase); CI runs this plus `bin/brakeman --no-pager`
- `yarn build` — bundle JS with esbuild into `app/assets/builds`

## Architecture

Core domain flow: `AssignmentCreator` (app/services/assignment_creator.rb) builds an `Assignment` by picking random questions whose Elo is near the user's, widening the search range in Fibonacci steps until enough are found. Answering happens in `AnswersController#create`: it records a `UserAnswer`, then updates both the user's and the question's Elo via the `Elo` module (app/services/elo.rb — dynamic K-factor, upset bonuses), and routes to either a feedback screen, the next question, or the assignment summary depending on the `feedback_after_answer` setting (assignment-level overrides user-level).

Model chain: `Assignment → AssignmentQuestion → UserAnswer`, with `Question` having `PossibleAnswer`s, many-to-many `Topic`s, and a polymorphic `attachable` (`QuestionImage` or `QuestionScript`).

Controllers: `AuthenticatedController` is the base for logged-in pages (session-based auth, `current_user` from `session[:user_id]`). The `Overseer::` namespace is the admin area — `Overseer::BaseController` requires `current_user.admin?` and uses the `admin` layout. Other layouts: `application`, `modal` (answer flow), `landingpage`, `simple`.

Frontend: Hotwire/Stimulus (controllers in `app/javascript/controllers`), Tailwind via tailwindcss-rails, esbuild for bundling. No system tests are generated for this app.

Database: schema format is SQL (`db/structure.sql`, not schema.rb). Seed question generators live in `db/math_problems/`.

Deployment is via Kamal (`config/deploy.yml`) to wunderkind.bg; errors go to Sentry.
