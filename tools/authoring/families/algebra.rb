# Алгебра: степени и корени, рационални изрази, квадратни уравнения,
# системи и неравенства.
#
# Symbolic answers go through options — ExactValue compares non-numeric answers
# as strings, and "(x+3)(x-2)" typed with different spacing would be marked
# wrong. Numeric answers stay exact-value.

# --------------------------------------------------------- Степени и корени ---

Authoring.family "pow.evaluate", topic: "Степени и корени", area: "algebra",
                 rungs: [ 1080, 1170, 1260, 1350, 1440, 1540 ] do |c|
  spec = c.by_level([ [ 2..5, 2..2 ], [ 2..9, 2..3 ], [ 2..12, 2..3 ],
                      [ 2..8, 3..4 ], [ 2..6, 3..5 ], [ 2..5, 4..7 ] ])
  base = c.int(spec[0])
  exponent = c.int(spec[1])
  value = base**exponent
  raise Authoring::Duplicate if value > 200_000

  c.q(
    text: "Пресметни #{Num.power(base, exponent)}.",
    answer: Num.ans(value),
    explanation: Explain.build(
      idea: "Степента е кратко записано повторено умножение: основата се умножава по себе си толкова пъти, колкото показва показателят.",
      steps: [
        "#{Num.power(base, exponent)} = #{([ base ] * exponent).join(' · ')}.",
        (1...exponent).map { |i| "#{base**i} · #{base} = #{base**(i + 1)}" }.join(", ") + "."
      ],
      answer: Num.ans(value),
      check: "#{value} : #{base} = #{value / base} = #{Num.power(base, exponent - 1)}.",
      watch: "#{Num.power(base, exponent)} не е #{base} · #{exponent} = #{base * exponent}."
    )
  )
end

Authoring.family "pow.same_base", topic: "Степени и корени", area: "algebra",
                 rungs: [ 1150, 1240, 1330, 1420, 1510, 1610 ] do |c|
  base = c.int(c.by_level([ 2..3, 2..4, 2..5, 2..6, 2..8, 2..10 ]))
  m = c.int(2..c.by_level([ 4, 5, 6, 8, 10, 14 ]))
  n = c.int(1..c.by_level([ 3, 4, 5, 6, 8, 10 ]))
  divide = c.coin && m > n
  exponent = divide ? m - n : m + n
  value = base**exponent
  raise Authoring::Duplicate if value > 500_000

  c.q(
    text: "Пресметни #{Num.power(base, m)} #{divide ? ':' : '·'} #{Num.power(base, n)}.",
    answer: Num.ans(value),
    explanation: Explain.build(
      idea: divide ? "При деление на степени с равни основи показателите се изваждат." :
                     "При умножение на степени с равни основи показателите се събират.",
      steps: [
        divide ? "#{m} − #{n} = #{exponent}, значи изразът е #{Num.power(base, exponent)}." :
                 "#{m} + #{n} = #{exponent}, значи изразът е #{Num.power(base, exponent)}.",
        "#{Num.power(base, exponent)} = #{value}."
      ],
      answer: Num.ans(value),
      check: "#{Num.power(base, m)} = #{base**m} и #{Num.power(base, n)} = #{base**n}: #{base**m} #{divide ? ':' : '·'} #{base**n} = #{value}.",
      watch: "Основата не се променя — тя остава #{base}, а не става #{base * base}."
    )
  )
end

Authoring.family "pow.power_of_power", topic: "Степени и корени", area: "algebra",
                 rungs: [ 1250, 1340, 1430, 1520, 1610, 1710 ] do |c|
  base = c.int(c.by_level([ 2..3, 2..4, 2..5, 2..6, 2..7, 2..9 ]))
  m = c.int(2..c.by_level([ 3, 3, 4, 4, 5, 6 ]))
  n = c.int(2..c.by_level([ 2, 3, 3, 4, 4, 5 ]))
  exponent = m * n
  value = base**exponent
  raise Authoring::Duplicate if value > 1_000_000

  c.q(
    text: "Пресметни (#{Num.power(base, m)})#{Num.sup(n)}.",
    answer: Num.ans(value),
    explanation: Explain.build(
      idea: "При степенуване на степен основата остава същата, а показателите се умножават.",
      steps: [
        "Показателите се умножават: #{m} · #{n} = #{exponent}.",
        "(#{Num.power(base, m)})#{Num.sup(n)} = #{Num.power(base, exponent)}.",
        "#{Num.power(base, exponent)} = #{value}."
      ],
      answer: Num.ans(value),
      check: "#{Num.power(base, m)} = #{base**m}, а #{base**m}#{Num.sup(n)} = #{value}.",
      watch: "Показателите се умножават (#{m} · #{n} = #{exponent}), не се събират (#{m + n})."
    )
  )
end

Authoring.family "pow.negative_exponent", topic: "Степени и корени", area: "algebra",
                 rungs: [ 1400, 1490, 1580, 1670, 1760, 1860 ] do |c|
  base = c.int(c.by_level([ 2..3, 2..4, 2..5, 2..6, 2..8, 2..10 ]))
  exponent = c.int(1..c.by_level([ 2, 2, 3, 3, 4, 5 ]))
  value = Rational(1, base**exponent)

  c.q(
    text: "Пресметни #{base}#{Num.sup(-exponent)} и запиши отговора като дроб.",
    answer: Num.frac(value),
    explanation: Explain.build(
      idea: "Отрицателният показател означава обратна стойност: a на степен −n е 1 върху a на степен n.",
      steps: [
        "#{base}#{Num.sup(-exponent)} = 1 : #{Num.power(base, exponent)}.",
        "#{Num.power(base, exponent)} = #{base**exponent}, значи стойността е #{Num.frac(value)}."
      ],
      answer: Num.frac(value),
      check: "#{base}#{Num.sup(-exponent)} · #{Num.power(base, exponent)} = #{base}#{Num.sup(0)} = 1.",
      watch: "Отрицателният показател не прави числото отрицателно — резултатът е положителна дроб."
    )
  )
end

Authoring.family "sqrt.perfect", topic: "Степени и корени", area: "algebra",
                 rungs: [ 1100, 1190, 1280, 1370, 1460, 1560 ] do |c|
  root = c.int(c.by_level([ 2..10, 4..15, 8..22, 12..32, 20..50, 30..99 ]))
  square = root * root

  c.q(
    text: "Пресметни корен квадратен от #{square}.",
    answer: Num.ans(root),
    explanation: Explain.build(
      idea: "Търсим неотрицателното число, чийто квадрат е #{square}.",
      steps: [
        "#{root} · #{root} = #{square}.",
        "Значи √#{square} = #{root}."
      ],
      answer: Num.ans(root),
      check: "#{root}² = #{square} — проверката е самото повдигане на квадрат.",
      watch: "√#{square} не е #{square} : 2 = #{Num.dec(Rational(square, 2), 1)} — коренът не е половината."
    )
  )
end

Authoring.family "sqrt.simplify", topic: "Степени и корени", area: "algebra",
                 rungs: [ 1450, 1540, 1630, 1720, 1810, 1910 ] do |c|
  outside = c.int(c.by_level([ 2..3, 2..4, 2..5, 3..7, 4..9, 5..12 ]))
  inside = c.pick([ 2, 3, 5, 6, 7, 10, 11, 13 ])
  radicand = outside * outside * inside
  correct = "#{outside}√#{inside}"

  c.q(
    text: "Опрости √#{radicand}.",
    options: c.options(correct, "#{outside * inside}√#{inside}", "#{outside}√#{inside * outside}", "√#{radicand}"),
    answer: correct,
    explanation: Explain.build(
      idea: "Изваждаме изпод корена най-големия точен квадрат, който дели подкоренното число.",
      steps: [
        "#{radicand} = #{outside * outside} · #{inside}, а #{outside * outside} = #{outside}².",
        "√#{radicand} = √#{outside * outside} · √#{inside} = #{outside}√#{inside}."
      ],
      answer: correct,
      check: "(#{outside}√#{inside})² = #{outside * outside} · #{inside} = #{radicand}.",
      watch: "Изнесеното число излиза като корен от квадрата — #{outside}, не #{outside * outside}."
    )
  )
end

Authoring.family "pow.scientific", topic: "Степени и корени", area: "algebra",
                 rungs: [ 1350, 1440, 1530, 1620, 1710, 1810 ] do |c|
  mantissa = c.int(11..99)
  exponent = c.int(c.by_level([ 2..3, 3..4, 4..5, 5..7, 6..9, 8..12 ]))
  value = mantissa * (10**(exponent - 1))
  correct = "#{Num.dec(Rational(mantissa, 10), 1)} · 10#{Num.sup(exponent)}"

  c.q(
    text: "Запиши числото #{value} в стандартен вид (a · 10ⁿ, където 1 ≤ a < 10).",
    options: c.options(correct,
                       "#{mantissa} · 10#{Num.sup(exponent - 1)}",
                       "#{Num.dec(Rational(mantissa, 10), 1)} · 10#{Num.sup(exponent + 1)}",
                       "#{Num.dec(Rational(mantissa, 100), 2)} · 10#{Num.sup(exponent + 1)}"),
    answer: correct,
    explanation: Explain.build(
      idea: "Запетаята се мести така, че пред нея да остане една цифра; броят премествания е показателят на 10.",
      steps: [
        "#{value} има #{value.to_s.size} цифри, значи запетаята се мести #{exponent} места наляво.",
        "Получава се #{Num.dec(Rational(mantissa, 10), 1)}, а изгубените места се компенсират с 10#{Num.sup(exponent)}."
      ],
      answer: correct,
      check: "#{Num.dec(Rational(mantissa, 10), 1)} · 10#{Num.sup(exponent)} = #{value}.",
      watch: "Множителят a трябва да е между 1 и 10 — затова #{mantissa} · 10#{Num.sup(exponent - 1)} не е стандартен вид."
    )
  )
end

Authoring.family "sqrt.equation", topic: "Степени и корени", area: "algebra",
                 rungs: [ 1300, 1390, 1480, 1570, 1660, 1760 ] do |c|
  root = c.int(c.by_level([ 2..8, 3..12, 4..18, 5..25, 8..40, 10..70 ]))
  square = root * root

  c.q(
    text: "Реши уравнението x² = #{square}. Кой е положителният корен?",
    answer: Num.ans(root),
    explanation: Explain.build(
      idea: "Уравнението x² = a има два корена: √a и −√a.",
      steps: [
        "√#{square} = #{root}, защото #{root} · #{root} = #{square}.",
        "Значи x = #{root} или x = #{Num::MINUS}#{root}; търси се положителният."
      ],
      answer: "x = #{root}",
      check: "#{root}² = #{square} и (#{Num::MINUS}#{root})² = #{square} — и двата корена стават.",
      watch: "Отрицателният корен също е решение — забравя се често, макар тук да не се търси."
    )
  )
end

# ------------------------------------------------------- Рационални изрази ---

Authoring.family "rat.expand_square", topic: "Рационални изрази", area: "algebra",
                 rungs: [ 1350, 1440, 1530, 1620, 1710, 1810 ] do |c|
  a = c.int(c.by_level([ 1..2, 1..3, 1..4, 2..5, 2..7, 3..9 ]))
  b = c.int(c.by_level([ 1..5, 2..8, 3..12, 4..15, 5..20, 6..30 ]))
  minus = c.coin
  correct = "#{Num.monomial(a * a, 'x²')} #{minus ? Num::MINUS : '+'} #{2 * a * b}x + #{b * b}"

  c.q(
    text: "Разкрий скобите: (#{Num.monomial(a, 'x')} #{minus ? Num::MINUS : '+'} #{b})².",
    options: c.options(correct,
                       "#{Num.monomial(a * a, 'x²')} + #{b * b}",
                       "#{Num.monomial(a * a, 'x²')} #{minus ? Num::MINUS : '+'} #{a * b}x + #{b * b}",
                       "#{Num.monomial(a * a, 'x²')} #{minus ? Num::MINUS : '+'} #{2 * a * b}x #{minus ? '+' : Num::MINUS} #{b * b}"),
    answer: correct,
    explanation: Explain.build(
      idea: "Формула за съкратено умножение: (a ± b)² = a² ± 2ab + b².",
      steps: [
        "a = #{Num.monomial(a, 'x')}, b = #{b}.",
        "a² = #{Num.monomial(a * a, 'x²')}, 2ab = #{2 * a * b}x, b² = #{b * b}.",
        "Значи (#{Num.monomial(a, 'x')} #{minus ? Num::MINUS : '+'} #{b})² = #{correct}."
      ],
      answer: correct,
      check: "При x = 1: (#{a} #{minus ? Num::MINUS : '+'} #{b})² = #{((minus ? a - b : a + b)**2)}, а изразът дава #{(a * a) + (minus ? -2 * a * b : 2 * a * b) + (b * b)}.",
      watch: "Средният член 2ab не бива да се пропуска — квадратът на сбор не е сбор на квадратите."
    )
  )
end

Authoring.family "rat.difference_of_squares", topic: "Рационални изрази", area: "algebra",
                 rungs: [ 1300, 1390, 1480, 1570, 1660, 1760 ] do |c|
  middle = c.int(c.by_level([ 5..20, 10..40, 15..70, 25..150, 40..400, 60..900 ]))
  gap = c.int(1..c.by_level([ 2, 3, 4, 6, 8, 12 ]))
  a = middle + gap
  b = middle - gap
  value = (a * a) - (b * b)

  c.q(
    text: "Пресметни бързо #{a}² − #{b}².",
    answer: Num.ans(value),
    explanation: Explain.build(
      idea: "Разлика на квадрати: a² − b² = (a − b)(a + b). Така двете големи умножения стават едно малко.",
      steps: [
        "a − b = #{a} − #{b} = #{a - b}.",
        "a + b = #{a} + #{b} = #{a + b}.",
        "#{a - b} · #{a + b} = #{value}."
      ],
      answer: Num.ans(value),
      check: "Направо: #{a}² = #{a * a}, #{b}² = #{b * b}, а #{a * a} − #{b * b} = #{value}.",
      watch: "a² − b² не е (a − b)² = #{(a - b)**2}."
    )
  )
end

Authoring.family "rat.evaluate", topic: "Рационални изрази", area: "algebra",
                 rungs: [ 1280, 1370, 1460, 1550, 1640, 1740 ] do |c|
  a = c.int(c.by_level([ 1..3, 1..5, 2..7, 2..9, 3..12, 4..20 ]))
  b = c.int(c.by_level([ 1..5, 2..9, 3..14, 4..20, 5..40, 6..80 ]))
  x = c.int(c.by_level([ 1..4, 1..6, 2..8, -5..8, -9..12, -15..20 ]))
  raise Authoring::Duplicate if x.zero?

  value = (a * x * x) + (b * x)

  c.q(
    text: "Пресметни стойността на израза #{Num.monomial(a, 'x²')} + #{Num.monomial(b, 'x')} при x = #{Num.bg(x)}.",
    answer: Num.ans(value),
    explanation: Explain.build(
      idea: "Заместваме стойността на x навсякъде и спазваме реда на действията: първо степен, после умножение, после събиране.",
      steps: [
        "x² = (#{Num.bg(x)})² = #{x * x}.",
        "#{a} · #{x * x} = #{a * x * x} и #{b} · #{Num.bg(x)} = #{Num.bg(b * x)}.",
        "#{a * x * x} + #{Num.bg(b * x)} = #{Num.bg(value)}."
      ],
      answer: Num.bg(value),
      check: "Изразът може да се разложи: x(#{Num.monomial(a, 'x')} + #{b}) = #{Num.bg(x)} · #{Num.bg((a * x) + b)} = #{Num.bg(value)}.",
      watch: x.negative? ? "Квадратът на отрицателно число е положителен: (#{Num.bg(x)})² = #{x * x}." : "Степента се пресмята преди умножението."
    )
  )
end

Authoring.family "rat.factor_common", topic: "Рационални изрази", area: "algebra",
                 rungs: [ 1400, 1490, 1580, 1670, 1760, 1860 ] do |c|
  common = c.int(c.by_level([ 2..4, 2..6, 3..8, 4..12, 5..18, 6..30 ]))
  a = c.int(1..c.by_level([ 4, 6, 8, 12, 20, 40 ]))
  b = c.int(1..c.by_level([ 4, 6, 8, 12, 20, 40 ]))
  raise Authoring::Duplicate if Num.gcd(a, b) != 1

  correct = "#{common}x(#{Num.monomial(a, 'x')} + #{b})"

  c.q(
    text: "Разложи на множители: #{Num.monomial(common * a, 'x²')} + #{Num.monomial(common * b, 'x')}.",
    options: c.options(correct,
                       "#{common}(#{Num.monomial(a, 'x²')} + #{Num.monomial(b, 'x')})",
                       "x(#{Num.monomial(common * a, 'x')} + #{common * b})",
                       "#{common}x(#{Num.monomial(a, 'x')} + #{common * b})"),
    answer: correct,
    explanation: Explain.build(
      idea: "Изнасяме пред скоба най-големия общ множител на членовете — и число, и променлива.",
      steps: [
        "Числата: НОД(#{common * a}, #{common * b}) = #{common}.",
        "Променливите: и двата члена съдържат поне x.",
        "Изнасяме #{common}x: #{Num.monomial(common * a, 'x²')} + #{Num.monomial(common * b, 'x')} = #{correct}."
      ],
      answer: correct,
      check: "Разкриване обратно: #{common}x · #{Num.monomial(a, 'x')} = #{Num.monomial(common * a, 'x²')} и #{common}x · #{b} = #{Num.monomial(common * b, 'x')}.",
      watch: "Изнася се най-големият общ множител — иначе в скобата остава още нещо общо."
    )
  )
end

Authoring.family "rat.factor_trinomial", topic: "Рационални изрази", area: "algebra",
                 rungs: [ 1500, 1590, 1680, 1770, 1860, 1960 ] do |c|
  p = c.int(c.by_level([ 1..4, 1..6, 2..8, 2..12, 3..18, 4..30 ]))
  q = c.int(c.by_level([ 1..4, 1..6, 2..8, 2..12, 3..18, 4..30 ]))
  raise Authoring::Duplicate if p == q

  sum = p + q
  product = p * q
  correct = "(x + #{p})(x + #{q})"

  c.q(
    text: "Разложи на множители: x² + #{sum}x + #{product}.",
    options: c.options(correct, "(x + #{sum})(x + #{product})", "(x #{Num::MINUS} #{p})(x #{Num::MINUS} #{q})", "(x + #{p + 1})(x + #{q - 1})"),
    answer: correct,
    explanation: Explain.build(
      idea: "Търсим две числа със сбор #{sum} и произведение #{product} — те стават свободните членове на двете скоби.",
      steps: [
        "Двойки с произведение #{product}: #{Num.divisors(product).select { |d| d * d <= product }.map { |d| "#{d} и #{product / d}" }.join(', ')}.",
        "Сборът #{p} + #{q} = #{sum} пасва.",
        "Значи x² + #{sum}x + #{product} = #{correct}."
      ],
      answer: correct,
      check: "Разкриване: x² + #{q}x + #{p}x + #{product} = x² + #{sum}x + #{product}.",
      watch: "Числата в скобите се умножават до свободния член и се събират до коефициента пред x."
    )
  )
end

Authoring.family "rat.undefined_value", topic: "Рационални изрази", area: "algebra",
                 rungs: [ 1330, 1420, 1510, 1600, 1690, 1790 ] do |c|
  a = c.int(c.by_level([ 1..1, 1..2, 1..3, 2..5, 2..8, 3..12 ]))
  b = c.int(c.by_level([ 1..8, 2..12, 3..20, 4..40, 5..80, 6..150 ]))
  minus = c.coin
  root = minus ? Rational(b, a) : Rational(-b, a)
  raise Authoring::Duplicate unless root.denominator == 1

  numerator = c.int(2..20)

  c.q(
    text: "За коя стойност на x изразът #{numerator} : (#{Num.monomial(a, 'x')} #{minus ? Num::MINUS : '+'} #{b}) няма смисъл?",
    answer: Num.ans(root),
    explanation: Explain.build(
      idea: "Изразът няма смисъл, когато знаменателят е нула — деление на нула не е определено.",
      steps: [
        "#{Num.monomial(a, 'x')} #{minus ? Num::MINUS : '+'} #{b} = 0.",
        minus ? "#{Num.monomial(a, 'x')} = #{b}, значи x = #{Num.bg(root)}." : "#{Num.monomial(a, 'x')} = #{Num::MINUS}#{b}, значи x = #{Num.bg(root)}."
      ],
      answer: "x = #{Num.bg(root)}",
      check: "При x = #{Num.bg(root)}: #{a} · #{Num.bg(root)} #{minus ? Num::MINUS : '+'} #{b} = 0.",
      watch: "Числителят няма значение — забраната идва само от знаменателя."
    )
  )
end

# --------------------------------------------------------- Квадратни уравнения ---

Authoring.family "quad.factored_roots", topic: "Квадратни уравнения", area: "algebra",
                 rungs: [ 1380, 1470, 1560, 1650, 1740, 1840 ] do |c|
  a = c.int(c.by_level([ 1..5, 1..8, 2..12, 2..20, 3..40, 4..90 ]))
  b = c.int(c.by_level([ 1..5, 1..8, 2..12, 2..20, 3..40, 4..90 ]))
  raise Authoring::Duplicate if a == b

  bigger = [ a, b ].max

  c.q(
    text: "Реши уравнението (x #{Num::MINUS} #{a})(x #{Num::MINUS} #{b}) = 0. Кой е по-големият корен?",
    answer: Num.ans(bigger),
    explanation: Explain.build(
      idea: "Произведение е нула точно когато някой от множителите е нула.",
      steps: [
        "x − #{a} = 0 дава x = #{a}.",
        "x − #{b} = 0 дава x = #{b}.",
        "По-големият корен е #{bigger}."
      ],
      answer: "x = #{bigger}",
      check: "При x = #{bigger} единият множител става 0, значи произведението е 0.",
      watch: "Уравнението има два корена; въпросът иска само по-големия."
    )
  )
end

Authoring.family "quad.solve_integer_roots", topic: "Квадратни уравнения", area: "algebra",
                 rungs: [ 1480, 1570, 1660, 1750, 1840, 1940 ] do |c|
  p = c.int(c.by_level([ 1..4, 1..6, 1..8, 2..12, 2..20, 3..40 ]))
  q = c.int(c.by_level([ 1..4, 1..6, 1..8, 2..12, 2..20, 3..40 ]))
  raise Authoring::Duplicate if p == q

  b = -(p + q)
  cc = p * q
  discriminant = (b * b) - (4 * cc)
  bigger = [ p, q ].max

  c.q(
    text: "Реши уравнението x² #{Num.term(b, 'x')} #{Num.term(cc, '')} = 0. Кой е по-големият корен?",
    answer: Num.ans(bigger),
    explanation: Explain.build(
      idea: "Пресмятаме дискриминантата D = b² − 4ac и след това корените по формулата.",
      steps: [
        "a = 1, b = #{Num.bg(b)}, c = #{cc}.",
        "D = (#{Num.bg(b)})² − 4 · 1 · #{cc} = #{b * b} − #{4 * cc} = #{discriminant}.",
        "√D = #{Integer.sqrt(discriminant)}, значи x = (#{-b} ± #{Integer.sqrt(discriminant)}) : 2, тоест #{p} и #{q}."
      ],
      answer: "x = #{bigger}",
      check: "Формули на Виет: сборът на корените е #{p + q} = #{-b}, произведението е #{p * q} = #{cc}.",
      watch: "Знакът на b влиза в квадрат — (#{Num.bg(b)})² = #{b * b} е положително."
    )
  )
end

Authoring.family "quad.discriminant", topic: "Квадратни уравнения", area: "algebra",
                 rungs: [ 1420, 1510, 1600, 1690, 1780, 1880 ] do |c|
  a = c.int(c.by_level([ 1..2, 1..3, 1..4, 1..6, 2..9, 2..15 ]))
  b = c.int(c.by_level([ 1..8, 2..12, 3..20, 4..30, 5..50, 6..90 ]))
  cc = c.int(c.by_level([ 1..8, 1..12, 2..20, 2..30, 3..50, 4..90 ]))
  negative_c = c.coin
  cc = -cc if negative_c
  discriminant = (b * b) - (4 * a * cc)

  c.q(
    text: "Колко е дискриминантата на уравнението #{Num.monomial(a, 'x²')} #{Num.term(b, 'x')} #{Num.term(cc, '')} = 0?",
    answer: Num.ans(discriminant),
    explanation: Explain.build(
      idea: "Дискриминантата се смята по D = b² − 4ac и казва колко реални корена има уравнението.",
      steps: [
        "a = #{a}, b = #{b}, c = #{Num.bg(cc)}.",
        "b² = #{b * b}, 4ac = 4 · #{a} · #{Num.signed(cc)} = #{Num.bg(4 * a * cc)}.",
        "D = #{b * b} − #{Num.signed(4 * a * cc)} = #{Num.bg(discriminant)}."
      ],
      answer: "D = #{Num.bg(discriminant)}",
      check: discriminant.positive? ? "D > 0, значи уравнението има два различни реални корена." :
                                      (discriminant.zero? ? "D = 0, значи има един (двоен) корен." : "D < 0, значи няма реални корени."),
      watch: "Знакът на c влиза във формулата: при отрицателно c изразът −4ac става положителен."
    )
  )
end

Authoring.family "quad.vieta", topic: "Квадратни уравнения", area: "algebra",
                 rungs: [ 1500, 1590, 1680, 1770, 1860, 1960 ] do |c|
  p = c.int(c.by_level([ 1..5, 1..8, 2..12, 2..20, 3..40, 4..80 ]))
  q = c.int(c.by_level([ 1..5, 1..8, 2..12, 2..20, 3..40, 4..80 ]))
  b = -(p + q)
  cc = p * q
  ask_sum = c.coin

  c.q(
    text: "За уравнението x² #{Num.term(b, 'x')} + #{cc} = 0 намери #{ask_sum ? 'сбора' : 'произведението'} на корените, " \
          "без да го решаваш.",
    answer: Num.ans(ask_sum ? p + q : cc),
    explanation: Explain.build(
      idea: "Формули на Виет: за x² + px + q = 0 сборът на корените е −p, а произведението е q.",
      steps: [
        "Тук p = #{Num.bg(b)}, q = #{cc}.",
        ask_sum ? "Сбор на корените = −(#{Num.bg(b)}) = #{p + q}." : "Произведение на корените = #{cc}."
      ],
      answer: Num.ans(ask_sum ? p + q : cc),
      check: "Корените наистина са #{p} и #{q}: сборът им е #{p + q}, произведението #{cc}.",
      watch: "Сборът сменя знака на коефициента пред x, произведението — не."
    )
  )
end

Authoring.family "quad.area_word", topic: "Квадратни уравнения", area: "algebra",
                 rungs: [ 1550, 1640, 1730, 1820, 1910, 2010 ] do |c|
  width = c.int(c.by_level([ 2..8, 3..12, 4..18, 5..30, 8..60, 10..120 ]))
  extra = c.int(c.by_level([ 1..5, 2..8, 3..12, 4..20, 5..40, 6..80 ]))
  length = width + extra
  area = width * length

  c.q(
    text: "Правоъгълник има лице #{area} см², а дължината му е с #{extra} см по-голяма от ширината. " \
          "Колко сантиметра е ширината?",
    answer: Num.ans(width),
    explanation: Explain.build(
      idea: "Означаваме ширината с x; тогава дължината е x + #{extra} и лицето дава квадратно уравнение.",
      steps: [
        "x(x + #{extra}) = #{area}, тоест x² + #{extra}x − #{area} = 0.",
        "D = #{extra}² + 4 · #{area} = #{(extra * extra) + (4 * area)}, √D = #{Integer.sqrt((extra * extra) + (4 * area))}.",
        "x = (−#{extra} + #{Integer.sqrt((extra * extra) + (4 * area))}) : 2 = #{width} см (отрицателният корен отпада)."
      ],
      answer: "#{width} см",
      check: "#{width} · #{length} = #{area} см², а #{length} − #{width} = #{extra} см.",
      watch: "Отрицателният корен е математически верен, но дължина не може да е отрицателна."
    )
  )
end

Authoring.family "quad.count_roots", topic: "Квадратни уравнения", area: "algebra",
                 rungs: [ 1450, 1540, 1630, 1720, 1810, 1910 ] do |c|
  a = c.int(1..c.by_level([ 2, 3, 4, 6, 9, 15 ]))
  b = c.int(c.by_level([ 1..8, 2..12, 3..20, 4..30, 5..50, 6..90 ]))
  cc = c.int(c.by_level([ 1..12, 1..20, 2..40, 2..70, 3..120, 4..250 ]))
  discriminant = (b * b) - (4 * a * cc)
  answer = discriminant.positive? ? "два" : (discriminant.zero? ? "един" : "нула")

  c.q(
    text: "Колко реални корена има уравнението #{Num.monomial(a, 'x²')} + #{b}x + #{cc} = 0?",
    options: c.options(answer, "два", "един", "нула"),
    answer: answer,
    explanation: Explain.build(
      idea: "Броят реални корени се чете от дискриминантата: D > 0 — два, D = 0 — един, D < 0 — нито един.",
      steps: [
        "D = #{b}² − 4 · #{a} · #{cc} = #{b * b} − #{4 * a * cc} = #{Num.bg(discriminant)}.",
        discriminant.positive? ? "D > 0 → два различни реални корена." :
          (discriminant.zero? ? "D = 0 → един двоен корен." : "D < 0 → няма реални корени.")
      ],
      answer: "#{answer} #{answer == 'един' ? 'корен' : 'корена'}",
      check: "Графиката е парабола, която #{discriminant.positive? ? 'пресича оста x в две точки' : (discriminant.zero? ? 'се допира до оста x' : 'не докосва оста x')}.",
      watch: "Достатъчна е само дискриминантата — уравнението не е нужно да се решава."
    )
  )
end

# --------------------------------------------------------- Системи уравнения ---

Authoring.family "sys.sum_difference", topic: "Системи уравнения", area: "algebra",
                 rungs: [ 1330, 1420, 1510, 1600, 1690, 1790 ] do |c|
  x = c.int(c.by_level([ 2..10, 3..20, 4..40, 5..80, 8..200, 10..500 ]))
  y = c.int(1...x)
  sum = x + y
  difference = x - y

  c.q(
    text: "Реши системата x + y = #{sum}, x − y = #{difference}. Колко е x?",
    answer: Num.ans(x),
    explanation: Explain.build(
      idea: "Събираме двете уравнения — y се унищожава и остава само x.",
      steps: [
        "(x + y) + (x − y) = #{sum} + #{difference}, значи 2x = #{sum + difference}.",
        "x = #{sum + difference} : 2 = #{x}.",
        "Тогава y = #{sum} − #{x} = #{y}."
      ],
      answer: "x = #{x}",
      check: "#{x} + #{y} = #{sum} и #{x} − #{y} = #{difference}.",
      watch: "Събирането маха y само защото коефициентите му са +1 и −1."
    )
  )
end

Authoring.family "sys.elimination", topic: "Системи уравнения", area: "algebra",
                 rungs: [ 1450, 1540, 1630, 1720, 1810, 1910 ] do |c|
  x = c.int(c.by_level([ 1..6, 1..9, 2..12, 2..20, 3..40, 4..80 ]))
  y = c.int(c.by_level([ 1..6, 1..9, 2..12, 2..20, 3..40, 4..80 ]))
  a1 = c.int(2..c.by_level([ 3, 4, 5, 7, 9, 12 ]))
  b1 = c.int(1..c.by_level([ 3, 4, 5, 7, 9, 12 ]))
  a2 = c.int(1..c.by_level([ 3, 4, 5, 7, 9, 12 ]))
  b2 = c.int(1..c.by_level([ 3, 4, 5, 7, 9, 12 ]))
  raise Authoring::Duplicate if (a1 * b2) - (a2 * b1) == 0

  c1 = (a1 * x) + (b1 * y)
  c2 = (a2 * x) + (b2 * y)

  c.q(
    text: "Реши системата #{Num.monomial(a1, 'x')} + #{Num.monomial(b1, 'y')} = #{c1}, " \
          "#{Num.monomial(a2, 'x')} + #{Num.monomial(b2, 'y')} = #{c2}. Колко е x?",
    answer: Num.ans(x),
    explanation: Explain.build(
      idea: "Изравняваме коефициентите пред y и изваждаме уравненията, за да остане само x.",
      steps: [
        "Умножаваме първото по #{b2} и второто по #{b1}: #{a1 * b2}x + #{b1 * b2}y = #{c1 * b2} и #{a2 * b1}x + #{b1 * b2}y = #{c2 * b1}.",
        "Изваждаме: #{Num.lead((a1 * b2) - (a2 * b1))} = #{Num.bg((c1 * b2) - (c2 * b1))}.",
        "x = #{Num.bg((c1 * b2) - (c2 * b1))} : #{Num.bg((a1 * b2) - (a2 * b1))} = #{x}, а оттам y = #{y}."
      ],
      answer: "x = #{x}",
      check: "#{a1} · #{x} + #{b1} · #{y} = #{c1} и #{a2} · #{x} + #{b2} · #{y} = #{c2}.",
      watch: "Умножава се цялото уравнение — включително дясната страна."
    )
  )
end

Authoring.family "sys.tickets_word", topic: "Системи уравнения", area: "algebra",
                 rungs: [ 1500, 1590, 1680, 1770, 1860, 1960 ] do |c|
  adult_price = c.int(c.by_level([ 4..10, 5..15, 6..20, 8..30, 10..50, 12..90 ]))
  child_price = c.int(2..(adult_price - 1))
  adults = c.int(c.by_level([ 2..6, 2..10, 3..15, 4..25, 5..50, 8..100 ]))
  children = c.int(c.by_level([ 2..6, 2..10, 3..15, 4..25, 5..50, 8..100 ]))
  people = adults + children
  money = (adults * adult_price) + (children * child_price)

  c.q(
    text: "За екскурзия са купени #{people} билета за #{money} лв. Билетът за възрастен е #{adult_price} лв., " \
          "а за дете — #{child_price} лв. Колко са билетите за възрастни?",
    answer: Num.ans(adults),
    explanation: Explain.build(
      idea: "Две неизвестни, две условия: брой билети и обща сума. Работим чрез предположението „всички са детски“.",
      steps: [
        "Ако всички #{people} бяха детски: #{people} · #{child_price} = #{people * child_price} лв.",
        "Разлика до действителната сума: #{money} − #{people * child_price} = #{money - (people * child_price)} лв.",
        "Всеки билет за възрастен добавя #{adult_price - child_price} лв.: #{money - (people * child_price)} : #{adult_price - child_price} = #{adults}."
      ],
      answer: "#{adults} билета за възрастни",
      check: "#{adults} · #{adult_price} + #{children} · #{child_price} = #{money} лв. при #{people} билета.",
      watch: "Двете условия трябва да са изпълнени едновременно — само сумата не стига."
    )
  )
end

Authoring.family "sys.ages_word", topic: "Системи уравнения", area: "algebra",
                 rungs: [ 1420, 1510, 1600, 1690, 1780, 1880 ] do |c|
  child = c.int(c.by_level([ 4..12, 5..16, 6..20, 7..25, 8..35, 10..50 ]))
  gap = c.int(c.by_level([ 18..30, 20..35, 22..40, 24..45, 25..50, 26..55 ]))
  parent = child + gap
  total = parent + child

  c.q(
    text: "Баща и син са заедно на #{total} години, а бащата е с #{gap} години по-възрастен. На колко години е синът?",
    answer: Num.ans(child),
    explanation: Explain.build(
      idea: "Две уравнения: сбор и разлика на възрастите.",
      steps: [
        "x + y = #{total} и x − y = #{gap}.",
        "Изваждаме: 2y = #{total} − #{gap} = #{total - gap}.",
        "y = #{total - gap} : 2 = #{child} години."
      ],
      answer: "#{child} години",
      check: "Бащата е #{parent}: #{parent} + #{child} = #{total} и #{parent} − #{child} = #{gap}.",
      watch: "Разликата във възрастите не се променя с годините — това е ключът към този тип задачи."
    )
  )
end

# ------------------------------------------------------------- Неравенства ---

Authoring.family "ineq.linear_smallest", topic: "Неравенства", area: "algebra",
                 rungs: [ 1250, 1340, 1430, 1520, 1610, 1710 ] do |c|
  a = c.int(c.by_level([ 2..4, 2..6, 3..9, 4..15, 5..30, 6..60 ]))
  x = c.int(c.by_level([ 2..8, 2..12, 3..20, 4..40, 5..90, 6..200 ]))
  b = c.int(c.by_level([ 1..10, 2..20, 3..40, 4..80, 6..200, 8..500 ]))
  right = (a * x) + b

  c.q(
    text: "Реши неравенството #{a}x + #{b} > #{right}. Кое е най-малкото цяло число, което е решение?",
    answer: Num.ans(x + 1),
    explanation: Explain.build(
      idea: "Неравенството се решава като уравнение; посоката на знака се пази, защото делим на положително число.",
      steps: [
        "#{a}x > #{right} − #{b} = #{a * x}.",
        "x > #{a * x} : #{a} = #{x}.",
        "Най-малкото цяло число, по-голямо от #{x}, е #{x + 1}."
      ],
      answer: Num.ans(x + 1),
      check: "При x = #{x + 1}: #{a} · #{x + 1} + #{b} = #{(a * (x + 1)) + b} > #{right}. При x = #{x} се получава точно #{right} — не е по-голямо.",
      watch: "Знакът е строг (>), затова самото #{x} не е решение."
    )
  )
end

Authoring.family "ineq.negative_coefficient", topic: "Неравенства", area: "algebra",
                 rungs: [ 1400, 1490, 1580, 1670, 1760, 1860 ] do |c|
  a = c.int(c.by_level([ 2..4, 2..6, 3..9, 4..15, 5..30, 6..60 ]))
  x = c.int(c.by_level([ 2..8, 2..12, 3..20, 4..40, 5..90, 6..200 ]))
  b = c.int(c.by_level([ 1..10, 2..20, 3..40, 4..80, 6..200, 8..500 ]))
  right = b - (a * x)

  c.q(
    text: "Реши неравенството #{Num::MINUS}#{a}x + #{b} < #{Num.bg(right)}. Кое е най-малкото цяло число, което е решение?",
    answer: Num.ans(x + 1),
    explanation: Explain.build(
      idea: "При деление (или умножение) с отрицателно число знакът на неравенството се обръща.",
      steps: [
        "#{Num::MINUS}#{a}x < #{Num.bg(right)} − #{b} = #{Num.bg(-(a * x))}.",
        "Делим на #{Num::MINUS}#{a} и обръщаме знака: x > #{x}.",
        "Най-малкото цяло решение е #{x + 1}."
      ],
      answer: Num.ans(x + 1),
      check: "При x = #{x + 1}: #{Num::MINUS}#{a} · #{x + 1} + #{b} = #{Num.bg((-a * (x + 1)) + b)} < #{Num.bg(right)}.",
      watch: "Забравеното обръщане на знака дава точно обратния отговор."
    )
  )
end

Authoring.family "ineq.count_integers", topic: "Неравенства", area: "algebra",
                 rungs: [ 1350, 1440, 1530, 1620, 1710, 1810 ] do |c|
  low = c.int(c.by_level([ 1..8, 1..15, 2..30, -10..40, -30..90, -60..200 ]))
  width = c.int(c.by_level([ 3..8, 4..12, 5..20, 6..30, 8..60, 10..120 ]))
  high = low + width
  count = high - low - 1

  c.q(
    text: "Колко цели числа x удовлетворяват неравенството #{Num.bg(low)} < x < #{Num.bg(high)}?",
    answer: Num.ans(count),
    explanation: Explain.build(
      idea: "Строгите неравенства изключват краищата — броим целите числа стриктно между тях.",
      steps: [
        "Първото подходящо цяло число е #{Num.bg(low + 1)}, последното е #{Num.bg(high - 1)}.",
        "Броят им е #{Num.bg(high - 1)} − #{Num.bg(low + 1)} + 1 = #{count}."
      ],
      answer: "#{count} числа",
      check: "Ако краищата се брояха, числата щяха да са #{count + 2}.",
      watch: "„Между“ при строг знак не включва самите #{Num.bg(low)} и #{Num.bg(high)}."
    )
  )
end

Authoring.family "ineq.budget_word", topic: "Неравенства", area: "algebra",
                 rungs: [ 1300, 1390, 1480, 1570, 1660, 1760 ] do |c|
  price = c.int(c.by_level([ 2..6, 3..10, 4..15, 5..25, 8..50, 10..90 ]))
  count = c.int(c.by_level([ 2..8, 3..12, 4..20, 5..30, 6..50, 8..90 ]))
  fixed = c.int(c.by_level([ 1..10, 2..20, 3..40, 5..80, 8..200, 10..400 ]))
  budget = (price * count) + fixed + c.int(0...price)
  item, = c.goods

  c.q(
    text: "С #{budget} лв. трябва да се плати такса #{fixed} лв. и да се купят #{item.many} по #{price} лв. " \
          "Колко най-много #{item.many} могат да се купят?",
    answer: Num.ans(count),
    explanation: Explain.build(
      idea: "Записваме условието като неравенство и търсим най-голямото цяло решение.",
      steps: [
        "#{fixed} + #{price}n ≤ #{budget}.",
        "#{price}n ≤ #{budget} − #{fixed} = #{budget - fixed}.",
        "n ≤ #{budget - fixed} : #{price} = #{Num.dec(Rational(budget - fixed, price), 2)}, значи най-много #{count}."
      ],
      answer: "#{item.count(count)}",
      check: "#{count} броя струват #{count * price} лв., с таксата #{(count * price) + fixed} лв. ≤ #{budget} лв. Още един брой би дал #{((count + 1) * price) + fixed} лв.",
      watch: "Броят е цяло число — частичният резултат се закръгля надолу, не нагоре."
    )
  )
end

Authoring.family "ineq.brackets", topic: "Неравенства", area: "algebra",
                 rungs: [ 1450, 1540, 1630, 1720, 1810, 1910 ] do |c|
  a = c.int(c.by_level([ 2..4, 2..5, 2..7, 3..10, 4..20, 5..40 ]))
  b = c.int(c.by_level([ 1..6, 1..10, 2..15, 3..25, 4..50, 5..90 ]))
  x = c.int(c.by_level([ 2..8, 2..12, 3..20, 4..40, 5..90, 6..200 ]))
  right = a * (x + b)

  c.q(
    text: "Реши неравенството #{a}(x + #{b}) ≥ #{right}. Кое е най-малкото цяло число, което е решение?",
    answer: Num.ans(x),
    explanation: Explain.build(
      idea: "Освобождаваме скобата с деление на положителното #{a} — знакът не се обръща.",
      steps: [
        "x + #{b} ≥ #{right} : #{a} = #{x + b}.",
        "x ≥ #{x + b} − #{b} = #{x}.",
        "Знакът е ≥, затова самото #{x} е решение."
      ],
      answer: Num.ans(x),
      check: "При x = #{x}: #{a}(#{x} + #{b}) = #{right} ≥ #{right}. При x = #{x - 1} се получава #{a * (x - 1 + b)} < #{right}.",
      watch: "При „≥“ границата влиза в решението, за разлика от „>“."
    )
  )
end
