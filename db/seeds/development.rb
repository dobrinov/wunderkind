# Development-only seed data: a small cast of users with real history, so every
# screen in the app has something to show. Everything goes through the real
# services (SessionComposer, AnswerSubmission, HomeworkCreator,
# ChallengeMatchmaker/ChallengeSubmission, QuestionReport.file!) under
# travel_to, so ratings, XP, streaks, badges, spaced review and mastery are all
# internally consistent — nothing is written into a table by hand that a
# service owns.
#
# The cast (password everywhere: "password"):
#   viki@example.com     Вики   — untouched: sees the calibration ladder cold
#   eli@example.com      Ели    — 10 weeks of practice, rising trend, streak,
#                                 badges, hints used, a skip, filed reports
#   bobi@example.com     Боби   — strong student (Силен/Отличен), mastered
#                                 topics, duel record
#   ani@example.com      Ани    — struggling beginner, deferred topics
#   teacher@example.com  Мария  — classroom with all four, two homeworks,
#                                 authored questions in draft/library/review
#   parent@example.com   Ивана  — linked to Ели by code, manages Ния (who has
#                                 her own practice history to look at)
#   admin@example.com    Деян   — report queue and review queue both populated
#
# Idempotent: bails out if the cast already exists.

require "active_support/testing/time_helpers"
include ActiveSupport::Testing::TimeHelpers

if User.exists?(email: "eli@example.com")
  puts "Development seeds already present — skipping. (Drop and re-create the DB to rebuild them.)"
  return
end

if Question.published.count < 1000
  puts "Question bank looks empty or tiny — import db/seeds/ladders first. Skipping development seeds."
  return
end

puts "Seeding development data (this simulates ~10 weeks of real usage and takes a few minutes)..."

# --- Answer construction ------------------------------------------------------
# Builds a raw submission for a question, correct or wrong, the same shape the
# controllers pass to Grading. Returns nil when it cannot build one (then the
# caller flips the intention rather than submitting something blank).

def correct_raw_for(question)
  case question.answer_type
  when "exact_value"
    { value: question.grading["expected"].to_s }
  when "multiple_choice"
    { selected_ids: question.correct_possible_answers.map(&:id) }
  when "interactive"
    state = correct_state_for(question)
    state && { state: state }
  end
end

def correct_state_for(question)
  solution = question.grading["solution"]
  params = question.grading["params"]
  candidates = []
  candidates << solution if solution.is_a?(Hash)
  candidates << { "selected" => solution["correct"] } if solution.is_a?(Hash) && solution["correct"]

  candidates.find do |state|
    Widgets.correct?(question.widget_type, solution: solution, state: state, params: params) rescue false
  end
end

def wrong_raw_for(question)
  case question.answer_type
  when "exact_value"
    expected = question.grading["expected"]
    tolerance = question.grading["tolerance"]
    value = %w[999999 123456.5 -777].find do |candidate|
      !(ExactValue.equivalent?(expected, candidate, tolerance: tolerance) rescue false)
    end
    value && { value: value }
  when "multiple_choice"
    wrong_ids = question.possible_answers.reject(&:correct).map(&:id)
    wrong_ids.any? ? { selected_ids: [ wrong_ids.first ] } : nil
  when "interactive"
    state = wrong_state_for(question)
    state && { state: state }
  end
end

def wrong_state_for(question)
  solution = question.grading["solution"]
  params = question.grading["params"]
  base = correct_state_for(question) || (solution.is_a?(Hash) ? solution : nil)
  return nil unless base

  [ 1, 7, 13 ].each do |shift|
    mutated = mutate_state(base, shift)
    next if mutated.blank? || mutated == base

    graded = (Widgets.correct?(question.widget_type, solution: solution, state: mutated, params: params) rescue true)
    return mutated unless graded
  end
  nil
end

def mutate_state(value, shift)
  case value
  when Hash then value.transform_values { |inner| mutate_state(inner, shift) }
  when Array then value.map { |inner| mutate_state(inner, shift) }
  when Integer then value + shift
  when Float then value + shift
  when String then value.match?(/\A-?\d+\z/) ? (value.to_i + shift).to_s : value
  else value
  end
end

# Answers one assignment question through the real pipeline. `correct:` is an
# intention: when a submission of that verdict cannot be constructed for the
# widget, the other verdict is submitted instead — the simulation only needs
# approximate accuracy.
def submit_answer(assignment_question, user, correct:, hints_used: 0)
  question = assignment_question.question
  raw = correct ? correct_raw_for(question) : wrong_raw_for(question)
  raw ||= correct ? wrong_raw_for(question) : correct_raw_for(question)
  return :skipped_no_raw unless raw

  # The same write HintRevealsController makes as it serves each rung.
  assignment_question.update!(hints_revealed: hints_used) if hints_used.positive?

  AnswerSubmission.call(
    assignment_question: assignment_question,
    user: user,
    raw: raw,
    duration_ms: rand(6_000..75_000)
  )
end

# Probability the student answers correctly, from a "true skill" the rating
# system does not see — this is what makes the ratings converge somewhere real.
def answers_correctly?(true_rating, question)
  expected = 1.0 / (1 + 10**((question.elo - true_rating) / 400.0))
  rand < expected
end

# One full practice session at a moment in time.
def run_session(user, true_rating:, at:, question_count: 10, kind: :practice, use_hints: false)
  travel_to(at) do
    assignment = SessionComposer.execute(user: user, question_count: question_count, kind: kind)
    assignment.assignment_questions.order(:position).includes(question: :hint).each do |aq|
      correct = answers_correctly?(true_rating, aq.question)
      hints = use_hints && correct && aq.question.hint.present? && rand < 0.25 ? 1 : 0
      submit_answer(aq, user, correct: correct, hints_used: hints)
    end
    assignment
  end
end

# --- The cast -----------------------------------------------------------------

def seed_student(name:, email:, nickname:, elo: nil, daily_minutes: nil)
  attributes = {
    name: name, email: email, password: "password", role: :student,
    nickname: nickname, daily_minutes_target: daily_minutes
  }.compact
  attributes[:elo] = elo if elo
  user = User.new_student(attributes)
  user.save!
  user
end

eli  = seed_student(name: "Ели",  email: "eli@example.com",  nickname: "eli_star", daily_minutes: 15)
bobi = seed_student(name: "Боби", email: "bobi@example.com", nickname: "bobi_pro", elo: 1600)
ani  = seed_student(name: "Ани",  email: "ani@example.com",  nickname: "ani_m", daily_minutes: 10)
# Вики exists to be brand new: zero answers, so opening her account shows the
# calibration ladder exactly as a real new student meets it. (The base-seed
# Виктор can't be relied on for this — a used development database may already
# carry history on him.)
viki = seed_student(name: "Вики", email: "viki@example.com", nickname: "viki")

admin  = User.find_by!(email: "admin@example.com")
maria  = User.find_by!(email: "teacher@example.com")
ivana  = User.find_by!(email: "parent@example.com")
viktor = User.find_by!(email: "student@example.com")
niya   = ivana.managed_children.first || User.create_managed_child!(parent: ivana, name: "Ния")

today = Date.current

# --- Ели: ten weeks of practice with a genuinely improving true skill ---------
# Week 6 is deliberately empty (a holiday), so the trend chart shows a gap
# rather than a zero. The final week runs every day, so the streak is alive.

puts "  Ели: 10 weeks of practice..."
eli_true = 780
(0..9).each do |week|
  next if week == 6

  days = week == 9 ? (-5..-1).to_a : [ 0, 1, 2, 3, 4, 5 ].sample(3).sort
  days.each do |day|
    at = (today - (9 - week).weeks + day.days).to_time.change(hour: 17, min: rand(0..55))
    next if at > Time.current

    run_session(eli, true_rating: eli_true, at: at, use_hints: true)
  end
  eli_true += 55 # she is learning: ~780 → ~1250 across the ten weeks
end

# Today: a daily session (the kind daily_minutes_target sizes), keeping the
# streak alive and putting her on this week's leaderboard.
run_session(eli, true_rating: eli_true, at: Time.current.change(hour: 9, min: 30), question_count: 6, kind: :daily)

# One honest "не съм го учил" on a topic the student has barely met — deferral
# only fires while the topic has fewer than DEFERRAL_MAX_GAMES games, so the
# skip has to land on an unseen topic to leave a visible deferred_until.
def skip_unseen_topic(user, at:)
  travel_to(at) do
    Topic.where.not(id: user.skills.select(:topic_id)).pluck(:id).shuffle.each do |topic_id|
      questions = Dispatcher.pick(user, count: 2, topic_ids: [ topic_id ])
      next if questions.size < 2

      assignment = Assignment.build(user: user, kind: :practice)
      questions.each_with_index { |question, index| assignment.assignment_questions.build(question:, position: index + 1) }
      assignment.save!
      assignment.assignment_questions.order(:position).each do |aq|
        AnswerSubmission.skip(assignment_question: aq, user: user, duration_ms: rand(3_000..9_000))
      end
      return true
    end
    false
  end
end

skip_unseen_topic(eli, at: Time.current.change(hour: 10, min: 15))

# --- Боби: a strong student ----------------------------------------------------
# Starts already rated 1600 (a transfer, the case User.new_student's comment
# reserves) and plays four weeks at true skill ~1800, so several topics cross
# the mastery bar on their own.

puts "  Боби: 4 strong weeks..."
(0..3).each do |week|
  [ 0, 2, 4 ].each do |day|
    at = (today - (3 - week).weeks + day.days).to_time.change(hour: 19, min: rand(0..55))
    next if at > Time.current

    run_session(bobi, true_rating: 1800, at: at)
  end
end
run_session(bobi, true_rating: 1800, at: Time.current.change(hour: 8, min: 45))

# Two focused sessions on one topic he is genuinely good at, answered clean, so
# the mastery flow (rating ≥ 1400 with 10+ games on the topic) actually fires
# and there is a mastered topic to look at.
mastery_topic = Topic.find_by(name: "Питагорова теорема")
if mastery_topic
  [ 2, 1 ].each do |days_ago|
    travel_to((today - days_ago).to_time.change(hour: 20, min: 10)) do
      questions = Dispatcher.pick(bobi, count: 6, topic_ids: [ mastery_topic.id ])
      next if questions.empty?

      assignment = Assignment.build(user: bobi, kind: :practice)
      questions.each_with_index { |question, index| assignment.assignment_questions.build(question:, position: index + 1) }
      assignment.save!
      assignment.assignment_questions.order(:position).includes(:question).each do |aq|
        submit_answer(aq, bobi, correct: true)
      end
    end
  end
end

# --- Ани: a struggling beginner -------------------------------------------------

puts "  Ани: 2 hard weeks..."
[ 12, 10, 8, 5, 3, 1 ].each do |days_ago|
  at = (today - days_ago).to_time.change(hour: 16, min: rand(0..55))
  run_session(ani, true_rating: 700, at: at)
end
# A topic she hasn't been taught yet, skipped this morning.
skip_unseen_topic(ani, at: Time.current.change(hour: 11, min: 0))

# --- Ния: the managed child has her own week to look at -------------------------

puts "  Ния: 3 short sessions..."
[ 4, 2, 0 ].each do |days_ago|
  at = (today - days_ago).to_time.change(hour: 18, min: rand(0..55))
  next if at > Time.current

  run_session(niya, true_rating: 820, at: at, question_count: 6)
end

# --- Classroom and homework -----------------------------------------------------

puts "  Classroom + homework..."
classroom = maria.classrooms.create!(name: "5. клас — Математика", leaderboard_enabled: true)
[ eli, bobi, ani, viki, viktor ].each { |student| classroom.classroom_memberships.create!(user: student) }

free_text_questions = Question.published.where(answer_type: Question.answer_types[:free_text]).to_a

# A finished homework from last week: Ели and Боби completed it (Ели's free-text
# answer already overridden by Мария), Ани got halfway.
past_homework = travel_to(9.days.ago.change(hour: 12)) do
  HomeworkCreator.execute(
    assigner: maria, classroom: classroom,
    title: "Дроби — преговор", due_at: 2.days.from_now,
    students: [ eli, bobi, ani, viki ],
    question_ids: free_text_questions.first ? [ free_text_questions.first.id ] : [],
    auto_count: 5, hints_allowed: false
  )
end

def answer_homework(homework, student, true_rating:, at:, limit: nil)
  assignment = homework.assignments.find_by!(user: student)
  travel_to(at) do
    scope = assignment.assignment_questions.order(:position).includes(:question)
    scope = scope.limit(limit) if limit
    scope.each do |aq|
      if aq.question.answer_type == "free_text"
        AnswerSubmission.call(
          assignment_question: aq, user: student,
          raw: { value: "Защото частите са равни: разделих цялото на еднакви дялове и преброих колко от тях са оцветени." },
          duration_ms: rand(40_000..120_000)
        )
      else
        submit_answer(aq, student, correct: answers_correctly?(true_rating, aq.question))
      end
    end
  end
  assignment
end

answer_homework(past_homework, eli, true_rating: 1100, at: 8.days.ago.change(hour: 17))
answer_homework(past_homework, bobi, true_rating: 1800, at: 8.days.ago.change(hour: 20))
answer_homework(past_homework, ani, true_rating: 700, at: 7.days.ago.change(hour: 16), limit: 3)

# Мария reviewed Ели's free-text answer and accepted it — the same write
# AnswerOverridesController performs.
if free_text_questions.first
  override = UserAnswer.joins(assignment_question: :assignment).
    where(assignments: { homework_id: past_homework.id }, user_id: eli.id).
    find { |answer| answer.response["verdict"] == "pending_review" }
  override&.update!(correct: true, response: override.response.merge("verdict" => "correct", "overridden" => true))
end

# A live homework due next week: Ели finished it yesterday (her free-text answer
# still pending review — try the override flow as Мария), Боби is halfway, Ани
# and Виктор haven't started.
current_homework = travel_to(2.days.ago.change(hour: 13)) do
  HomeworkCreator.execute(
    assigner: maria, classroom: classroom,
    title: "Проценти и части от цяло", due_at: 7.days.from_now,
    students: [ eli, bobi, ani, viki ],
    question_ids: free_text_questions.second ? [ free_text_questions.second.id ] : [],
    auto_count: 5, hints_allowed: true
  )
end

answer_homework(current_homework, eli, true_rating: 1250, at: 1.day.ago.change(hour: 18))
answer_homework(current_homework, bobi, true_rating: 1800, at: 1.day.ago.change(hour: 19), limit: 3)

# --- Duels -----------------------------------------------------------------------
# Played through the real matchmaker: the second player joins via the PATIENCE
# path (their ratings sit further apart than MAX_GAP), so the lobby has to be
# 45+ seconds old before the opponent arrives.

puts "  Duels..."
def play_duel(host, joiner, base_time, winner: nil)
  challenge = nil
  travel_to(base_time) { challenge = ChallengeMatchmaker.call(user: host) }
  travel_to(base_time + 50.seconds) do
    joined = ChallengeMatchmaker.call(user: joiner)
    raise "matchmaker did not pair the duel" unless joined.id == challenge.id
  end

  challenge.reload
  cursor = base_time + 55.seconds
  challenge.challenge_questions.order(:position).includes(:question).each do |challenge_question|
    challenge.participants.includes(:user).each do |participant|
      correct = winner.present? && participant.user_id == winner.id
      # An intended wrong answer must never fall back to a correct one — that
      # would hand points to a player who is supposed to lose (or draw). A
      # question we can't answer as intended is simply left unanswered.
      raw = correct ? correct_raw_for(challenge_question.question) : wrong_raw_for(challenge_question.question)
      next unless raw

      travel_to(cursor) { ChallengeSubmission.serve(participant) }
      cursor += rand(3..7).seconds
      travel_to(cursor) do
        ChallengeSubmission.call(participant: participant.reload, challenge_question: challenge_question, raw: raw)
      end
    end
  end

  # A player who left questions unanswered keeps the match active; run the
  # shared clock out so it settles the way an abandoned match really would.
  challenge.reload
  if challenge.active?
    clock = challenge.question_count * challenge.seconds_per_question
    travel_to(challenge.started_at + clock.seconds + 5.seconds) { ChallengeSubmission.settle(challenge) }
  end
  challenge.reload
end

play_duel(bobi, eli, 5.days.ago.change(hour: 19), winner: bobi)   # Боби wins
play_duel(eli, bobi, 2.days.ago.change(hour: 19), winner: eli)    # the upset
play_duel(eli, ani, 1.day.ago.change(hour: 18), winner: nil)      # nobody scores: a draw

# --- Question reports --------------------------------------------------------------
# Filed on questions the students really met. Two questions stay open in the
# admin queue (one with a pile of two reporters), one closed as resolved, one
# dismissed.

puts "  Question reports..."
answered = ->(user) { Question.joins(assignment_questions: :user_answer).where(user_answers: { user_id: user.id }).distinct }
eli_questions = answered.call(eli).limit(8).to_a
ani_questions = (answered.call(ani).limit(4).to_a - eli_questions.first(2))

travel_to(1.day.ago.change(hour: 18, min: 40)) do
  QuestionReport.file!(question: eli_questions[0], user: eli, reason: :wrong_answer,
                       note: "Отговорих 12 и ми пише грешно, а в тетрадката на всички е 12.")
end
travel_to(Time.current.change(hour: 10, min: 20)) do
  QuestionReport.file!(question: eli_questions[0], user: bobi, reason: :wrong_answer,
                       note: "И при мен не приема верния отговор.")
  QuestionReport.file!(question: eli_questions[1], user: eli, reason: :typo,
                       note: "В условието пише „киломтера“.")
end

travel_to(3.days.ago.change(hour: 15)) do
  QuestionReport.file!(question: ani_questions[0], user: ani, reason: :misleading, note: "Не разбирам какво се иска.")
  QuestionReport.file!(question: ani_questions[1], user: ani, reason: :image)
end
travel_to(2.days.ago.change(hour: 9)) do
  QuestionReport.close_pile!(question: ani_questions[0], status: :resolved, by: admin)
  QuestionReport.close_pile!(question: ani_questions[1], status: :dismissed, by: admin)
end

# --- Мария's authored questions: draft, private library, and the review queue ------

puts "  Teacher-authored questions..."
def clone_question_for(author, status)
  source = Question.published.where(answer_type: Question.answer_types[:exact_value]).order("RANDOM()").first
  clone = Question.new(
    source.attributes.slice("text", "answer", "explanation", "body", "body_text", "answer_type", "grading", "elo")
  )
  clone.author = author
  clone.status = status
  clone.save!
  clone.topics = source.topics
  clone
end

clone_question_for(maria, :draft)
clone_question_for(maria, :private_library)
clone_question_for(maria, :in_review)

# A hint typed by hand, still unreviewed — the gate at /overseer/questions/:id/hint.
unhinted = Question.published.where.missing(:hint).where(answer_type: Question.answer_types[:exact_value]).first
if unhinted
  begin
    QuestionHint.create!(question: unhinted,
                         ladder: [ "Прочети условието още веднъж — какво точно се търси?",
                                   "Опитай да запишеш даденото като сметка, преди да смяташ." ])
  rescue StandardError => error
    puts "    (skipped the unreviewed hint: #{error.message})"
  end
end

# --- Streak replay -------------------------------------------------------------------
# The blocks above travel back and forth in time (practice first, then homework
# and duels on earlier days), but Streaks.record is order-sensitive. Replay each
# student's activity dates chronologically through the real service so the
# streaks come out the way real usage would have produced them.

puts "  Streak replay..."
[ eli, bobi, ani, niya ].each do |student|
  dates = student.user_answers.pluck(:created_at).map(&:to_date)
  dates += ChallengeAnswer.joins(:challenge_participant).
    where(challenge_participants: { user_id: student.id }).pluck(:created_at).map(&:to_date)
  student.update!(current_streak: 0, longest_streak: 0, streak_freezes: 0, last_active_on: nil)
  dates.uniq.sort.each { |date| Streaks.record(student, on: date) }
  student.save!
end

# --- Parent links -------------------------------------------------------------------

eli.ensure_link_code!
ivana.parent_links.create!(child: eli)

puts
puts "Development seeds ready. The cast (password: \"password\"):"
puts "  admin@example.com    Деян   — admin: report queue, review queue, overseer"
puts "  teacher@example.com  Мария  — classroom, two homeworks, authored questions"
puts "  parent@example.com   Ивана  — linked to Ели, manages Ния (switch profiles)"
puts "  viki@example.com     Вики   — brand new: the calibration experience"
puts "  eli@example.com      Ели    — #{eli.reload.elo} Elo, #{eli.current_streak}-day streak, trend chart, badges"
puts "  bobi@example.com     Боби   — #{bobi.reload.elo} Elo, #{bobi.skills.where.not(mastered_at: nil).count} mastered topics, duel record"
puts "  ani@example.com      Ани    — #{ani.reload.elo} Elo, deferred topics, open reports"
