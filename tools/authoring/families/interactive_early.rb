# Интерактивни задачи за най-малките: броене, числата до 100, часовник,
# сравняване. Рейтингите тук започват от 600 — под тях няма смисъл, защото
# това е долният край, от който стартира всеки нов ученик.

EARLY = [ 600, 660, 720, 790, 860, 930 ].freeze

Authoring.family "early.count_cells", topic: "Събиране и изваждане", area: "interactive_early", variants: 11,
                 rungs: EARLY do |c|
  count = c.int(c.by_level([ 2..8, 3..12, 4..18, 6..24, 8..30, 10..40 ]))
  cols = c.pick([ 5, 6, 8, 10 ])
  rows = [ (count / cols) + 2, 8 ].min
  raise Authoring::Duplicate if count >= rows * cols

  c.q(
    text: "Оцвети точно #{count} квадратчета в мрежата.",
    widget: WidgetKit.grid_shade(rows: rows, cols: cols, count: count),
    explanation: Explain.build(
      idea: "Броим квадратчетата едно по едно или на групи по #{cols} — по цял ред наведнъж.",
      steps: [
        "Един пълен ред е #{cols} квадратчета.",
        "#{count} = #{count / cols} пълни реда и още #{count % cols}."
      ],
      answer: "#{count} квадратчета",
      check: "Броенето по редове дава същия отговор като броенето едно по едно.",
      watch: "Броят е важен, не формата — квадратчетата може да са където и да е."
    )
  )
end

Authoring.family "early.pick_even", topic: "Числа и редици", area: "interactive_early", variants: 11,
                 rungs: EARLY do |c|
  band = c.by_level([ 1..12, 1..20, 5..40, 10..60, 15..100, 20..200 ])
  evens = c.sample(band.select(&:even?), 2)
  odds = c.sample(band.select(&:odd?), 3)
  raise Authoring::Duplicate if evens.size < 2 || odds.size < 3

  options = (evens + odds).sort.map { |n| [ n.to_s, n.even? ] }
  ask_even = c.coin
  options = options.map { |label, even| [ label, ask_even ? even : !even ] }

  c.q(
    text: "Избери всички #{ask_even ? 'четни' : 'нечетни'} числа сред #{options.map(&:first).join(', ')}.",
    widget: WidgetKit.multi_select(options),
    explanation: Explain.build(
      idea: "Четните числа завършват на 0, 2, 4, 6 или 8; нечетните — на 1, 3, 5, 7 или 9.",
      steps: [
        "Четни: #{evens.sort.join(', ')}.",
        "Нечетни: #{odds.sort.join(', ')}."
      ],
      answer: options.select(&:last).map(&:first).join(", "),
      check: "Четните числа се делят на 2 без остатък.",
      watch: "Гледа се само последната цифра, а не колко голямо е числото."
    )
  )
end

Authoring.family "early.blank_add_sub", topic: "Събиране и изваждане", area: "interactive_early", variants: 11,
                 rungs: EARLY do |c|
  spec = c.by_level([ 2..10, 3..20, 5..40, 8..60, 10..100, 15..200 ])
  a = c.int(spec)
  b = c.int(1..a)

  c.q(
    text: "Попълни сбора и разликата на числата #{a} и #{b}.",
    widget: WidgetKit.blanks([ [ "sum", "сбор", a + b ], [ "diff", "разлика", a - b ] ]),
    explanation: Explain.build(
      idea: "Сборът събира двете числа, разликата показва с колко едното е по-голямо.",
      steps: [
        "#{a} + #{b} = #{a + b}.",
        "#{a} − #{b} = #{a - b}."
      ],
      answer: "#{a + b} и #{a - b}",
      check: "Сборът минус разликата е #{(a + b) - (a - b)} = 2 · #{b}.",
      watch: "Разликата се смята от по-голямото към по-малкото число."
    )
  )
end

Authoring.family "early.hundred_chart", topic: "Числа и редици", area: "interactive_early", variants: 11,
                 rungs: EARLY do |c|
  start = c.int(c.by_level([ 1..3, 1..5, 1..8, 2..12, 3..20, 5..40 ])) * 10
  row = (start..(start + 9)).to_a
  blanks = c.sample((0..9).to_a, c.by_level([ 2, 3, 3, 4, 4, 5 ]))
  rows = [ row.each_with_index.map { |value, i| blanks.include?(i) ? nil : value } ]

  c.q(
    text: "Попълни липсващите числа в реда от таблицата със стотица: числата от #{start} до #{start + 9}.",
    widget: WidgetKit.grid_fill(rows: rows, answers: [ row ]),
    explanation: Explain.build(
      idea: "В реда всяко следващо число е с 1 по-голямо от предишното.",
      steps: [
        "Редът започва с #{start} и завършва с #{start + 9}.",
        blanks.sort.map { |i| "На мястото след #{row[i] - 1} стои #{row[i]}." }.first(3).join(" ")
      ],
      answer: blanks.sort.map { |i| row[i] }.join(", "),
      check: "Всички числа в реда имат еднаква цифра на десетиците — #{start / 10}.",
      watch: "След число, което завършва на 9, идва нова десетица."
    )
  )
end

Authoring.family "early.clock_oclock", topic: "Събиране и изваждане", area: "interactive_early", variants: 11,
                 rungs: EARLY do |c|
  hour = c.int(1..12)
  minute = c.pick(c.by_level([ [ 0 ], [ 0, 30 ], [ 0, 30 ], [ 0, 15, 30, 45 ], [ 0, 15, 30, 45 ], [ 0, 10, 20, 30, 40, 50 ] ]))

  c.q(
    text: "Нагласи часовника на #{hour}:#{format('%02d', minute)} " \
          "(#{minute.zero? ? "#{count_noun(hour, 'час', 'часа')} точно" : minute == 30 ? "#{hour} и половина" : "#{count_noun(hour, 'час', 'часа')} и #{minute} минути"}).",
    widget: WidgetKit.clock(hours: hour, minutes: minute),
    explanation: Explain.build(
      idea: "Малката стрелка показва часа, голямата — минутите.",
      steps: [
        "Часът е #{hour}: малката стрелка сочи натам.",
        minute.zero? ? "Точен час: голямата стрелка сочи 12." : "#{minute} минути: голямата стрелка е на #{count_noun(minute / 5, 'деление', 'деления')} след 12."
      ],
      answer: "#{hour}:#{format('%02d', minute)}",
      check: "Пълна обиколка на голямата стрелка е един час.",
      watch: "Голямата стрелка на 6 значи „и половина“, а не 6 часа."
    )
  )
end

Authoring.family "early.compare_bins", topic: "Числа и редици", area: "interactive_early", variants: 11,
                 rungs: EARLY do |c|
  pivot = c.int(c.by_level([ 5..10, 8..20, 10..40, 20..60, 30..100, 50..200 ]))
  values = []
  12.times do
    value = c.int([ 1, pivot - 12 ].max..(pivot + 12))
    values << value if value != pivot && !values.include?(value)
  end
  values = values.first(5)
  raise Authoring::Duplicate if values.count { |v| v < pivot } < 2 || values.count { |v| v > pivot } < 2

  items = values.sort.each_with_index.map { |value, i| [ "n#{i}", value.to_s, value < pivot ? "less" : "more" ] }

  c.q(
    text: "Разпредели числата #{values.sort.join(', ')} според това дали са по-малки или по-големи от #{pivot}.",
    widget: WidgetKit.categorize(bins: [ [ "less", "по-малки" ], [ "more", "по-големи" ] ], items: items),
    explanation: Explain.build(
      idea: "Сравняваме всяко число с #{pivot} — по числовата ос по-малките стоят вляво.",
      steps: [
        "По-малки: #{values.select { |v| v < pivot }.sort.join(', ')}.",
        "По-големи: #{values.select { |v| v > pivot }.sort.join(', ')}."
      ],
      answer: "по-малки: #{values.select { |v| v < pivot }.sort.join(', ')}",
      check: "Числата, по-големи от #{pivot}, са с поне 1 повече от него.",
      watch: "Числото #{pivot} не е нито по-малко, нито по-голямо от себе си — то не е в списъка."
    )
  )
end

Authoring.family "early.match_ten_pairs", topic: "Събиране и изваждане", area: "interactive_early", variants: 11,
                 rungs: EARLY do |c|
  target = c.pick(c.by_level([ [ 10 ], [ 10, 20 ], [ 10, 20 ], [ 20, 50 ], [ 50, 100 ], [ 100, 200 ] ]))
  parts = c.sample((1...target).select { |n| (n % (target / 10)).zero? }, 3)
  raise Authoring::Duplicate if parts.size < 3 || parts.uniq.size < 3

  pairs = parts.map { |part| [ part.to_s, (target - part).to_s ] }
  raise Authoring::Duplicate if pairs.flatten.uniq.size < 6

  c.q(
    text: "Свържи всяко число (#{parts.join(', ')}) с числото, което го допълва до #{target}.",
    widget: WidgetKit.matcher(pairs),
    explanation: Explain.build(
      idea: "Двете числа заедно трябва да дават #{target} — това са „приятелските двойки“ на #{target}.",
      steps: pairs.map { |first, second| "#{first} + #{second} = #{target}" },
      answer: pairs.map { |first, second| "#{first} и #{second}" }.join(", "),
      check: "Всяка двойка се проверява със събиране.",
      watch: "Ако сборът излезе повече от #{target}, двойката е сгрешена."
    )
  )
end

Authoring.family "early.line_neighbours", topic: "Числа и редици", area: "interactive_early", variants: 6,
                 rungs: EARLY do |c|
  max = c.by_level([ 10, 20, 20, 50, 100, 100 ])
  step = max > 20 ? (max / 20) : 1
  value = c.int(1..((max / step) - 1)) * step
  before = value - step
  after = value + step

  c.q(
    text: "Попълни числото преди и числото след #{value} (стъпката е #{step}).",
    widget: WidgetKit.blanks([ [ "before", "преди", before ], [ "after", "след", after ] ]),
    explanation: Explain.build(
      idea: "Съседните числа се получават с изваждане и събиране на стъпката.",
      steps: [
        "#{value} − #{step} = #{before}.",
        "#{value} + #{step} = #{after}."
      ],
      answer: "#{before} и #{after}",
      check: "Трите числа са на равни разстояния: #{before}, #{value}, #{after}.",
      watch: "Преди значи по-малко, след значи повече."
    )
  )
end

Authoring.family "early.shade_half", topic: "Дроби", area: "interactive_early", variants: 4,
                 rungs: EARLY do |c|
  cols = c.pick([ 4, 6, 8, 10 ])
  rows = c.pick([ 2, 4 ])
  total = rows * cols
  part = c.pick(c.by_level([ [ 2 ], [ 2 ], [ 2, 4 ], [ 2, 4 ], [ 2, 4, 5 ], [ 2, 4, 5, 10 ] ]))
  raise Authoring::Duplicate unless (total % part).zero?

  shaded = total / part

  c.q(
    text: "Мрежата има #{total} квадратчета. Оцвети #{part == 2 ? 'половината' : "една #{part}-та част"} от тях.",
    widget: WidgetKit.grid_shade(rows: rows, cols: cols, count: shaded),
    explanation: Explain.build(
      idea: "Една #{part}-та част значи мрежата се дели на #{part} равни групи и се оцветява една от тях.",
      steps: [
        "#{total} : #{part} = #{shaded} квадратчета в група.",
        "Оцветяваме една група — #{shaded} квадратчета."
      ],
      answer: "#{shaded} квадратчета",
      check: "#{part} · #{shaded} = #{total} — точно цялата мрежа.",
      watch: "Оцветяваме една част, не #{part} части."
    )
  )
end

Authoring.family "early.sort_three", topic: "Числа и редици", area: "interactive_early", variants: 11,
                 rungs: EARLY do |c|
  band = c.by_level([ 1..15, 1..30, 5..60, 10..120, 20..300, 50..900 ])
  values = c.sample(band.to_a, 3)
  raise Authoring::Duplicate if values.uniq.size < 3

  descending = c.level >= 3 && c.coin
  sorted = descending ? values.sort.reverse : values.sort

  c.q(
    text: "Подреди числата #{values.join(', ')} от #{descending ? 'най-голямото към най-малкото' : 'най-малкото към най-голямото'}.",
    widget: WidgetKit.ordering(sorted.map { |value| [ value, value ] }),
    explanation: Explain.build(
      idea: "Сравняваме числата по големина и ги подреждаме едно след друго.",
      steps: [
        "Най-малкото е #{values.min}, най-голямото е #{values.max}.",
        "Редът е #{sorted.join(' → ')}."
      ],
      answer: sorted.join(" → "),
      check: "Разликата между най-голямото и най-малкото е #{values.max - values.min}.",
      watch: descending ? "Тук се започва от най-голямото." : "Тук се започва от най-малкото."
    )
  )
end

Authoring.family "early.plot_first_quadrant", topic: "Линейна функция", area: "interactive_early", variants: 4,
                 rungs: [ 860, 930, 1000, 1070, 1140, 1210 ] do |c|
  x = c.int(c.by_level([ 1..3, 1..4, 1..5, 2..6, 3..7, 4..8 ]))
  y = c.int(c.by_level([ 1..3, 1..4, 1..5, 2..6, 3..7, 4..8 ]))

  c.q(
    text: "Постави точката с #{x} стъпки надясно и #{y} стъпки нагоре от началото " \
          "(точката (#{x}; #{y})).",
    widget: WidgetKit.plot(points: [ [ x, y ] ], x_range: (0..9), y_range: (0..9)),
    explanation: Explain.build(
      idea: "Първото число казва колко надясно, второто — колко нагоре.",
      steps: [
        "От (0; 0) вървим #{x} надясно.",
        "После #{y} нагоре — стигаме до (#{x}; #{y})."
      ],
      answer: "(#{x}; #{y})",
      check: "Точката е точно над #{x} по хоризонталната ос.",
      watch: "Редът е важен: (#{x}; #{y}) и (#{y}; #{x}) са различни точки#{x == y ? ' — освен когато числата съвпадат' : ''}."
    )
  )
end
