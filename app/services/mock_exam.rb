# „Пробен изпит": a timed paper for one exam (НВО 4/7/10, the матура), sat like
# the real thing rather than practised like a session. Every exam-age child in
# the family field test asked for one — „how far am I from a good score" was
# the question no screen answered.
#
# What makes it a mock and not practice:
#   * *The exam's difficulty, not the child's.* The problems are spread evenly
#     across the exam's own grade window (Competitions::Event#elo_range), so the
#     score says something about the exam rather than being pinned near 70% the
#     way every adaptive session is.
#   * *Timed.* `minutes` from FORMATS; once they run out the paper is over and
#     what was left unanswered counts as not done.
#   * *No help.* No hints, no verdict or sound after each answer — the score and
#     the topics come at the end, on the summary.
# It is still measured: these are fresh problems and the answers are evidence.
#
# The numbers are a mock's, not the ministry's: a fixed count and time per exam,
# scored as a percentage. The real formats and point scales are a later step.
module MockExam
  Format = Struct.new(:questions, :minutes, keyword_init: true)
  FORMATS = Hash.new(Format.new(questions: 20, minutes: 60)).merge(
    "nvo-4-klas" => Format.new(questions: 15, minutes: 45)
  ).freeze

  NothingToSit = Class.new(StandardError)

  module_function

  def format_for(event) = FORMATS[event.slug]

  def start!(user:, event:)
    format = format_for(event)
    questions = pick(event, format.questions)
    raise NothingToSit if questions.size < format.questions / 2

    assignment = Assignment.build(user: user, kind: :mock, competition_slug: event.slug, feedback_after_answer: false)
    questions.each_with_index { |question, index| assignment.assignment_questions.build(question: question, position: index + 1) }
    assignment.save!
    assignment
  end

  # Evenly across the exam's window, easiest first as on a real paper, one per
  # template; a rung with nothing near it is filled from the nearest rung that
  # has something.
  def pick(event, count)
    topic_ids = event.topic_ids
    return [] if topic_ids.empty?

    range = event.elo_range
    floor = range.begin || 0
    ceiling = range.end || (floor + 800)
    pool = Dispatcher.practice_pool.where(id: Question.joins(:topics).where(topics: { id: topic_ids }).select(:id))

    picked = []
    shapes = Set.new
    count.times do |index|
      target = floor + ((ceiling - floor) * (index + 0.5) / count).round
      candidate = pool.where.not(id: picked.map(&:id))
                      .order(Arel.sql("ABS(questions.elo - #{target.to_i}), RANDOM()"))
                      .limit(20).to_a
                      .find { |question| shapes.add?(ProblemSeeds.shape_of(question.body_text.to_s)) }
      picked << candidate if candidate
    end
    picked
  end

  def deadline(assignment) = assignment.created_at + format_for(event_of(assignment)).minutes.minutes
  def over?(assignment) = Time.current >= deadline(assignment)
  def event_of(assignment) = Competitions.find(assignment.competition_slug)

  # Ends the paper: what is unanswered stays unanswered and counts as not done.
  # Stamped no later than the deadline, so a paper left open overnight still
  # says it took its 60 minutes, not „2 часа".
  def finish!(assignment)
    assignment.update!(completed_at: [ Time.current, deadline(assignment) ].min) if assignment.completed_at.nil?
  end

  Result = Struct.new(:total, :correct, :answered, :percent, :weakest, :minutes_used, keyword_init: true)
  TopicScore = Struct.new(:topic, :correct, :total, keyword_init: true)

  def result(assignment)
    rows = assignment.assignment_questions.includes(:user_answer, question: :topics).to_a
    correct = rows.count { |row| row.user_answer&.correct? }
    by_topic = Hash.new { |hash, topic| hash[topic] = TopicScore.new(topic: topic, correct: 0, total: 0) }
    rows.each do |row|
      topic = row.question.topics.first or next
      by_topic[topic].total += 1
      by_topic[topic].correct += 1 if row.user_answer&.correct?
    end
    weakest = by_topic.values.select { |score| score.correct < score.total }
                      .sort_by { |score| [ score.correct.to_f / score.total, -score.total ] }.first(3)
    last = rows.filter_map { |row| row.user_answer&.created_at }.max
    Result.new(total: rows.size, correct: correct, answered: rows.count(&:user_answer),
               percent: rows.empty? ? 0 : (correct * 100.0 / rows.size).round,
               weakest: weakest,
               minutes_used: last ? (((last - assignment.created_at) / 60.0).ceil) : 0)
  end
end
