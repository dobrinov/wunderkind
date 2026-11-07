---
paths:
  - "app/services/friends.rb"
  - "app/services/leagues.rb"
  - "app/services/leaderboards.rb"
  - "app/controllers/friendships_controller.rb"
  - "app/controllers/leagues_controller.rb"
  - "app/controllers/leaderboards_controller.rb"
  - "app/controllers/nicknames_controller.rb"
  - "app/controllers/parents/league_permissions_controller.rb"
  - "app/models/friendship.rb"
  - "app/models/league*.rb"
  - "app/views/friendships/**"
  - "app/views/leagues/**"
  - "app/views/leaderboards/**"
  - "app/views/nicknames/**"
  - "app/helpers/leagues_helper.rb"
---

# Friends and leagues

The duel itself — matchmaking, the ready room, scoring, invitation rooms — is in `duels.md`.

Friends (`/friends`, `FriendshipsController`, students only — a child's friends are not a parent's to browse) are one `friendships` row per pair holding whichever way round it was asked, so every query looks in both columns (`involving`, `pick_between`). **How you find somebody is the whole design**: there is no search by name and no browsing of other students, because this app is used by children — the only way in is a six-character `users.friend_code` the other child handed over, which is the stance the app already takes for linking a parent. That code is deliberately *not* `link_code`: typing a link code makes you a **parent** of the account, with a parent's view of everything, and a child giving a classmate their friend code must not be giving that away. A request still has to be accepted, so a code passed on by a third party does not silently land in a list. Presence is `users.last_seen_at`, stamped by `AuthenticatedController#record_presence` at most once a `User::PRESENCE_THROTTLE` and read as `online?` inside `User::ONLINE_WINDOW` — `update_column`, not `touch`, because presence is a note about the browser and must not bump `updated_at` or fire callbacks, and never while impersonating, for the reason a duel question is not served then: the child is not at the screen, and a green dot beside their name would be saying they are. `Friends.list` sorts the people who are here first, since the list is read to decide who to invite.

**Leagues** — „класации с приятели“ (`Leagues`, `League`, `LeagueMembership`, the „С приятели“ section under the week's board on the duel's „Класация“ tab — `/leagues` itself redirects there) — are private weekly leaderboards, and **not ranked by XP**: their members are friends and siblings of every age, and XP is paid per answer, so a first-grader racing through times-table facts out-earned a twelfth-grader every week (the family field test). A league point is effort against the child's own goal (`Leagues.effort`): each Sofia day pays up to `DAY_POINTS` (100) in proportion to practice minutes over `daily_minutes_target` (answers, not skips, each counted for at most `ANSWER_CAP_MS`, five minutes), and nothing past the goal — so a week is worth at most 700 to anybody and grinding buys nothing; ties go to the week's XP, and a row's note is its days with the goal met. Monday resets leagues with the global board, which stays on XP (strangers, no claim to fairness between ages). A member with no points yet this week is listed without a place, as not having practised, because a list ending in „— 0“ reads to a child as being singled out. Getting in mirrors making a friend: the owner adds accepted friends when creating it, and anybody else needs the league's six-character code from a member — no search, no browsing. Members are shown as `User#short_name` (first name and surname initial): the people in a league chose to be there with each other, which is why a league shows names while the global board shows nicknames only. Only members can open a league (it is looked up among the student's own); the owner can change the code (the old one stops working, members stay), take somebody out or delete it, and an owner who leaves hands it to the longest-standing member, the last one out deleting it. A managed child is in a league according to `users.leagues_allowed`, set from the child's page (`Parents::LeaguePermissionsController`; switching off takes the child out of all of them); while it is NULL — the parent has not said — a child with a login of their own is in and one without is not (`User#leagues_on?`). A student who is not managed decides for themselves. Every page that shows a student to other children — the duel, friends, the weekly board, leagues — first asks a student with no nickname for one (`AuthenticatedController#require_nickname`, `NicknamesController`), because without it they were „Противник" in requests and duels and missing from the board. The public board that would go with this is designed but not built — see BACKLOG.md.
