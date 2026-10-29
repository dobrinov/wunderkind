// Numbers the specs share with the app.
//
// Written here by hand rather than read out of Ruby, and kept to the few that
// a spec would otherwise hard-code. If one drifts the placement spec fails on
// its own loop count, which is a readable way to find out.
export const QUESTION_COUNT = 8

// A daily session for a student with no answer history: DailyPractice's
// DEFAULT_MINUTES (10) at its DEFAULT_SECONDS_PER_QUESTION (45), rounded.
export const DAILY_QUESTION_COUNT = 13
