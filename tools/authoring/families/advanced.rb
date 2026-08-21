# Тригонометрия, редици, стереометрия, вероятности и статистика, анализ.
#
# The upper end of the ladder. Irrational answers go through options, because
# a student typing √3/2 into the answer field would be compared as text.

PI_ADV = Rational(314, 100)
SQRT2 = Rational(1414, 1000)
SQRT3 = Rational(1732, 1000)

# ------------------------------------------------- Тригонометрични функции ---

Authoring.family "trig.special_value", topic: "Тригонометрични функции", area: "advanced",
                 rungs: [ 1470, 1560, 1650, 1740, 1830, 1930 ] do |c|
  table = {
    [ "sin", 0 ] => "0", [ "sin", 30 ] => "1/2", [ "sin", 45 ] => "√2/2", [ "sin", 60 ] => "√3/2", [ "sin", 90 ] => "1",
    [ "cos", 0 ] => "1", [ "cos", 30 ] => "√3/2", [ "cos", 45 ] => "√2/2", [ "cos", 60 ] => "1/2", [ "cos", 90 ] => "0",
    [ "tg", 0 ] => "0", [ "tg", 30 ] => "√3/3", [ "tg", 45 ] => "1", [ "tg", 60 ] => "√3",
    [ "sin", 120 ] => "√3/2", [ "sin", 135 ] => "√2/2", [ "sin", 150 ] => "1/2", [ "sin", 180 ] => "0",
    [ "cos", 120 ] => "−1/2", [ "cos", 135 ] => "−√2/2", [ "cos", 150 ] => "−√3/2", [ "cos", 180 ] => "−1",
    [ "tg", 120 ] => "−√3", [ "tg", 135 ] => "−1", [ "tg", 150 ] => "−√3/3", [ "tg", 180 ] => "0",
    [ "sin", 210 ] => "−1/2", [ "sin", 225 ] => "−√2/2", [ "sin", 240 ] => "−√3/2", [ "sin", 270 ] => "−1",
    [ "cos", 210 ] => "−√3/2", [ "cos", 225 ] => "−√2/2", [ "cos", 240 ] => "−1/2", [ "cos", 270 ] => "0",
    [ "sin", 300 ] => "−√3/2", [ "sin", 315 ] => "−√2/2", [ "sin", 330 ] => "−1/2", [ "sin", 360 ] => "0",
    [ "cos", 300 ] => "1/2", [ "cos", 315 ] => "√2/2", [ "cos", 330 ] => "√3/2", [ "cos", 360 ] => "1"
  }
  keys = table.keys
  # The ladder walks round the unit circle: the first quadrant, then the angles
  # whose sign has to be worked out. The bands do not overlap, so a higher rung
  # always has new questions to ask.
  pool = c.by_level([ keys.select { |(_, a)| [ 0, 30, 90 ].include?(a) },
                      keys.select { |(_, a)| [ 45, 60 ].include?(a) },
                      keys.select { |(_, a)| [ 120, 135 ].include?(a) },
                      keys.select { |(_, a)| [ 150, 180 ].include?(a) },
                      keys.select { |(_, a)| [ 210, 225, 240, 270 ].include?(a) },
                      keys.select { |(_, a)| a >= 300 } ])
  function, angle = c.pick(pool)
  correct = table[[ function, angle ]]
  wrong = (table.values.uniq - [ correct ]).then { |values| c.sample(values, 3) }

  c.q(
    text: "Колко е #{function} #{angle}°?",
    options: c.options(correct, wrong),
    answer: correct,
    explanation: Explain.build(
      idea: "Стойностите за 0°, 30°, 45°, 60° и 90° се четат от правоъгълните триъгълници 30-60-90 и 45-45-90 (или от единичната окръжност).",
      steps: [
        function == "tg" ? "tg α = sin α : cos α." : "#{function} α е #{function == 'sin' ? 'ординатата' : 'абсцисата'} на точката от единичната окръжност при ъгъл α.",
        "За #{angle}° таблицата дава #{correct}."
      ],
      answer: correct,
      check: "Проверка чрез основното тъждество: sin²α + cos²α = 1 за всеки ъгъл.",
      watch: "sin расте от 0 до 1 при ъгъл от 0° до 90°, а cos намалява от 1 до 0."
    )
  )
end

Authoring.family "trig.ratio_in_triangle", topic: "Тригонометрични функции", area: "advanced",
                 rungs: [ 1500, 1590, 1680, 1770, 1860, 1960 ] do |c|
  a, b, hyp = pythagorean_triple(c)
  a, b = b, a if c.coin
  which = c.pick([ "sin", "cos", "tg" ])
  value = case which
  when "sin" then Rational(a, hyp)
  when "cos" then Rational(b, hyp)
  else Rational(a, b)
  end

  c.q(
    text: "В правоъгълен триъгълник срещуположният на ъгъл α катет е #{a} см, прилежащият е #{b} см, " \
          "а хипотенузата е #{hyp} см. Колко е #{which} α? Запиши като несъкратима дроб.",
    answer: Num.frac(value),
    explanation: Explain.build(
      idea: "Определенията: sin = срещулежащ катет : хипотенуза, cos = прилежащ катет : хипотенуза, tg = срещулежащ : прилежащ.",
      steps: [
        which == "sin" ? "sin α = #{a} : #{hyp} = #{Num.frac(value)}." :
          (which == "cos" ? "cos α = #{b} : #{hyp} = #{Num.frac(value)}." : "tg α = #{a} : #{b} = #{Num.frac(value)}."),
        "Дробта се съкращава до #{Num.frac(value)}."
      ],
      answer: Num.frac(value),
      check: "Триъгълникът е правоъгълен: #{a}² + #{b}² = #{(a * a) + (b * b)} = #{hyp}².",
      watch: "sin и cos винаги са под 1 (катет е по-малък от хипотенузата), а tg може да е и над 1."
    )
  )
end

Authoring.family "trig.find_side", topic: "Тригонометрични функции", area: "advanced",
                 rungs: [ 1560, 1650, 1740, 1830, 1920, 2020 ] do |c|
  angle = c.pick([ 30, 60 ])
  hyp = c.int(c.by_level([ 2..8, 3..14, 4..24, 6..40, 8..80, 10..160 ])) * 2
  opposite = angle == 30 ? Rational(hyp, 2) : nil
  raise Authoring::Duplicate if opposite.nil?

  c.q(
    text: "В правоъгълен триъгълник хипотенузата е #{hyp} см, а един от острите ъгли е 30°. " \
          "Колко сантиметра е катетът срещу ъгъла от 30°?",
    answer: Num.ans(opposite),
    explanation: Explain.build(
      idea: "Катетът срещу ъгъл от 30° е равен на половината от хипотенузата — това е известното свойство на триъгълника 30-60-90.",
      steps: [
        "sin 30° = 1/2, а sin 30° = катет : хипотенуза.",
        "катет = #{hyp} · 1/2 = #{Num.ans(opposite)} см."
      ],
      answer: "#{Num.ans(opposite)} см",
      check: "Другият катет е #{Num.dec(Rational(hyp, 2) * SQRT3, 2)} см (половин хипотенуза по √3) — по-дълъг, както се очаква срещу 60°.",
      watch: "Половината е от хипотенузата, не от другия катет."
    )
  )
end

Authoring.family "trig.identity", topic: "Тригонометрични функции", area: "advanced",
                 rungs: [ 1600, 1690, 1780, 1870, 1960, 2060 ] do |c|
  a, b, hyp = pythagorean_triple(c)
  a, b = b, a if c.coin
  sin_value = Rational(a, hyp)
  cos_value = Rational(b, hyp)

  c.q(
    text: "За остър ъгъл α е известно, че sin α = #{Num.frac(sin_value)}. Колко е cos α? Запиши като несъкратима дроб.",
    answer: Num.frac(cos_value),
    explanation: Explain.build(
      idea: "Основното тригонометрично тъждество: sin²α + cos²α = 1.",
      steps: [
        "sin²α = (#{Num.frac(sin_value)})² = #{Num.frac(sin_value * sin_value)}.",
        "cos²α = 1 − #{Num.frac(sin_value * sin_value)} = #{Num.frac(1 - (sin_value * sin_value))}.",
        "cos α = √#{Num.frac(1 - (sin_value * sin_value))} = #{Num.frac(cos_value)} (ъгълът е остър, затова знакът е плюс)."
      ],
      answer: Num.frac(cos_value),
      check: "#{Num.frac(sin_value)}² + #{Num.frac(cos_value)}² = #{Num.frac((sin_value * sin_value) + (cos_value * cos_value))}.",
      watch: "Изваждането е при квадратите, не при самите синус и косинус."
    )
  )
end

# ------------------------------------------------------ Решаване на триъгълник ---

Authoring.family "tri.area_with_sine", topic: "Решаване на триъгълник", area: "advanced",
                 rungs: [ 1620, 1710, 1800, 1890, 1980, 2080 ] do |c|
  a = c.int(c.by_level([ 2..8, 3..14, 4..22, 6..40, 8..80, 10..150 ])) * 2
  b = c.int(c.by_level([ 2..8, 3..14, 4..22, 6..40, 8..80, 10..150 ]))
  area = Rational(a * b, 4)

  c.q(
    text: "Триъгълник има страни #{a} см и #{b} см и ъгъл 30° между тях. Колко квадратни сантиметра е лицето му?",
    answer: Num.ans(area),
    explanation: Explain.build(
      idea: "S = (1/2) · a · b · sin γ, където γ е ъгълът между двете страни.",
      steps: [
        "sin 30° = 1/2.",
        "S = (1/2) · #{a} · #{b} · (1/2) = #{a * b} : 4 = #{Num.ans(area)} см²."
      ],
      answer: "#{Num.ans(area)} см²",
      check: "Ако ъгълът беше прав, лицето щеше да е #{Num.ans(Rational(a * b, 2))} см² — при 30° е точно наполовина.",
      watch: "Синусът на ъгъла между страните участва — не самият ъгъл в градуси."
    )
  )
end

Authoring.family "tri.sine_rule", topic: "Решаване на триъгълник", area: "advanced",
                 rungs: [ 1680, 1770, 1860, 1950, 2040, 2140 ] do |c|
  side = c.int(c.by_level([ 2..10, 3..16, 4..26, 6..44, 8..90, 10..180 ]))
  angle_known = 30
  angle_other = 90
  other_side = side * 2

  c.q(
    text: "В триъгълник срещу ъгъл от 30° лежи страна #{side} см. Колко сантиметра е страната срещу правия ъгъл?",
    answer: Num.ans(other_side),
    explanation: Explain.build(
      idea: "Синусова теорема: a : sin α = b : sin β — страните са пропорционални на синусите на срещулежащите ъгли.",
      steps: [
        "#{side} : sin #{angle_known}° = x : sin #{angle_other}°.",
        "sin 30° = 1/2, sin 90° = 1.",
        "x = #{side} · 1 : (1/2) = #{other_side} см."
      ],
      answer: "#{other_side} см",
      check: "Срещу по-големия ъгъл лежи по-голямата страна: 90° > 30° и #{other_side} > #{side}.",
      watch: "Отношението е страна към синус на срещулежащия ъгъл, а не към самия ъгъл."
    )
  )
end

Authoring.family "tri.cosine_rule", topic: "Решаване на триъгълник", area: "advanced",
                 rungs: [ 1720, 1810, 1900, 1990, 2080, 2180 ] do |c|
  a = c.int(c.by_level([ 2..8, 3..12, 4..18, 5..30, 8..60, 10..120 ]))
  b = c.int(c.by_level([ 2..8, 3..12, 4..18, 5..30, 8..60, 10..120 ]))
  squared = (a * a) + (b * b) - (a * b)
  root = Integer.sqrt(squared)
  exact = root * root == squared
  # Above the first rungs the third side is usually irrational: then the
  # question asks for two decimals and the grader allows the rounding.
  raise Authoring::Duplicate if !exact && c.level < 2

  rounded = Rational((Math.sqrt(squared) * 100).round, 100)

  c.q(
    text: "Триъгълник има страни #{a} см и #{b} см и ъгъл 60° между тях. Колко сантиметра е третата страна?" +
          (exact ? "" : " (Закръгли до стотни.)"),
    answer: exact ? Num.ans(root) : Num.dec2(rounded),
    tolerance: exact ? nil : "0.02",
    explanation: Explain.build(
      idea: "Косинусова теорема: c² = a² + b² − 2ab · cos γ. При γ = 60° косинусът е 1/2, значи c² = a² + b² − ab.",
      steps: [
        "a² + b² = #{a * a} + #{b * b} = #{(a * a) + (b * b)}.",
        "2ab · cos 60° = 2 · #{a} · #{b} · 1/2 = #{a * b}.",
        exact ? "c² = #{(a * a) + (b * b)} − #{a * b} = #{squared}, значи c = #{root} см." :
                "c² = #{(a * a) + (b * b)} − #{a * b} = #{squared}, значи c = √#{squared} ≈ #{Num.dec2(rounded)} см."
      ],
      answer: "#{exact ? root : Num.dec2(rounded)} см",
      check: "Проверка с неравенството на триъгълника: #{exact ? root : Num.dec2(rounded)} < #{a} + #{b} = #{a + b}.",
      watch: "При 90° формулата се свежда до Питагоровата теорема; при 60° остава допълнителният член −ab."
    )
  )
end

Authoring.family "tri.height_from_area", topic: "Решаване на триъгълник", area: "advanced",
                 rungs: [ 1580, 1670, 1760, 1850, 1940, 2040 ] do |c|
  base = c.int(c.by_level([ 2..10, 3..16, 4..26, 6..44, 8..90, 10..180 ]))
  height = c.int(c.by_level([ 2..10, 3..16, 4..26, 6..44, 8..90, 10..180 ]))
  area = Rational(base * height, 2)

  c.q(
    text: "Лицето на триъгълник е #{Num.ans(area)} см², а една от страните му е #{base} см. " \
          "Колко сантиметра е височината към тази страна?",
    answer: Num.ans(height),
    explanation: Explain.build(
      idea: "От S = a · h : 2 следва h = 2S : a.",
      steps: [
        "2S = 2 · #{Num.ans(area)} = #{Num.ans(area * 2)}.",
        "h = #{Num.ans(area * 2)} : #{base} = #{height} см."
      ],
      answer: "#{height} см",
      check: "#{base} · #{height} : 2 = #{Num.ans(area)} см².",
      watch: "Умножението по 2 е задължително — иначе височината излиза наполовина."
    )
  )
end

# ------------------------------------------------------ Аритметична прогресия ---

Authoring.family "ap.nth_term", topic: "Аритметична прогресия", area: "advanced",
                 rungs: [ 1330, 1420, 1510, 1600, 1690, 1790 ] do |c|
  first = c.int(c.by_level([ 1..10, 2..20, -10..30, -20..50, -40..100, -90..250 ]))
  step = c.int(c.by_level([ 2..6, 2..9, -8..12, -12..18, -25..35, -50..80 ]))
  raise Authoring::Duplicate if step.zero?

  n = c.int(c.by_level([ 5..10, 6..15, 8..25, 10..40, 15..80, 20..200 ]))
  value = first + ((n - 1) * step)

  c.q(
    text: "Аритметична прогресия започва с #{Num.bg(first)} и има разлика #{Num.bg(step)}. Кой е #{n}-ият ѝ член?",
    answer: Num.ans(value),
    explanation: Explain.build(
      idea: "aₙ = a₁ + (n − 1)d — от първия член се правят n − 1 стъпки.",
      steps: [
        "n − 1 = #{n - 1} стъпки по #{Num.bg(step)}: #{n - 1} · #{Num.bg(step)} = #{Num.bg((n - 1) * step)}.",
        "a#{n} = #{Num.bg(first)} + #{Num.bg((n - 1) * step)} = #{Num.bg(value)}."
      ],
      answer: "a#{n} = #{Num.bg(value)}",
      check: "a₂ = #{Num.bg(first + step)}, a₃ = #{Num.bg(first + (2 * step))} — стъпката е постоянна.",
      watch: "Стъпките са n − 1, не n: първият член вече е на мястото си."
    )
  )
end

Authoring.family "ap.sum", topic: "Аритметична прогресия", area: "advanced",
                 rungs: [ 1420, 1510, 1600, 1690, 1780, 1880 ] do |c|
  first = c.int(c.by_level([ 1..8, 1..15, 2..25, -10..40, -20..80, -40..200 ]))
  step = c.int(c.by_level([ 1..5, 2..8, 2..12, 3..18, 4..30, 5..60 ]))
  n = c.int(c.by_level([ 4..8, 5..12, 6..20, 8..30, 10..60, 12..120 ]))
  last = first + ((n - 1) * step)
  sum = (first + last) * n / 2
  raise Authoring::Duplicate unless (((first + last) * n) % 2).zero?

  c.q(
    text: "Намери сбора на първите #{n} члена на аритметична прогресия с първи член #{Num.bg(first)} и разлика #{step}.",
    answer: Num.ans(sum),
    explanation: Explain.build(
      idea: "Сборът е средното на първия и последния член, умножено по броя членове: Sₙ = (a₁ + aₙ) · n : 2.",
      steps: [
        "a#{n} = #{Num.bg(first)} + #{n - 1} · #{step} = #{Num.bg(last)}.",
        "a₁ + a#{n} = #{Num.bg(first)} + #{Num.bg(last)} = #{Num.bg(first + last)}.",
        "S = #{Num.bg(first + last)} · #{n} : 2 = #{Num.bg(sum)}."
      ],
      answer: "S#{n} = #{Num.bg(sum)}",
      check: "Средният член е #{Num.dec(Rational(first + last, 2), 1)}, а #{n} такива дават #{Num.bg(sum)}.",
      watch: "Умножава се по броя членове #{n}, не по разликата."
    )
  )
end

Authoring.family "ap.find_difference", topic: "Аритметична прогресия", area: "advanced",
                 rungs: [ 1400, 1490, 1580, 1670, 1760, 1860 ] do |c|
  first = c.int(c.by_level([ 1..10, 2..20, -8..30, -15..50, -30..100, -60..250 ]))
  step = c.int(c.by_level([ 2..6, 2..9, 3..12, 4..18, 5..30, 6..60 ]))
  n = c.int(c.by_level([ 4..8, 5..12, 6..18, 8..25, 10..50, 12..100 ]))
  value = first + ((n - 1) * step)

  c.q(
    text: "В аритметична прогресия първият член е #{Num.bg(first)}, а #{n}-ият е #{Num.bg(value)}. Колко е разликата d?",
    answer: Num.ans(step),
    explanation: Explain.build(
      idea: "От aₙ = a₁ + (n − 1)d изразяваме d.",
      steps: [
        "aₙ − a₁ = #{Num.bg(value)} − #{Num.bg(first)} = #{Num.bg(value - first)}.",
        "Това са #{n - 1} стъпки: d = #{Num.bg(value - first)} : #{n - 1} = #{step}."
      ],
      answer: "d = #{step}",
      check: "#{Num.bg(first)} + #{n - 1} · #{step} = #{Num.bg(value)}.",
      watch: "Дели се на #{n - 1}, не на #{n}."
    )
  )
end

Authoring.family "ap.theatre_word", topic: "Аритметична прогресия", area: "advanced",
                 rungs: [ 1450, 1540, 1630, 1720, 1810, 1910 ] do |c|
  first = c.int(c.by_level([ 8..15, 10..20, 12..30, 15..40, 18..60, 20..120 ]))
  step = c.int(1..c.by_level([ 2, 3, 4, 5, 6, 8 ]))
  rows = c.int(c.by_level([ 5..10, 6..14, 8..20, 10..28, 12..40, 15..80 ]))
  last = first + ((rows - 1) * step)
  total = (first + last) * rows / 2
  raise Authoring::Duplicate unless (((first + last) * rows) % 2).zero?

  c.q(
    text: "В салон първият ред има #{first} места, а всеки следващ — с #{step} повече. Редовете са #{rows}. " \
          "Колко места има салонът?",
    answer: Num.ans(total),
    explanation: Explain.build(
      idea: "Местата по редове образуват аритметична прогресия; търси се сборът ѝ.",
      steps: [
        "Последен ред: #{first} + #{rows - 1} · #{step} = #{last} места.",
        "Сбор: (#{first} + #{last}) · #{rows} : 2 = #{first + last} · #{rows} : 2 = #{total}."
      ],
      answer: "#{total} места",
      check: "Средно по #{Num.dec(Rational(total, rows), 1)} места на ред при #{rows} реда.",
      watch: "Не се умножава първият ред по броя редове — местата растат."
    )
  )
end

# ------------------------------------------------------- Геометрична прогресия ---

Authoring.family "gp.nth_term", topic: "Геометрична прогресия", area: "advanced",
                 rungs: [ 1430, 1520, 1610, 1700, 1790, 1890 ] do |c|
  first = c.int(c.by_level([ 1..5, 1..8, 2..12, 2..20, 3..40, 4..90 ]))
  ratio = c.int(c.by_level([ 2..2, 2..3, 2..3, 2..4, 3..5, 3..6 ]))
  n = c.int(c.by_level([ 3..5, 4..6, 4..7, 5..8, 5..9, 6..10 ]))
  value = first * (ratio**(n - 1))
  raise Authoring::Duplicate if value > 5_000_000

  c.q(
    text: "Геометрична прогресия има първи член #{first} и частно #{ratio}. Кой е #{n}-ият ѝ член?",
    answer: Num.ans(value),
    explanation: Explain.build(
      idea: "aₙ = a₁ · q на степен (n − 1) — от първия член се прави n − 1 умножение.",
      steps: [
        "q на степен #{n - 1} = #{Num.power(ratio, n - 1)} = #{ratio**(n - 1)}.",
        "a#{n} = #{first} · #{ratio**(n - 1)} = #{value}."
      ],
      answer: "a#{n} = #{value}",
      check: "Първите членове са #{(0...[ n, 4 ].min).map { |i| first * (ratio**i) }.join(', ')}, ...",
      watch: "Степента е n − 1, а не n — първият член още не е умножаван."
    )
  )
end

Authoring.family "gp.ratio", topic: "Геометрична прогресия", area: "advanced",
                 rungs: [ 1400, 1490, 1580, 1670, 1760, 1860 ] do |c|
  first = c.int(c.by_level([ 1..6, 2..10, 2..15, 3..25, 4..50, 5..100 ]))
  ratio = c.int(c.by_level([ 2..3, 2..4, 2..5, 2..6, 3..8, 3..12 ]))
  n = c.int(3..c.by_level([ 4, 4, 5, 5, 6, 6 ]))
  value = first * (ratio**(n - 1))
  raise Authoring::Duplicate if value > 2_000_000

  c.q(
    text: "В геометрична прогресия първият член е #{first}, а #{n}-ият е #{value}. Колко е частното q (положително)?",
    answer: Num.ans(ratio),
    explanation: Explain.build(
      idea: "От aₙ = a₁ · q^(n−1) следва q^(n−1) = aₙ : a₁.",
      steps: [
        "#{value} : #{first} = #{ratio**(n - 1)}.",
        "Търсим число, чиято #{n - 1}-та степен е #{ratio**(n - 1)}: това е #{ratio}."
      ],
      answer: "q = #{ratio}",
      check: "#{first} · #{ratio}#{Num.sup(n - 1)} = #{value}.",
      watch: "Частното се получава с корен, не с деление на #{n - 1}."
    )
  )
end

Authoring.family "gp.sum", topic: "Геометрична прогресия", area: "advanced",
                 rungs: [ 1520, 1610, 1700, 1790, 1880, 1980 ] do |c|
  first = c.int(c.by_level([ 1..4, 1..6, 2..10, 2..15, 3..30, 4..60 ]))
  ratio = c.int(c.by_level([ 2..2, 2..3, 2..3, 2..4, 2..5, 3..6 ]))
  n = c.int(c.by_level([ 3..5, 4..6, 4..7, 5..8, 5..9, 6..10 ]))
  sum = first * ((ratio**n) - 1) / (ratio - 1)
  raise Authoring::Duplicate if sum > 5_000_000

  c.q(
    text: "Намери сбора на първите #{n} члена на геометрична прогресия с първи член #{first} и частно #{ratio}.",
    answer: Num.ans(sum),
    explanation: Explain.build(
      idea: "Sₙ = a₁ · (qⁿ − 1) : (q − 1).",
      steps: [
        "q#{Num.sup(n)} = #{ratio**n}.",
        "S = #{first} · (#{ratio**n} − 1) : (#{ratio} − 1) = #{first} · #{(ratio**n) - 1} : #{ratio - 1}.",
        "S = #{sum}."
      ],
      answer: "S#{n} = #{sum}",
      check: "Директно: #{(0...n).map { |i| first * (ratio**i) }.join(' + ')} = #{sum}.",
      watch: "Знаменателят е q − 1 = #{ratio - 1}; при q = 1 формулата не важи."
    )
  )
end

Authoring.family "gp.doubling_word", topic: "Геометрична прогресия", area: "advanced",
                 rungs: [ 1470, 1560, 1650, 1740, 1830, 1930 ] do |c|
  start = c.int(c.by_level([ 1..4, 1..8, 2..15, 2..30, 3..60, 5..120 ]))
  ratio = c.int(c.by_level([ 2..2, 2..3, 2..3, 2..4, 3..4, 3..5 ]))
  days = c.int(c.by_level([ 3..5, 4..6, 4..7, 5..8, 5..9, 6..10 ]))
  final = start * (ratio**(days - 1))
  raise Authoring::Duplicate if final > 3_000_000

  c.q(
    text: "Първия ден са споделени #{start} публикации, а всеки следващ ден — #{ratio} пъти повече от предишния. " \
          "Колко публикации се споделят на #{days}-ия ден?",
    answer: Num.ans(final),
    explanation: Explain.build(
      idea: "Броят на публикациите образува геометрична прогресия с частно #{ratio}.",
      steps: [
        "Ден 1: #{start}; ден 2: #{start * ratio}; ден 3: #{start * ratio * ratio}.",
        "Ден #{days}: #{start} · #{ratio}#{Num.sup(days - 1)} = #{final}."
      ],
      answer: "#{final} публикации",
      check: "#{final} : #{ratio} = #{final / ratio} — толкова са били предния ден.",
      watch: "Растежът е умножение, не събиране — затова числата се надуват бързо."
    )
  )
end

# --------------------------------------------------------- Призма и пирамида ---

Authoring.family "prism.volume_rect_base", topic: "Призма и пирамида", area: "advanced",
                 rungs: [ 1380, 1470, 1560, 1650, 1740, 1840 ] do |c|
  a = c.int(c.by_level([ 2..6, 2..9, 3..12, 4..20, 6..40, 8..80 ]))
  b = c.int(c.by_level([ 2..6, 2..9, 3..12, 4..20, 6..40, 8..80 ]))
  h = c.int(c.by_level([ 2..8, 3..12, 4..18, 5..30, 8..60, 10..120 ]))
  volume = a * b * h

  c.q(
    text: "Права призма има за основа правоъгълник #{a} см на #{b} см и височина #{h} см. " \
          "Колко кубични сантиметра е обемът ѝ?",
    answer: Num.ans(volume),
    explanation: Explain.build(
      idea: "Обемът на права призма е лице на основата по височина.",
      steps: [
        "Основа: #{a} · #{b} = #{a * b} см².",
        "V = #{a * b} · #{h} = #{volume} см³."
      ],
      answer: "#{volume} см³",
      check: "Ако височината се удвои, обемът става #{2 * volume} см³.",
      watch: "Височината на призмата е перпендикулярна на основата — не е диагонал."
    )
  )
end

Authoring.family "pyramid.volume", topic: "Призма и пирамида", area: "advanced",
                 rungs: [ 1480, 1570, 1660, 1750, 1840, 1940 ] do |c|
  side = c.int(c.by_level([ 2..6, 3..9, 3..12, 4..20, 6..40, 8..80 ]))
  h = c.int(c.by_level([ 3..9, 3..12, 4..18, 6..30, 9..60, 12..120 ]))
  raise Authoring::Duplicate unless ((side * side * h) % 3).zero?

  volume = side * side * h / 3

  c.q(
    text: "Правилна четириъгълна пирамида има основен ръб #{side} см и височина #{h} см. " \
          "Колко кубични сантиметра е обемът ѝ?",
    answer: Num.ans(volume),
    explanation: Explain.build(
      idea: "Обемът на пирамида е една трета от обема на призма със същата основа и височина.",
      steps: [
        "Основа: #{side} · #{side} = #{side * side} см².",
        "V = #{side * side} · #{h} : 3 = #{side * side * h} : 3 = #{volume} см³."
      ],
      answer: "#{volume} см³",
      check: "Призма със същата основа и височина би имала #{side * side * h} см³ — три пъти повече.",
      watch: "Делението на 3 е това, което отличава пирамидата от призмата."
    )
  )
end

Authoring.family "prism.surface_cube_scaled", topic: "Призма и пирамида", area: "advanced",
                 rungs: [ 1420, 1510, 1600, 1690, 1780, 1880 ] do |c|
  edge = c.int(c.by_level([ 2..8, 3..12, 4..18, 6..30, 9..60, 12..120 ]))
  surface = 6 * edge * edge
  ask_edge = c.level >= 3 && c.coin

  c.q(
    text: ask_edge ? "Повърхнината на куб е #{surface} см². Колко сантиметра е ръбът му?" :
                     "Куб има ръб #{edge} см. Колко квадратни сантиметра е повърхнината му?",
    answer: Num.ans(ask_edge ? edge : surface),
    explanation: Explain.build(
      idea: "Кубът има 6 еднакви квадратни стени, значи S = 6a².",
      steps: ask_edge ?
        [ "a² = #{surface} : 6 = #{edge * edge}.", "a = √#{edge * edge} = #{edge} см." ] :
        [ "Една стена: #{edge}² = #{edge * edge} см².", "S = 6 · #{edge * edge} = #{surface} см²." ],
      answer: ask_edge ? "#{edge} см" : "#{surface} см²",
      check: "6 · #{edge}² = #{surface} см², а обемът е #{edge**3} см³ — различна величина.",
      watch: "Стените са 6, а не 4 — горната и долната също се броят."
    )
  )
end

# ---------------------------------------------------------- Ротационни тела ---

Authoring.family "cyl.volume", topic: "Ротационни тела", area: "advanced",
                 rungs: [ 1500, 1590, 1680, 1770, 1860, 1960 ] do |c|
  radius = c.int(c.by_level([ 1..4, 2..6, 2..9, 3..14, 4..25, 5..50 ]))
  h = c.int(c.by_level([ 2..8, 3..12, 4..18, 5..30, 8..60, 10..120 ]))
  volume = PI_ADV * radius * radius * h

  c.q(
    text: "Цилиндър има радиус на основата #{radius} см и височина #{h} см. " \
          "Колко кубични сантиметра е обемът му? (Приеми π ≈ 3,14.)",
    answer: Num.dec2(volume),
    tolerance: "0.05",
    explanation: Explain.build(
      idea: "Обемът на цилиндър е лице на основата (кръг) по височина: V = πr²h.",
      steps: [
        "Основа: 3,14 · #{radius}² = 3,14 · #{radius * radius} = #{Num.dec2(PI_ADV * radius * radius)} см².",
        "V = #{Num.dec2(PI_ADV * radius * radius)} · #{h} = #{Num.dec2(volume)} см³."
      ],
      answer: "#{Num.dec2(volume)} см³",
      check: "Описаният паралелепипед с основа #{2 * radius} на #{2 * radius} см има обем #{4 * radius * radius * h} см³ — цилиндърът е около 78,5% от него.",
      watch: "Радиусът се повдига на квадрат, височината — не."
    )
  )
end

Authoring.family "cone.volume", topic: "Ротационни тела", area: "advanced",
                 rungs: [ 1560, 1650, 1740, 1830, 1920, 2020 ] do |c|
  radius = c.int(c.by_level([ 1..4, 2..6, 2..9, 3..14, 4..25, 5..50 ]))
  h = c.int(c.by_level([ 3..9, 3..12, 6..18, 6..30, 9..60, 12..120 ]))
  raise Authoring::Duplicate unless (h % 3).zero?

  volume = PI_ADV * radius * radius * h / 3

  c.q(
    text: "Конус има радиус на основата #{radius} см и височина #{h} см. " \
          "Колко кубични сантиметра е обемът му? (Приеми π ≈ 3,14.)",
    answer: Num.dec2(volume),
    tolerance: "0.05",
    explanation: Explain.build(
      idea: "Конусът е една трета от цилиндър със същата основа и височина: V = πr²h : 3.",
      steps: [
        "Основа: 3,14 · #{radius * radius} = #{Num.dec2(PI_ADV * radius * radius)} см².",
        "Цилиндър: #{Num.dec2(PI_ADV * radius * radius)} · #{h} = #{Num.dec2(PI_ADV * radius * radius * h)} см³.",
        "Конус: #{Num.dec2(PI_ADV * radius * radius * h)} : 3 = #{Num.dec2(volume)} см³."
      ],
      answer: "#{Num.dec2(volume)} см³",
      check: "Три такива конуса пълнят цилиндъра: 3 · #{Num.dec2(volume)} = #{Num.dec2(PI_ADV * radius * radius * h)} см³.",
      watch: "Делението на 3 важи за конус и пирамида, не за цилиндър и призма."
    )
  )
end

Authoring.family "sphere.volume", topic: "Ротационни тела", area: "advanced",
                 rungs: [ 1620, 1710, 1800, 1890, 1980, 2080 ] do |c|
  radius = c.int(c.by_level([ 1..6, 2..9, 3..14, 4..22, 6..40, 8..90 ]))
  volume = Rational(4, 3) * PI_ADV * (radius**3)

  c.q(
    text: "Топка има радиус #{radius} см. Колко кубични сантиметра е обемът ѝ? (Приеми π ≈ 3,14.)",
    answer: Num.dec2(volume),
    tolerance: "0.05",
    explanation: Explain.build(
      idea: "Обемът на кълбо е V = (4/3)πr³.",
      steps: [
        "r³ = #{radius}³ = #{radius**3}.",
        "V = (4 : 3) · 3,14 · #{radius**3} = #{Num.dec2(volume)} см³."
      ],
      answer: "#{Num.dec2(volume)} см³",
      check: "Описаният куб с ръб #{2 * radius} см има обем #{(2 * radius)**3} см³ — кълбото е около 52% от него.",
      watch: "Радиусът е на трета степен — при удвояване обемът става 8 пъти по-голям."
    )
  )
end

Authoring.family "cyl.surface", topic: "Ротационни тела", area: "advanced",
                 rungs: [ 1580, 1670, 1760, 1850, 1940, 2040 ] do |c|
  radius = c.int(c.by_level([ 1..4, 2..6, 2..9, 3..14, 4..25, 5..50 ]))
  h = c.int(c.by_level([ 2..8, 3..12, 4..18, 5..30, 8..60, 10..120 ]))
  lateral = 2 * PI_ADV * radius * h
  total = lateral + (2 * PI_ADV * radius * radius)

  c.q(
    text: "Цилиндър има радиус #{radius} см и височина #{h} см. Колко квадратни сантиметра е пълната му повърхнина? " \
          "(Приеми π ≈ 3,14.)",
    answer: Num.dec2(total),
    tolerance: "0.05",
    explanation: Explain.build(
      idea: "Повърхнината е две основи (кръгове) плюс развитата околна стена (правоъгълник с дължина обиколката).",
      steps: [
        "Основи: 2 · 3,14 · #{radius}² = #{Num.dec2(2 * PI_ADV * radius * radius)} см².",
        "Околна стена: 2 · 3,14 · #{radius} · #{h} = #{Num.dec2(lateral)} см².",
        "S = #{Num.dec2(2 * PI_ADV * radius * radius)} + #{Num.dec2(lateral)} = #{Num.dec2(total)} см²."
      ],
      answer: "#{Num.dec2(total)} см²",
      check: "Околната стена, развита в равнина, е правоъгълник #{Num.dec2(2 * PI_ADV * radius)} см на #{h} см.",
      watch: "Основите са две — една отдолу и една отгоре."
    )
  )
end

# --------------------------------------------------------------- Вероятност ---

Authoring.family "prob.balls", topic: "Вероятност", area: "advanced",
                 rungs: [ 1140, 1230, 1320, 1410, 1500, 1600 ] do |c|
  first = c.int(c.by_level([ 1..5, 2..8, 2..12, 3..20, 4..40, 5..90 ]))
  second = c.int(c.by_level([ 1..5, 2..8, 2..12, 3..20, 4..40, 5..90 ]))
  total = first + second
  probability = Rational(first, total)

  c.q(
    text: "В кутия има #{first} червени и #{second} сини топки. Изважда се една топка наслуки. " \
          "Колко е вероятността да е червена? Запиши като несъкратима дроб.",
    answer: Num.frac(probability),
    explanation: Explain.build(
      idea: "Вероятността е брой благоприятни изходи, разделен на брой всички равновъзможни изходи.",
      steps: [
        "Благоприятни: #{first} червени топки.",
        "Всички: #{first} + #{second} = #{total} топки.",
        "P = #{first}/#{total} = #{Num.frac(probability)}."
      ],
      answer: Num.frac(probability),
      check: "Вероятността да е синя е #{Num.frac(Rational(second, total))}, а двете дават 1.",
      watch: "Знаменателят е общият брой топки, не броят на другия цвят."
    )
  )
end

Authoring.family "prob.dice_condition", topic: "Вероятност", area: "advanced",
                 rungs: [ 1200, 1290, 1380, 1470, 1560, 1660 ] do |c|
  condition = c.pick(c.by_level([ [ :even, :greater ], [ :even, :greater, :multiple ],
                                  [ :greater, :multiple, :two_dice_sum ], [ :multiple, :two_dice_sum, :two_dice_same ],
                                  [ :two_dice_sum, :sum_at_least ], [ :sum_at_least, :at_least_one_six ] ]))
  case condition
  when :even
    favourable = 3
    total = 6
    text = "Хвърля се зар. Колко е вероятността да се падне четно число? Запиши като несъкратима дроб."
    steps = [ "Четните числа на зара са 2, 4 и 6 — три на брой.", "P = 3/6 = 1/2." ]
  when :greater
    threshold = c.int(1..5)
    favourable = 6 - threshold
    total = 6
    text = "Хвърля се зар. Колко е вероятността да се падне число, по-голямо от #{threshold}? Запиши като несъкратима дроб."
    steps = [ "Благоприятни са #{((threshold + 1)..6).to_a.join(', ')} — #{favourable} на брой.", "P = #{favourable}/6 = #{Num.frac(favourable, 6)}." ]
  when :multiple
    divisor = c.pick([ 2, 3 ])
    favourable = (1..6).count { |value| (value % divisor).zero? }
    total = 6
    text = "Хвърля се зар. Колко е вероятността да се падне число, кратно на #{divisor}? Запиши като несъкратима дроб."
    steps = [ "Кратните на #{divisor} до 6 са #{(1..6).select { |v| (v % divisor).zero? }.join(', ')}.", "P = #{favourable}/6 = #{Num.frac(favourable, 6)}." ]
  when :two_dice_sum
    target = c.int(4..10)
    favourable = (1..6).sum { |first| (1..6).count { |second| first + second == target } }
    raise Authoring::Duplicate if favourable.zero?

    total = 36
    text = "Хвърлят се два зара. Колко е вероятността сборът им да е #{target}? Запиши като несъкратима дроб."
    steps = [ "Всички изходи: 6 · 6 = 36.",
              "Сбор #{target} се получава по #{favourable} начина.",
              "P = #{favourable}/36 = #{Num.frac(favourable, 36)}." ]
  when :sum_at_least
    target = c.int(5..11)
    favourable = (1..6).sum { |first| (1..6).count { |second| first + second >= target } }
    total = 36
    text = "Хвърлят се два зара. Колко е вероятността сборът им да е поне #{target}? Запиши като несъкратима дроб."
    steps = [ "Всички изходи: 6 · 6 = 36.",
              "Сбор поне #{target} се получава по #{favourable} начина.",
              "P = #{favourable}/36 = #{Num.frac(favourable, 36)}." ]
  when :at_least_one_six
    dice = c.int(2..3)
    total = 6**dice
    favourable = total - (5**dice)
    text = "Хвърлят се #{dice} зара. Колко е вероятността поне един от тях да покаже 6? Запиши като несъкратима дроб."
    steps = [ "Всички изходи: 6#{Num.sup(dice)} = #{total}.",
              "Без нито една шестица: 5#{Num.sup(dice)} = #{5**dice} изхода.",
              "Значи благоприятните са #{total} − #{5**dice} = #{favourable}, а P = #{Num.frac(favourable, total)}." ]
  else
    favourable = 6
    total = 36
    text = "Хвърлят се два зара. Колко е вероятността да се паднат две еднакви числа? Запиши като несъкратима дроб."
    steps = [ "Еднакви двойки: (1,1), (2,2), ..., (6,6) — 6 на брой.", "Всички изходи: 36.", "P = 6/36 = 1/6." ]
  end
  probability = Rational(favourable, total)

  c.q(
    text: text,
    answer: Num.frac(probability),
    explanation: Explain.build(
      idea: "Всички изходи при хвърляне на зар са равновъзможни, затова вероятността е отношение на броеве.",
      steps: steps,
      answer: Num.frac(probability),
      check: "Вероятността е между 0 и 1: #{Num.frac(probability)} ≈ #{Num.dec(probability, 3)}.",
      watch: "Броят на всички изходи при два зара е 36, не 12."
    )
  )
end

Authoring.family "prob.complement", topic: "Вероятност", area: "advanced",
                 rungs: [ 1180, 1270, 1360, 1450, 1540, 1640 ] do |c|
  denominator = c.int(c.by_level([ 2..6, 3..10, 4..15, 5..25, 6..50, 8..100 ]))
  numerator = c.int(1...denominator)
  probability = Rational(numerator, denominator)
  complement = 1 - probability

  c.q(
    text: "Вероятността едно събитие да се случи е #{Num.frac(probability)}. " \
          "Колко е вероятността то да не се случи? Запиши като несъкратима дроб.",
    answer: Num.frac(complement),
    explanation: Explain.build(
      idea: "Събитието и неговото противоположно изчерпват всички възможности, затова сборът на вероятностите им е 1.",
      steps: [
        "P(не) = 1 − P(да) = 1 − #{Num.frac(probability)}.",
        "1 = #{denominator}/#{denominator}, значи P(не) = #{Num.frac(complement)}."
      ],
      answer: Num.frac(complement),
      check: "#{Num.frac(probability)} + #{Num.frac(complement)} = 1.",
      watch: "Противоположната вероятност не е обратната дроб (#{Num.frac(Rational(denominator, numerator))})."
    )
  )
end

Authoring.family "prob.two_events", topic: "Вероятност", area: "advanced",
                 rungs: [ 1400, 1490, 1580, 1670, 1760, 1860 ] do |c|
  d1 = c.int(c.by_level([ 2..4, 2..6, 3..8, 3..12, 4..20, 5..40 ]))
  d2 = c.int(c.by_level([ 2..4, 2..6, 3..8, 3..12, 4..20, 5..40 ]))
  n1 = c.int(1...d1)
  n2 = c.int(1...d2)
  probability = Rational(n1, d1) * Rational(n2, d2)

  c.q(
    text: "Две независими събития имат вероятности #{Num.frac(n1, d1)} и #{Num.frac(n2, d2)}. " \
          "Колко е вероятността да се случат и двете? Запиши като несъкратима дроб.",
    answer: Num.frac(probability),
    explanation: Explain.build(
      idea: "За независими събития вероятността и двете да се случат е произведението на вероятностите им.",
      steps: [
        "P = #{Num.frac(n1, d1)} · #{Num.frac(n2, d2)} = #{n1 * n2}/#{d1 * d2}.",
        "След съкращаване: #{Num.frac(probability)}."
      ],
      answer: Num.frac(probability),
      check: "Резултатът е по-малък и от двете вероятности — две условия наведнъж са по-редки.",
      watch: "Вероятностите се умножават, а не се събират — сборът би могъл да надхвърли 1."
    )
  )
end

# ---------------------------------------------------------------- Статистика ---

Authoring.family "stat.mean", topic: "Статистика", area: "advanced",
                 rungs: [ 1060, 1150, 1240, 1330, 1420, 1520 ] do |c|
  count = c.by_level([ 3, 4, 5, 5, 6, 8 ])
  mean = c.int(c.by_level([ 3..12, 4..20, 5..40, 8..80, 10..200, 15..500 ]))
  values = Array.new(count - 1) { mean + c.int(-mean / 2..mean / 2) }
  last = (mean * count) - values.sum
  raise Authoring::Duplicate if last.negative?

  values << last
  values = values.shuffle(random: c.rng)

  c.q(
    text: "Намери средното аритметично на числата #{values.join(', ')}.",
    answer: Num.ans(mean),
    explanation: Explain.build(
      idea: "Средното аритметично е сборът на всички стойности, разделен на техния брой.",
      steps: [
        "Сбор: #{values.join(' + ')} = #{values.sum}.",
        "Брой: #{count}.",
        "#{values.sum} : #{count} = #{mean}."
      ],
      answer: Num.ans(mean),
      check: "Средното лежи между най-малкото (#{values.min}) и най-голямото (#{values.max}).",
      watch: "Броят е #{count} — всички стойности се броят, включително повтарящите се."
    )
  )
end

Authoring.family "stat.median", topic: "Статистика", area: "advanced",
                 rungs: [ 1120, 1210, 1300, 1390, 1480, 1580 ] do |c|
  count = c.by_level([ 5, 5, 6, 7, 8, 9 ])
  values = Array.new(count) { c.int(c.by_level([ 1..20, 2..40, 3..80, 5..150, 8..400, 10..900 ])) }
  sorted = values.sort
  median = count.odd? ? sorted[count / 2] : Rational(sorted[(count / 2) - 1] + sorted[count / 2], 2)

  c.q(
    text: "Намери медианата на числата #{values.join(', ')}.",
    answer: Num.ans(median),
    explanation: Explain.build(
      idea: "Медианата е средната стойност след подреждане; при четен брой е средното на двете средни.",
      steps: [
        "Подредени: #{sorted.join(', ')}.",
        count.odd? ? "Броят е нечетен (#{count}), затова медианата е числото на позиция #{(count / 2) + 1}: #{sorted[count / 2]}." :
                     "Броят е четен (#{count}), затова медианата е средното на #{sorted[(count / 2) - 1]} и #{sorted[count / 2]}: #{Num.ans(median)}."
      ],
      answer: Num.ans(median),
      check: "От двете страни на медианата остават по #{count / 2} стойности.",
      watch: "Числата задължително се подреждат първо — медианата не е средното аритметично (#{Num.dec(Rational(values.sum, count), 2)})."
    )
  )
end

Authoring.family "stat.range_mode", topic: "Статистика", area: "advanced",
                 rungs: [ 1080, 1170, 1260, 1350, 1440, 1540 ] do |c|
  count = c.by_level([ 5, 6, 6, 7, 8, 9 ])
  values = Array.new(count - 2) { c.int(c.by_level([ 1..20, 2..40, 3..80, 5..150, 8..400, 10..900 ])) }
  repeated = c.pick(values)
  values += [ repeated, repeated ]
  values = values.shuffle(random: c.rng)
  ask_range = c.coin
  range = values.max - values.min
  raise Authoring::Duplicate if values.tally.values.count { |n| n == values.tally.values.max } > 1

  c.q(
    text: ask_range ? "Намери размаха на данните #{values.join(', ')}." :
                      "Коя е модата на данните #{values.join(', ')}?",
    answer: Num.ans(ask_range ? range : repeated),
    explanation: Explain.build(
      idea: ask_range ? "Размахът е разликата между най-голямата и най-малката стойност." :
                        "Модата е стойността, която се среща най-често.",
      steps: ask_range ?
        [ "Най-голяма: #{values.max}. Най-малка: #{values.min}.", "#{values.max} − #{values.min} = #{range}." ] :
        [ "Броим срещанията: #{values.tally.sort_by { |_, n| -n }.map { |value, n| "#{value} — #{n} пъти" }.join(', ')}.",
          "Най-често се среща #{repeated}." ],
      answer: Num.ans(ask_range ? range : repeated),
      check: ask_range ? "Всички стойности се побират в интервал с дължина #{range}." : "#{repeated} се среща #{values.count(repeated)} пъти — повече от всяка друга стойност.",
      watch: ask_range ? "Размахът е разлика, не сбор." : "Модата е стойност от данните, не броят на срещанията."
    )
  )
end

Authoring.family "stat.weighted_mean", topic: "Статистика", area: "advanced",
                 rungs: [ 1300, 1390, 1480, 1570, 1660, 1760 ] do |c|
  groups = c.by_level([ 2, 2, 3, 3, 4, 4 ])
  counts = Array.new(groups) { c.int(c.by_level([ 2..8, 3..12, 4..20, 5..30, 6..50, 8..90 ])) }
  values = c.sample((2..6).to_a, groups)
  raise Authoring::Duplicate if values.size < groups
  total_count = counts.sum
  total_sum = counts.zip(values).sum { |n, value| n * value }
  mean = Rational(total_sum, total_count)
  exact = mean.denominator == 1

  c.q(
    text: "В клас #{counts.zip(values).map { |n, value| "#{n} ученици имат оценка #{value}" }.join(', ')}. " \
          "Колко е средният успех на класа?#{exact ? '' : ' (Закръгли до стотни.)'}",
    answer: exact ? Num.ans(mean) : Num.dec2(mean),
    tolerance: exact ? nil : "0.01",
    explanation: Explain.build(
      idea: "Средната стойност при групи се смята с тегла: всяка оценка се брои толкова пъти, колкото ученици я имат.",
      steps: [
        "Сбор на оценките: #{counts.zip(values).map { |n, value| "#{n} · #{value}" }.join(' + ')} = #{total_sum}.",
        "Брой ученици: #{counts.join(' + ')} = #{total_count}.",
        "#{total_sum} : #{total_count} = #{exact ? mean : Num.dec2(mean)}."
      ],
      answer: exact ? Num.ans(mean) : Num.dec2(mean),
      check: "Средното е между най-малката (#{values.min}) и най-голямата (#{values.max}) оценка.",
      watch: "Не се осредняват самите оценки (#{Num.dec(Rational(values.sum, groups), 2)}) — групите са различно големи."
    )
  )
end

# ------------------------------------------------------------------ Анализ ---

Authoring.family "deriv.polynomial", topic: "Производна", area: "advanced",
                 rungs: [ 1700, 1790, 1880, 1970, 2060, 2160 ] do |c|
  a = c.int(c.by_level([ 1..3, 1..5, 2..8, 2..12, 3..20, 4..40 ]))
  b = c.int(c.by_level([ 1..5, 2..9, 3..14, 4..25, 5..50, 6..90 ]))
  cc = c.int(c.by_level([ 1..8, 2..15, 3..25, 4..40, 5..80, 6..150 ]))
  x = c.int(c.by_level([ 1..4, 1..6, -4..7, -6..9, -10..15, -20..30 ]))
  derivative_at = (2 * a * x) + b

  c.q(
    text: "Дадена е функцията f(x) = #{Num.quadratic(a, b, cc)}. Колко е f′(#{Num.bg(x)})?",
    answer: Num.ans(derivative_at),
    explanation: Explain.build(
      idea: "Диференцираме почленно: (xⁿ)′ = n·xⁿ⁻¹, а производната на константа е 0.",
      steps: [
        "f′(x) = #{2 * a}x + #{b}.",
        "f′(#{Num.bg(x)}) = #{2 * a} · #{Num.bg(x)} + #{b} = #{Num.bg(2 * a * x)} + #{b} = #{Num.bg(derivative_at)}."
      ],
      answer: "f′(#{Num.bg(x)}) = #{Num.bg(derivative_at)}",
      check: "Свободният член #{cc} не влияе на производната — той изчезва при диференциране.",
      watch: "Коефициентът пред x² се умножава по 2, а показателят пада с единица."
    )
  )
end

Authoring.family "deriv.tangent_slope", topic: "Производна", area: "advanced",
                 rungs: [ 1750, 1840, 1930, 2020, 2110, 2200 ] do |c|
  a = c.int(c.by_level([ 1..2, 1..4, 2..6, 2..10, 3..16, 4..30 ]))
  b = c.int(c.by_level([ 1..5, 2..9, 3..14, 4..25, 5..50, 6..90 ]))
  x = c.int(c.by_level([ 1..4, 1..6, -4..7, -6..9, -10..15, -20..30 ]))
  slope = (2 * a * x) + b

  c.q(
    text: "Колко е ъгловият коефициент на допирателната към графиката на f(x) = #{Num.quadratic(a, b, 0)} в точката с абсциса x = #{Num.bg(x)}?",
    answer: Num.ans(slope),
    explanation: Explain.build(
      idea: "Ъгловият коефициент на допирателната в дадена точка е стойността на производната там.",
      steps: [
        "f′(x) = #{2 * a}x + #{b}.",
        "k = f′(#{Num.bg(x)}) = #{2 * a} · #{Num.bg(x)} + #{b} = #{Num.bg(slope)}."
      ],
      answer: "k = #{Num.bg(slope)}",
      check: "Ако k = 0, допирателната е хоризонтална — тук #{slope.zero? ? 'точно това се случва' : "k = #{Num.bg(slope)} ≠ 0, значи не е"}.",
      watch: "Търси се производната в точката, а не стойността на функцията."
    )
  )
end

Authoring.family "deriv.extremum", topic: "Производна", area: "advanced",
                 rungs: [ 1800, 1890, 1980, 2070, 2160, 2250 ] do |c|
  a = c.int(c.by_level([ 1..2, 1..3, 1..5, 2..8, 2..14, 3..25 ]))
  vertex = c.int(c.by_level([ 1..5, -5..6, -8..8, -12..12, -20..20, -40..40 ]))
  b = -2 * a * vertex
  cc = c.int(-20..20)

  c.q(
    text: "За коя стойност на x функцията f(x) = #{Num.quadratic(a, b, cc)} има минимум?",
    answer: Num.ans(vertex),
    explanation: Explain.build(
      idea: "В точка на екстремум производната е нула; при a > 0 това е минимум.",
      steps: [
        "f′(x) = #{2 * a}x #{Num.term(b, '')}.",
        "#{2 * a}x #{Num.term(b, '')} = 0 дава x = #{Num.bg(-b)} : #{2 * a} = #{Num.bg(vertex)}.",
        "Понеже #{a} > 0, параболата е с клони нагоре и това е минимум."
      ],
      answer: "x = #{Num.bg(vertex)}",
      check: "f(#{Num.bg(vertex)}) = #{Num.bg((a * vertex * vertex) + (b * vertex) + cc)}, а съседните стойности f(#{Num.bg(vertex - 1)}) = #{Num.bg((a * (vertex - 1)**2) + (b * (vertex - 1)) + cc)} и f(#{Num.bg(vertex + 1)}) = #{Num.bg((a * (vertex + 1)**2) + (b * (vertex + 1)) + cc)} са по-големи.",
      watch: "Нулата на производната дава мястото на екстремума, а не стойността му."
    )
  )
end

Authoring.family "deriv.velocity", topic: "Производна", area: "advanced",
                 rungs: [ 1780, 1870, 1960, 2050, 2140, 2230 ] do |c|
  a = c.int(c.by_level([ 1..3, 1..5, 2..8, 2..12, 3..20, 4..40 ]))
  b = c.int(c.by_level([ 1..6, 2..10, 3..16, 4..30, 5..60, 6..120 ]))
  t = c.int(c.by_level([ 1..4, 1..6, 2..8, 2..12, 3..20, 4..40 ]))
  velocity = (2 * a * t) + b

  c.q(
    text: "Тяло се движи по закона s(t) = #{Num.quadratic(a, b, 0, 't')} (метри за t секунди). " \
          "Колко метра в секунда е скоростта му в момента t = #{t} s?",
    answer: Num.ans(velocity),
    explanation: Explain.build(
      idea: "Скоростта е производната на изминатия път по времето.",
      steps: [
        "v(t) = s′(t) = #{2 * a}t + #{b}.",
        "v(#{t}) = #{2 * a} · #{t} + #{b} = #{velocity} m/s."
      ],
      answer: "#{velocity} m/s",
      check: "Средната скорост между t = #{t} и t = #{t + 1} е #{((a * (t + 1)**2) + (b * (t + 1))) - ((a * t * t) + (b * t))} m/s — близо до моментната.",
      watch: "Пътят и скоростта са различни величини: s(#{t}) = #{(a * t * t) + (b * t)} м, но скоростта е #{velocity} m/s."
    )
  )
end
