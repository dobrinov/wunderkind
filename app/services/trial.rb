# „Опитай без профил": a handful of real problems for a visitor who has not
# signed up, so they can see what a session feels like before they are asked
# for an email. Offered on every public page, each with the problems that page
# is about (a Deck): a grade's, a topic's, or a competition's — and for a
# competition whose papers the bank holds, that competition's own problems.
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

  TOPIC_PREFIX = "tema-".freeze

  module_function

  # LENGTH question ids from the deck, easy to hard: one at random from each
  # of LENGTH equal slices of the Elo its problems actually occupy, so the set
  # climbs the way a session does instead of being five of the easiest.
  # Random, unlike the public pages' samples: those are read by a crawler,
  # this is used by a person, and „Още 5 задачи" should mean new ones.
  #
  # Outside the query cache, which would hand back the same „random" row for
  # the same SQL within one request or console session.
  def pick(deck)
    ActiveRecord::Base.uncached { pick_uncached(deck) }
  end

  def pick_uncached(deck)
    scope = deck.pool
    floor = scope.minimum(:elo)
    ceiling = scope.maximum(:elo)
    return [] if floor.nil?

    step = (ceiling - floor).fdiv(LENGTH)
    used_topics = []

    ids = (0...LENGTH).filter_map do |index|
      low = (floor + step * index).floor
      high = index == LENGTH - 1 ? ceiling : (floor + step * (index + 1)).floor
      band = scope.where(elo: low..high)
      id = Trial.unlike(band, used_topics).order(Arel.sql("RANDOM()")).pick(:id) ||
           band.order(Arel.sql("RANDOM()")).pick(:id)
      used_topics.concat(Question.find(id).topic_ids) if id
      id
    end

    ids.uniq
  end

  # A band's problems from topics the set has not had yet: five problems that
  # are two „Числа и редици" and two „Събиране и изваждане" show a fraction of
  # what the bank is. Where the band has nothing else — a topic's own deck —
  # the caller falls back to the whole band.
  def unlike(scope, topic_ids)
    return scope if topic_ids.empty?

    scope.where.not(id: Question.joins(:topics).where(topics: { id: topic_ids }).select(:id))
  end

  # Published problems that can be shown and graded without an account, each
  # with the worked explanation the feedback card is there to show.
  def gradable
    Question.published
            .where(answer_type: [ :multiple_choice, :exact_value, :interactive ])
            .where("questions.answer_type <> ? OR questions.grading->>'widget' NOT IN (?)",
                   Question.answer_types[:interactive], DRAWN_WIDGETS)
            .where.not(explanation: [ nil, "" ])
  end

  def within_topics(scope, topic_ids)
    scope.where(id: Question.joins(:topics).where(topics: { id: topic_ids }).select(:id))
  end

  # What a trial deals from, named by one URL segment:
  #
  #   3-klas                          a grade (Curriculum's window and programme)
  #   tema-drobi                      a topic, easy to hard across all of it
  #   kenguru                         a competition or exam: its topics and grades
  #   sofiyski-matematicheski-turnir-3-klas
  #                                   one grade of a competition whose papers the
  #                                   bank holds: its real problems (PastPapers)
  #                                   and the ones written on their model
  Deck = Struct.new(:key, :grade, :topic, :event, :paper_grade, keyword_init: true) do
    def self.find(key)
      key = key.to_s
      if (grade = Curriculum.grade(key))
        new(key: key, grade: grade)
      elsif key.start_with?(TOPIC_PREFIX) && (topic = Curriculum.find_topic(key.delete_prefix(TOPIC_PREFIX)))
        new(key: key, topic: topic)
      elsif (event = Competitions.find(key))
        new(key: key, event: event)
      elsif (match = key.match(/\A(.+)-(\d{1,2})-klas\z/)) && (event = Competitions.find(match[1])) &&
            PastPapers.grades(event.slug).include?(match[2].to_i)
        new(key: key, event: event, paper_grade: match[2].to_i)
      end
    end

    def self.for_grade(grade) = new(key: grade.slug, grade: grade)
    def self.for_topic(topic) = new(key: "#{TOPIC_PREFIX}#{topic.slug}", topic: topic)
    def self.for_event(event, grade = nil) = new(key: grade ? "#{event.slug}-#{grade}-klas" : event.slug, event: event, paper_grade: grade)

    def kind
      if grade then "grade"
      elsif topic then "topic"
      else "competition"
      end
    end

    def event_name = event && (event.short.presence || event.name.to_s)

    def name
      if grade then grade.name
      elsif topic then topic.name
      elsif paper_grade then "#{event_name} · #{I18n.t("curriculum.grade_name", number: paper_grade)}"
      else event_name
      end
    end

    # A competition with real papers in the bank asks for the grade first:
    # СМТ runs from 1st grade to 12th, and five problems spread across all of
    # it would be four the visitor's child cannot read.
    def grade_choices
      return [] unless event && paper_grade.nil?

      @grade_choices ||= PastPapers.grades(event.slug).select { |each| Deck.for_event(event, each).enough? }
    end

    def enough? = pool.count >= LENGTH

    def pool
      if grade
        Trial.within_topics(Trial.gradable.where(elo: grade.range), Curriculum.topic_ids(grade))
      elsif topic
        Trial.within_topics(Trial.gradable, [ topic.id ])
      elsif paper_grade
        own = Trial.gradable.where("questions.source ->> 'competition' = ? AND questions.source ->> 'grade' = ?",
                                   event.slug, paper_grade.to_s)
        return own if own.count >= LENGTH

        window = Curriculum.grades.find { |each| each.number == paper_grade }&.range || event.elo_range
        Trial.within_topics(Trial.gradable.where(elo: window), event.topic_ids)
      else
        Trial.within_topics(Trial.gradable.where(elo: event.elo_range), event.topic_ids)
      end
    end

    # What the analytics events carry: all low-cardinality.
    def props = { kind: kind, grade: grade&.number || paper_grade, competition: event&.slug }.compact
  end

  # The visitor's run through one deck, kept in the session as plain JSON-able
  # values.
  class Run
    attr_reader :deck, :ids, :answers

    def self.load(session, deck)
      data = session[:trial]
      return nil unless data.is_a?(Hash) && data["deck"] == deck.key && data["ids"].is_a?(Array)

      new(deck, data["ids"], data["answers"].is_a?(Hash) ? data["answers"] : {})
    end

    def self.start(session, deck)
      run = new(deck, Trial.pick(deck), {})
      run.save(session)
      run
    end

    def initialize(deck, ids, answers)
      @deck = deck
      @ids = ids
      @answers = answers
    end

    def save(session)
      session[:trial] = { "deck" => deck.key, "ids" => ids, "answers" => answers }
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
