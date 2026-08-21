# Функции: линейна, квадратна, показателна, логаритмична.

# ----------------------------------------------------------- Линейна функция ---

Authoring.family "lin.evaluate", topic: "Линейна функция", area: "functions",
                 rungs: [ 1230, 1320, 1410, 1500, 1590, 1690 ] do |c|
  a = c.int(c.by_level([ 2..5, 2..8, -6..9, -9..12, -15..20, -30..40 ]))
  b = c.int(c.by_level([ 1..8, -6..12, -12..20, -20..35, -40..70, -90..150 ]))
  x = c.int(c.by_level([ 1..6, -4..8, -8..12, -12..20, -20..40, -40..90 ]))
  raise Authoring::Duplicate if a.zero?

  value = (a * x) + b

  c.q(
    text: "Дадена е функцията f(x) = #{Num.linear(a, b)}. Колко е f(#{Num.bg(x)})?",
    answer: Num.ans(value),
    explanation: Explain.build(
      idea: "Заместваме x със стойността и пресмятаме, като спазваме знаците.",
      steps: [
        "f(#{Num.bg(x)}) = #{Num.bg(a)} · #{Num.signed(x)} #{b.negative? ? Num::MINUS : '+'} #{b.abs}.",
        "#{Num.bg(a)} · #{Num.bg(x)} = #{Num.bg(a * x)}.",
        "#{Num.bg(a * x)} #{b.negative? ? Num::MINUS : '+'} #{b.abs} = #{Num.bg(value)}."
      ],
      answer: "f(#{Num.bg(x)}) = #{Num.bg(value)}",
      check: "Съседна стойност: f(#{Num.bg(x + 1)}) = #{Num.bg(value + a)} — разликата е точно коефициентът #{Num.bg(a)}.",
      watch: a.negative? ? "Отрицателният коефициент обръща знака при умножение." : "Свободният член се добавя след умножението."
    )
  )
end

Authoring.family "lin.find_x", topic: "Линейна функция", area: "functions",
                 rungs: [ 1280, 1370, 1460, 1550, 1640, 1740 ] do |c|
  a = c.int(c.by_level([ 2..5, 2..8, 2..10, -9..12, -15..20, -30..40 ]))
  raise Authoring::Duplicate if a.zero?

  b = c.int(c.by_level([ 1..8, -6..12, -12..20, -20..35, -40..70, -90..150 ]))
  x = c.int(c.by_level([ 1..6, -4..8, -8..12, -12..20, -20..40, -40..90 ]))
  value = (a * x) + b

  c.q(
    text: "За функцията f(x) = #{Num.linear(a, b)} намери x, за което f(x) = #{Num.bg(value)}.",
    answer: Num.ans(x),
    explanation: Explain.build(
      idea: "Задаваме уравнение и го решаваме спрямо x.",
      steps: [
        "#{Num.linear(a, b)} = #{Num.bg(value)}.",
        "#{Num.lead(a)} = #{Num.bg(value)} #{b.negative? ? '+' : Num::MINUS} #{b.abs} = #{Num.bg(a * x)}.",
        "x = #{Num.bg(a * x)} : #{Num.bg(a)} = #{Num.bg(x)}."
      ],
      answer: "x = #{Num.bg(x)}",
      check: "f(#{Num.bg(x)}) = #{Num.bg(a)} · #{Num.bg(x)} #{b.negative? ? Num::MINUS : '+'} #{b.abs} = #{Num.bg(value)}.",
      watch: "Свободният член се премества с обратен знак."
    )
  )
end

Authoring.family "lin.slope_two_points", topic: "Линейна функция", area: "functions",
                 rungs: [ 1350, 1440, 1530, 1620, 1710, 1810 ] do |c|
  a = c.int(c.by_level([ 1..4, -5..6, -8..8, -12..12, -20..20, -40..40 ]))
  raise Authoring::Duplicate if a.zero?

  b = c.int(c.by_level([ 0..6, -6..10, -12..15, -20..30, -40..60, -90..120 ]))
  x1 = c.int(-8..8)
  gap = c.int(1..6)
  x2 = x1 + gap
  y1 = (a * x1) + b
  y2 = (a * x2) + b

  c.q(
    text: "През точките A(#{Num.bg(x1)}; #{Num.bg(y1)}) и B(#{Num.bg(x2)}; #{Num.bg(y2)}) минава права. " \
          "Колко е ъгловият ѝ коефициент?",
    answer: Num.ans(a),
    explanation: Explain.build(
      idea: "Ъгловият коефициент е отношението на изменението по y към изменението по x.",
      steps: [
        "Δy = #{Num.bg(y2)} − #{Num.bg(y1)} = #{Num.bg(y2 - y1)}.",
        "Δx = #{Num.bg(x2)} − #{Num.bg(x1)} = #{gap}.",
        "k = #{Num.bg(y2 - y1)} : #{gap} = #{Num.bg(a)}."
      ],
      answer: "k = #{Num.bg(a)}",
      check: "Правата е y = #{Num.linear(a, b)}; и двете точки я удовлетворяват.",
      watch: "Редът на точките не е важен, стига числителят и знаменателят да се вземат в един и същ ред."
    )
  )
end

Authoring.family "lin.zero", topic: "Линейна функция", area: "functions",
                 rungs: [ 1300, 1390, 1480, 1570, 1660, 1760 ] do |c|
  a = c.int(c.by_level([ 2..5, 2..8, -8..9, -12..12, -20..20, -40..40 ]))
  raise Authoring::Duplicate if a.zero?

  x = c.int(c.by_level([ 1..6, -5..8, -9..12, -15..20, -30..40, -60..90 ]))
  b = -a * x

  c.q(
    text: "Намери нулата на функцията f(x) = #{Num.linear(a, b)} (стойността на x, за която f(x) = 0).",
    answer: Num.ans(x),
    explanation: Explain.build(
      idea: "Нулата на функция е абсцисата на пресечната точка с оста x — решаваме f(x) = 0.",
      steps: [
        "#{Num.linear(a, b)} = 0.",
        "#{Num.lead(a)} = #{Num.bg(-b)}.",
        "x = #{Num.bg(-b)} : #{Num.bg(a)} = #{Num.bg(x)}."
      ],
      answer: "x = #{Num.bg(x)}",
      check: "f(#{Num.bg(x)}) = #{Num.bg(a)} · #{Num.bg(x)} #{b.negative? ? Num::MINUS : '+'} #{b.abs} = 0.",
      watch: "Нулата на функцията е стойност на x, а не на y."
    )
  )
end

Authoring.family "lin.taxi_word", topic: "Линейна функция", area: "functions",
                 rungs: [ 1250, 1340, 1430, 1520, 1610, 1710 ] do |c|
  start_fee = c.int(c.by_level([ 1..4, 2..6, 2..8, 3..12, 4..20, 5..40 ]))
  per_km = c.int(c.by_level([ 1..3, 1..4, 2..5, 2..8, 3..12, 4..20 ]))
  km = c.int(c.by_level([ 2..8, 3..15, 4..25, 5..40, 8..90, 10..200 ]))
  total = start_fee + (per_km * km)
  ask_km = c.level >= 3 && c.coin

  c.q(
    text: ask_km ? "Такси взема #{start_fee} лв. начална такса и по #{per_km} лв. на километър. Пътуване струва #{total} лв. Колко километра е било?" :
                   "Такси взема #{start_fee} лв. начална такса и по #{per_km} лв. на километър. Колко лева струва пътуване от #{km} км?",
    answer: Num.ans(ask_km ? km : total),
    explanation: Explain.build(
      idea: "Цената е линейна функция на разстоянието: f(x) = #{per_km}x + #{start_fee}.",
      steps: ask_km ?
        [ "#{per_km}x + #{start_fee} = #{total}.",
          "#{per_km}x = #{total} − #{start_fee} = #{per_km * km}.",
          "x = #{per_km * km} : #{per_km} = #{km} км." ] :
        [ "Пътят струва #{per_km} · #{km} = #{per_km * km} лв.",
          "С таксата: #{per_km * km} + #{start_fee} = #{total} лв." ],
      answer: ask_km ? "#{km} км" : "#{total} лв.",
      check: "#{per_km} · #{km} + #{start_fee} = #{total} лв.",
      watch: "Началната такса се плаща веднъж — тя не се умножава по километрите."
    )
  )
end

Authoring.family "lin.parallel", topic: "Линейна функция", area: "functions",
                 rungs: [ 1400, 1490, 1580, 1670, 1760, 1860 ] do |c|
  a = c.int(c.by_level([ 2..5, -6..6, -9..9, -12..12, -20..20, -40..40 ]))
  raise Authoring::Duplicate if a.zero?

  b = c.int(-12..12)
  new_b = c.int(-12..12)
  raise Authoring::Duplicate if b == new_b

  correct = "y = #{Num.linear(a, new_b)}"

  c.q(
    text: "Коя от правите е успоредна на y = #{Num.linear(a, b)}?",
    options: c.options(correct, "y = #{Num.linear(-a, new_b)}", "y = #{Num.linear(a + 1, b)}", "y = #{Num.linear(1, b)}"),
    answer: correct,
    explanation: Explain.build(
      idea: "Две прави са успоредни точно когато имат равни ъглови коефициенти и различни свободни членове.",
      steps: [
        "Ъгловият коефициент на дадената права е #{Num.bg(a)}.",
        "Търсим права със същия коефициент, но с друг свободен член: #{correct}."
      ],
      answer: correct,
      check: "Двете прави никога не се пресичат, защото #{Num.linear(a, b)} = #{Num.linear(a, new_b)} води до #{Num.bg(b)} = #{Num.bg(new_b)}, което е невярно.",
      watch: "Права със същия свободен член, но друг коефициент, се пресича с дадената."
    )
  )
end

# --------------------------------------------------------- Квадратна функция ---

Authoring.family "quadf.value", topic: "Квадратна функция", area: "functions",
                 rungs: [ 1420, 1510, 1600, 1690, 1780, 1880 ] do |c|
  a = c.int(c.by_level([ 1..2, 1..3, -3..4, -5..5, -8..8, -12..12 ]))
  raise Authoring::Duplicate if a.zero?

  b = c.int(c.by_level([ -4..4, -6..6, -9..9, -14..14, -25..25, -40..40 ]))
  cc = c.int(c.by_level([ -5..5, -8..8, -12..12, -20..20, -40..40, -70..70 ]))
  x = c.int(c.by_level([ 1..3, -3..4, -5..5, -7..7, -10..10, -15..15 ]))
  value = (a * x * x) + (b * x) + cc

  c.q(
    text: "Дадена е функцията f(x) = #{Num.quadratic(a, b, cc)}. Колко е f(#{Num.bg(x)})?",
    answer: Num.ans(value),
    explanation: Explain.build(
      idea: "Заместваме и спазваме реда: първо квадратът, после умноженията, накрая събиранията.",
      steps: [
        "x² = (#{Num.bg(x)})² = #{x * x}.",
        "#{Num.bg(a)} · #{x * x} = #{Num.bg(a * x * x)}, #{Num.bg(b)} · #{Num.bg(x)} = #{Num.bg(b * x)}.",
        "#{Num.bg(a * x * x)} + (#{Num.bg(b * x)}) + (#{Num.bg(cc)}) = #{Num.bg(value)}."
      ],
      answer: "f(#{Num.bg(x)}) = #{Num.bg(value)}",
      check: "f(0) = #{Num.bg(cc)} — свободният член винаги е стойността при x = 0.",
      watch: "(#{Num.bg(x)})² = #{x * x} — квадратът е положителен дори при отрицателно x."
    )
  )
end

Authoring.family "quadf.vertex", topic: "Квадратна функция", area: "functions",
                 rungs: [ 1500, 1590, 1680, 1770, 1860, 1960 ] do |c|
  a = c.int(c.by_level([ 1..2, 1..3, -3..4, -4..5, -6..8, -10..12 ]))
  raise Authoring::Duplicate if a.zero?

  vertex_x = c.int(c.by_level([ -3..3, -5..5, -7..7, -10..10, -15..15, -25..25 ]))
  b = -2 * a * vertex_x
  cc = c.int(-15..15)
  ask_y = c.level >= 2 && c.coin
  vertex_y = (a * vertex_x * vertex_x) + (b * vertex_x) + cc

  c.q(
    text: "Намери #{ask_y ? 'ординатата' : 'абсцисата'} на върха на параболата y = #{Num.quadratic(a, b, cc)}.",
    answer: Num.ans(ask_y ? vertex_y : vertex_x),
    explanation: Explain.build(
      idea: "Абсцисата на върха е x₀ = −b : (2a); ординатата се получава чрез заместване.",
      steps: [
        "x₀ = #{Num.bg(-b)} : (2 · #{Num.bg(a)}) = #{Num.bg(-b)} : #{Num.bg(2 * a)} = #{Num.bg(vertex_x)}.",
        ask_y ? "y₀ = f(#{Num.bg(vertex_x)}) = #{Num.bg(a)} · #{vertex_x * vertex_x} + #{Num.bg(b)} · #{Num.bg(vertex_x)} + #{Num.bg(cc)} = #{Num.bg(vertex_y)}." : nil
      ].compact,
      answer: ask_y ? "y₀ = #{Num.bg(vertex_y)}" : "x₀ = #{Num.bg(vertex_x)}",
      check: "Параболата е симетрична спрямо x = #{Num.bg(vertex_x)}: f(#{Num.bg(vertex_x - 1)}) = f(#{Num.bg(vertex_x + 1)}) = #{Num.bg((a * (vertex_x + 1)**2) + (b * (vertex_x + 1)) + cc)}.",
      watch: a.positive? ? "При a > 0 върхът е най-ниската точка — функцията има минимум." : "При a < 0 върхът е най-високата точка — функцията има максимум."
    )
  )
end

Authoring.family "quadf.max_area", topic: "Квадратна функция", area: "functions",
                 rungs: [ 1620, 1710, 1800, 1890, 1980, 2060 ] do |c|
  half = c.int(c.by_level([ 3..10, 4..16, 6..25, 8..40, 12..80, 15..150 ]))
  perimeter = 4 * half
  area = half * half

  c.q(
    text: "С ограда от #{perimeter} м се загражда правоъгълен двор. Колко квадратни метра е най-голямата възможна площ?",
    answer: Num.ans(area),
    explanation: Explain.build(
      idea: "При постоянен периметър площта е квадратна функция на едната страна и има максимум във върха си.",
      steps: [
        "Ако едната страна е x, другата е #{2 * half} − x, значи S(x) = x(#{2 * half} − x) = −x² + #{2 * half}x.",
        "Върхът е при x = #{2 * half} : 2 = #{half} м.",
        "S(#{half}) = #{half} · #{half} = #{area} м²."
      ],
      answer: "#{area} м²",
      check: "Опит със страни #{half - 1} и #{half + 1}: #{(half - 1) * (half + 1)} м² — по-малко от #{area} м².",
      watch: "Най-голяма площ при даден периметър дава квадратът — това е общото правило зад задачата."
    )
  )
end

Authoring.family "quadf.roots_count", topic: "Квадратна функция", area: "functions",
                 rungs: [ 1550, 1640, 1730, 1820, 1910, 2000 ] do |c|
  a = c.int(1..c.by_level([ 2, 3, 4, 6, 9, 12 ]))
  b = c.int(c.by_level([ 1..6, 2..10, 3..16, 4..25, 5..40, 6..80 ]))
  cc = c.int(c.by_level([ 1..10, 1..18, 2..30, 2..50, 3..90, 4..200 ]))
  discriminant = (b * b) - (4 * a * cc)
  answer = discriminant.positive? ? "две" : (discriminant.zero? ? "една" : "нула")

  c.q(
    text: "В колко точки параболата y = #{Num.quadratic(a, b, cc)} пресича абсцисната ос?",
    options: c.options(answer, "две", "една", "нула"),
    answer: answer,
    explanation: Explain.build(
      idea: "Пресечните точки с оста x са реалните корени на уравнението f(x) = 0 — броят им зависи от дискриминантата.",
      steps: [
        "D = #{b}² − 4 · #{a} · #{cc} = #{b * b} − #{4 * a * cc} = #{Num.bg(discriminant)}.",
        discriminant.positive? ? "D > 0 → две пресечни точки." : (discriminant.zero? ? "D = 0 → парабола, допираща оста." : "D < 0 → параболата минава изцяло над оста.")
      ],
      answer: "#{answer} #{answer == 'една' ? 'точка' : 'точки'}",
      check: "Клоните сочат нагоре (a = #{a} > 0), а върхът е на височина #{Num.dec(Rational(-discriminant, 4 * a), 2).sub('-', Num::MINUS)}.",
      watch: "Пресичането с оста y е винаги точно едно (в точката (0; #{cc})) — въпросът е за оста x."
    )
  )
end

# ------------------------------------------------------- Показателна функция ---

Authoring.family "exp.evaluate", topic: "Показателна функция", area: "functions",
                 rungs: [ 1470, 1560, 1650, 1740, 1830, 1930 ] do |c|
  base = c.int(c.by_level([ 2..3, 2..4, 2..5, 2..6, 2..8, 2..10 ]))
  x = c.int(c.by_level([ 2..4, 2..5, 3..6, 3..7, 4..8, 5..9 ]))
  value = base**x
  raise Authoring::Duplicate if value > 500_000

  c.q(
    text: "Дадена е функцията f(x) = #{base}#{Num.sup('x')}. Колко е f(#{x})?",
    answer: Num.ans(value),
    explanation: Explain.build(
      idea: "Показателната функция повдига основата на степен, равна на аргумента.",
      steps: [
        "f(#{x}) = #{Num.power(base, x)} = #{([ base ] * x).join(' · ')}.",
        "= #{value}."
      ],
      answer: Num.ans(value),
      check: "f(#{x - 1}) = #{base**(x - 1)}, а f(#{x}) е #{base} пъти повече: #{base**(x - 1)} · #{base} = #{value}.",
      watch: "При всяка стъпка по x стойността се умножава по #{base}, а не се увеличава с #{base}."
    )
  )
end

Authoring.family "exp.solve", topic: "Показателна функция", area: "functions",
                 rungs: [ 1520, 1610, 1700, 1790, 1880, 1980 ] do |c|
  base = c.int(c.by_level([ 2..3, 2..4, 2..5, 2..6, 2..7, 2..9 ]))
  x = c.int(c.by_level([ 2..4, 2..5, 3..6, 3..7, 4..8, 4..9 ]))
  value = base**x
  raise Authoring::Duplicate if value > 500_000

  c.q(
    text: "Реши уравнението #{base}#{Num.sup('x')} = #{value}.",
    answer: Num.ans(x),
    explanation: Explain.build(
      idea: "Записваме дясната страна като степен на същата основа; тогава показателите се приравняват.",
      steps: [
        "#{value} = #{Num.power(base, x)}.",
        "#{base}#{Num.sup('x')} = #{Num.power(base, x)} дава x = #{x}."
      ],
      answer: "x = #{x}",
      check: "#{Num.power(base, x)} = #{value} — заместването е вярно.",
      watch: "Показателната функция е строго растяща при основа над 1, затова решението е единствено."
    )
  )
end

Authoring.family "exp.doubling_word", topic: "Показателна функция", area: "functions",
                 rungs: [ 1500, 1590, 1680, 1770, 1860, 1960 ] do |c|
  start = c.int(c.by_level([ 1..5, 2..10, 3..20, 5..40, 8..100, 10..250 ]))
  factor = c.int(c.by_level([ 2..2, 2..3, 2..3, 2..4, 3..5, 3..6 ]))
  steps_count = c.int(c.by_level([ 2..4, 2..5, 3..6, 3..7, 4..8, 4..9 ]))
  final = start * (factor**steps_count)
  raise Authoring::Duplicate if final > 5_000_000

  c.q(
    text: "Бактериите в проба са #{start} и се увеличават #{factor} пъти на всеки час. " \
          "Колко ще бъдат след #{steps_count} часа?",
    answer: Num.ans(final),
    explanation: Explain.build(
      idea: "Многократно умножение по един и същ множител е степен: N = N₀ · q на степен броя периоди.",
      steps: [
        "След 1 час: #{start} · #{factor} = #{start * factor}.",
        "След #{steps_count} часа: #{start} · #{Num.power(factor, steps_count)} = #{start} · #{factor**steps_count} = #{final}."
      ],
      answer: "#{final} бактерии",
      check: "Обратно: #{final} : #{factor**steps_count} = #{start} — началният брой.",
      watch: "Растежът не е с #{factor} на час, а #{factor} пъти — затова числата растат много по-бързо."
    )
  )
end

Authoring.family "exp.compound_interest", topic: "Показателна функция", area: "functions",
                 rungs: [ 1600, 1690, 1780, 1870, 1960, 2050 ] do |c|
  rate = c.pick([ 10, 20, 25, 50 ])
  years = c.by_level([ 2, 2, 2, 3, 3, 4 ])
  # A round principal keeps the compounded amount a whole number of leva.
  principal = c.int(c.by_level([ 1..6, 2..10, 3..20, 4..40, 6..90, 8..200 ])) * 10_000
  factor = Rational(100 + rate, 100)
  final = principal * (factor**years)
  raise Authoring::Duplicate unless final.denominator == 1

  c.q(
    text: "Влог от #{principal} лв. расте с #{rate}% годишно, като лихвата се начислява върху натрупаната сума. " \
          "Колко лева има след #{years} години?",
    answer: Num.ans(final),
    explanation: Explain.build(
      idea: "Сложната лихва умножава сумата всяка година с един и същ множител: 1 + #{rate}/100 = #{Num.dec(factor, 2)}.",
      steps: [
        "След 1 година: #{principal} · #{Num.dec(factor, 2)} = #{Num.ans(principal * factor)} лв.",
        "След #{years} години: #{principal} · #{Num.dec(factor, 2)}#{Num.sup(years)} = #{Num.ans(final)} лв."
      ],
      answer: "#{Num.ans(final)} лв.",
      check: "При проста лихва щеше да има #{principal + (principal * rate * years / 100)} лв. — сложната дава повече.",
      watch: "Лихвата се начислява и върху вече натрупаната лихва — затова е степен, а не умножение по #{years}."
    )
  )
end

# ----------------------------------------------------- Логаритмична функция ---

Authoring.family "log.evaluate", topic: "Логаритмична функция", area: "functions",
                 rungs: [ 1530, 1620, 1710, 1800, 1890, 1990 ] do |c|
  base = c.int(c.by_level([ 2..3, 2..4, 2..5, 2..6, 2..8, 2..10 ]))
  exponent = c.int(c.by_level([ 2..4, 2..5, 2..6, 3..7, 3..8, 4..9 ]))
  value = base**exponent
  raise Authoring::Duplicate if value > 500_000

  c.q(
    text: "Пресметни log#{Num.sub_digits(base)} #{value}.",
    answer: Num.ans(exponent),
    explanation: Explain.build(
      idea: "Логаритъмът отговаря на въпроса: на каква степен трябва да се повдигне основата, за да се получи числото.",
      steps: [
        "Търсим x, за което #{base}#{Num.sup('x')} = #{value}.",
        "#{Num.power(base, exponent)} = #{value}, значи x = #{exponent}."
      ],
      answer: Num.ans(exponent),
      check: "#{base} на степен #{exponent} наистина е #{value}.",
      watch: "Логаритъмът е показател на степен — не е деление на числото на основата."
    )
  )
end

Authoring.family "log.solve_argument", topic: "Логаритмична функция", area: "functions",
                 rungs: [ 1580, 1670, 1760, 1850, 1940, 2040 ] do |c|
  base = c.int(c.by_level([ 2..3, 2..4, 2..5, 2..6, 2..7, 2..9 ]))
  exponent = c.int(c.by_level([ 2..4, 2..5, 2..6, 3..7, 3..8, 3..9 ]))
  value = base**exponent
  raise Authoring::Duplicate if value > 500_000

  c.q(
    text: "Реши уравнението log#{Num.sub_digits(base)} x = #{exponent}.",
    answer: Num.ans(value),
    explanation: Explain.build(
      idea: "Логаритмичното уравнение се пренаписва като степен: log_a x = n значи x = aⁿ.",
      steps: [
        "x = #{Num.power(base, exponent)}.",
        "#{Num.power(base, exponent)} = #{value}."
      ],
      answer: "x = #{value}",
      check: "log#{Num.sub_digits(base)} #{value} = #{exponent}, защото #{Num.power(base, exponent)} = #{value}.",
      watch: "Аргументът на логаритъм трябва да е положителен — тук #{value} > 0, всичко е наред."
    )
  )
end

Authoring.family "log.product_rule", topic: "Логаритмична функция", area: "functions",
                 rungs: [ 1650, 1740, 1830, 1920, 2010, 2100 ] do |c|
  base = c.int(c.by_level([ 2..2, 2..3, 2..3, 2..4, 2..5, 2..6 ]))
  m = c.int(1..c.by_level([ 3, 4, 5, 6, 7, 8 ]))
  n = c.int(1..c.by_level([ 3, 4, 5, 6, 7, 8 ]))
  first = base**m
  second = base**n
  divide = c.level >= 2 && c.coin && m > n
  result = divide ? m - n : m + n

  c.q(
    text: "Пресметни log#{Num.sub_digits(base)} #{first} #{divide ? Num::MINUS : '+'} log#{Num.sub_digits(base)} #{second}.",
    answer: Num.ans(result),
    explanation: Explain.build(
      idea: divide ? "Разлика на логаритми с една основа е логаритъм от частното." :
                     "Сбор на логаритми с една основа е логаритъм от произведението.",
      steps: [
        "log#{Num.sub_digits(base)} #{first} = #{m} и log#{Num.sub_digits(base)} #{second} = #{n}.",
        divide ? "#{m} − #{n} = #{result}." : "#{m} + #{n} = #{result}.",
        divide ? "Същото се вижда и така: log#{Num.sub_digits(base)}(#{first} : #{second}) = log#{Num.sub_digits(base)} #{first / second} = #{result}." :
                 "Същото се вижда и така: log#{Num.sub_digits(base)}(#{first} · #{second}) = log#{Num.sub_digits(base)} #{first * second} = #{result}."
      ],
      answer: Num.ans(result),
      check: "#{Num.power(base, result)} = #{base**result} — точно #{divide ? "#{first} : #{second}" : "#{first} · #{second}"}.",
      watch: "Логаритмите се събират, а числата вътре се умножават — не обратното."
    )
  )
end

Authoring.family "log.to_exponential", topic: "Логаритмична функция", area: "functions",
                 rungs: [ 1560, 1650, 1740, 1830, 1920, 2020 ] do |c|
  base = c.int(c.by_level([ 2..3, 2..4, 2..5, 2..6, 2..8, 2..10 ]))
  exponent = c.int(2..c.by_level([ 4, 5, 6, 7, 8, 9 ]))
  value = base**exponent
  raise Authoring::Duplicate if value > 500_000

  correct = "#{Num.power(base, exponent)} = #{value}"

  c.q(
    text: "Кой запис е равносилен на log#{Num.sub_digits(base)} #{value} = #{exponent}?",
    options: c.options(correct, "#{Num.power(value, exponent)} = #{base}", "#{Num.power(exponent, base)} = #{value}", "#{base} · #{exponent} = #{value}"),
    answer: correct,
    explanation: Explain.build(
      idea: "Логаритъмът и степента са две страни на едно и също: log_a b = n ⟺ aⁿ = b.",
      steps: [
        "Основата #{base} остава основа на степента.",
        "Стойността на логаритъма #{exponent} става показател.",
        "Аргументът #{value} става резултат: #{correct}."
      ],
      answer: correct,
      check: "#{([ base ] * exponent).join(' · ')} = #{value}.",
      watch: "Основата не сменя мястото си — тя е основа и в двата записа."
    )
  )
end
