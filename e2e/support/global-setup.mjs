import { execFileSync } from "node:child_process"

// One fixture per run, built before the server starts. `e2e:seed` leaves the
// schema alone and only rewrites the rows, so this is a second or two.
export default function globalSetup() {
  execFileSync("bin/rails", [ "e2e:seed" ], {
    cwd: new URL("../..", import.meta.url).pathname,
    env: { ...process.env, DATABASE_URL: process.env.E2E_DATABASE_URL || "postgres:///wunderkind_e2e" },
    stdio: "inherit"
  })
}
