// Browser tests for the flows that only exist once everything is running at
// once: Turbo, Stimulus, the polling duel screen, a <dialog> that needs
// showModal, and a red frame drawn over five different layouts. RSpec covers
// what the server decides; this covers what the browser does with it.
//
// Its own database and its own port, so a run never touches the development
// data and never fights the server you have open. The fixture is rebuilt once
// per run (globalSetup) rather than per test: specs each own their own
// accounts, which is cheaper than resetting between them and keeps a failing
// spec's data around to look at.
import { defineConfig, devices } from "@playwright/test"

const PORT = process.env.E2E_PORT || 3101
const DATABASE_URL = process.env.E2E_DATABASE_URL || "postgres:///wunderkind_e2e"

export default defineConfig({
  testDir: "./specs",
  outputDir: "../tmp/e2e",
  fullyParallel: false,
  // The duel spec drives two browser contexts through one shared clock, and
  // the fixture is shared; two workers racing over it is not worth the
  // minute it would save.
  workers: 1,
  retries: process.env.CI ? 1 : 0,
  reporter: process.env.CI ? "line" : [ [ "list" ] ],
  timeout: 30_000,
  expect: { timeout: 7_000 },

  use: {
    baseURL: `http://127.0.0.1:${PORT}`,
    locale: "bg-BG",
    timezoneId: "Europe/Sofia",
    trace: "retain-on-failure",
    screenshot: "only-on-failure"
  },

  projects: [ { name: "chromium", use: { ...devices["Desktop Chrome"] } } ],

  globalSetup: "./support/global-setup.mjs",

  webServer: {
    // Development rather than test: readable error pages when a spec fails,
    // and the asset pipeline behaves the way it does when you are looking at
    // the app yourself.
    // Its own pidfile: the repo's default is tmp/pids/server.pid, which the
    // development server you have open is already holding, and Rails refuses
    // to start a second one against it.
    command: `bin/rails server -p ${PORT} -b 127.0.0.1 -e development -P tmp/pids/e2e.pid`,
    url: `http://127.0.0.1:${PORT}/sign-in`,
    cwd: "..",
    reuseExistingServer: !process.env.CI,
    timeout: 60_000,
    env: { DATABASE_URL, RAILS_ENV: "development" }
  }
})
