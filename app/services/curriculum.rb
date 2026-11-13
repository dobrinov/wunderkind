# The grade ladder — and it exists for exactly one reason, so it is worth being
# blunt about it.
#
# The model has no school grades, on purpose: a first-grader who can do
# third-grade work gets it, and difficulty is the question's Elo, full stop.
# Nothing in here is read by Dispatcher, SessionComposer, Elo, Grading or any
# other part of the answer flow, and nothing here is stored on a user or a
# question. It is presentation only, for the public pages.
#
# But every parent in the country searches in grades — "задачи по математика за
# 3 клас", "НВО 4 клас математика", "упражнения по математика за 2 клас" — and
# a site that refuses to say the word "клас" is a site they never find. So the
# public pages speak grades at the door and the app behind the door still
# speaks Elo. The windows below are editorial, and they overlap on purpose:
# a grade is a range of ability, not a line, which is the same thing the app
# says once a child is inside.
#
# A window alone is not a grade, though: Elo measures how hard a problem is,
# not when school teaches it, and the 1450-1750 window holds logarithms that
# no seventh-grader has met. So each grade also names the topics the МОН
# programme teaches in it (PROGRAMME), and a grade page shows a topic only when
# the programme puts it there *and* the window holds enough of it.
module Curriculum
  Grade = Struct.new(:number, :floor, :ceiling, keyword_init: true) do
    def slug = "#{number}-klas"
    def topic_names = PROGRAMME.fetch(number)
    def name = I18n.t("curriculum.grade_name", number: number)
    def range = floor...ceiling

    # The exam at the end of the grade, if there is one: :nvo or :dzi. Those
    # pages carry the exam in their title because that is the query.
    def exam = EXAMS[number]
    def exam? = exam.present?
  end

  # НВО (национално външно оценяване) after 4th, 7th and 10th grade; ДЗИ
  # (държавен зрелостен изпит, the матура) after 12th. Different exams, so
  # different sections: "НВО подготовка" on the 12th-grade page would be wrong
  # in the one word a parent searched for.
  EXAMS = { 4 => :nvo, 7 => :nvo, 10 => :nvo, 12 => :dzi }.freeze

  # When a child may first be *served* a topic, by the bank's topic names: the
  # first hand-made reading of the МОН programmes, deliberately generous. It is
  # read by Dispatcher's grade hold (a topic more than a year ahead of the
  # child's grade is held back), by TaughtFrom, and by the exams' topic sets
  # (`programme: [5, 7]` in competitions.yml) — so it is about practice, and a
  # topic sits where a child can usefully meet it: counting problems from 4th
  # grade, though school names permutations only in 8th.
  #
  # What the public pages say school teaches in a grade is PROGRAMME, below.
  # The two differ on purpose; change this one only to change what is served.
  TOPICS = {
    1 => [ "Събиране и изваждане", "Числа и редици", "Текстови задачи", "Логически задачи" ],
    2 => [ "Събиране и изваждане", "Умножение и деление", "Числа и редици", "Ред на действията",
           "Текстови задачи", "Логически задачи", "Периметър" ],
    3 => [ "Събиране и изваждане", "Умножение и деление", "Числа и редици", "Ред на действията",
           "Дроби", "Периметър", "Ъгли", "Текстови задачи", "Логически задачи" ],
    4 => [ "Числа и редици", "Събиране и изваждане", "Умножение и деление", "Ред на действията",
           "Дроби", "Периметър", "Площ", "Ъгли", "Движение", "Текстови задачи", "Статистика",
           "Логически задачи", "Броене и комбинаторика" ],
    5 => [ "Числа и редици", "Делимост", "Прости числа", "НОД и НОК", "Остатъци", "Дроби",
           "Десетични числа", "Проценти", "Ъгли", "Периметър", "Площ", "Обем", "Окръжност",
           "Уравнения", "Текстови задачи", "Движение", "Работа", "Статистика", "Логически задачи",
           "Броене и комбинаторика" ],
    6 => [ "Числа и редици", "Степени и корени", "Проценти", "Уравнения", "Текстови задачи",
           "Движение", "Работа", "Окръжност", "Площ", "Обем", "Призма и пирамида", "Ротационни тела",
           "Статистика", "Вероятност", "Броене и комбинаторика", "Логически задачи" ],
    7 => [ "Рационални изрази", "Степени и корени", "Уравнения", "Неравенства", "Ъгли",
           "Еднакви триъгълници", "Площ",
           "Проценти", "Текстови задачи", "Движение", "Работа", "Статистика", "Вероятност",
           "Броене и комбинаторика", "Логически задачи" ],
    8 => [ "Степени и корени", "Квадратни уравнения", "Рационални изрази", "Неравенства",
           "Питагорова теорема", "Окръжност", "Ъгли", "Площ", "Текстови задачи", "Вероятност",
           "Статистика", "Логически задачи" ],
    9 => [ "Системи уравнения", "Линейна функция", "Квадратна функция", "Квадратни уравнения",
           "Неравенства", "Подобни фигури", "Решаване на триъгълник", "Тригонометрични функции",
           "Текстови задачи", "Вероятност", "Статистика" ],
    10 => [ "Аритметична прогресия", "Геометрична прогресия", "Тригонометрични функции",
            "Решаване на триъгълник", "Квадратни уравнения", "Неравенства", "Подобни фигури",
            "Вероятност", "Статистика" ],
    11 => [ "Показателна функция", "Логаритмична функция", "Тригонометрични функции",
            "Призма и пирамида", "Ротационни тела", "Броене и комбинаторика", "Вероятност", "Статистика" ],
    # Trigonometry and solving triangles are taught earlier, but 12th grade is
    # the year of the матура and the ДЗИ asks both — this page is where a
    # student preparing for it looks.
    12 => [ "Производна", "Призма и пирамида", "Ротационни тела", "Показателна функция",
            "Логаритмична функция", "Аритметична прогресия", "Геометрична прогресия", "Вероятност",
            "Статистика", "Тригонометрични функции", "Решаване на триъгълник" ]
  }.freeze

  # What the МОН programme teaches in each grade, by the bank's topic names —
  # read off the учебни програми по математика (общообразователна подготовка)
  # on mon.bg: the 2023 texts for grades 2-10, the 2018 ones for 1, 11 and 12,
  # checked 2026-11-13. A topic is listed in every grade that works on it, not
  # only the one that introduces it.
  #
  # This is the map of the public pages — a grade's page, its topic pages, test
  # and worksheet — and of the formula sheets and the handbook, which have to
  # agree with the textbook on a parent's table. It is not the map of what a
  # child is served: that is TOPICS, above, which this was split from when the
  # check found it generous in places (combinatorics in 4th-7th grade where the
  # programme has it in 8th, Pythagoras in 8th where it is 9th) and the grade
  # hold turned out to depend on exactly that.
  #
  # „Производна" is in no grade: the general programme does not teach it (it
  # is профилирана подготовка), so it has a topic page, an article and
  # formulas, and no grade page. 12th grade also lists what the матура
  # revises — progressions, solids — though they are not new that year.
  PROGRAMME = {
    1 => [ "Събиране и изваждане", "Числа и редици", "Текстови задачи", "Логически задачи" ],
    2 => [ "Събиране и изваждане", "Умножение и деление", "Числа и редици", "Ред на действията",
           "Текстови задачи", "Логически задачи", "Периметър" ],
    3 => [ "Събиране и изваждане", "Умножение и деление", "Числа и редици", "Ред на действията",
           "Дроби", "Периметър", "Ъгли", "Текстови задачи", "Логически задачи" ],
    4 => [ "Числа и редици", "Събиране и изваждане", "Умножение и деление", "Ред на действията",
           "Периметър", "Площ", "Ъгли", "Текстови задачи", "Логически задачи" ],
    5 => [ "Числа и редици", "Делимост", "Прости числа", "НОД и НОК", "Остатъци", "Дроби",
           "Десетични числа", "Проценти", "Периметър", "Площ", "Обем", "Уравнения", "Текстови задачи",
           "Движение", "Работа", "Статистика", "Логически задачи" ],
    6 => [ "Числа и редици", "Степени и корени", "Проценти", "Уравнения", "Текстови задачи",
           "Движение", "Работа", "Окръжност", "Площ", "Обем", "Призма и пирамида", "Ротационни тела",
           "Статистика", "Вероятност", "Логически задачи" ],
    7 => [ "Рационални изрази", "Степени и корени", "Уравнения", "Неравенства", "Ъгли",
           "Еднакви триъгълници", "Площ", "Проценти", "Текстови задачи", "Движение", "Работа",
           "Статистика", "Вероятност", "Логически задачи" ],
    8 => [ "Степени и корени", "Квадратни уравнения", "Рационални изрази", "Броене и комбинаторика",
           "Окръжност", "Ъгли", "Площ", "Текстови задачи", "Логически задачи" ],
    9 => [ "Системи уравнения", "Линейна функция", "Квадратна функция", "Квадратни уравнения",
           "Неравенства", "Питагорова теорема", "Подобни фигури", "Решаване на триъгълник",
           "Тригонометрични функции", "Текстови задачи", "Вероятност" ],
    10 => [ "Аритметична прогресия", "Геометрична прогресия", "Тригонометрични функции",
            "Решаване на триъгълник", "Призма и пирамида", "Ротационни тела", "Проценти", "Статистика" ],
    11 => [ "Показателна функция", "Логаритмична функция", "Тригонометрични функции",
            "Степени и корени", "Решаване на триъгълник", "Вероятност" ],
    12 => [ "Уравнения", "Неравенства", "Призма и пирамида", "Ротационни тела", "Показателна функция",
            "Логаритмична функция", "Аритметична прогресия", "Геометрична прогресия", "Вероятност",
            "Статистика", "Тригонометрични функции", "Решаване на триъгълник" ]
  }.freeze

  GRADES = [
    Grade.new(number: 1, floor: 600,  ceiling: 900),
    Grade.new(number: 2, floor: 700,  ceiling: 1000),
    Grade.new(number: 3, floor: 850,  ceiling: 1150),
    Grade.new(number: 4, floor: 1000, ceiling: 1300),
    Grade.new(number: 5, floor: 1150, ceiling: 1450),
    Grade.new(number: 6, floor: 1300, ceiling: 1600),
    Grade.new(number: 7, floor: 1450, ceiling: 1750),
    # From 8th grade on the windows widen and overlap more: the bank rates an
    # 11th-grade logarithm by how hard it is, not by when school teaches it,
    # and a routine one sits below a hard 8th-grade quadratic. TOPICS is what
    # keeps each page to its own grade's programme.
    Grade.new(number: 8, floor: 1450, ceiling: 1900),
    Grade.new(number: 9, floor: 1500, ceiling: 2000),
    Grade.new(number: 10, floor: 1550, ceiling: 2100),
    Grade.new(number: 11, floor: 1550, ceiling: 2200),
    Grade.new(number: 12, floor: 1600, ceiling: 2400)
  ].freeze

  # A topic needs this many published questions inside the window before it is
  # worth a line on a grade page: three problems is not a topic a child can
  # practise, and a page listing it would be promising something thin.
  MINIMUM_PER_TOPIC = 25

  # How many worked problems a public page shows. Enough that the page is worth
  # landing on and Google can see it is not a doorway, few enough that the bank
  # is not republished as a free worksheet site.
  SAMPLE_SIZE = 6

  module_function

  def grades = GRADES

  def grade(slug)
    GRADES.find { |candidate| candidate.slug == slug.to_s }
  end

  def find_topic(slug)
    Topic.where.not(parent_id: nil).find_by(slug: slug)
  end

  # Topics worth practising at this grade, commonest first: the programme's
  # topics for the grade, kept only where the bank has enough of them inside
  # the window — so the page can promise neither a topic school has not reached
  # nor one with no problems behind it.
  def topics_for(grade)
    counts = Question.published
                     .where(elo: grade.range)
                     .joins(:topics)
                     .where(topics: { id: topic_ids(grade) })
                     .group("topics.id")
                     .count

    Topic.where(id: counts.select { |_, count| count >= MINIMUM_PER_TOPIC }.keys)
         .sort_by { |topic| -counts.fetch(topic.id, 0) }
         .map { |topic| [ topic, counts.fetch(topic.id, 0) ] }
  end

  def question_count(grade)
    Question.published.where(elo: grade.range).joins(:topics).where(topics: { id: topic_ids(grade) }).distinct.count
  end

  def topic_ids(grade)
    Topic.where.not(parent_id: nil).where(name: grade.topic_names).ids
  end

  # The worked examples on a page.
  #
  # Deterministic, not sampled at random: a page that shows different problems
  # on every fetch teaches a crawler it is not worth caching, and a parent who
  # shares a link should land on what they saw.
  #
  # Taken at evenly spaced points across the Elo window rather than off the
  # front of it, because the page claims the problems run from easy to hard —
  # and the first six of a six-thousand-problem range are all the easiest
  # problem in different numbers. Each sample is from a topic the page has not
  # shown yet where its slice of the window has one (`other_topic`). A couple
  # of small indexed queries per sample.
  #
  # Multiple-choice and exact-value only: an interactive question's answer is a
  # widget state, which has no reading as a line of text and no way to be shown
  # on a page with no widget on it.
  #
  # `within_topics` narrows to a set of topic ids — a competition's, which is
  # neither one topic nor a grade's programme.
  #
  # `exclude` leaves out problems another page already shows: a grade's test
  # should not be the grade page's samples over again.
  def sample_questions(elo_range:, topic: nil, grade: nil, within_topics: nil, limit: SAMPLE_SIZE, exclude: nil)
    scope = showable(topic)
    scope = scope.where.not(id: exclude) if exclude.present?
    within_topics ||= topic_ids(grade) if grade
    scope = scope.where(id: Question.joins(:topics).where(topics: { id: within_topics }).select(:id)) if within_topics
    floor, ceiling = window(scope, elo_range)
    return [] if floor.nil?

    step = (ceiling - floor).fdiv(limit)
    used_topics = []

    (0...limit).filter_map do |index|
      low = (floor + step * index).round
      sample = other_topic(scope.where(elo: low...(floor + step * (index + 1)).round), used_topics) ||
               scope.where(elo: low..).order(:elo, :id).first
      used_topics.concat(sample.topic_ids) if sample
      sample
    end.uniq
  end

  # The easiest problem in a slice from a topic the page has not shown yet, so
  # six samples on a grade page are six kinds of problem rather than three
  # pairs. Nil when the slice has none — always, on a topic's own page — and
  # the caller takes the slice's easiest problem as before.
  def other_topic(slice, used_topics)
    slice = slice.where.not(id: Question.joins(:topics).where(topics: { id: used_topics }).select(:id)) if used_topics.any?
    slice.order(:elo, :id).first
  end

  def showable(topic)
    scope = Question.published
                    .where(answer_type: [ :multiple_choice, :exact_value ])
                    .where.not(explanation: [ nil, "" ])
                    .includes(:possible_answers, :topics)

    topic ? scope.joins(:topics).where(topics: { id: topic.id }) : scope
  end

  # The span actually occupied inside the asked-for range — a topic that stops
  # at 1360 should not have its samples spread to 1750 and come back with the
  # same problem six times.
  def window(scope, elo_range)
    # Two aggregates rather than one `pick`: `pick` is `limit(1).pluck`, and a
    # LIMIT 1 around MIN/MAX aggregates a single row — it returned [1000, 1000]
    # for a range holding three thousand problems.
    bounded = scope.where(elo: elo_range)
    [ bounded.minimum(:elo), bounded.maximum(:elo) ]
  end

  # Whether a topic has a page of its own in a grade (/matematika/5-klas/drobi):
  # the programme teaches it there and the window holds enough of it — the same
  # two conditions as a line on the grade page (topics_for).
  def grade_topic?(grade, topic)
    grade.topic_names.include?(topic.name) && grade_topic_count(grade, topic) >= MINIMUM_PER_TOPIC
  end

  def grade_topic_count(grade, topic)
    topic.questions.published.where(elo: grade.range).count
  end

  # The problems of a grade's test: TEST_LENGTH of them, spread across the
  # window like the page's samples and none of them one of those samples.
  TEST_LENGTH = 10

  # The problems of a worksheet (WorksheetsController): WORKSHEET_LENGTH of a
  # grade's, or of one topic's in the grade, spread over the window like every
  # other page's and none of them one the grade page, the topic's page in the
  # grade or the test already shows. Fewer than WORKSHEET_MINIMUM is not a
  # sheet worth printing, and the page does not exist.
  #
  # A sheet has variants („Друг лист", `?list=2`): a parent who printed the
  # sheet last week wants another, not the same twelve. Each variant is as
  # deterministic as the first — the key on its second page has to be the key
  # to the problems on its first, on every load — and is set from what the
  # variants before it left, so no problem is on two sheets. Up to
  # WORKSHEET_VARIANTS, fewer where the bank runs out.
  WORKSHEET_LENGTH = 12
  WORKSHEET_MINIMUM = 6
  WORKSHEET_VARIANTS = 5

  def worksheet_questions(grade, topic: nil, variant: 1)
    worksheet_sheets(grade, topic: topic).take(variant)[variant - 1] || []
  end

  # The sheets in order, lazily: the third is not set to show the first.
  def worksheet_sheets(grade, topic: nil)
    Enumerator.new do |sheets|
      shown = sample_questions(elo_range: grade.range, topic: topic, grade: (grade unless topic)).map(&:id)
      shown += test_questions(grade).map(&:id) unless topic

      WORKSHEET_VARIANTS.times do
        sheet = sample_questions(elo_range: grade.range, topic: topic, grade: (grade unless topic),
                                 limit: WORKSHEET_LENGTH, exclude: shown)
        break if sheet.size < WORKSHEET_MINIMUM

        sheets << sheet
        shown += sheet.map(&:id)
      end
    end
  end

  # How many variants a sheet has, for „Друг лист". Cached, like `worksheet?`.
  def worksheet_variants(grade, topic: nil)
    Rails.cache.fetch("curriculum/grade/#{grade.slug}/worksheets/#{topic&.slug}", expires_in: 12.hours) do
      worksheet_sheets(grade, topic: topic).count
    end
  end

  # Whether there is a worksheet to link to. Cached, like `test?`.
  def worksheet?(grade, topic: nil)
    Rails.cache.fetch("curriculum/grade/#{grade.slug}/worksheet/#{topic&.slug}", expires_in: 12.hours) do
      worksheet_questions(grade, topic: topic).any?
    end
  end

  # Whether a grade has a test to link to: on a thin bank a grade may have
  # nothing to set, and its test page is a 404 the hub, the grade's strip and
  # the sitemap must not point at. Cached, since all three ask it of every
  # grade on one page.
  def test?(grade)
    Rails.cache.fetch("curriculum/grade/#{grade.slug}/test", expires_in: 12.hours) { test_questions(grade).any? }
  end

  def test_questions(grade)
    shown = sample_questions(elo_range: grade.range, grade: grade).map(&:id)
    sample_questions(elo_range: grade.range, grade: grade, limit: TEST_LENGTH, exclude: shown)
  end

  # The grades a topic is worth showing on, for the cross-links between pages:
  # the ones whose programme teaches it and whose window holds some of it.
  def grades_for(topic)
    published = topic.questions.published
    low, high = published.minimum(:elo), published.maximum(:elo)
    return [] if low.blank?

    GRADES.select { |grade| grade.topic_names.include?(topic.name) && grade.floor < high && grade.ceiling > low }
  end
end
