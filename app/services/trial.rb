# „Опитай без профил": a handful of real problems for a visitor who has not
# signed up, so they can see what a session feels like before they are asked
# for an email.
#
# Nothing is stored. There is no user to store it on, and a guest account
# would mean a row per curious visitor and per crawler that followed the link,
# a cleanup job for them, and a merge into the real account on sign-up — all to
# keep five answers nobody will ask for again (placement measures the child
# properly the moment there is an account). The set and its answers live in
# the session cookie, which is the right size for five question ids and five
# short answers, and no question's Elo moves: a visitor is not a calibrated
# student, and a parent trying the 12th-grade set to see what it looks like is
# not evidence about those problems.
#
# The grade is the public pages' (Curriculum): it is how a parent arriving
# from „задачи за 3 клас" thinks, and it is presentation only, as it is there.
module Trial
  # Long enough to get a feel for it — an easy problem, a harder one, a wrong
  # answer and its explanation — and short enough that the end, where the
  # sign-up is, is reached.
  LENGTH = 5

  # A drawn answer (a filled-in table, an operation chain) is read back as a
  # drawing (answers/_grid_fill_review and friends), which needs a stored
  # answer; as a line of text it is „0,1: 170, 1,0: 162…". The rest of the
  # widgets read back fine, and they are a good half of what the app is.
  DRAWN_WIDGETS = WidgetAnswersHelper::DRAWN_ANSWERS.keys.freeze

  # What a stored answer's text is cut to: the session is a cookie.
  VALUE_LIMIT = 120

  module_function

  # LENGTH question ids for the grade, easy to hard: one at random from each of
  # LENGTH equal slices of the Elo the grade's problems actually occupy, so the
  # set climbs the way a session does instead of being five of the easiest.
  # Random, unlike the grade page's samples: the grade page is read by a
  # crawler, this is used by a person, and „Още 5 задачи" should mean new ones.
  def pick(grade)
    scope = pool(grade)
    floor = scope.minimum(:elo)
    ceiling = scope.maximum(:elo)
    return [] if floor.nil?

    step = (ceiling - floor).fdiv(LENGTH)

    ids = (0...LENGTH).filter_map do |index|
      low = (floor + step * index).floor
      high = index == LENGTH - 1 ? ceiling : (floor + step * (index + 1)).floor
      scope.where(elo: low..high).order(Arel.sql("RANDOM()")).pick(:id)
    end

    ids.uniq
  end

  # Published problems in the grade's window and programme that can be shown
  # and graded without an account, each with the worked explanation the
  # feedback card is there to show.
  def pool(grade)
    Question.published
            .where(elo: grade.range)
            .where(id: Question.joins(:topics).where(topics: { id: Curriculum.topic_ids(grade) }).select(:id))
            .where(answer_type: [ :multiple_choice, :exact_value, :interactive ])
            .where("questions.answer_type <> ? OR questions.grading->>'widget' NOT IN (?)",
                   Question.answer_types[:interactive], DRAWN_WIDGETS)
            .where.not(explanation: [ nil, "" ])
  end

  # The visitor's run through one grade's set, kept in the session as plain
  # JSON-able values.
  class Run
    attr_reader :grade, :ids, :answers

    def self.load(session, grade)
      data = session[:trial]
      return nil unless data.is_a?(Hash) && data["grade"] == grade.slug && data["ids"].is_a?(Array)

      new(grade, data["ids"], data["answers"].is_a?(Hash) ? data["answers"] : {})
    end

    def self.start(session, grade)
      run = new(grade, Trial.pick(grade), {})
      run.save(session)
      run
    end

    def initialize(grade, ids, answers)
      @grade = grade
      @ids = ids
      @answers = answers
    end

    def save(session)
      session[:trial] = { "grade" => grade.slug, "ids" => ids, "answers" => answers }
    end

    def length = ids.size
    def empty? = ids.empty?

    # Positions are 1-based, as in the URL and on the screen.
    def question_id(position) = ids[position - 1]
    def answer(position) = answers[position.to_s]
    def answered?(position) = answers.key?(position.to_s)

    def record(position, correct:, value:)
      answers[position.to_s] = { "correct" => correct, "value" => value.to_s.truncate(VALUE_LIMIT) }
    end

    def finished? = !empty? && answers.size >= length
    def correct_count = answers.values.count { |answer| answer["correct"] }

    # The first problem not yet answered — where a visitor who comes back
    # picks up.
    def next_position
      (1..length).find { |position| !answered?(position) }
    end

    def questions
      Question.includes(:possible_answers, :topics, :attachable).where(id: ids).index_by(&:id).values_at(*ids)
    end
  end
end
