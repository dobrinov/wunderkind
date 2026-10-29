# Задачи за 1. клас: текстови задачи и логически задачи под 900.
#
# The bank had sums at 600 and almost nothing in words until 830, so a child
# at the bottom met the same bare a + b for weeks and the 1st-grade page had
# no word problems or puzzles to show. These are the short story problems and
# first puzzles of the 1st- and 2nd-grade programmes: numbers to 10, then to
# 20, then round tens and numbers to 100. Every answer is a number or one of
# the listed options, so the public pages can show them with their answers.

module EarlyWords
  module_function

  # The number band of each rung: to 10, to 10, to 20, to 20, round tens, to 100.
  def band(c) = c.by_level([ 10, 10, 20, 20, 100, 100 ])

  # A number up to the rung's band; at the round-tens rung, a multiple of ten.
  def number(c, range)
    raise Authoring::Duplicate if range.none?
    return c.int(range) unless c.level == 4

    tens = ((range.min + 9) / 10)..(range.max / 10)
    raise Authoring::Duplicate if tens.none?

    c.int(tens) * 10
  end

  # Ordinals as written with digits: 4-ти, 4-та, 4-то (място).
  def ordinal(number, gender)
    forms = { masculine: %w[ви ри ми ти], feminine: %w[ва ра ма та], neuter: %w[во ро мо то] }.fetch(gender)
    suffix =
      if (11..19).cover?(number % 100) then forms[3]
      else
        case number % 10
        when 1 then forms[0]
        when 2 then forms[1]
        when 7, 8 then forms[2]
        else forms[3]
        end
      end
    "#{number}-#{suffix}"
  end

  # Things that come in colours, for "five are red, the rest are blue".
  COLOURED = [
    Props::Item.new("топка", "топки"), Props::Item.new("балон", "балона"),
    Props::Item.new("молив", "молива"), Props::Item.new("кубче", "кубчета"),
    Props::Item.new("значка", "значки"), Props::Item.new("картичка", "картички")
  ].freeze

  COLOURS = [ %w[червени сини], %w[жълти зелени], %w[бели черни], %w[сини зелени] ].freeze

  SHAPES = %w[кръг квадрат триъгълник звезда сърце].freeze
end

# ------------------------------------------------------------ Текстови задачи ---

Authoring.family "word.early_more_less", topic: "Текстови задачи", area: "early_words",
                 rungs: [ 620, 680, 740, 800, 860, 920 ] do |c|
  limit = EarlyWords.band(c)
  more = c.coin
  first, second = c.people(2)
  item = c.thing

  if more
    have = EarlyWords.number(c, 1..(limit - 1))
    diff = EarlyWords.number(c, 1..(limit - have))
    answer = have + diff
  else
    have = EarlyWords.number(c, 2..limit)
    diff = EarlyWords.number(c, 1..(have - 1))
    answer = have - diff
  end
  raise Authoring::Duplicate if diff.zero? || answer <= 0 || answer > limit

  word = more ? "повече" : "по-малко"
  sign = more ? "+" : "−"

  c.q(
    text: "#{first} има #{item.count(have)}. #{second} има с #{diff} #{word} от #{c.agree(first, 'него', 'нея')}. " \
          "Колко #{item.many} има #{second}?",
    answer: Num.ans(answer),
    explanation: Explain.build(
      idea: more ? "„С #{diff} повече“ значи, че към това, което има #{first}, прибавяме #{diff}." : "„С #{diff} по-малко“ значи, че от това, което има #{first}, изваждаме #{diff}.",
      steps: [
        "#{first} има #{have}.",
        "#{second} има с #{diff} #{word}: #{have} #{sign} #{diff} = #{answer}."
      ],
      answer: item.count(answer),
      check: more ? "#{answer} − #{have} = #{diff} — наистина с #{diff} повече." : "#{have} − #{answer} = #{diff} — наистина с #{diff} по-малко.",
      watch: more ? "„Повече“ значи събиране — #{second} има повече от #{first}, не по-малко." : "„По-малко“ значи изваждане — #{second} има по-малко от #{first}, не повече."
    )
  )
end

Authoring.family "word.early_compare", topic: "Текстови задачи", area: "early_words",
                 rungs: [ 660, 720, 780, 840, 900, 960 ] do |c|
  limit = EarlyWords.band(c)
  # Past the first two rungs the bigger number leaves the first ten, or 3 − 2 sits on a 20s rung.
  bigger = EarlyWords.number(c, c.by_level([ 3, 3, 11, 11, 20, 20 ])..limit)
  smaller = EarlyWords.number(c, 1..(bigger - 1))
  diff = bigger - smaller
  raise Authoring::Duplicate if diff.zero? || smaller.zero?

  first, second = c.people(2)
  item = c.thing
  ask_more = c.coin

  question =
    if ask_more
      "С колко #{item.many} повече има #{first} от #{second}?"
    else
      "С колко #{item.many} по-малко има #{second} от #{first}?"
    end

  c.q(
    text: "#{first} има #{item.count(bigger)}, а #{second} има #{item.count(smaller)}. #{question}",
    answer: Num.ans(diff),
    explanation: Explain.build(
      idea: "„С колко повече“ и „с колко по-малко“ питат за разликата: от по-голямото число изваждаме по-малкото.",
      steps: [
        "По-голямото число е #{bigger} (на #{first}), по-малкото е #{smaller} (на #{second}).",
        "#{bigger} − #{smaller} = #{diff}."
      ],
      answer: item.count(diff),
      check: "#{smaller} + #{diff} = #{bigger}.",
      watch: "Не събираме двете числа: #{bigger} + #{smaller} = #{bigger + smaller} е колко имат заедно, а не с колко се различават."
    ),
    hints: [ "Раздели ги по двойки: по един предмет на #{first} срещу един на #{second}. Колко на #{first} остават без двойка?" ]
  )
end

Authoring.family "word.early_two_steps", topic: "Текстови задачи", area: "early_words",
                 rungs: [ 700, 760, 820, 880, 940, 1000 ] do |c|
  limit = EarlyWords.band(c)
  start = EarlyWords.number(c, 3..limit)
  given = EarlyWords.number(c, 1..(start - 1))
  middle = start - given
  received = EarlyWords.number(c, 1..(limit - middle))
  answer = middle + received
  raise Authoring::Duplicate if given.zero? || received.zero? || given == received || answer > limit

  who, friend = c.people(2)
  item = c.thing

  c.q(
    text: "#{who} имаше #{item.count(start)}. Даде #{given} на #{friend}, а после получи още #{received} от баба си. " \
          "Колко #{item.many} има #{who} сега?",
    answer: Num.ans(answer),
    explanation: Explain.build(
      idea: "Вървим по реда на случилото се: първо дава (изваждаме), после получава (прибавяме).",
      steps: [
        "След като даде: #{start} − #{given} = #{middle}.",
        "След като получи: #{middle} + #{received} = #{answer}."
      ],
      answer: item.count(answer),
      check: "#{start} − #{given} + #{received} = #{answer}.",
      watch: "Даденото се изважда, а полученото се прибавя — двете числа не се събират заедно."
    ),
    hints: [ "Първо намери колко #{item.many} остават, след като даде на #{friend}." ]
  )
end

Authoring.family "word.early_missing_part", topic: "Текстови задачи", area: "early_words",
                 rungs: [ 640, 700, 760, 820, 880, 940 ] do |c|
  limit = EarlyWords.band(c)
  total = EarlyWords.number(c, 3..limit)
  part = EarlyWords.number(c, 1..(total - 1))
  rest = total - part
  # "1 от тях са червени" does not agree; one is not a part worth asking about.
  raise Authoring::Duplicate if part < 2 || rest.zero?

  item = c.pick(EarlyWords::COLOURED)
  known, asked = c.pick(EarlyWords::COLOURS)
  who = c.person

  c.q(
    text: "#{who} има #{item.count(total)}. #{part} от тях са #{known}, а останалите са #{asked}. " \
          "Колко са #{asked}те #{item.many}?",
    answer: Num.ans(rest),
    explanation: Explain.build(
      idea: "Всички #{item.many} са две части — #{known} и #{asked}. Знаем цялото и едната част, затова изваждаме.",
      steps: [
        "Всички са #{total}, #{known}те са #{part}.",
        "#{total} − #{part} = #{rest}."
      ],
      answer: "#{rest} #{asked}",
      check: "#{part} #{known} + #{rest} #{asked} = #{total}.",
      watch: "Не събираме #{total} и #{part}: #{part} вече са сред всичките #{total}."
    )
  )
end

# ------------------------------------------------------------ Логически задачи ---

Authoring.family "logic.early_pattern", topic: "Логически задачи", area: "early_words",
                 rungs: [ 620, 690, 760, 830, 900, 970 ] do |c|
  # The repeating unit as indexes into the chosen shapes: AB, ABC, AAB, ABB, ABC, AABC.
  unit_shape = c.by_level([ [ 0, 1 ], [ 0, 1, 2 ], [ 0, 0, 1 ], [ 0, 1, 1 ], [ 0, 1, 2 ], [ 0, 0, 1, 2 ] ])
  shapes = c.sample(EarlyWords::SHAPES, unit_shape.max + 1)
  unit = unit_shape.map { |index| shapes[index] }
  shown = Array.new((2 * unit.size) + c.int(0..1)) { |i| unit[i % unit.size] }

  # The low rungs ask for the next figure; the high ones for a place further on.
  position = c.level <= 2 ? shown.size + 1 : shown.size + c.int(3..(4 + (2 * c.level)))
  answer = unit[(position - 1) % unit.size]
  extra = (EarlyWords::SHAPES - shapes).first
  # "…, триъгълник, ... Коя фигура е следващата?" was reported as misleading: after
  # an ellipsis "the next one" has nothing to follow. The ellipsis stays only where
  # the question names a place further on, which is what it means there.
  text =
    if position == shown.size + 1
      "Фигурите се повтарят в този ред: #{shown.join(', ')}. Коя фигура идва веднага след тях?"
    else
      "Фигурите се повтарят в този ред: #{shown.join(', ')}, ... Коя фигура ще е на #{EarlyWords.ordinal(position, :neuter)} място?"
    end

  c.q(
    text: text,
    figure: Figures.shape_pattern(shown: shown, target: position),
    options: c.options(answer, shapes - [ answer ], extra),
    answer: answer,
    explanation: Explain.build(
      idea: "Намираме групата, която се повтаря, и броим по групи.",
      steps: [
        "Повтаря се групата „#{unit.join(', ')}“ — #{count_noun(unit.size, 'фигура', 'фигури')}.",
        if position == shown.size + 1
          "Показани са #{shown.size} фигури; #{EarlyWords.ordinal(position, :feminine)} фигура е #{EarlyWords.ordinal(((position - 1) % unit.size) + 1, :feminine)} в своята група."
        else
          "Групите свършват на #{unit.size}, #{2 * unit.size}, #{3 * unit.size}, ... място. " \
            "#{EarlyWords.ordinal(position, :neuter).capitalize} място е #{EarlyWords.ordinal(((position - 1) % unit.size) + 1, :neuter)} в своята група."
        end,
        "#{EarlyWords.ordinal(((position - 1) % unit.size) + 1, :feminine).capitalize} фигура в групата е #{answer}."
      ],
      answer: answer,
      check: "Изпиши редицата до #{EarlyWords.ordinal(position, :neuter)} място: #{Array.new(position) { |i| unit[i % unit.size] }.join(', ')}.",
      watch: if unit.size == 2
               "Броим местата по двойки: на всяко нечетно място е #{unit[0]}, на всяко четно — #{unit[1]}."
             else
               "Групата е от #{unit.size} фигури, не просто редуване на две — броим по цели групи."
             end
    ),
    hints: [ "Кои фигури се повтарят заедно, като група? Огради всяка група с пръст." ]
  )
end

Authoring.family "logic.early_order", topic: "Логически задачи", area: "early_words",
                 rungs: [ 650, 720, 790, 860, 930, 1000 ] do |c|
  size = c.by_level([ 3, 3, 3, 4, 4, 5 ])
  # Tallest first.
  order = c.people(size)
  pairs = order.each_cons(2).to_a
  statements = pairs.map do |taller, shorter|
    if c.level.zero? || c.coin
      "#{taller} е #{c.agree(taller, 'по-висок', 'по-висока')} от #{shorter}."
    else
      "#{shorter} е #{c.agree(shorter, 'по-нисък', 'по-ниска')} от #{taller}."
    end
  end
  statements = statements.shuffle(random: c.rng) if c.level >= 2

  ask = c.by_level([ :tallest, :shortest, :either, :either, :second, :second ])
  ask = c.coin ? :tallest : :shortest if ask == :either
  answer, question =
    case ask
    when :tallest then [ order.first, "Кое дете е най-високо?" ]
    when :shortest then [ order.last, "Кое дете е най-ниско?" ]
    else [ order[1], "Кое дете е второ по височина?" ]
    end

  c.q(
    text: "#{statements.join(' ')} #{question}",
    options: c.options(answer, order - [ answer ]),
    answer: answer,
    explanation: Explain.build(
      idea: "Нареждаме децата от най-високото до най-ниското, като слагаме всяко сравнение на мястото му.",
      steps: pairs.map { |taller, shorter| "По височина #{taller} е преди #{shorter}." } +
             [ "Редът е: #{order.join(', ')}." ],
      answer: answer,
      check: "Всяко изречение от условието отговаря на реда #{order.join(' > ')}.",
      watch: "„#{pairs.first.last} е #{c.agree(pairs.first.last, 'по-нисък', 'по-ниска')} от #{pairs.first.first}“ казва същото като " \
             "„#{pairs.first.first} е #{c.agree(pairs.first.first, 'по-висок', 'по-висока')} от #{pairs.first.last}“ — „по-нисък“ обръща реда."
    ),
    hints: [ "Подреди имената едно под друго: най-високото дете горе, най-ниското долу." ]
  )
end

Authoring.family "logic.early_queue", topic: "Логически задачи", area: "early_words",
                 rungs: [ 700, 770, 840, 910, 980, 1050 ] do |c|
  kind = c.by_level([ :places, :places, :around, :around, :between, :between ])
  limit = c.by_level([ 6, 9, 9, 15, 15, 25 ])
  who, other = c.people(2)
  gender = c.female?(who) ? :feminine : :masculine

  case kind
  when :places
    front = c.int(2..limit)
    back = c.int(2..limit)
    answer = front + back - 1
    text = "Деца стоят в редица. #{who} е #{EarlyWords.ordinal(front, gender)} отпред и " \
           "#{EarlyWords.ordinal(back, gender)} отзад. Колко деца има в редицата?"
    steps = [
      "Отпред до #{who} включително има #{front} деца.",
      "Зад #{c.agree(who, 'него', 'нея')} остават #{back} − 1 = #{back - 1}, защото #{who} е #{c.agree(who, 'преброен', 'преброена')} и отзад.",
      "#{front} + #{back - 1} = #{answer}."
    ]
    check = "Нарисувай #{answer} кръгчета: #{who} е #{EarlyWords.ordinal(front, :neuter)} кръгче отляво и #{EarlyWords.ordinal(back, :neuter)} отдясно."
    watch = "#{front} + #{back} = #{front + back} брои #{who} два пъти."
  when :around
    before = c.int(1..limit)
    after = c.int(1..limit)
    answer = before + after + 1
    text = "Деца стоят в редица. Пред #{who} има #{count_noun(before, 'дете', 'деца')}, а зад #{c.agree(who, 'него', 'нея')} — " \
           "#{count_noun(after, 'дете', 'деца')}. Колко деца има в редицата?"
    steps = [
      "Децата пред и зад #{who}: #{before} + #{after} = #{before + after}.",
      "Добавяме и #{c.agree(who, 'самия', 'самата')} #{who}: #{before + after} + 1 = #{answer}."
    ]
    check = "#{before} отпред, #{who}, #{after} отзад — общо #{answer}."
    watch = "#{before} + #{after} = #{before + after} са само другите деца — #{who} също стои в редицата."
  else
    front = c.int(1..limit)
    back = c.int(1..limit)
    between = c.int(1..limit)
    answer = front + between + back
    text = "Деца стоят в редица. #{who} стои пред #{other} и е #{EarlyWords.ordinal(front, gender)} отпред. " \
           "#{other} е #{EarlyWords.ordinal(back, c.female?(other) ? :feminine : :masculine)} отзад. " \
           "Между #{who} и #{other} стоят #{count_noun(between, 'дете', 'деца')}. Колко деца има в редицата?"
    raise Authoring::Duplicate if between == 1 # "стоят 1 дете" — keep the plural verb honest

    steps = [
      "От началото до #{who} включително: #{front}.",
      "Между тях: #{between}.",
      "От #{other} включително до края: #{back}.",
      "#{front} + #{between} + #{back} = #{answer}."
    ]
    check = "Нарисувай кръгчетата: #{front}, после #{between}, после #{back} — общо #{answer}."
    watch = "#{who} и #{other} са преброени по веднъж — в първата и в третата група."
  end

  c.q(
    text: text,
    answer: Num.ans(answer),
    explanation: Explain.build(
      idea: "Рисуваме редицата с кръгчета и внимаваме никое дете да не е преброено два пъти или пропуснато.",
      steps: steps,
      answer: count_noun(answer, "дете", "деца"),
      check: check,
      watch: watch
    ),
    hints: [ "Нарисувай децата като кръгчета в редица и отбележи #{who}." ]
  )
end
