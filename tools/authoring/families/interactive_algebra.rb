# Интерактивни задачи: уравнения, неравенства, изрази, функции, прогресии.
#
# Two blanks instead of one wherever the method has two halves — the roots of a
# quadratic, x and y of a system, the slope and the intercept — because a single
# typed number lets a student stop halfway and still be marked right.

# ---------------------------------------------------------------- Попълване ---

Authoring.family "blank.equation_steps", topic: "Уравнения", area: "interactive_algebra", variants: 11,
                 rungs: [ 1020, 1110, 1200, 1290, 1380, 1470 ] do |c|
  a = c.int(c.by_level([ 2..5, 2..8, 3..12, 4..20, 5..40, 6..90 ]))
  x = c.int(c.by_level([ 2..9, 2..15, 3..25, 4..50, 5..120, 6..300 ]))
  b = c.int(c.by_level([ 1..12, 2..25, 3..50, 5..120, 8..300, 10..800 ]))
  right = (a * x) + b

  c.q(
    text: "Реши уравнението #{a}x + #{b} = #{right} на две стъпки: попълни на колко е равно #{a}x и на колко е равно x.",
    widget: WidgetKit.blanks([ [ "ax", "#{a}x", a * x ], [ "x", "x", x ] ], prompt: "#{a}x + #{b} = #{right}"),
    explanation: Explain.build(
      idea: "Първо освобождаваме члена с x от свободното число, после делим на коефициента.",
      steps: [
        "#{a}x = #{right} − #{b} = #{a * x}.",
        "x = #{a * x} : #{a} = #{x}."
      ],
      answer: "#{a}x = #{a * x}, x = #{x}",
      check: "#{a} · #{x} + #{b} = #{right}.",
      watch: "Делението идва последно — докато свободният член стои отляво, коефициентът не се маха."
    )
  )
end

Authoring.family "blank.quadratic_roots", topic: "Квадратни уравнения", area: "interactive_algebra", variants: 11,
                 rungs: [ 1450, 1540, 1630, 1720, 1810, 1900 ] do |c|
  p = c.int(c.by_level([ 1..5, 1..8, 2..12, 2..20, 3..40, 4..80 ]))
  q = c.int(c.by_level([ 1..5, 1..8, 2..12, 2..20, 3..40, 4..80 ]))
  raise Authoring::Duplicate if p == q

  b = -(p + q)
  cc = p * q

  c.q(
    text: "Реши уравнението x² #{Num.term(b, 'x')} + #{cc} = 0 и попълни двата корена (по-малкия и по-големия).",
    widget: WidgetKit.blanks([ [ "x1", "по-малък корен", [ p, q ].min ], [ "x2", "по-голям корен", [ p, q ].max ] ],
                             prompt: "x² #{Num.term(b, 'x')} + #{cc} = 0"),
    explanation: Explain.build(
      idea: "Търсим две числа със сбор #{p + q} и произведение #{cc} — формулите на Виет ги дават направо.",
      steps: [
        "Сбор на корените: #{p + q}. Произведение: #{cc}.",
        "Двойката #{p} и #{q} изпълнява и двете.",
        "Проверка с дискриминанта: D = #{b * b} − 4 · #{cc} = #{(b * b) - (4 * cc)} = #{Integer.sqrt((b * b) - (4 * cc))}²."
      ],
      answer: "x₁ = #{[ p, q ].min}, x₂ = #{[ p, q ].max}",
      check: "(x − #{p})(x − #{q}) = x² #{Num.term(b, 'x')} + #{cc}.",
      watch: "Знакът в скобите е обратен на знака на корена: корен #{p} идва от скобата (x − #{p})."
    )
  )
end

Authoring.family "blank.system_xy", topic: "Системи уравнения", area: "interactive_algebra", variants: 11,
                 rungs: [ 1380, 1470, 1560, 1650, 1740, 1830 ] do |c|
  x = c.int(c.by_level([ 1..6, 1..9, 2..12, 2..20, 3..40, 4..80 ]))
  y = c.int(c.by_level([ 1..6, 1..9, 2..12, 2..20, 3..40, 4..80 ]))
  a1 = c.int(1..c.by_level([ 3, 4, 5, 7, 9, 12 ]))
  b1 = c.int(1..c.by_level([ 3, 4, 5, 7, 9, 12 ]))
  a2 = c.int(1..c.by_level([ 3, 4, 5, 7, 9, 12 ]))
  b2 = c.int(1..c.by_level([ 3, 4, 5, 7, 9, 12 ]))
  raise Authoring::Duplicate if (a1 * b2) - (a2 * b1) == 0

  c1 = (a1 * x) + (b1 * y)
  c2 = (a2 * x) + (b2 * y)

  c.q(
    text: "Реши системата #{Num.monomial(a1, 'x')} + #{Num.monomial(b1, 'y')} = #{c1} и " \
          "#{Num.monomial(a2, 'x')} + #{Num.monomial(b2, 'y')} = #{c2}. Попълни x и y.",
    widget: WidgetKit.blanks([ [ "x", "x", x ], [ "y", "y", y ] ]),
    explanation: Explain.build(
      idea: "Изравняваме коефициентите пред едната неизвестна и изваждаме двете уравнения.",
      steps: [
        "Умножаваме първото по #{b2}, второто по #{b1}: коефициентът пред y става #{b1 * b2} и в двете.",
        "След изваждане: #{Num.lead((a1 * b2) - (a2 * b1))} = #{Num.bg((c1 * b2) - (c2 * b1))}, значи x = #{x}.",
        "Заместваме в първото: #{a1} · #{x} + #{b1}y = #{c1}, откъдето y = #{y}."
      ],
      answer: "x = #{x}, y = #{y}",
      check: "#{a1} · #{x} + #{b1} · #{y} = #{c1} и #{a2} · #{x} + #{b2} · #{y} = #{c2}.",
      watch: "Двойката трябва да върши работа и в двете уравнения, не само в първото."
    )
  )
end

Authoring.family "blank.progression_start", topic: "Аритметична прогресия", area: "interactive_algebra", variants: 11,
                 rungs: [ 1400, 1490, 1580, 1670, 1760, 1850 ] do |c|
  first = c.int(c.by_level([ 1..10, 1..20, -10..30, -20..60, -40..120, -80..300 ]))
  step = c.int(c.by_level([ 2..6, 2..9, 3..12, 4..18, 5..30, 6..60 ]))
  m = c.int(2..4)
  n = m + c.int(2..6)
  term_m = first + ((m - 1) * step)
  term_n = first + ((n - 1) * step)

  c.q(
    text: "В аритметична прогресия #{m}-ият член е #{Num.bg(term_m)}, а #{n}-ият е #{Num.bg(term_n)}. " \
          "Попълни разликата d и първия член a₁.",
    widget: WidgetKit.blanks([ [ "d", "d", step ], [ "a1", "a₁", Num.ans(first) ] ]),
    explanation: Explain.build(
      idea: "Между #{m}-ия и #{n}-ия член има #{n - m} стъпки, значи разликата се получава с деление.",
      steps: [
        "#{Num.bg(term_n)} − #{Num.bg(term_m)} = #{Num.bg(term_n - term_m)} за #{n - m} стъпки.",
        "d = #{Num.bg(term_n - term_m)} : #{n - m} = #{step}.",
        "Назад от #{m}-ия член: a₁ = #{Num.bg(term_m)} − #{m - 1} · #{step} = #{Num.bg(first)}."
      ],
      answer: "d = #{step}, a₁ = #{Num.bg(first)}",
      check: "a#{n} = #{Num.bg(first)} + #{n - 1} · #{step} = #{Num.bg(term_n)}.",
      watch: "Стъпките между членове m и n са n − m, не n."
    )
  )
end

Authoring.family "blank.line_from_points", topic: "Линейна функция", area: "interactive_algebra", variants: 11,
                 rungs: [ 1420, 1510, 1600, 1690, 1780, 1870 ] do |c|
  a = c.int(c.by_level([ 1..4, -4..5, -6..6, -9..9, -15..15, -30..30 ]))
  raise Authoring::Duplicate if a.zero?

  b = c.int(c.by_level([ 0..6, -6..10, -12..15, -20..30, -40..60, -90..120 ]))
  x1 = c.int(-6..6)
  x2 = x1 + c.int(1..5)
  y1 = (a * x1) + b
  y2 = (a * x2) + b

  c.q(
    text: "Права минава през точките A(#{Num.bg(x1)}; #{Num.bg(y1)}) и B(#{Num.bg(x2)}; #{Num.bg(y2)}). " \
          "Попълни ъгловия коефициент k и свободния член m на уравнението y = kx + m.",
    widget: WidgetKit.blanks([ [ "k", "k", Num.ans(a) ], [ "m", "m", Num.ans(b) ] ]),
    explanation: Explain.build(
      idea: "Ъгловият коефициент е отношението на изменението по y към изменението по x; свободният член се намира чрез заместване.",
      steps: [
        "k = (#{Num.bg(y2)} − #{Num.bg(y1)}) : (#{Num.bg(x2)} − #{Num.bg(x1)}) = #{Num.bg(y2 - y1)} : #{x2 - x1} = #{Num.bg(a)}.",
        "Заместваме A: #{Num.bg(y1)} = #{Num.bg(a)} · #{Num.bg(x1)} + m, значи m = #{Num.bg(b)}."
      ],
      answer: "k = #{Num.bg(a)}, m = #{Num.bg(b)}",
      check: "И двете точки удовлетворяват y = #{Num.linear(a, b)}.",
      watch: "Изменението по x стои в знаменателя — размяната обръща наклона."
    )
  )
end

Authoring.family "blank.vertex_pair", topic: "Квадратна функция", area: "interactive_algebra", variants: 11,
                 rungs: [ 1540, 1630, 1720, 1810, 1900, 1990 ] do |c|
  a = c.int(c.by_level([ 1..2, 1..3, -3..4, -4..5, -6..8, -10..12 ]))
  raise Authoring::Duplicate if a.zero?

  vertex_x = c.int(c.by_level([ -3..3, -5..5, -7..7, -10..10, -15..15, -25..25 ]))
  b = -2 * a * vertex_x
  cc = c.int(-20..20)
  vertex_y = (a * vertex_x * vertex_x) + (b * vertex_x) + cc

  c.q(
    text: "Намери върха на параболата y = #{Num.quadratic(a, b, cc)}: попълни абсцисата и ординатата му.",
    widget: WidgetKit.blanks([ [ "x0", "x₀", Num.ans(vertex_x) ], [ "y0", "y₀", Num.ans(vertex_y) ] ]),
    explanation: Explain.build(
      idea: "x₀ = −b : (2a), а ординатата се получава чрез заместване на x₀ във формулата.",
      steps: [
        "x₀ = #{Num.bg(-b)} : #{Num.bg(2 * a)} = #{Num.bg(vertex_x)}.",
        "y₀ = #{Num.bg(a)} · #{vertex_x * vertex_x} #{Num.term(b * vertex_x, '')} #{Num.term(cc, '')} = #{Num.bg(vertex_y)}."
      ],
      answer: "(#{Num.bg(vertex_x)}; #{Num.bg(vertex_y)})",
      check: "f(#{Num.bg(vertex_x - 1)}) = f(#{Num.bg(vertex_x + 1)}) = #{Num.bg((a * (vertex_x + 1)**2) + (b * (vertex_x + 1)) + cc)} — симетрия около върха.",
      watch: a.positive? ? "При a > 0 върхът е минимум." : "При a < 0 върхът е максимум."
    )
  )
end

Authoring.family "blank.integer_bounds", topic: "Неравенства", area: "interactive_algebra", variants: 11,
                 rungs: [ 1300, 1390, 1480, 1570, 1660, 1750 ] do |c|
  a = c.int(c.by_level([ 2..4, 2..6, 3..9, 4..15, 5..30, 6..60 ]))
  low = c.int(c.by_level([ 1..8, -5..12, -10..20, -20..40, -40..90, -80..200 ]))
  width = c.int(c.by_level([ 3..8, 4..12, 5..20, 6..30, 8..60, 10..120 ]))
  high = low + width
  left = a * low
  right = a * high

  c.q(
    text: "Реши двойното неравенство #{Num.bg(left)} < #{a}x < #{Num.bg(right)}. " \
          "Попълни най-малкото и най-голямото цяло число, което е решение.",
    widget: WidgetKit.blanks([ [ "min", "най-малко", Num.ans(low + 1) ], [ "max", "най-голямо", Num.ans(high - 1) ] ]),
    explanation: Explain.build(
      idea: "Делим и трите части на положителното #{a} — знаците остават същите.",
      steps: [
        "#{Num.bg(left)} : #{a} = #{Num.bg(low)} и #{Num.bg(right)} : #{a} = #{Num.bg(high)}.",
        "Значи #{Num.bg(low)} < x < #{Num.bg(high)}.",
        "Целите числа вътре започват от #{Num.bg(low + 1)} и стигат до #{Num.bg(high - 1)}."
      ],
      answer: "от #{Num.bg(low + 1)} до #{Num.bg(high - 1)}",
      check: "Броят им е #{high - low - 1}.",
      watch: "Знаците са строги, затова #{Num.bg(low)} и #{Num.bg(high)} не влизат."
    )
  )
end

Authoring.family "blank.expand_square", topic: "Рационални изрази", area: "interactive_algebra", variants: 11,
                 rungs: [ 1400, 1490, 1580, 1670, 1760, 1850 ] do |c|
  a = c.int(c.by_level([ 1..2, 1..3, 1..4, 2..6, 2..9, 3..12 ]))
  b = c.int(c.by_level([ 1..5, 2..8, 3..12, 4..15, 5..25, 6..40 ]))
  minus = c.coin
  middle = (minus ? -1 : 1) * 2 * a * b

  c.q(
    text: "Разкрий скобите: (#{Num.monomial(a, 'x')} #{minus ? Num::MINUS : '+'} #{b})² = #{a * a}x² + ☐x + ☐. " \
          "Попълни коефициента пред x и свободния член.",
    widget: WidgetKit.blanks([ [ "b", "пред x", Num.ans(middle) ], [ "c", "свободен член", b * b ] ]),
    explanation: Explain.build(
      idea: "Формулата (a ± b)² = a² ± 2ab + b² — средният член е двойното произведение.",
      steps: [
        "a = #{Num.monomial(a, 'x')}, b = #{b}.",
        "2ab = 2 · #{a} · #{b} = #{2 * a * b}, със знак #{minus ? 'минус' : 'плюс'}: #{Num.bg(middle)}.",
        "b² = #{b}² = #{b * b}."
      ],
      answer: "#{Num.bg(middle)} и #{b * b}",
      check: "При x = 1: (#{a} #{minus ? Num::MINUS : '+'} #{b})² = #{(minus ? a - b : a + b)**2}, а изразът дава #{(a * a) + middle + (b * b)}.",
      watch: "Свободният член е винаги положителен — минусът влиза само в средния."
    )
  )
end

Authoring.family "blank.power_forms", topic: "Степени и корени", area: "interactive_algebra", variants: 11,
                 rungs: [ 1350, 1440, 1530, 1620, 1710, 1800 ] do |c|
  base = c.pick(c.by_level([ [ 2 ], [ 2, 3 ], [ 3, 5 ], [ 2, 5 ], [ 2, 6, 7 ], [ 3, 10, 11 ] ]))
  exponent = 2 * c.int(c.by_level([ 2..3, 2..4, 2..4, 3..5, 3..6, 4..7 ]))
  value = base**exponent
  raise Authoring::Duplicate if value > 5_000_000

  square_base = base**(exponent / 2)

  c.q(
    text: "Числото #{value} се записва като степен по два начина. Попълни показателя n в #{base}#{Num.sup('n')} = #{value} " \
          "и показателя m в #{square_base}#{Num.sup('m')} = #{value}.",
    widget: WidgetKit.blanks([ [ "n", "n", exponent ], [ "m", "m", 2 ] ]),
    explanation: Explain.build(
      idea: "Една и съща стойност може да се запише с различна основа, ако показателят се нагласи.",
      steps: [
        "#{value} = #{([ base ] * exponent).join(' · ')} = #{base}#{Num.sup(exponent)}.",
        "#{square_base} = #{base}#{Num.sup(exponent / 2)}, затова #{square_base}² = #{base}#{Num.sup(exponent)} = #{value}."
      ],
      answer: "n = #{exponent}, m = 2",
      check: "#{square_base} · #{square_base} = #{value}.",
      watch: "При смяна на основата показателят се дели или умножава — не остава същият."
    )
  )
end

# ---------------------------------------------------- Избор на всички верни ---

Authoring.family "pick.equation_solutions", topic: "Уравнения", area: "interactive_algebra", variants: 11,
                 rungs: [ 1150, 1240, 1330, 1420, 1510, 1600 ] do |c|
  a = c.int(c.by_level([ 2..4, 2..6, 3..9, 4..15, 5..30, 6..60 ]))
  x = c.int(c.by_level([ 2..8, 2..12, 3..20, 4..40, 5..90, 6..200 ]))
  b = c.int(c.by_level([ 1..10, 2..20, 3..40, 5..80, 8..200, 10..500 ]))
  right = (a * x) + b
  wrong = [ x + 1, x - 1, right - b, x * 2 ].uniq.reject { |value| value == x || value <= 0 }.first(4)
  raise Authoring::Duplicate if wrong.size < 3

  options = ([ [ x, true ] ] + wrong.map { |value| [ value, false ] }).sort_by(&:first).map { |value, ok| [ value.to_s, ok ] }

  c.q(
    text: "Кои от числата #{options.map(&:first).join(', ')} са решения на уравнението #{a}x + #{b} = #{right}? " \
          "Избери всички верни.",
    widget: WidgetKit.multi_select(options),
    explanation: Explain.build(
      idea: "Заместваме всяко число и проверяваме дали равенството става вярно.",
      steps: [
        "x = #{x}: #{a} · #{x} + #{b} = #{right} — вярно.",
        wrong.first(2).map { |value| "x = #{value}: #{a} · #{value} + #{b} = #{(a * value) + b} ≠ #{right}" }.join("; ") + "."
      ],
      answer: x.to_s,
      check: "Линейно уравнение с ненулев коефициент има точно едно решение, така че верният избор е един.",
      watch: "Тук верният отговор е само един, но задачата пита „всички“ — не бива да се избира втори наслуки."
    )
  )
end

Authoring.family "pick.inequality_solutions", topic: "Неравенства", area: "interactive_algebra", variants: 11,
                 rungs: [ 1250, 1340, 1430, 1520, 1610, 1700 ] do |c|
  a = c.int(c.by_level([ 2..4, 2..6, 3..9, 4..12, 5..20, 6..40 ]))
  threshold = c.int(c.by_level([ 2..8, 3..15, 4..25, 5..50, 8..120, 10..300 ]))
  b = c.int(c.by_level([ 1..10, 2..20, 3..40, 5..80, 8..200, 10..400 ]))
  right = (a * threshold) + b
  candidates = c.sample(((threshold - 4)..(threshold + 5)).to_a.reject { |value| value <= 0 }, 6).sort
  raise Authoring::Duplicate if candidates.size < 5 || candidates.none? { |value| value > threshold } || candidates.none? { |value| value <= threshold }

  options = candidates.map { |value| [ value.to_s, value > threshold ] }

  c.q(
    text: "Кои от числата #{candidates.join(', ')} са решения на неравенството #{a}x + #{b} > #{right}? Избери всички.",
    widget: WidgetKit.multi_select(options),
    explanation: Explain.build(
      idea: "Решаваме неравенството веднъж, после проверяваме кои от дадените числа попадат в решението.",
      steps: [
        "#{a}x > #{right} − #{b} = #{a * threshold}.",
        "x > #{threshold}.",
        "Подходящи са #{candidates.select { |value| value > threshold }.join(', ')}."
      ],
      answer: candidates.select { |value| value > threshold }.join(", "),
      check: "При x = #{threshold} лявата страна е точно #{right} — не е по-голяма, значи #{threshold} отпада.",
      watch: "Строгото „>“ изключва самата граница."
    )
  )
end

Authoring.family "pick.equal_powers", topic: "Степени и корени", area: "interactive_algebra", variants: 11,
                 rungs: [ 1380, 1470, 1560, 1650, 1740, 1830 ] do |c|
  target = c.pick(c.by_level([ [ 16, 64 ], [ 64, 81 ], [ 64, 256 ], [ 128, 729 ], [ 512, 1024 ], [ 2401, 4096 ] ]))
  equal = []
  (2..12).each do |base|
    exponent = 2
    while base**exponent <= target
      equal << "#{base}#{Num.sup(exponent)}" if base**exponent == target
      exponent += 1
    end
  end
  equal = equal.first(3)
  raise Authoring::Duplicate if equal.size < 2

  wrong = []
  6.times do
    base = c.int(2..12)
    exponent = c.int(2..6)
    label = "#{base}#{Num.sup(exponent)}"
    wrong << label if base**exponent != target && !wrong.include?(label) && !equal.include?(label)
  end
  wrong = wrong.first(3)
  raise Authoring::Duplicate if wrong.size < 3

  options = (equal + wrong).map { |label| [ label, equal.include?(label) ] }

  c.q(
    text: "Кои от изразите #{options.map(&:first).join(', ')} са равни на #{target}? Избери всички.",
    widget: WidgetKit.multi_select(options),
    explanation: Explain.build(
      idea: "Пресмятаме всяка степен или разлагаме #{target} на прости множители: #{target} = #{Num.factor_string(target)}.",
      steps: [
        "Равни на #{target}: #{equal.join(', ')}.",
        "Останалите дават други стойности."
      ],
      answer: equal.join(", "),
      check: "Всички верни записи имат едно и също разлагане на прости множители.",
      watch: "Различна основа не значи различна стойност: #{equal.join(' = ')}."
    )
  )
end

Authoring.family "pick.arithmetic_sequences", topic: "Аритметична прогресия", area: "interactive_algebra", variants: 11,
                 rungs: [ 1330, 1420, 1510, 1600, 1690, 1780 ] do |c|
  make_arithmetic = lambda do
    first = c.int(1..c.by_level([ 10, 20, 40, 80, 150, 400 ]))
    step = c.int(1..c.by_level([ 5, 8, 12, 20, 40, 90 ]))
    (0..3).map { |i| first + (i * step) }
  end
  make_other = lambda do
    first = c.int(1..8)
    ratio = c.int(2..4)
    kind = c.pick([ :geometric, :growing, :squares ])
    case kind
    when :geometric then (0..3).map { |i| first * (ratio**i) }
    when :squares then (1..4).map { |i| (first + i)**2 }
    else (0..3).map { |i| first + (i * (i + 1) / 2) }
    end
  end

  good = 2.times.map { make_arithmetic.call }
  bad = 3.times.map { make_other.call }
  options = (good + bad).map { |terms| [ terms.join(", "), good.include?(terms) ] }.uniq { |label, _| label }
  raise Authoring::Duplicate if options.count { |_, ok| ok } < 2 || options.size < 5

  c.q(
    text: "Коя от редиците #{options.map(&:first).map { |labels| labels.split(', ').first(3).join(', ') }.join(' | ')} " \
          "е аритметична прогресия? Избери всички такива.",
    widget: WidgetKit.multi_select(options),
    explanation: Explain.build(
      idea: "Аритметична е редицата, при която разликата между съседните членове е постоянна.",
      steps: good.map { |terms| "#{terms.join(', ')} — разлика #{terms[1] - terms[0]} навсякъде." } +
             bad.first(2).map { |terms| "#{terms.join(', ')} — разлики #{(1...terms.size).map { |i| terms[i] - terms[i - 1] }.join(', ')}, не са равни." },
      answer: good.map { |terms| terms.join(", ") }.join(" | "),
      check: "При аритметична прогресия a₂ − a₁ = a₃ − a₂ = a₄ − a₃.",
      watch: "Растящата редица не е задължително аритметична — важна е постоянната стъпка."
    )
  )
end

Authoring.family "pick.system_pairs", topic: "Системи уравнения", area: "interactive_algebra", variants: 11,
                 rungs: [ 1450, 1540, 1630, 1720, 1810, 1900 ] do |c|
  x = c.int(c.by_level([ 1..6, 1..9, 2..12, 2..20, 3..40, 4..70 ]))
  y = c.int(c.by_level([ 1..6, 1..9, 2..12, 2..20, 3..40, 4..70 ]))
  sum = x + y
  difference = x - y
  candidates = [ [ x, y ] ]
  8.times do
    dx = c.int(-3..3)
    pair = [ x + dx, y - dx ]
    candidates << pair if pair.all?(&:positive?) && !candidates.include?(pair)
  end
  candidates = candidates.first(5)
  raise Authoring::Duplicate if candidates.size < 4

  options = candidates.map { |px, py| [ "(#{px}; #{py})", px + py == sum && px - py == difference ] }

  c.q(
    text: "Коя двойка (x; y) е решение на системата x + y = #{sum}, x − y = #{Num.bg(difference)}? Избери всички верни.",
    widget: WidgetKit.multi_select(options),
    explanation: Explain.build(
      idea: "Решението трябва да върши работа и в двете уравнения — проверяваме двойките една по една.",
      steps: [
        "Всички двойки тук имат сбор #{sum}, затова първото уравнение не различава нищо.",
        "Второто решава: x − y = #{Num.bg(difference)} само за (#{x}; #{y})."
      ],
      answer: "(#{x}; #{y})",
      check: "#{x} + #{y} = #{sum} и #{x} − #{y} = #{Num.bg(difference)}.",
      watch: "Едно изпълнено уравнение не стига — системата иска и двете."
    )
  )
end

# --------------------------------------------------------------- Свързване ---

Authoring.family "match.function_values", topic: "Линейна функция", area: "interactive_algebra", variants: 11,
                 rungs: [ 1280, 1370, 1460, 1550, 1640, 1730 ] do |c|
  point = c.int(c.by_level([ 1..3, 1..4, 2..5, -4..6, -6..8, -10..12 ]))
  pairs = 3.times.map do
    a = c.int(c.by_level([ 1..5, 2..8, -6..9, -9..12, -15..20, -30..40 ]))
    b = c.int(c.by_level([ 0..6, -6..10, -12..16, -20..30, -40..60, -90..120 ]))
    [ "f(x) = #{Num.linear(a, b)}", (a * point) + b ]
  end
  raise Authoring::Duplicate if pairs.map(&:last).uniq.size < 3 || pairs.map(&:first).uniq.size < 3

  c.q(
    text: "Свържи всяка функция със стойността ѝ при x = #{Num.bg(point)}.",
    widget: WidgetKit.matcher(pairs.map { |formula, value| [ formula, Num.bg(value) ] }),
    explanation: Explain.build(
      idea: "Заместваме x = #{Num.bg(point)} във всяка формула и пресмятаме.",
      steps: pairs.map { |formula, value| "#{formula} → #{Num.bg(value)}" },
      answer: pairs.map { |formula, value| "#{formula} = #{Num.bg(value)}" }.join(", "),
      check: "Различните коефициенти дават различни стойности в една и съща точка.",
      watch: "Знакът пред коефициента се пренася при умножението."
    )
  )
end

Authoring.family "match.equation_solution", topic: "Уравнения", area: "interactive_algebra", variants: 11,
                 rungs: [ 1200, 1290, 1380, 1470, 1560, 1650 ] do |c|
  pairs = 3.times.map do
    a = c.int(c.by_level([ 2..5, 2..8, 3..10, 4..15, 5..25, 6..50 ]))
    x = c.int(c.by_level([ 1..8, 2..12, 2..20, 3..40, 4..90, 5..200 ]))
    b = c.int(c.by_level([ 1..10, 2..20, 3..40, 5..80, 8..200, 10..500 ]))
    [ "#{a}x + #{b} = #{(a * x) + b}", x ]
  end
  raise Authoring::Duplicate if pairs.map(&:last).uniq.size < 3

  c.q(
    text: "Свържи всяко от уравненията #{pairs.map(&:first).join('; ')} с корена му.",
    widget: WidgetKit.matcher(pairs.map { |equation, root| [ equation, root.to_s ] }),
    explanation: Explain.build(
      idea: "Всяко уравнение се решава на две стъпки: махаме свободния член, после делим на коефициента.",
      steps: pairs.map { |equation, root| "#{equation} → x = #{root}" },
      answer: pairs.map { |equation, root| "#{equation}: x = #{root}" }.join("; "),
      check: "Заместването връща дясната страна във всяко от уравненията.",
      watch: "Голям свободен член не значи голям корен — важно е и колко е коефициентът."
    )
  )
end

Authoring.family "match.sequence_next", topic: "Геометрична прогресия", area: "interactive_algebra", variants: 11,
                 rungs: [ 1380, 1470, 1560, 1650, 1740, 1830 ] do |c|
  pairs = 3.times.map do
    first = c.int(c.by_level([ 1..4, 1..6, 2..9, 2..15, 3..30, 4..60 ]))
    ratio = c.int(c.by_level([ 2..2, 2..3, 2..3, 2..4, 3..5, 3..6 ]))
    terms = (0..3).map { |i| first * (ratio**i) }
    [ terms.join(", "), first * (ratio**4) ]
  end
  raise Authoring::Duplicate if pairs.map(&:last).uniq.size < 3

  c.q(
    text: "Свържи всяка от прогресиите #{pairs.map { |terms, _| terms.split(', ').first(3).join(', ') }.join(' | ')} " \
          "със следващия ѝ член.",
    widget: WidgetKit.matcher(pairs.map { |terms, nxt| [ terms, nxt.to_s ] }),
    explanation: Explain.build(
      idea: "Намираме частното (всеки член делен на предишния) и умножаваме последния по него.",
      steps: pairs.map do |terms, nxt|
        values = terms.split(", ").map(&:to_i)
        "#{terms}: q = #{values[1] / values[0]}, следващ #{values.last} · #{values[1] / values[0]} = #{nxt}"
      end,
      answer: pairs.map { |terms, nxt| "#{terms} → #{nxt}" }.join("; "),
      check: "Частното е едно и също между всеки два съседни члена.",
      watch: "При геометрична прогресия се умножава, а не се прибавя."
    )
  )
end

# ------------------------------------------------------------------ Таблици ---

Authoring.family "table.linear_values", topic: "Линейна функция", area: "interactive_algebra", variants: 11,
                 rungs: [ 1250, 1340, 1430, 1520, 1610, 1700 ] do |c|
  a = c.int(c.by_level([ 2..4, 2..6, -6..8, -9..9, -15..15, -25..25 ]))
  raise Authoring::Duplicate if a.zero?

  b = c.int(c.by_level([ 0..6, -6..10, -12..16, -20..30, -40..60, -90..120 ]))
  inputs = c.sample((-4..6).to_a, 4).sort
  outputs = inputs.map { |x| (a * x) + b }
  hidden = c.sample((0..3).to_a, c.by_level([ 2, 2, 2, 3, 3, 3 ]))
  rows = [ inputs.map { |x| Num.bg(x) }, outputs.each_with_index.map { |value, i| hidden.include?(i) ? nil : Num.bg(value) } ]

  c.q(
    text: "Попълни таблицата за функцията f(x) = #{Num.linear(a, b)}.",
    widget: WidgetKit.grid_fill(rows: rows, answers: [ inputs.map { |x| Num.bg(x) }, outputs.map { |value| Num.ans(value) } ],
                                row_headers: [ "x", "f(x)" ]),
    explanation: Explain.build(
      idea: "За всяко x умножаваме по #{Num.bg(a)} и прибавяме #{Num.bg(b)}.",
      steps: hidden.sort.map { |i| "f(#{Num.bg(inputs[i])}) = #{Num.bg(a)} · #{Num.bg(inputs[i])} #{b.negative? ? Num::MINUS : '+'} #{b.abs} = #{Num.bg(outputs[i])}" },
      answer: hidden.sort.map { |i| Num.bg(outputs[i]) }.join(", "),
      check: "При стъпка 1 по x стойността се променя с #{Num.bg(a)} — таблицата трябва да го показва.",
      watch: "Отрицателен коефициент обръща посоката: по-голямо x дава по-малко f(x)."
    )
  )
end

Authoring.family "table.sequence_terms", topic: "Аритметична прогресия", area: "interactive_algebra", variants: 11,
                 rungs: [ 1300, 1390, 1480, 1570, 1660, 1750 ] do |c|
  first = c.int(c.by_level([ 1..10, 1..20, -10..30, -20..60, -40..120, -80..250 ]))
  step = c.int(c.by_level([ 2..6, 2..9, 3..12, 4..20, 5..35, 6..70 ]))
  terms = (0..5).map { |i| first + (i * step) }
  hidden = c.sample((1..5).to_a, c.by_level([ 2, 2, 3, 3, 3, 4 ]))
  rows = [ (1..6).map { |n| "a#{n}" }, terms.each_with_index.map { |value, i| hidden.include?(i) ? nil : Num.bg(value) } ]

  c.q(
    text: "Аритметична прогресия започва с #{Num.bg(first)} и има разлика #{step}. Попълни липсващите членове.",
    widget: WidgetKit.grid_fill(rows: rows, answers: [ (1..6).map { |n| "a#{n}" }, terms.map { |value| Num.ans(value) } ]),
    explanation: Explain.build(
      idea: "Всеки следващ член е предишният плюс разликата #{step}.",
      steps: hidden.sort.first(3).map { |i| "a#{i + 1} = #{Num.bg(terms[i - 1])} + #{step} = #{Num.bg(terms[i])}" },
      answer: hidden.sort.map { |i| Num.bg(terms[i]) }.join(", "),
      check: "a₆ = #{Num.bg(first)} + 5 · #{step} = #{Num.bg(terms.last)}.",
      watch: "Разликата се прибавя веднъж на стъпка — не се умножава по номера на члена."
    )
  )
end

# -------------------------------------------------- Координатна система ---

Authoring.family "plot.line_points", topic: "Линейна функция", area: "interactive_algebra", variants: 11,
                 rungs: [ 1300, 1390, 1480, 1570, 1660, 1750 ] do |c|
  a = c.pick(c.by_level([ [ 1, 2 ], [ 1, 2, -1 ], [ 1, 2, -2 ], [ 1, 2, 3, -2 ], [ 2, 3, -3 ], [ 1, 2, 3, -3 ] ]))
  b = c.int(-3..3)
  xs = c.sample((-4..4).to_a.select { |x| ((a * x) + b).between?(-5, 5) }, 2)
  raise Authoring::Duplicate if xs.size < 2

  points = xs.map { |x| [ x, (a * x) + b ] }

  c.q(
    text: "Постави в координатната система двете точки от графиката на y = #{Num.linear(a, b)} " \
          "с абсциси #{Num.bg(xs[0])} и #{Num.bg(xs[1])}.",
    widget: WidgetKit.plot(points: points),
    explanation: Explain.build(
      idea: "Заместваме всяка абсциса във формулата и получаваме ординатата на точката.",
      steps: points.map { |x, y| "x = #{Num.bg(x)} → y = #{Num.bg(a)} · #{Num.bg(x)} #{b.negative? ? Num::MINUS : '+'} #{b.abs} = #{Num.bg(y)}" },
      answer: points.map { |x, y| "(#{Num.bg(x)}; #{Num.bg(y)})" }.join(" и "),
      check: "Двете точки лежат на една права с наклон #{Num.bg(a)}.",
      watch: "Първата координата е по хоризонталната ос, втората — по вертикалната."
    )
  )
end

Authoring.family "plot.intercepts", topic: "Линейна функция", area: "interactive_algebra", variants: 3,
                 rungs: [ 1400, 1490, 1580, 1670, 1760, 1850 ] do |c|
  a = c.pick([ 1, 2, -1, -2, 3, -3 ])
  zero_x = c.int(-4..4)
  raise Authoring::Duplicate if zero_x.zero?

  b = -a * zero_x
  raise Authoring::Duplicate unless b.between?(-5, 5)

  c.q(
    text: "Правата y = #{Num.linear(a, b)} пресича осите в две точки. Постави ги в координатната система.",
    widget: WidgetKit.plot(points: [ [ zero_x, 0 ], [ 0, b ] ]),
    explanation: Explain.build(
      idea: "С оста x правата се среща там, където y = 0; с оста y — там, където x = 0.",
      steps: [
        "y = 0: #{Num.lead(a)} #{Num.term(b, '')} = 0, значи x = #{Num.bg(zero_x)} — точката (#{Num.bg(zero_x)}; 0).",
        "x = 0: y = #{Num.bg(b)} — точката (0; #{Num.bg(b)})."
      ],
      answer: "(#{Num.bg(zero_x)}; 0) и (0; #{Num.bg(b)})",
      check: "И двете точки удовлетворяват y = #{Num.linear(a, b)}.",
      watch: "Свободният член се чете направо като пресечна точка с оста y."
    )
  )
end

Authoring.family "plot.system_solution", topic: "Системи уравнения", area: "interactive_algebra", variants: 11,
                 rungs: [ 1500, 1590, 1680, 1770, 1860, 1950 ] do |c|
  x = c.int(-4..4)
  y = c.int(-4..4)
  a1 = c.pick([ 1, -1, 2, -2 ])
  a2 = c.pick([ 1, -1, 2, -2 ])
  raise Authoring::Duplicate if a1 == a2

  b1 = y - (a1 * x)
  b2 = y - (a2 * x)
  raise Authoring::Duplicate unless b1.between?(-6, 6) && b2.between?(-6, 6)

  c.q(
    text: "Двете прави y = #{Num.linear(a1, b1)} и y = #{Num.linear(a2, b2)} се пресичат в една точка. " \
          "Постави я в координатната система.",
    widget: WidgetKit.plot(points: [ [ x, y ] ]),
    explanation: Explain.build(
      idea: "Пресечната точка е решението на системата — приравняваме двата израза за y.",
      steps: [
        "#{Num.linear(a1, b1)} = #{Num.linear(a2, b2)}.",
        "#{Num.lead(a1 - a2)} = #{Num.bg(b2 - b1)}, значи x = #{Num.bg(x)}.",
        "y = #{Num.bg(a1)} · #{Num.bg(x)} #{b1.negative? ? Num::MINUS : '+'} #{b1.abs} = #{Num.bg(y)}."
      ],
      answer: "(#{Num.bg(x)}; #{Num.bg(y)})",
      check: "Точката лежи и на двете прави.",
      watch: "Пресечната точка е една — прави с различни наклони винаги се пресичат точно веднъж."
    )
  )
end

# --------------------------------------------------------------- Групиране ---

Authoring.family "sortbins.roots_count", topic: "Квадратни уравнения", area: "interactive_algebra", variants: 11,
                 rungs: [ 1520, 1610, 1700, 1790, 1880, 1970 ] do |c|
  items = []
  10.times do
    a = c.int(1..c.by_level([ 2, 3, 4, 5, 8, 12 ]))
    b = c.int(1..c.by_level([ 6, 10, 16, 25, 40, 80 ]))
    cc = c.int(1..c.by_level([ 8, 16, 30, 50, 90, 200 ]))
    discriminant = (b * b) - (4 * a * cc)
    bin = discriminant.positive? ? "two" : (discriminant.zero? ? "one" : "none")
    items << [ "#{Num.monomial(a, 'x²')} + #{b}x + #{cc} = 0", bin ]
  end
  chosen = items.uniq(&:first).first(4)
  raise Authoring::Duplicate if chosen.size < 4 || chosen.map(&:last).uniq.size < 2

  bins = [ [ "two", "два корена" ], [ "none", "няма корени" ] ]
  raise Authoring::Duplicate unless chosen.all? { |_, bin| %w[two none].include?(bin) }
  raise Authoring::Duplicate unless chosen.map(&:last).uniq.sort == %w[none two]

  c.q(
    text: "Разпредели уравненията #{chosen.map(&:first).join('; ')} според броя на реалните им корени.",
    widget: WidgetKit.categorize(bins: bins, items: chosen.each_with_index.map { |(label, bin), i| [ "q#{i}", label, bin ] }),
    explanation: Explain.build(
      idea: "Броят реални корени се чете от дискриминантата D = b² − 4ac.",
      steps: chosen.map do |label, bin|
        numbers = label.scan(/\d+/).map(&:to_i)
        "#{label}: D = #{bin == 'two' ? 'положителна' : 'отрицателна'} → #{bin == 'two' ? 'два корена' : 'няма реални корени'}."
      end,
      answer: bins.map { |id, name| "#{name}: #{chosen.select { |_, bin| bin == id }.map(&:first).join('; ')}" }.join(" | "),
      check: "Уравнение с отрицателна дискриминанта има графика, която не докосва оста x.",
      watch: "Дискриминантата се смята с знаците на коефициентите — не само с абсолютните им стойности."
    )
  )
end

Authoring.family "sortbins.function_direction", topic: "Линейна функция", area: "interactive_algebra", variants: 11,
                 rungs: [ 1250, 1340, 1430, 1520, 1610, 1700 ] do |c|
  items = []
  8.times do
    a = c.int(c.by_level([ -5..5, -8..8, -12..12, -20..20, -40..40, -90..90 ]))
    next if a.zero?

    b = c.int(-12..12)
    items << [ "y = #{Num.linear(a, b)}", a.positive? ? "up" : "down" ]
  end
  chosen = items.uniq(&:first).first(4)
  raise Authoring::Duplicate if chosen.size < 4 || chosen.map(&:last).uniq.size < 2

  c.q(
    text: "Разпредели функциите #{chosen.map(&:first).join(', ')} на растящи и намаляващи.",
    widget: WidgetKit.categorize(bins: [ [ "up", "растяща" ], [ "down", "намаляваща" ] ],
                                 items: chosen.each_with_index.map { |(label, bin), i| [ "f#{i}", label, bin ] }),
    explanation: Explain.build(
      idea: "Знакът на ъгловия коефициент решава: положителен — растяща, отрицателен — намаляваща.",
      steps: chosen.map { |label, bin| "#{label} → #{bin == 'up' ? 'растяща' : 'намаляваща'}." },
      answer: chosen.map { |label, bin| "#{label}: #{bin == 'up' ? 'растяща' : 'намаляваща'}" }.join("; "),
      check: "При растяща функция по-голямо x дава по-голямо y.",
      watch: "Свободният член мести правата нагоре или надолу, но не променя посоката ѝ."
    )
  )
end
