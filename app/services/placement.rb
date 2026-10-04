# Finding out where a new student stands, in eight questions, and telling them.
#
# The app has always placed students — `Dispatcher.calibrating?` runs a ladder
# over their first twelve answers and the rating converges. Two things were
# wrong with it. It is *invisible*: a child answers twelve ordinary-looking
# questions and is never told what came of it, so the one moment that could say
# „here is where you are starting" passes without a word. And it is slower than
# it needs to be: a fixed ladder of rungs climbing 400 points asks the same
# questions of a child who is plainly struggling and one who is plainly flying.
#
# This asks instead. Each answer narrows the range the next question is drawn
# from, so eight questions locate a student inside a few dozen Elo points, and
# the session ends on a screen that names their band.
#
# **Gallop, then bisect.** A pure binary search would open at the midpoint of
# the bank, which for most children is a problem they cannot read — and this
# app's whole stance on starting ratings is that starting low is the cheap
# mistake (see Dispatcher.starting_rating). So the first question sits near the
# bottom and the search *climbs*, doubling its step while the answers are
# right, until one is wrong. That wrong answer closes a bracket, and the rest
# of the session bisects it. A struggling child meets one easy question and is
# then measured carefully at the bottom; a strong one is carried up in three or
# four jumps and measured carefully at the top. Nobody is asked to start in the
# middle of a bank they have never seen.
#
# A skip counts as too hard. „Не съм го учил" is the honest answer to a problem
# from a topic school has not reached, and reading it as a wrong answer is both
# true and kinder than making the child guess — see Assignment#skippable?.
module Placement
  QUESTION_COUNT = 8

  # The first step up from the floor, doubling on each correct answer: 200,
  # 400, 800, 1600 — four of them cross the whole bank, so even the strongest
  # student reaches their level with questions to spare for bisecting.
  CLIMB = 200

  NotEnoughQuestions = Class.new(StandardError)

  Result = Struct.new(:rating, :band, :correct, :total, keyword_init: true)

  module_function

  # The span the search works in: the bank's own occupied range, not a constant.
  # A placement that could land a student outside the difficulties that exist
  # would be placing them nowhere.
  def range
    pool = Dispatcher.practice_pool
    floor = pool.minimum(:elo)&.round
    ceiling = pool.maximum(:elo)&.round
    raise NotEnoughQuestions if floor.nil? || ceiling.nil? || ceiling <= floor

    [ floor, ceiling ]
  end

  # Who is still worth placing.
  #
  # Not simply "has no placed_at": every account that existed before this was
  # built has none, and a child with ten weeks of history has a rating that
  # hundreds of real answers converged on. Replacing that with an eight-question
  # estimate would be a downgrade dressed as a feature. So the question asked is
  # the one that was always being asked — is this rating still a guess? —
  # and Dispatcher.calibrating? already answers it, placed_at included.
  def due?(user)
    user.student? && Dispatcher.calibrating?(user)
  end

  # A placement that was abandoned part-way and still has a question waiting.
  # A child who closed the tab on question three should come back to question
  # three, not start a fresh eight — and certainly not leave a half-answered
  # session behind every time they open the card.
  def unfinished(user)
    assignment = user.assignments.placement.where(completed_at: nil).order(:created_at).last
    assignment if assignment&.next_assignment_question
  end

  def start!(user)
    assignment = Assignment.create!(user: user, kind: :placement)
    append_question!(assignment, [])
    assignment
  end

  # Called after each answer: adds the next question, narrowed by everything
  # answered so far, or finishes the session when there are no more to ask.
  def advance!(assignment)
    asked = rows(assignment)
    return finish!(assignment) if asked.size >= QUESTION_COUNT

    append_question!(assignment, asked) || finish!(assignment)
  end

  # The session's questions and answers, always read fresh.
  #
  # Never `assignment.assignment_questions` on its own: by the time advance! is
  # called the answer that triggered it was saved through a *different*
  # instance of the same row, so a cached association reports the newest answer
  # as missing — and a search that cannot see the last answer asks the same
  # question again and places everybody at the floor. Adding a query method
  # builds a new relation, which is what makes this a fresh read.
  def rows(assignment)
    assignment.assignment_questions.includes(:question, :user_answer).to_a
  end

  # What the answers so far say: the hardest question cleared and the easiest
  # one missed. `high` is nil until something has been missed, which is what
  # tells `next_target` it is still climbing.
  def bracket(assignment, asked = rows(assignment))
    floor, ceiling = range
    low = floor
    high = nil

    asked.each do |aq|
      answer = aq.user_answer
      next if answer.nil?

      elo = aq.question.elo
      # Skipped counts with the misses: see the note at the top.
      if answer.correct?
        low = [ low, elo ].max
      else
        high = high ? [ high, elo ].min : elo
      end
    end

    [ low, high, ceiling ]
  end

  # Where to aim the next question.
  def next_target(assignment, asked = rows(assignment))
    low, high, ceiling = bracket(assignment, asked)
    return midpoint(low, high) if high

    # Still climbing: double the step for each correct answer in a row, so the
    # search crosses the bank in a handful of questions rather than inching.
    cleared = asked.filter_map(&:user_answer).count(&:correct?)

    [ low + CLIMB * (2**cleared), ceiling ].min
  end

  # The rating the session lands on.
  #
  # A student who missed nothing is placed at the hardest thing they cleared
  # rather than at the top of the bank: eight right answers says „at least
  # this", not „everything". A student who missed everything sits at the floor.
  def rating_for(assignment, asked = rows(assignment))
    low, high, _ceiling = bracket(assignment, asked)

    high ? midpoint(low, high) : low
  end

  def finish!(assignment)
    user = assignment.user
    rating = rating_for(assignment)

    ActiveRecord::Base.transaction do
      # Reloaded because AnswerSubmission completes the session on its own
      # instance a moment earlier; stamping a second time would move the
      # finishing time by however long this took.
      assignment.reload
      assignment.update!(completed_at: Time.current) if assignment.completed_at.nil?
      # Set before any `skills` row exists, so the per-topic ratings that get
      # created later start from the placed number rather than from the floor
      # every new account is seeded with.
      user.update!(elo: rating, placed_at: Time.current)
    end

    result(assignment)
  end

  def result(assignment)
    answers = rows(assignment).filter_map(&:user_answer)

    Result.new(
      rating: assignment.user.elo,
      band: RatingBand.new(assignment.user.elo),
      correct: answers.count(&:correct?),
      total: answers.size
    )
  end

  def append_question!(assignment, asked)
    question = Dispatcher.at_rung(
      assignment.user,
      rung: next_target(assignment, asked),
      excluding: asked.map(&:question)
    )
    return nil if question.nil?

    assignment.assignment_questions.create!(question: question, position: asked.size + 1)
  end

  def midpoint(low, high) = ((low + high) / 2.0).round
end
