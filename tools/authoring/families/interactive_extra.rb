# Втора вълна интерактивни задачи: същите теми, но през уиджети, които още не са
# използвани за тях — площни модели, координатна система за симетрия, колонно
# смятане в таблица, разпределяне по признак.

# ------------------------------------------------------- Площни модели ---

Authoring.family "shade.multiplication_model", topic: "Умножение и деление", area: "interactive_extra", variants: 11,
                 rungs: [ 820, 910, 1000, 1090, 1180, 1270 ] do |c|
  a = c.int(c.by_level([ 2..4, 2..5, 3..6, 3..7, 4..8, 4..9 ]))
  b = c.int(c.by_level([ 2..5, 3..6, 3..8, 4..9, 5..10, 6..12 ]))
  rows = c.int(a..[ a + 4, 10 ].min)
  cols = c.int(b..[ b + 4, 12 ].min)
  cells = (0...a).flat_map { |r| (0...b).map { |cc| "#{r},#{cc}" } }

  c.q(
    text: "Оцвети правоъгълник #{a} на #{b} в горния ляв ъгъл на мрежата #{rows} на #{cols}. " \
          "Той показва произведението #{a} · #{b} = #{a * b}.",
    widget: WidgetKit.grid_shade(rows: rows, cols: cols, cells: cells),
    explanation: Explain.build(
      idea: "Умножението е площ: #{a} реда по #{b} квадратчета правят правоъгълник с #{a * b} квадратчета.",
      steps: [
        "Броим #{a} реда надолу и #{b} колони надясно.",
        "Оцветените квадратчета са #{a} · #{b} = #{a * b}."
      ],
      answer: "#{a * b} квадратчета",
      check: "#{a * b} : #{b} = #{a} — обратното действие връща броя редове.",
      watch: "Правоъгълникът тръгва от ъгъла — иначе броенето се обърква."
    )
  )
end

Authoring.family "shade.factor_rectangle", topic: "Делимост", area: "interactive_extra", variants: 11,
                 rungs: [ 1000, 1090, 1180, 1270, 1360, 1450 ] do |c|
  number = c.int(c.by_level([ 6..20, 8..30, 10..40, 12..48, 15..60, 18..72 ]))
  divisors = Num.divisors(number).select { |d| d.between?(2, 8) && (number / d) <= 12 }
  raise Authoring::Duplicate if divisors.empty?

  a = c.pick(divisors)
  b = number / a
  rows = [ a + c.int(0..2), 10 ].min
  cols = [ b + c.int(0..2), 12 ].min
  raise Authoring::Duplicate if rows < a || cols < b

  cells = (0...a).flat_map { |r| (0...b).map { |cc| "#{r},#{cc}" } }

  c.q(
    text: "Числото #{number} се разлага като #{a} · #{b}. Оцвети правоъгълник #{a} на #{b} " \
          "в горния ляв ъгъл на мрежата, който показва това разлагане.",
    widget: WidgetKit.grid_shade(rows: rows, cols: cols, cells: cells),
    explanation: Explain.build(
      idea: "Всяко разлагане на число на два множителя е правоъгълник с толкова квадратчета.",
      steps: [
        "#{number} = #{a} · #{b}.",
        "Правоъгълникът има #{a} реда и #{b} колони."
      ],
      answer: "#{a} на #{b}",
      check: "Делителите на #{number} са #{Num.divisors(number).join(', ')} — всяка двойка дава правоъгълник.",
      watch: "Просто число има само един правоъгълник (1 на себе си) — затова #{number} не е просто."
    )
  )
end

Authoring.family "shade.remainder_model", topic: "Остатъци", area: "interactive_extra", variants: 11,
                 rungs: [ 1050, 1140, 1230, 1320, 1410, 1500 ] do |c|
  divisor = c.int(c.by_level([ 3..5, 3..6, 4..7, 4..8, 5..9, 5..10 ]))
  quotient = c.int(2..[ c.by_level([ 4, 5, 6, 7, 8, 9 ]), 9 ].min)
  rest = c.int(1...divisor)
  dividend = (divisor * quotient) + rest
  rows = quotient + 1
  cols = divisor
  cells = (0...quotient).flat_map { |r| (0...divisor).map { |cc| "#{r},#{cc}" } } +
          (0...rest).map { |cc| "#{quotient},#{cc}" }

  c.q(
    text: "Оцвети #{dividend} квадратчета в мрежата с редове по #{divisor}, като пълниш ред по ред. " \
          "Така се вижда, че #{dividend} : #{divisor} дава частно #{quotient} и остатък #{rest}.",
    widget: WidgetKit.grid_shade(rows: rows, cols: cols, cells: cells),
    explanation: Explain.build(
      idea: "Деление с остатък значи: пълни редове по #{divisor} и още малко отгоре.",
      steps: [
        "#{quotient} пълни реда по #{divisor} са #{divisor * quotient} квадратчета.",
        "Остават #{rest} квадратчета за непълния ред.",
        "#{divisor * quotient} + #{rest} = #{dividend}."
      ],
      answer: "#{quotient} пълни реда и #{rest} отгоре",
      check: "#{dividend} : #{divisor} = #{quotient} и остатък #{rest}.",
      watch: "Остатъкът винаги е по-малък от дължината на реда."
    )
  )
end

# --------------------------------------------------- Колонно смятане в таблица ---

Authoring.family "table.column_addition", topic: "Събиране и изваждане", area: "interactive_extra", variants: 11,
                 rungs: [ 900, 990, 1080, 1170, 1260, 1350 ] do |c|
  size = c.by_level([ 2, 3, 3, 4, 4, 5 ])
  a = c.int((10**(size - 1))..((10**size) - 1))
  b = c.int((10**(size - 1))..((10**size) - 1))
  sum = a + b
  digits = ->(number, width) { number.to_s.rjust(width, " ").chars }
  width = sum.to_s.size
  answers = [ digits.call(a, width), digits.call(b, width), digits.call(sum, width) ]
  rows = [ answers[0], answers[1], Array.new(width) { nil } ]

  c.q(
    text: "Събери в стълб #{a} + #{b}: попълни цифрите на сбора отляво надясно.",
    widget: WidgetKit.grid_fill(rows: rows, answers: answers, row_headers: [ "", "+", "=" ]),
    explanation: Explain.build(
      idea: "Събираме разред по разред отдясно наляво и пренасяме, когато сборът мине 9.",
      steps: [
        "Единици: #{a % 10} + #{b % 10} = #{(a % 10) + (b % 10)}.",
        "Продължаваме нагоре със същото правило.",
        "Сборът е #{sum}."
      ],
      answer: sum.to_s,
      check: "#{sum} − #{b} = #{a}.",
      watch: "Всяка клетка е една цифра — пренасянето се отразява в съседната отляво."
    )
  )
end

Authoring.family "table.subtraction_check", topic: "Събиране и изваждане", area: "interactive_extra", variants: 11,
                 rungs: [ 950, 1040, 1130, 1220, 1310, 1400 ] do |c|
  size = c.by_level([ 2, 3, 3, 4, 4, 5 ])
  a = c.int((10**(size - 1))..((10**size) - 1))
  b = c.int((10**(size - 2))..(a - 1))
  difference = a - b
  answers = [ [ a, b, difference ], [ difference, b, a ] ]
  rows = [ [ a, b, nil ], [ nil, b, a ] ]

  c.q(
    text: "Попълни разликата #{a} − #{b} и провери резултата чрез събиране (втория ред).",
    widget: WidgetKit.grid_fill(rows: rows, answers: answers,
                                column_headers: [ "първо число", "второ число", "резултат" ],
                                row_headers: [ "изваждане", "проверка" ]),
    explanation: Explain.build(
      idea: "Проверката на изваждане е събиране: разлика + умалител = умаляемо.",
      steps: [
        "#{a} − #{b} = #{difference}.",
        "Проверка: #{difference} + #{b} = #{a}."
      ],
      answer: "#{difference} и #{a}",
      check: "И двата реда описват едно и също равенство.",
      watch: "Проверката не е повторение на изваждането — тя използва обратното действие."
    )
  )
end

Authoring.family "table.fraction_operations", topic: "Дроби", area: "interactive_extra", variants: 11,
                 rungs: [ 1200, 1290, 1380, 1470, 1560, 1650 ] do |c|
  denominator = c.int(c.by_level([ 3..6, 4..8, 5..10, 6..12, 8..16, 10..24 ]))
  a = c.int(1...denominator)
  b = c.int(1...denominator)
  sum = Rational(a + b, denominator)
  difference = Rational(a - b, denominator)
  product = Rational(a * b, denominator * denominator)
  answers = [ [ Num.frac(sum), Num.frac(difference), Num.frac(product) ] ]
  hidden = c.sample((0..2).to_a, c.by_level([ 1, 2, 2, 2, 3, 3 ]))
  rows = [ answers[0].each_with_index.map { |value, i| hidden.include?(i) ? nil : value } ]
  raise Authoring::Duplicate if difference.negative? || difference.zero?

  c.q(
    text: "За дробите #{Num.frac(a, denominator)} и #{Num.frac(b, denominator)} попълни липсващите резултати " \
          "(отговорите се пишат като дроб или като десетично число).",
    widget: WidgetKit.grid_fill(rows: rows, answers: answers, column_headers: [ "сбор", "разлика", "произведение" ]),
    explanation: Explain.build(
      idea: "При равни знаменатели събирането и изваждането работят с числителите; умножението умножава и двете части.",
      steps: [
        "Сбор: #{a}/#{denominator} + #{b}/#{denominator} = #{Num.frac(sum)}.",
        "Разлика: #{a}/#{denominator} − #{b}/#{denominator} = #{Num.frac(difference)}.",
        "Произведение: #{a} · #{b} / (#{denominator} · #{denominator}) = #{Num.frac(product)}."
      ],
      answer: hidden.sort.map { |i| answers[0][i] }.join(", "),
      check: "Произведението е по-малко и от двете дроби, защото и двете са под 1.",
      watch: "Знаменателят се умножава само при умножение — при събиране остава същият."
    )
  )
end

# --------------------------------------------------------- Координатна система ---

Authoring.family "plot.polygon_vertex", topic: "Площ", area: "interactive_extra", variants: 11,
                 rungs: [ 1200, 1290, 1380, 1470, 1560, 1650 ] do |c|
  x = c.int(-4..2)
  y = c.int(-4..2)
  size = c.int(2..4)
  raise Authoring::Duplicate unless (x + size).between?(-5, 5) && (y + size).between?(-5, 5)

  c.q(
    text: "Три от върховете на квадрат са (#{Num.bg(x)}; #{Num.bg(y)}), (#{Num.bg(x + size)}; #{Num.bg(y)}) " \
          "и (#{Num.bg(x + size)}; #{Num.bg(y + size)}). Постави четвъртия и намери страната му.",
    widget: WidgetKit.plot(points: [ [ x, y + size ] ],
                           fixed: [ [ x, y, "A" ], [ x + size, y, "B" ], [ x + size, y + size, "C" ] ]),
    explanation: Explain.build(
      idea: "Квадратът има равни страни и прави ъгли — четвъртият връх се получава със същото преместване като между другите два.",
      steps: [
        "От B до C се върви #{size} нагоре; същото важи от A нататък.",
        "Четвъртият връх е (#{Num.bg(x)}; #{Num.bg(y + size)})."
      ],
      answer: "(#{Num.bg(x)}; #{Num.bg(y + size)})",
      check: "Страната е #{size}, значи лицето е #{size * size} квадратни единици.",
      watch: "Върхът е точно над A, не по диагонала."
    )
  )
end

Authoring.family "plot.function_point", topic: "Квадратна функция", area: "interactive_extra", variants: 11,
                 rungs: [ 1450, 1540, 1630, 1720, 1810, 1900 ] do |c|
  a = c.pick([ 1, 1, -1 ])
  b = c.int(-2..2)
  cc = c.int(-3..3)
  x = c.int(-2..2)
  y = (a * x * x) + (b * x) + cc
  raise Authoring::Duplicate unless y.between?(-5, 5)

  c.q(
    text: "Дадена е функцията y = #{Num.quadratic(a, b, cc)}. Постави точката от графиката ѝ с абсциса #{Num.bg(x)}.",
    widget: WidgetKit.plot(points: [ [ x, y ] ]),
    explanation: Explain.build(
      idea: "Заместваме абсцисата във формулата и получаваме ординатата.",
      steps: [
        "x = #{Num.bg(x)} → x² = #{x * x}.",
        "y = #{Num.bg(a)} · #{x * x} #{Num.term(b * x, '')} #{Num.term(cc, '')} = #{Num.bg(y)}."
      ],
      answer: "(#{Num.bg(x)}; #{Num.bg(y)})",
      check: "Точката (0; #{Num.bg(cc)}) също е от графиката — свободният член се чете направо.",
      watch: "Квадратът на отрицателно число е положителен."
    )
  )
end

Authoring.family "plot.symmetric_pair", topic: "Подобни фигури", area: "interactive_extra", variants: 11,
                 rungs: [ 1300, 1390, 1480, 1570, 1660, 1750 ] do |c|
  x = c.int(-4..4)
  y = c.int(-4..4)
  raise Authoring::Duplicate if x.zero? || y.zero? || x == y

  c.q(
    text: "Постави образите на точката A(#{Num.bg(x)}; #{Num.bg(y)}) при симетрия спрямо оста x и при симетрия спрямо оста y.",
    widget: WidgetKit.plot(points: [ [ x, -y ], [ -x, y ] ], fixed: [ [ x, y, "A" ] ]),
    explanation: Explain.build(
      idea: "Симетрия спрямо ос сменя знака само на едната координата.",
      steps: [
        "Спрямо оста x: (#{Num.bg(x)}; #{Num.bg(-y)}).",
        "Спрямо оста y: (#{Num.bg(-x)}; #{Num.bg(y)})."
      ],
      answer: "(#{Num.bg(x)}; #{Num.bg(-y)}) и (#{Num.bg(-x)}; #{Num.bg(y)})",
      check: "Двата образа и оригиналът образуват правоъгълник с център началото.",
      watch: "Спрямо оста x се сменя ординатата — координатата „нагоре-надолу“."
    )
  )
end

# --------------------------------------------------------------- Подреждане ---

Authoring.family "sort.operation_results", topic: "Ред на действията", area: "interactive_extra", variants: 11,
                 rungs: [ 1050, 1140, 1230, 1320, 1410, 1500 ] do |c|
  spec = c.by_level([ 2..8, 2..12, 3..20, 4..40, 6..80, 8..150 ])
  expressions = 4.times.map do
    a = c.int(spec)
    b = c.int(2..9)
    kind = c.pick([ :add, :mul, :sub, :brackets ])
    case kind
    when :add then [ "#{a} + #{b}", a + b ]
    when :mul then [ "#{a} · #{b}", a * b ]
    when :sub then [ "#{a * b} #{Num::MINUS} #{b}", (a * b) - b ]
    else [ "(#{a} + #{b}) · 2", (a + b) * 2 ]
    end
  end
  raise Authoring::Duplicate if expressions.map(&:last).uniq.size < 4

  sorted = expressions.sort_by(&:last)

  c.q(
    text: "Подреди изразите #{expressions.map(&:first).join(', ')} по стойност — от най-малката към най-голямата.",
    widget: WidgetKit.ordering(sorted.map { |label, _| [ label, label ] }),
    explanation: Explain.build(
      idea: "Пресмятаме всеки израз и подреждаме получените числа.",
      steps: [
        expressions.map { |label, value| "#{label} = #{value}" }.join(", ") + ".",
        "Подредени: #{sorted.map(&:last).join(' < ')}."
      ],
      answer: sorted.map(&:first).join(" → "),
      check: "Разликата между най-големия и най-малкия резултат е #{sorted.last.last - sorted.first.last}.",
      watch: "Изразът с най-големи числа не е задължително с най-голяма стойност."
    )
  )
end

Authoring.family "sort.areas", topic: "Площ", area: "interactive_extra", variants: 11,
                 rungs: [ 1150, 1240, 1330, 1420, 1510, 1600 ] do |c|
  shapes = 4.times.map do
    kind = c.pick([ :rect, :square, :triangle ])
    case kind
    when :rect
      a = c.int(2..c.by_level([ 8, 12, 20, 40, 80, 150 ]))
      b = c.int(2..c.by_level([ 8, 12, 20, 40, 80, 150 ]))
      [ "правоъгълник #{a} на #{b}", a * b ]
    when :square
      a = c.int(2..c.by_level([ 8, 12, 18, 30, 60, 120 ]))
      [ "квадрат със страна #{a}", a * a ]
    else
      base = c.int(2..c.by_level([ 10, 16, 24, 50, 100, 200 ])) * 2
      height = c.int(2..c.by_level([ 8, 12, 20, 40, 80, 150 ]))
      [ "триъгълник с основа #{base} и височина #{height}", base * height / 2 ]
    end
  end
  raise Authoring::Duplicate if shapes.map(&:last).uniq.size < 4

  sorted = shapes.sort_by(&:last)

  c.q(
    text: "Подреди фигурите по лице — от най-малкото към най-голямото: #{shapes.map(&:first).join('; ')}.",
    widget: WidgetKit.ordering(sorted.map { |label, _| [ label, label ] }),
    explanation: Explain.build(
      idea: "Пресмятаме лицето на всяка фигура по формулата ѝ и сравняваме числата.",
      steps: shapes.map { |label, area| "#{label}: #{area} кв. единици" },
      answer: sorted.map(&:first).join(" → "),
      check: "Най-голямото лице е #{sorted.last.last}, най-малкото — #{sorted.first.last}.",
      watch: "Триъгълникът има деление на 2 — без него подредбата се обърква."
    )
  )
end

Authoring.family "sort.angles_size", topic: "Ъгли", area: "interactive_extra", variants: 11,
                 rungs: [ 950, 1040, 1130, 1220, 1310, 1400 ] do |c|
  descriptions = [
    [ "прав ъгъл", 90 ], [ "изпънат ъгъл", 180 ], [ "половината от прав ъгъл", 45 ],
    [ "третината от изпънат ъгъл", 60 ], [ "ъгъл от 30°", 30 ], [ "ъгъл от 120°", 120 ],
    [ "ъгъл от 150°", 150 ], [ "четвъртината от изпънат ъгъл", 45 ], [ "ъгъл от 75°", 75 ]
  ]
  chosen = c.sample(descriptions, 4)
  raise Authoring::Duplicate if chosen.map(&:last).uniq.size < 4

  sorted = chosen.sort_by(&:last)

  c.q(
    text: "Подреди ъглите по големина — от най-малкия към най-големия: #{chosen.map(&:first).join('; ')}.",
    widget: WidgetKit.ordering(sorted.map { |label, _| [ label, label ] }),
    explanation: Explain.build(
      idea: "Превръщаме всяко описание в градуси и подреждаме.",
      steps: [ chosen.map { |label, degrees| "#{label} = #{degrees}°" }.join(", ") + "." ],
      answer: sorted.map(&:first).join(" → "),
      check: "Правият ъгъл (90°) стои по средата на изпънатия (180°).",
      watch: "„Половината от прав ъгъл“ е 45°, не 90 : 2 = 45 — тук съвпада, но описанието трябва да се чете внимателно."
    )
  )
end

# ------------------------------------------------------------- Групиране ---

Authoring.family "sortbins.rounding_target", topic: "Числа и редици", area: "interactive_extra", variants: 11,
                 rungs: [ 1000, 1090, 1180, 1270, 1360, 1450 ] do |c|
  unit = c.by_level([ 10, 10, 100, 100, 1000, 1000 ])
  low = c.int(2..40) * unit
  high = low + unit
  values = c.sample(((low - (unit / 2))...(high + (unit / 2))).to_a, 5)
  raise Authoring::Duplicate if values.count { |v| (v - low).abs < unit / 2 } < 2

  items = values.sort.each_with_index.map do |value, i|
    [ "v#{i}", value.to_s, ((value + (unit / 2)) / unit) * unit == low ? "low" : "high" ]
  end
  raise Authoring::Duplicate if items.map(&:last).uniq.size < 2

  c.q(
    text: "Разпредели числата #{values.sort.join(', ')} според това до кое кръгло число се закръглят " \
          "(до най-близките #{unit == 10 ? 'десетици' : unit == 100 ? 'стотици' : 'хиляди'}).",
    widget: WidgetKit.categorize(bins: [ [ "low", low.to_s ], [ "high", high.to_s ] ], items: items),
    explanation: Explain.build(
      idea: "Средата между #{low} и #{high} е #{low + (unit / 2)}: под нея се закръгля надолу, от нея нагоре.",
      steps: [
        "Числа под #{low + (unit / 2)} → #{low}.",
        "Числа от #{low + (unit / 2)} нагоре → #{high}."
      ],
      answer: items.map { |_, label, bin| "#{label} → #{bin == 'low' ? low : high}" }.join(", "),
      check: "Разстоянието до избраното кръгло число е по-малко от #{unit / 2}.",
      watch: "Точно средата се закръгля нагоре — това е уговорка, не изчисление."
    )
  )
end

Authoring.family "sortbins.decimal_fraction", topic: "Десетични числа", area: "interactive_extra", variants: 11,
                 rungs: [ 1150, 1240, 1330, 1420, 1510, 1600 ] do |c|
  terminating = [ Rational(1, 2), Rational(1, 4), Rational(3, 5), Rational(7, 10), Rational(5, 8), Rational(9, 20) ]
  repeating = [ Rational(1, 3), Rational(2, 3), Rational(1, 6), Rational(5, 7), Rational(4, 9), Rational(7, 11) ]
  items = c.sample(terminating, 2).map { |value| [ Num.frac(value), "fin" ] } +
          c.sample(repeating, 3).map { |value| [ Num.frac(value), "rep" ] }
  raise Authoring::Duplicate if items.map(&:first).uniq.size < 5

  c.q(
    text: "Разпредели дробите #{items.map(&:first).join(', ')} според това дали десетичният им запис е краен или периодичен.",
    widget: WidgetKit.categorize(bins: [ [ "fin", "краен" ], [ "rep", "периодичен" ] ],
                                 items: items.each_with_index.map { |(label, bin), i| [ "f#{i}", label, bin ] }),
    explanation: Explain.build(
      idea: "Десетичният запис е краен точно когато знаменателят на несъкратимата дроб се дели само на 2 и на 5.",
      steps: [
        "Крайни: #{items.select { |_, bin| bin == 'fin' }.map(&:first).join(', ')} — знаменателите им са произведения на 2 и 5.",
        "Периодични: #{items.select { |_, bin| bin == 'rep' }.map(&:first).join(', ')} — знаменателите съдържат 3, 7, 9 или 11."
      ],
      answer: "крайни: #{items.select { |_, bin| bin == 'fin' }.map(&:first).join(', ')}",
      check: "1/3 = 0,333... е периодична, 1/4 = 0,25 е крайна.",
      watch: "Дробта първо се съкращава — 3/6 е всъщност 1/2 и има краен запис."
    )
  )
end

Authoring.family "sortbins.percent_more_less", topic: "Проценти", area: "interactive_extra", variants: 11,
                 rungs: [ 1200, 1290, 1380, 1470, 1560, 1650 ] do |c|
  base = c.int(c.by_level([ 2..10, 3..20, 4..40, 6..80, 10..200, 15..500 ])) * 100
  half = base / 2
  items = 5.times.map do
    pct = c.pick([ 10, 20, 25, 40, 50, 60, 75, 80, 90 ])
    value = base * pct / 100
    [ "#{pct}% от #{base}", value > half ? "more" : "less" ]
  end.uniq(&:first)
  raise Authoring::Duplicate if items.size < 4 || items.map(&:last).uniq.size < 2

  c.q(
    text: "Разпредели стойностите #{items.map(&:first).join(', ')} според това дали са повече или по-малко от половината на #{base}.",
    widget: WidgetKit.categorize(bins: [ [ "more", "над половината" ], [ "less", "под половината" ] ],
                                 items: items.each_with_index.map { |(label, bin), i| [ "p#{i}", label, bin ] }),
    explanation: Explain.build(
      idea: "Половината е 50%, затова сравнението е между процента и 50.",
      steps: [
        "Половината от #{base} е #{half}.",
        "Проценти над 50 дават повече от #{half}, под 50 — по-малко."
      ],
      answer: items.select { |_, bin| bin == "more" }.map(&:first).join(", "),
      check: "50% от #{base} = #{half} — точно на границата.",
      watch: "Сравнението е между процентите, самото пресмятане дори не е нужно."
    )
  )
end

# ------------------------------------------------------------- Свързване ---

Authoring.family "match.decimal_fraction", topic: "Десетични числа", area: "interactive_extra", variants: 11,
                 rungs: [ 1050, 1140, 1230, 1320, 1410, 1500 ] do |c|
  pool = [ [ Rational(1, 2), "0,5" ], [ Rational(1, 4), "0,25" ], [ Rational(3, 4), "0,75" ],
           [ Rational(1, 5), "0,2" ], [ Rational(2, 5), "0,4" ], [ Rational(1, 10), "0,1" ],
           [ Rational(3, 10), "0,3" ], [ Rational(1, 8), "0,125" ], [ Rational(5, 8), "0,625" ],
           [ Rational(1, 20), "0,05" ], [ Rational(7, 20), "0,35" ], [ Rational(3, 25), "0,12" ] ]
  window = c.by_level([ pool[0..3], pool[0..5], pool[2..7], pool[4..9], pool[6..11], pool ])
  pairs = c.sample(window, 3).map { |value, decimal| [ Num.frac(value), decimal ] }
  raise Authoring::Duplicate if pairs.map(&:last).uniq.size < 3

  c.q(
    text: "Свържи всяка дроб (#{pairs.map(&:first).join(', ')}) с десетичния ѝ запис.",
    widget: WidgetKit.matcher(pairs),
    explanation: Explain.build(
      idea: "Дробта се превръща в десетично число чрез деление на числителя на знаменателя.",
      steps: pairs.map { |fraction, decimal| "#{fraction} = #{decimal}" },
      answer: pairs.map { |fraction, decimal| "#{fraction} = #{decimal}" }.join(", "),
      check: "Умножено по знаменателя, десетичното число дава числителя.",
      watch: "0,5 и 0,05 се различават десет пъти — броят нули има значение."
    )
  )
end

Authoring.family "match.operation_inverse", topic: "Умножение и деление", area: "interactive_extra", variants: 11,
                 rungs: [ 900, 990, 1080, 1170, 1260, 1350 ] do |c|
  spec = c.by_level([ 2..9, 2..15, 3..25, 4..50, 6..120, 8..300 ])
  pairs = 3.times.map do
    a = c.int(spec)
    b = c.int(2..12)
    kind = c.pick([ :mul, :add ])
    kind == :mul ? [ "#{a} · #{b}", "#{a * b} : #{b}" ] : [ "#{a} + #{b}", "#{a + b} #{Num::MINUS} #{b}" ]
  end
  raise Authoring::Duplicate if pairs.map(&:first).uniq.size < 3

  c.q(
    text: "Свържи всяко действие (#{pairs.map(&:first).join(', ')}) с обратното му, което връща началното число.",
    widget: WidgetKit.matcher(pairs),
    explanation: Explain.build(
      idea: "Умножението се връща с деление, събирането — с изваждане.",
      steps: pairs.map { |direct, inverse| "#{direct} → и обратно: #{inverse}" },
      answer: pairs.map { |direct, inverse| "#{direct} ↔ #{inverse}" }.join(", "),
      check: "След двете действия се получава първоначалното число.",
      watch: "Обратното на „· #{pairs.first.first[/\d+$/]}“ е деление на същото число, не изваждане."
    )
  )
end

# ------------------------------------------------------------------- Избор ---

Authoring.family "pick.fraction_gt_half", topic: "Дроби", area: "interactive_extra", variants: 11,
                 rungs: [ 1000, 1090, 1180, 1270, 1360, 1450 ] do |c|
  values = []
  12.times do
    d = c.int(c.by_level([ 2..6, 2..8, 3..10, 3..12, 4..16, 5..20 ]))
    n = c.int(1...d)
    value = Rational(n, d)
    values << value if !values.include?(value) && value != Rational(1, 2)
  end
  values = values.first(5)
  raise Authoring::Duplicate if values.size < 5 || values.count { |v| v > Rational(1, 2) } < 2 || values.count { |v| v < Rational(1, 2) } < 2

  options = values.map { |value| [ Num.frac(value), value > Rational(1, 2) ] }

  c.q(
    text: "Кои от дробите #{values.map { |v| Num.frac(v) }.join(', ')} са по-големи от 1/2? Избери всички.",
    widget: WidgetKit.multi_select(options),
    explanation: Explain.build(
      idea: "Дробта е над 1/2 точно когато числителят е повече от половината знаменател.",
      steps: [
        values.map { |v| "#{Num.frac(v)}: половината от #{v.denominator} е #{Num.dec(Rational(v.denominator, 2), 1)}, а числителят е #{v.numerator}" }.first(3).join("; ") + ".",
        "По-големи от 1/2 са #{values.select { |v| v > Rational(1, 2) }.map { |v| Num.frac(v) }.join(', ')}."
      ],
      answer: values.select { |v| v > Rational(1, 2) }.map { |v| Num.frac(v) }.join(", "),
      check: "В десетичен вид: #{values.map { |v| Num.dec(v, 2) }.join(', ')} срещу 0,5.",
      watch: "Сравняването на числителите без знаменателите не работи."
    )
  )
end

Authoring.family "pick.divisible_by_two_rules", topic: "Делимост", area: "interactive_extra", variants: 11,
                 rungs: [ 1250, 1340, 1430, 1520, 1610, 1700 ] do |c|
  first = c.pick([ 2, 3, 4, 5 ])
  second = c.pick([ 3, 5, 6, 9 ])
  raise Authoring::Duplicate if first == second

  step = Num.lcm(first, second)
  good = c.sample((1..20).map { |k| k * step }, 2)
  bad = []
  10.times do
    candidate = c.int(good.min..(good.max + step))
    bad << candidate if (candidate % step) != 0 && !bad.include?(candidate)
  end
  bad = bad.first(3)
  options = (good + bad).sort.map { |n| [ n.to_s, good.include?(n) ] }
  raise Authoring::Duplicate if bad.size < 3

  c.q(
    text: "Кои от числата #{options.map(&:first).join(', ')} се делят едновременно на #{first} и на #{second}? Избери всички.",
    widget: WidgetKit.multi_select(options),
    explanation: Explain.build(
      idea: "Число се дели едновременно на #{first} и на #{second} точно когато се дели на НОК(#{first}, #{second}) = #{step}.",
      steps: [
        "НОК(#{first}, #{second}) = #{step}.",
        good.map { |n| "#{n} : #{step} = #{n / step}" }.join(", ") + " — тези се делят.",
        "Останалите дават остатък при деление на #{step}."
      ],
      answer: good.sort.join(", "),
      check: "Всяко избрано число се дели и на #{first}, и на #{second} поотделно.",
      watch: "Делимост на #{first} и делимост на #{second} поотделно не стигат — трябват едновременно."
    )
  )
end

Authoring.family "pick.true_equations", topic: "Ред на действията", area: "interactive_extra", variants: 11,
                 rungs: [ 1150, 1240, 1330, 1420, 1510, 1600 ] do |c|
  spec = c.by_level([ 2..8, 2..12, 3..20, 4..40, 6..90, 8..200 ])
  statements = 5.times.map do
    a = c.int(spec)
    b = c.int(2..9)
    d = c.int(spec)
    correct = c.coin
    value = (a * b) + d
    shown = correct ? value : value + c.pick([ -3, -2, -1, 1, 2, 3 ])
    [ "#{a} · #{b} + #{d} = #{shown}", shown == value ]
  end.uniq(&:first)
  raise Authoring::Duplicate if statements.size < 5 || statements.count(&:last) < 2 || statements.count { |_, ok| !ok } < 2

  c.q(
    text: "Кои от равенствата са верни? Избери всички: #{statements.map(&:first).join('; ')}.",
    widget: WidgetKit.multi_select(statements),
    explanation: Explain.build(
      idea: "Проверяваме всяко равенство, като спазваме реда на действията: умножение преди събиране.",
      steps: statements.first(3).map do |label, ok|
        numbers = label.scan(/\d+/).map(&:to_i)
        "#{label}: #{numbers[0]} · #{numbers[1]} = #{numbers[0] * numbers[1]}, плюс #{numbers[2]} прави #{(numbers[0] * numbers[1]) + numbers[2]} — #{ok ? 'вярно' : 'невярно'}."
      end,
      answer: statements.select(&:last).map(&:first).join("; "),
      check: "Всяко вярно равенство издържа пресмятане от двете страни.",
      watch: "Ако се събере преди да се умножи, почти всяко равенство изглежда невярно."
    )
  )
end

# --------------------------------------------------------------- Часовник ---

Authoring.family "clock.modular", topic: "Остатъци", area: "interactive_extra", variants: 11,
                 rungs: [ 1200, 1290, 1380, 1470, 1560, 1650 ] do |c|
  start = c.int(1..12)
  hours = c.int(c.by_level([ 13..40, 20..80, 30..150, 50..400, 80..900, 120..3000 ]))
  result = ((start + hours - 1) % 12) + 1

  c.q(
    text: "Часовникът показва #{start}:00. Нагласи го на времето след #{hours} часа.",
    widget: WidgetKit.clock(hours: result, minutes: 0),
    explanation: Explain.build(
      idea: "Часовникът брои по модул 12 — интересува ни остатъкът при деление на 12.",
      steps: [
        "#{hours} : 12 = #{hours / 12} и остатък #{hours % 12}.",
        "Пълните обиколки не променят стрелките; остават #{count_noun(hours % 12, 'час', 'часа')}.",
        "#{start} + #{hours % 12} по модул 12 дава #{result}."
      ],
      answer: "#{result}:00",
      check: "След #{(hours / 12) * 12} часа часовникът пак показва #{start}:00.",
      watch: "След 12 идва 1, не 13 — това е смисълът на „по модул 12“."
    )
  )
end

Authoring.family "clock.half_hours", topic: "Събиране и изваждане", area: "interactive_extra", variants: 11,
                 rungs: [ 780, 870, 960, 1050, 1140, 1230 ] do |c|
  hour = c.int(1..12)
  halves = c.int(1..c.by_level([ 3, 5, 7, 9, 12, 20 ]))
  total = (hour * 60) + (halves * 30)
  end_hour = ((total / 60 - 1) % 12) + 1
  end_minute = total % 60

  c.q(
    text: "Часът е #{hour}:00. Нагласи часовника след #{halves} половин часа " \
          "(тоест след #{halves * 30} минути).",
    widget: WidgetKit.clock(hours: end_hour, minutes: end_minute),
    explanation: Explain.build(
      idea: "Два половин часа правят един цял час.",
      steps: [
        "#{halves} · 30 = #{halves * 30} минути.",
        "#{halves * 30} минути са #{count_noun(halves / 2, 'час', 'часа')}#{halves.odd? ? ' и 30 минути' : ''}.",
        "Часът става #{end_hour}:#{format('%02d', end_minute)}."
      ],
      answer: "#{end_hour}:#{format('%02d', end_minute)}",
      check: "Назад #{halves * 30} минути се връщаме на #{hour}:00.",
      watch: "Нечетен брой половинки оставя 30 минути в остатък."
    )
  )
end
