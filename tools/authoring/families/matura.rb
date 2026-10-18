# Задачи от ДЗИ (матурата): производна, логаритмични и показателни уравнения,
# тригонометрия, решаване на триъгълник.
#
# The 12th-grade topics each had four families of the first, routine kind —
# evaluate a logarithm, differentiate a polynomial — so a student preparing for
# the матура cycled through them in a few sessions. These are the shapes the
# exam itself asks: the largest value on a closed interval, the tangent line,
# a log equation with a root the domain throws out, the 4ˣ − k·2ˣ + m = 0
# substitution, a ratio from one ratio and a quadrant, reduction formulas, and
# the median, circumradius and inradius of a triangle.

module Matura
  module_function

  # x³ − 6x² + 9x + 2, from its coefficients.
  def cubic(b, c, d)
    [ "x#{Num.sup(3)}", Num.term(b, "x#{Num.sup(2)}"), Num.term(c, "x"), Num.term(d, "") ].reject(&:empty?).join(" ")
  end

  # (x − 2), (x + 1), x — one factor of a factored polynomial.
  def factor(root)
    return "x" if root.zero?

    root.positive? ? "(x #{Num::MINUS} #{root})" : "(x + #{root.abs})"
  end

  # Integer sides up to `limit`, as triangles: every (a, b, c) with a ≤ b ≤ c.
  def triangles(limit)
    (1..limit).flat_map do |c|
      (1..c).flat_map { |b| (1..b).filter_map { |a| [ a, b, c ] if a + b > c } }
    end
  end

  # Triangles whose median to the longest-but-named side is a whole number.
  # The median to side c is ½√(2a² + 2b² − c²).
  MEDIANS = triangles(40).flat_map do |sides|
    sides.permutation.to_a.uniq.filter_map do |a, b, c|
      square = (2 * a * a) + (2 * b * b) - (c * c)
      next unless square.positive? && (square % 4).zero?

      root = Integer.sqrt(square / 4)
      [ a, b, c, root ] if root * root == square / 4
    end
  end.uniq.freeze

  # Triangles with a whole-number area and inradius (Heron's formula).
  INRADII = triangles(60).filter_map do |a, b, c|
    next unless (a + b + c).even?

    p = (a + b + c) / 2
    square = p * (p - a) * (p - b) * (p - c)
    area = Integer.sqrt(square)
    next unless area * area == square && area.positive? && (area % p).zero?

    [ a, b, c, area, area / p ]
  end.freeze

  # The rung's band of the longest side: each rung asks about a new size, so a
  # higher rung always has new triangles to ask about.
  def side_band(c, bounds)
    low = c.level.zero? ? 0 : bounds[c.level - 1]
    (low + 1)..bounds[c.level]
  end

  QUADRANTS = {
    1 => { range: "(0°; 90°)", sin: 1, cos: 1, name: "I" },
    2 => { range: "(90°; 180°)", sin: 1, cos: -1, name: "II" },
    3 => { range: "(180°; 270°)", sin: -1, cos: -1, name: "III" },
    4 => { range: "(270°; 360°)", sin: -1, cos: 1, name: "IV" }
  }.freeze

  # Values that come out rational, so the sum can be typed as a number.
  REDUCTION = {
    "sin" => { 0 => 0, 30 => Rational(1, 2), 90 => 1, 150 => Rational(1, 2), 180 => 0, 210 => Rational(-1, 2),
               270 => -1, 330 => Rational(-1, 2) },
    "cos" => { 0 => 1, 60 => Rational(1, 2), 90 => 0, 120 => Rational(-1, 2), 180 => -1, 240 => Rational(-1, 2),
               270 => 0, 300 => Rational(1, 2) },
    "tg" => { 0 => 0, 45 => 1, 135 => -1, 180 => 0, 225 => 1, 315 => -1 }
  }.freeze

  # The acute angle a reduction formula brings an angle back to.
  def reference(angle)
    a = angle % 360
    [ a, 180 - a, a - 180, 360 - a ].find { |value| value.between?(0, 90) }
  end

  # "+ 10 · 2ˣ", "− 2ˣ" — a signed coefficient in front of `symbol`.
  def times(coefficient, symbol)
    sign = coefficient.negative? ? Num::MINUS : "+"
    coefficient.abs == 1 ? "#{sign} #{symbol}" : "#{sign} #{coefficient.abs} · #{symbol}"
  end

  # "+ 16", "− 24"
  def plus(value) = "#{value.negative? ? Num::MINUS : '+'} #{value.abs}"

  def quadrant_of(angle)
    a = angle % 360
    return nil if (a % 90).zero?

    (a / 90) + 1
  end
end

# ------------------------------------------------------------------ Производна ---

Authoring.family "deriv.max_on_interval", topic: "Производна", area: "matura",
                 rungs: [ 1850, 1940, 2030, 2120, 2210, 2300 ] do |c|
  mid = c.int(c.by_level([ 0..1, -1..2, -2..2, -3..3, -4..4, -6..6 ]))
  half = c.int(c.by_level([ 1..2, 1..3, 1..3, 1..4, 2..5, 2..6 ]))
  r1 = mid - half
  r2 = mid + half
  # f′(x) = 3(x − r1)(x − r2), so f(x) = x³ − 3·mid·x² + 3·r1·r2·x + d.
  b = -3 * mid
  cc = 3 * r1 * r2
  d = c.int(-12..12)
  f = ->(x) { (x**3) + (b * x * x) + (cc * x) + d }

  # The low rungs hold both critical points; higher up the interval may cut one
  # off, and then the answer often sits at an end of it.
  lo = c.level >= 3 && c.coin ? c.int((r1 + 1)..r2) : c.int((r1 - 2)..(r1 - 1))
  hi = c.int((r2 + 1)..(r2 + 2))
  raise Authoring::Duplicate unless lo < hi

  ask = c.coin ? :max : :min
  inside = [ r1, r2 ].select { |r| r > lo && r < hi }
  points = ([ lo, hi ] + inside).uniq.sort
  values = points.to_h { |x| [ x, f.(x) ] }
  answer = ask == :max ? values.values.max : values.values.min
  word = ask == :max ? "най-голямата" : "най-малката"

  c.q(
    text: "Намерете #{word} стойност на функцията f(x) = #{Matura.cubic(b, cc, d)} в интервала [#{Num.bg(lo)}; #{Num.bg(hi)}].",
    answer: Num.ans(answer),
    explanation: Explain.build(
      idea: "Непрекъсната функция в затворен интервал достига #{word} си стойност или в нула на производната, или в край на интервала — сравняваме всички тези стойности.",
      steps: [
        "f′(x) = #{Num.quadratic(3, 2 * b, cc)} = 3#{Matura.factor(r1)}#{Matura.factor(r2)}.",
        "Нулите на f′ са x = #{Num.bg(r1)} и x = #{Num.bg(r2)}; " +
          (inside.empty? ? "нито една не е вътре в интервала." : "в интервала #{inside.size == 1 ? 'е' : 'са'} #{inside.map { |r| "x = #{Num.bg(r)}" }.join(' и ')}."),
        "Стойности: #{values.map { |x, v| "f(#{Num.bg(x)}) = #{Num.bg(v)}" }.join(', ')}.",
        "#{word.capitalize} от тях е #{Num.bg(answer)}."
      ],
      answer: Num.bg(answer),
      check: "f(#{Num.bg(values.key(answer))}) = #{Num.bg(answer)}, а всяка друга от сравнените стойности е #{ask == :max ? 'по-малка' : 'по-голяма'}.",
      watch: "Не стига да се намери екстремумът: #{word} стойност в затворен интервал може да е в края му."
    ),
    hints: [ "Намери нулите на производната и виж кои от тях са в интервала.",
             "Сравни стойностите на f в тези точки и в двата края на интервала." ]
  )
end

Authoring.family "deriv.tangent_line", topic: "Производна", area: "matura",
                 rungs: [ 1750, 1840, 1930, 2020, 2110, 2200 ] do |c|
  cubic = c.level >= 3
  a = c.int(c.by_level([ 1..2, 1..3, 1..4, 1..2, 1..3, 1..4 ])) * (c.coin ? 1 : -1)
  b = c.int(-6..6)
  cc = c.int(-9..9)
  x0 = c.int(c.by_level([ 1..2, -2..3, -3..3, -2..2, -3..3, -4..4 ]))
  raise Authoring::Duplicate if x0.zero?

  if cubic
    f = ->(x) { (a * (x**3)) + (b * x) + cc }
    fp = ->(x) { (3 * a * x * x) + b }
    formula = [ Num.lead(a, "x#{Num.sup(3)}"), Num.term(b, "x"), Num.term(cc, "") ].reject(&:empty?).join(" ")
    derivative = "#{Num.lead(3 * a, "x#{Num.sup(2)}")} #{Num.term(b, '')}".strip
  else
    f = ->(x) { (a * x * x) + (b * x) + cc }
    fp = ->(x) { (2 * a * x) + b }
    formula = Num.quadratic(a, b, cc)
    derivative = Num.linear(2 * a, b)
  end
  k = fp.(x0)
  y0 = f.(x0)
  m = y0 - (k * x0)

  c.q(
    text: "Допирателната към графиката на f(x) = #{formula} в точката с абсциса x₀ = #{Num.bg(x0)} има уравнение y = kx + m. Намерете m.",
    answer: Num.ans(m),
    explanation: Explain.build(
      idea: "Допирателната в x₀ е y = f(x₀) + f′(x₀)(x − x₀): ъгловият коефициент е производната, а правата минава през точката от графиката.",
      steps: [
        "f(#{Num.bg(x0)}) = #{Num.bg(y0)}.",
        "f′(x) = #{derivative}, затова k = f′(#{Num.bg(x0)}) = #{Num.bg(k)}.",
        "m = f(x₀) − k · x₀ = #{Num.bg(y0)} − #{Num.signed(k)} · #{Num.signed(x0)} = #{Num.bg(m)}."
      ],
      answer: "m = #{Num.bg(m)}",
      check: "Правата y = #{Num.linear(k, m)} минава през (#{Num.bg(x0)}; #{Num.bg(y0)}): #{Num.signed(k)} · #{Num.signed(x0)} + #{Num.signed(m)} = #{Num.bg(y0)}.",
      watch: "m не е f(x₀): правата минава през точката (x₀; f(x₀)), а не през (0; f(x₀))."
    )
  )
end

Authoring.family "deriv.quotient_value", topic: "Производна", area: "matura",
                 rungs: [ 1700, 1790, 1880, 1970, 2060, 2150 ] do |c|
  spread = c.by_level([ 1..3, 1..4, 1..6, 2..8, 2..10, 3..14 ])
  a, b, cc, d = Array.new(4) { c.int(spread) * (c.coin ? 1 : -1) }
  x0 = c.int(c.by_level([ 0..2, -2..3, -3..3, -4..4, -5..5, -6..6 ]))
  det = (a * d) - (b * cc)
  bottom = (cc * x0) + d
  raise Authoring::Duplicate if det.zero? || bottom.zero?

  value = Rational(det, bottom * bottom)

  c.q(
    text: "Дадена е функцията f(x) = (#{Num.linear(a, b)})/(#{Num.linear(cc, d)}). Пресметнете f′(#{Num.bg(x0)}).",
    answer: Num.ans(value),
    explanation: Explain.build(
      idea: "Производна на частно: (u : v)′ = (u′v − uv′) : v². За две линейни функции числителят се свежда до константа.",
      steps: [
        "u = #{Num.linear(a, b)}, u′ = #{Num.bg(a)}; v = #{Num.linear(cc, d)}, v′ = #{Num.bg(cc)}.",
        "u′v − uv′ = #{Num.signed(a)}(#{Num.linear(cc, d)}) − #{Num.signed(cc)}(#{Num.linear(a, b)}) = #{Num.bg(det)}.",
        "f′(x) = #{Num.bg(det)} : (#{Num.linear(cc, d)})#{Num.sup(2)}.",
        "При x = #{Num.bg(x0)}: v = #{Num.bg(bottom)}, f′(#{Num.bg(x0)}) = #{Num.bg(det)} : #{Num.bg(bottom * bottom)} = #{Num.bg(value)}."
      ],
      answer: Num.bg(value),
      check: "Числителят е ad − bc = #{Num.signed(a)} · #{Num.signed(d)} − #{Num.signed(b)} · #{Num.signed(cc)} = #{Num.bg(det)}.",
      watch: "Редът в числителя е u′v − uv′; разменен, дава същото число с обратен знак."
    )
  )
end

# ------------------------------------------------- Логаритми и показателни ---

Authoring.family "log.equation_domain", topic: "Логаритмична функция", area: "matura",
                 rungs: [ 1800, 1890, 1980, 2070, 2160, 2250 ] do |c|
  base = c.pick(c.by_level([ [ 2 ], [ 2, 3 ], [ 2, 3 ], [ 2, 3, 5 ], [ 2, 3, 5, 6 ], [ 2, 3, 5, 6, 10 ] ]))
  n = c.int(c.by_level([ 2..3, 2..4, 3..5, 2..5, 3..6, 3..7 ]))
  product = base**n
  raise Authoring::Duplicate if product > 10_000

  small = c.pick((1...Integer.sqrt(product) + 1).select { |s| (product % s).zero? && s * s < product })
  big = product / small
  k = big - small
  minus = c.coin
  log = "log#{Num.sub_digits(base)}"

  if minus
    equation = "#{log} x + #{log} (x #{Num::MINUS} #{k}) = #{n}"
    domain = "x > #{k}"
    quadratic = "x#{Num.sup(2)} #{Num::MINUS} #{k}x #{Num::MINUS} #{product} = 0"
    answer = big
    rejected = -small
  else
    equation = "#{log} x + #{log} (x + #{k}) = #{n}"
    domain = "x > 0"
    quadratic = "x#{Num.sup(2)} + #{k}x #{Num::MINUS} #{product} = 0"
    answer = small
    rejected = -big
  end

  c.q(
    text: "Решете уравнението #{equation}.",
    answer: Num.ans(answer),
    explanation: Explain.build(
      idea: "Сбор от логаритми с една основа е логаритъм от произведението; накрая всеки корен се проверява в дефиниционното множество.",
      steps: [
        "ДМ: и двата аргумента са положителни, т.е. #{domain}.",
        "#{log} (x(x #{minus ? Num::MINUS : '+'} #{k})) = #{n}, значи x(x #{minus ? Num::MINUS : '+'} #{k}) = #{Num.power(base, n)} = #{product}.",
        "#{quadratic} има корени x = #{answer} и x = #{Num.bg(rejected)}.",
        "x = #{Num.bg(rejected)} не е в ДМ и отпада."
      ],
      answer: "x = #{answer}",
      check: "#{log} #{answer} + #{log} #{minus ? answer - k : answer + k} = #{log} #{product} = #{n}.",
      watch: "Отрицателният корен на квадратното уравнение не е решение — логаритъм от отрицателно число не съществува."
    ),
    hints: [ "Събери логаритмите в един: log a + log b = log (a · b).",
             "Не забравяй да провериш кои корени са в дефиниционното множество." ]
  )
end

Authoring.family "exp.substitution", topic: "Показателна функция", area: "matura",
                 rungs: [ 1850, 1940, 2030, 2120, 2210, 2300 ] do |c|
  base = c.pick(c.by_level([ [ 2 ], [ 3 ], [ 2, 3 ], [ 2, 3 ], [ 2, 3 ], [ 2, 3, 5 ] ]))
  one_root = c.level >= 3 && c.coin
  square = base * base
  power = "#{square}#{Num.sup('x')}"
  t = "#{base}#{Num.sup('x')}"

  if one_root
    p = c.int(1..c.by_level([ 3, 3, 3, 4, 4, 3 ]))
    big = base**p
    m = c.int(1..12)
    raise Authoring::Duplicate if m == big

    # t² + (m − big)t − m·big = 0 has roots t = big and t = −m.
    middle = m - big
    constant = -m * big
    equation = "#{power} #{Matura.times(middle, t)} #{Matura.plus(constant)} = 0"
    in_t = "t#{Num.sup(2)} #{Matura.times(middle, 't').sub(' · t', 't')} #{Matura.plus(constant)} = 0"
    roots_t = "t = #{big} и t = #{Num.bg(-m)}"
    tail = "t = #{Num.bg(-m)} отпада, защото #{t} > 0. От #{t} = #{big} = #{Num.power(base, p)} следва x = #{p}."
    question = "Решете уравнението #{equation}."
    answer = p
    answer_text = "x = #{p}"
    check = "#{square}#{Num.sup(p.to_s)} #{Matura.times(middle, big)} #{Matura.plus(constant)} = #{big * big} #{Matura.plus(middle * big)} #{Matura.plus(constant)} = 0."
  else
    p, q = c.sample((0..c.by_level([ 3, 3, 4, 4, 4, 3 ])).to_a, 2).sort
    small = base**p
    big = base**q
    equation = "#{power} #{Num::MINUS} #{small + big} · #{t} + #{small * big} = 0"
    in_t = "t#{Num.sup(2)} #{Num::MINUS} #{small + big}t + #{small * big} = 0"
    roots_t = "t = #{small} и t = #{big}"
    tail = "#{t} = #{small} = #{Num.power(base, p)} дава x = #{p}; #{t} = #{big} = #{Num.power(base, q)} дава x = #{q}."
    question = "Колко е сборът от корените на уравнението #{equation}?"
    answer = p + q
    answer_text = "#{p} + #{q} = #{p + q}"
    check = "При x = #{q}: #{big * big} − #{small + big} · #{big} + #{small * big} = 0."
  end

  c.q(
    text: question,
    answer: Num.ans(answer),
    explanation: Explain.build(
      idea: "#{power} = (#{t})#{Num.sup(2)}, затова полагаме t = #{t} > 0 и решаваме квадратно уравнение.",
      steps: [
        "С t = #{t}: #{in_t}.",
        "Корените са #{roots_t}.",
        tail
      ],
      answer: answer_text,
      check: check,
      watch: "#{t} е винаги положително — отрицателен корен за t не дава решение за x."
    ),
    hints: [ "Забележи, че #{power} = (#{t})#{Num.sup(2)}. Положи t = #{t}." ]
  )
end

# -------------------------------------------------------------- Тригонометрия ---

Authoring.family "trig.from_one_ratio", topic: "Тригонометрични функции", area: "matura",
                 rungs: [ 1650, 1740, 1830, 1920, 2010, 2100 ] do |c|
  leg, other, hyp = c.pick(PRIMITIVE_TRIPLES.first(c.by_level([ 2, 3, 4, 5, 6, 8 ])))
  leg, other = other, leg if c.coin
  quadrant = c.by_level([ 1, 2, 2, 3, 4, c.int(2..4) ])
  given_sin = c.level < 5 || c.coin
  ask = c.by_level([ :other, :other, :tg, c.pick([ :other, :tg ]), c.pick([ :other, :tg ]), :tg ])
  signs = Matura::QUADRANTS.fetch(quadrant)

  sin = Rational(signs[:sin] * (given_sin ? leg : other), hyp)
  cos = Rational(signs[:cos] * (given_sin ? other : leg), hyp)
  given_name, given_value = given_sin ? [ "sin", sin ] : [ "cos", cos ]
  other_name, other_value = given_sin ? [ "cos", cos ] : [ "sin", sin ]
  tg = sin / cos
  answer, asked = ask == :tg ? [ tg, "tg α" ] : [ other_value, "#{other_name} α" ]

  c.q(
    text: "Ако #{given_name} α = #{Num.bg(given_value)} и α ∈ #{signs[:range]}, намерете #{asked}.",
    answer: Num.ans(answer),
    explanation: Explain.build(
      idea: "От sin²α + cos²α = 1 намираме втората функция по абсолютна стойност, а знакът ѝ се чете от квадранта.",
      steps: [
        "#{other_name}²α = 1 − (#{Num.bg(given_value)})² = 1 − #{Num.frac(given_value**2)} = #{Num.frac(other_value**2)}.",
        "α е в #{signs[:name]} квадрант, където #{other_name} α #{other_value.positive? ? '> 0' : '< 0'}, затова #{other_name} α = #{Num.bg(other_value)}.",
        ("tg α = sin α : cos α = #{Num.bg(sin)} : #{Num.signed(cos)} = #{Num.bg(tg)}." if ask == :tg)
      ],
      answer: "#{asked} = #{Num.bg(answer)}",
      check: "(#{Num.bg(sin)})² + (#{Num.bg(cos)})² = #{Num.frac(sin**2)} + #{Num.frac(cos**2)} = 1.",
      watch: "Коренът дава две стойности ±#{Num.frac(other_value.abs)} — квадрантът решава коя е вярната."
    ),
    hints: [ "Използвай sin²α + cos²α = 1.", "В #{signs[:name]} квадрант кои от sin и cos са отрицателни?" ]
  )
end

Authoring.family "trig.reduction_sum", topic: "Тригонометрични функции", area: "matura",
                 rungs: [ 1600, 1690, 1780, 1870, 1960, 2050 ] do |c|
  limit = c.by_level([ 90, 180, 360, 360, 720, 720 ])
  count = c.by_level([ 2, 2, 2, 3, 3, 3 ])
  pool = Matura::REDUCTION.flat_map do |name, table|
    table.keys.flat_map { |angle| [ angle, angle + 360 ].map { |a| [ name, a ] } }
  end.select { |_, angle| angle <= limit }.uniq
  # Past the first rung at least one angle needs a reduction formula.
  terms = c.sample(pool, count)
  raise Authoring::Duplicate if c.level.positive? && terms.all? { |_, angle| angle <= 90 }
  raise Authoring::Duplicate if terms.map(&:last).uniq.size < count

  signs = [ 1 ] + Array.new(count - 1) { c.coin ? 1 : -1 }
  values = terms.map { |name, angle| Matura::REDUCTION.fetch(name).fetch(angle % 360) }
  total = signs.zip(values).sum { |sign, value| sign * value }

  expression = terms.each_with_index.map do |(name, angle), index|
    word = "#{name} #{angle}°"
    next word if index.zero?

    "#{signs[index].positive? ? '+' : Num::MINUS} #{word}"
  end.join(" ")

  explain = terms.zip(values).map do |(name, angle), value|
    reduced = Matura.reference(angle)
    quadrant = Matura.quadrant_of(angle)
    where = quadrant ? "ъгъл в #{Matura::QUADRANTS.fetch(quadrant)[:name]} квадрант, свежда се до #{reduced}°" : "ъгъл на оста"
    "#{name} #{angle}° = #{Num.bg(value)} (#{angle >= 360 ? "#{angle}° = 360° + #{angle - 360}°; " : ''}#{where})."
  end

  c.q(
    text: "Пресметнете #{expression}.",
    answer: Num.ans(total),
    explanation: Explain.build(
      idea: "Всеки ъгъл се свежда до остър (или ъгъл на оста) с формулите за привеждане; знакът идва от квадранта.",
      steps: explain + [ "#{expression} = #{signs.zip(values).each_with_index.map { |(sign, value), i| i.zero? ? Num.bg(value) : "#{sign.positive? ? '+' : Num::MINUS} #{Num.signed(value)}" }.join(' ')} = #{Num.bg(total)}." ],
      answer: Num.bg(total),
      check: "Знаците: sin е положителен в I и II квадрант, cos — в I и IV, tg — в I и III.",
      watch: "Периодът е 360° за sin и cos (и 180° за tg) — ъгъл над 360° първо се намалява с 360°."
    )
  )
end

# --------------------------------------------------------- Решаване на триъгълник ---

Authoring.family "tri.median_length", topic: "Решаване на триъгълник", area: "matura",
                 rungs: [ 1800, 1890, 1980, 2070, 2160, 2250 ] do |c|
  band = Matura.side_band(c, [ 10, 15, 20, 26, 32, 40 ])
  a, b, side, median = c.pick(Matura::MEDIANS.select { |sides| band.cover?(sides.first(3).max) })
  raise Authoring::Duplicate if a == b && c.level >= 2 # an isosceles median is the altitude, an easier problem

  square = (2 * a * a) + (2 * b * b) - (side * side)

  c.q(
    text: "В триъгълник ABC страните са BC = #{a} см, AC = #{b} см и AB = #{side} см. Намерете дължината на медианата CM.",
    answer: Num.ans(median),
    explanation: Explain.build(
      idea: "Медианата към страна c се намира по формулата m_c² = (2a² + 2b² − c²) : 4, която следва от косинусовата теорема.",
      steps: [
        "Медианата CM е към страната AB = #{side}.",
        "2 · #{a}² + 2 · #{b}² − #{side}² = #{2 * a * a} + #{2 * b * b} − #{side * side} = #{square}.",
        "CM² = #{square} : 4 = #{square / 4}, CM = #{median} см."
      ],
      answer: "#{median} см",
      check: "#{median}² = #{median * median} и 4 · #{median * median} = #{square}.",
      watch: "c във формулата е страната, *към която* е медианата — тук AB, а не BC или AC."
    )
  )
end

Authoring.family "tri.circumradius", topic: "Решаване на триъгълник", area: "matura",
                 rungs: [ 1700, 1790, 1880, 1970, 2060, 2150 ] do |c|
  kind = c.by_level([ :side_30, :side_any, :radius_given, :two_angles, :two_angles, :two_angles_radius ])
  alpha = c.by_level([ [ 30 ], [ 30, 150, 90 ], [ 30, 150, 90 ], [ 30, 150 ], [ 30, 150, 90 ], [ 30, 150, 90 ] ]).then { c.pick(_1) }
  sin = alpha == 90 ? 1 : Rational(1, 2)
  side = c.int(c.by_level([ 3..12, 4..20, 4..24, 5..30, 6..40, 8..60 ]))
  side *= 2 if alpha == 90 && side.odd? && kind != :radius_given && kind != :two_angles_radius
  radius = alpha == 90 ? side / 2 : side
  sin_text = alpha == 90 ? "1" : "1/2"

  angles_text =
    if %i[two_angles two_angles_radius].include?(kind)
      beta = c.int(10..(180 - alpha - 10))
      gamma = 180 - alpha - beta
      raise Authoring::Duplicate if beta == gamma

      "∠B = #{beta}° и ∠C = #{gamma}°"
    else
      "∠A = #{alpha}°"
    end

  if %i[radius_given two_angles_radius].include?(kind)
    radius = c.int(c.by_level([ 3..12, 4..20, 4..24, 5..30, 6..40, 8..60 ]))
    side = alpha == 90 ? 2 * radius : radius
    text = "В триъгълник ABC #{angles_text}, а радиусът на описаната окръжност е R = #{radius} см. Намерете BC."
    answer = side
    final = "BC = 2R · sin A = 2 · #{radius} · #{sin_text} = #{side} см."
  else
    text = "В триъгълник ABC страната BC е #{side} см, а #{angles_text}. Намерете радиуса R на описаната окръжност."
    answer = radius
    final = "R = BC : (2 sin A) = #{side} : (2 · #{sin_text}) = #{radius} см."
  end

  c.q(
    text: text,
    answer: Num.ans(answer),
    explanation: Explain.build(
      idea: "Синусовата теорема: BC : sin A = 2R — страната и срещулежащият ѝ ъгъл дават радиуса на описаната окръжност.",
      steps: [
        (angles_text.start_with?("∠B") ? "∠A = 180° − #{angles_text.scan(/\d+/).join('° − ')}° = #{alpha}°." : nil),
        "sin #{alpha}° = #{sin_text}.",
        final
      ],
      answer: "#{answer} см",
      check: "#{side} : #{sin_text} = #{2 * radius} = 2 · #{radius}.",
      watch: alpha == 150 ? "sin 150° = sin 30° = 1/2 — тъп ъгъл не променя формулата." : "BC лежи срещу ∠A — във формулата влиза точно този ъгъл."
    )
  )
end

Authoring.family "tri.inradius", topic: "Решаване на триъгълник", area: "matura",
                 rungs: [ 1850, 1940, 2030, 2120, 2210, 2300 ] do |c|
  band = Matura.side_band(c, [ 15, 20, 26, 34, 44, 60 ])
  a, b, side, area, r = c.pick(Matura::INRADII.select { |t| band.cover?(t[2]) })
  p = (a + b + side) / 2

  c.q(
    text: "Страните на триъгълник са #{a} см, #{b} см и #{side} см. Намерете радиуса на вписаната в него окръжност.",
    answer: Num.ans(r),
    explanation: Explain.build(
      idea: "Лицето е S = p · r, където p е полупериметърът; лицето се намира по Херонова формула.",
      steps: [
        "p = (#{a} + #{b} + #{side}) : 2 = #{p}.",
        "S = √(#{p} · #{p - a} · #{p - b} · #{p - side}) = √#{area * area} = #{area} см².",
        "r = S : p = #{area} : #{p} = #{r} см."
      ],
      answer: "#{r} см",
      check: "p · r = #{p} · #{r} = #{area} = S.",
      watch: "Във формулата S = p · r влиза полупериметърът, не целият периметър (#{2 * p})."
    ),
    hints: [ "Свържи лицето с радиуса: S = p · r.", "Лицето намери по Херонова формула." ]
  )
end
