# Дроби, десетични числа и проценти — the three ways of writing the same thing,
# which is exactly where students lose their footing.

# -------------------------------------------------------------------- Дроби ---

Authoring.family "frac.of_amount_story", topic: "Дроби", area: "fractions",
                 rungs: [ 830, 910, 1000, 1090, 1180, 1280 ] do |c|
  spec = c.by_level([ [ 2..4, 2..8 ], [ 2..5, 3..12 ], [ 2..6, 4..15 ],
                      [ 3..8, 5..20 ], [ 4..10, 6..30 ], [ 5..12, 8..50 ] ])
  denominator = c.int(spec[0])
  numerator = c.int(1...denominator)
  unit = c.int(spec[1])
  total = denominator * unit
  part = numerator * unit
  group = c.pick([ "ученици", "книги", "стикери", "ябълки", "билета", "въпроса" ])

  c.q(
    text: "От #{total} #{group} #{Num.frac(numerator, denominator)} са раздадени. Колко #{group} са раздадени?",
    answer: Num.ans(part),
    explanation: Explain.build(
      idea: "Дробта от число се намира на две стъпки: делим на знаменателя, умножаваме по числителя.",
      steps: [
        "Една #{denominator}-та част: #{total} : #{denominator} = #{unit}.",
        "#{numerator} такива части: #{unit} · #{numerator} = #{part}."
      ],
      answer: "#{part} #{group}",
      check: "Остават #{total - part}, а #{part} + #{total - part} = #{total}.",
      watch: "Дели се на знаменателя (#{denominator}), а не на числителя (#{numerator})."
    )
  )
end

Authoring.family "frac.add_same_denominator", topic: "Дроби", area: "fractions",
                 rungs: [ 850, 930, 1020, 1110, 1200, 1300 ] do |c|
  denominator = c.int(c.by_level([ 3..6, 4..9, 5..12, 6..16, 8..24, 10..40 ]))
  a = c.int(1...denominator)
  b = c.int(1...denominator)
  sum = Rational(a + b, denominator)

  c.q(
    text: "Събери дробите #{Num.frac(a, denominator)} и #{Num.frac(b, denominator)}. Запиши отговора съкратен.",
    answer: Num.frac(sum),
    explanation: Explain.build(
      idea: "При равни знаменатели се събират само числителите — частите са еднакво големи.",
      steps: [
        "#{a}/#{denominator} + #{b}/#{denominator} = #{a + b}/#{denominator}.",
        (a + b) == sum.numerator && denominator == sum.denominator ?
          "Дробта вече е несъкратима." :
          "Съкращаваме с #{Num.gcd(a + b, denominator)}: #{a + b}/#{denominator} = #{Num.frac(sum)}.",
        sum > 1 ? "Като смесено число: #{Num.mixed(sum)}." : nil
      ].compact,
      answer: Num.frac(sum),
      check: "#{Num.frac(sum)} · #{denominator} = #{Num.ans(sum * denominator)} — толкова #{denominator}-ти има в отговора.",
      watch: "Знаменателят не се събира: #{denominator} + #{denominator} = #{2 * denominator} е грешка."
    )
  )
end

Authoring.family "frac.add_unlike", topic: "Дроби", area: "fractions",
                 rungs: [ 1050, 1140, 1230, 1320, 1410, 1510 ] do |c|
  spec = c.by_level([ [ 2..4, 2..6 ], [ 2..5, 3..8 ], [ 2..6, 3..10 ],
                      [ 3..8, 4..12 ], [ 4..10, 5..15 ], [ 5..14, 6..20 ] ])
  d1 = c.int(spec[0])
  d2 = c.int(spec[1])
  raise Authoring::Duplicate if d1 == d2

  n1 = c.int(1...d1)
  n2 = c.int(1...d2)
  sum = Rational(n1, d1) + Rational(n2, d2)
  common = Num.lcm(d1, d2)
  subtract = c.level >= 2 && c.coin
  result = subtract ? Rational(n1, d1) - Rational(n2, d2) : sum
  raise Authoring::Duplicate if subtract && result <= 0

  c.q(
    text: "Пресметни #{Num.frac(n1, d1)} #{subtract ? Num::MINUS : '+'} #{Num.frac(n2, d2)} и съкрати отговора.",
    answer: Num.frac(result),
    explanation: Explain.build(
      idea: "Различни знаменатели се привеждат към общ — най-удобно към НОК на двата.",
      steps: [
        "НОК(#{d1}, #{d2}) = #{common}.",
        "#{n1}/#{d1} = #{n1 * (common / d1)}/#{common} и #{n2}/#{d2} = #{n2 * (common / d2)}/#{common}.",
        "#{n1 * (common / d1)}/#{common} #{subtract ? Num::MINUS : '+'} #{n2 * (common / d2)}/#{common} = #{subtract ? (n1 * (common / d1)) - (n2 * (common / d2)) : (n1 * (common / d1)) + (n2 * (common / d2))}/#{common} = #{Num.frac(result)}."
      ],
      answer: Num.frac(result),
      check: "Приблизително: #{Num.dec(Rational(n1, d1))} #{subtract ? Num::MINUS : '+'} #{Num.dec(Rational(n2, d2))} ≈ #{Num.dec(result)} — съвпада с #{Num.frac(result)}.",
      watch: "Числителите се разширяват заедно със знаменателите — не се преписват както са."
    )
  )
end

Authoring.family "frac.multiply", topic: "Дроби", area: "fractions",
                 rungs: [ 1000, 1090, 1180, 1270, 1360, 1460 ] do |c|
  spec = c.by_level([ 2..5, 2..7, 3..9, 3..12, 4..15, 5..20 ])
  d1 = c.int(spec)
  d2 = c.int(spec)
  n1 = c.int(1...d1)
  n2 = c.int(1...d2)
  product = Rational(n1, d1) * Rational(n2, d2)

  c.q(
    text: "Пресметни #{Num.frac(n1, d1)} · #{Num.frac(n2, d2)} и съкрати отговора.",
    answer: Num.frac(product),
    explanation: Explain.build(
      idea: "Дроби се умножават направо: числител по числител, знаменател по знаменател.",
      steps: [
        "#{n1} · #{n2} = #{n1 * n2} и #{d1} · #{d2} = #{d1 * d2}.",
        "Получаваме #{n1 * n2}/#{d1 * d2}.",
        Num.gcd(n1 * n2, d1 * d2) > 1 ? "Съкращаваме с #{Num.gcd(n1 * n2, d1 * d2)}: #{Num.frac(product)}." : "Дробта е несъкратима."
      ],
      answer: Num.frac(product),
      check: "Произведението е по-малко и от двата множителя, защото и двете дроби са под 1.",
      watch: "Не се търси общ знаменател — това е нужно само при събиране и изваждане."
    )
  )
end

Authoring.family "frac.divide", topic: "Дроби", area: "fractions",
                 rungs: [ 1120, 1210, 1300, 1390, 1480, 1580 ] do |c|
  spec = c.by_level([ 2..5, 2..7, 3..9, 3..12, 4..15, 5..20 ])
  d1 = c.int(spec)
  d2 = c.int(spec)
  n1 = c.int(1...d1)
  n2 = c.int(1...d2)
  quotient = Rational(n1, d1) / Rational(n2, d2)

  c.q(
    text: "Пресметни #{Num.frac(n1, d1)} : #{Num.frac(n2, d2)} и съкрати отговора.",
    answer: Num.frac(quotient),
    explanation: Explain.build(
      idea: "Делението на дроб е умножение с обърнатата ѝ дроб.",
      steps: [
        "Обръщаме втората дроб: #{Num.frac(n2, d2)} става #{Num.frac(d2, n2)}.",
        "#{Num.frac(n1, d1)} · #{Num.frac(d2, n2)} = #{n1 * d2}/#{d1 * n2}.",
        "След съкращаване: #{Num.frac(quotient)}."
      ],
      answer: Num.frac(quotient),
      check: "#{Num.frac(quotient)} · #{Num.frac(n2, d2)} = #{Num.frac(quotient * Rational(n2, d2))} — връщаме се към първата дроб.",
      watch: "Обръща се само делителят (втората дроб), не и делимото."
    )
  )
end

Authoring.family "frac.simplify", topic: "Дроби", area: "fractions",
                 rungs: [ 900, 990, 1080, 1170, 1260, 1360 ] do |c|
  spec = c.by_level([ [ 2..6, 2..5 ], [ 2..9, 2..7 ], [ 3..12, 2..9 ],
                      [ 4..16, 3..12 ], [ 5..24, 4..15 ], [ 6..40, 5..20 ] ])
  factor = c.int(spec[0])
  denominator = c.int(spec[1])
  numerator = c.int(1...denominator)
  raise Authoring::Duplicate if Num.gcd(numerator, denominator) != 1 || factor == 1

  reduced = Rational(numerator, denominator)

  c.q(
    text: "Съкрати дробта #{numerator * factor}/#{denominator * factor}.",
    answer: Num.frac(reduced),
    explanation: Explain.build(
      idea: "Търсим най-големия общ делител на числителя и знаменателя и делим и двата на него.",
      steps: [
        "#{numerator * factor} = #{Num.factor_string(numerator * factor)}, #{denominator * factor} = #{Num.factor_string(denominator * factor)}.",
        "НОД(#{numerator * factor}, #{denominator * factor}) = #{factor}.",
        "#{numerator * factor} : #{factor} = #{numerator} и #{denominator * factor} : #{factor} = #{denominator}."
      ],
      answer: Num.frac(reduced),
      check: "#{numerator}/#{denominator} и #{numerator * factor}/#{denominator * factor} дават една и съща десетична стойност: #{Num.dec(reduced, 3)}.",
      watch: "Числителят и знаменателят се делят на едно и също число — иначе дробта се променя."
    )
  )
end

Authoring.family "frac.compare", topic: "Дроби", area: "fractions",
                 rungs: [ 950, 1040, 1130, 1220, 1310, 1410 ] do |c|
  spec = c.by_level([ 2..6, 3..8, 3..10, 4..12, 5..16, 6..24 ])
  d1 = c.int(spec)
  d2 = c.int(spec)
  n1 = c.int(1...d1)
  n2 = c.int(1...d2)
  first = Rational(n1, d1)
  second = Rational(n2, d2)
  raise Authoring::Duplicate if first == second

  bigger = [ first, second ].max
  common = Num.lcm(d1, d2)

  c.q(
    text: "Коя дроб е по-голяма: #{Num.frac(n1, d1)} или #{Num.frac(n2, d2)}? Запиши по-голямата.",
    answer: Num.frac(bigger),
    explanation: Explain.build(
      idea: "Свеждаме двете дроби до общ знаменател — тогава решават числителите.",
      steps: [
        "Общ знаменател: #{common}.",
        "#{Num.frac(n1, d1)} = #{n1 * (common / d1)}/#{common}, #{Num.frac(n2, d2)} = #{n2 * (common / d2)}/#{common}.",
        "#{[ n1 * (common / d1), n2 * (common / d2) ].max} > #{[ n1 * (common / d1), n2 * (common / d2) ].min}, значи по-голяма е #{Num.frac(bigger)}."
      ],
      answer: Num.frac(bigger),
      check: "В десетичен вид: #{Num.dec(first, 3)} и #{Num.dec(second, 3)}.",
      watch: "По-големият знаменател значи по-малки части — не по-голяма дроб."
    )
  )
end

Authoring.family "frac.mixed_number", topic: "Дроби", area: "fractions",
                 rungs: [ 980, 1070, 1160, 1250, 1340, 1440 ] do |c|
  denominator = c.int(c.by_level([ 2..5, 3..7, 3..9, 4..12, 5..16, 6..24 ]))
  whole = c.int(c.by_level([ 1..3, 1..5, 2..7, 2..10, 3..15, 4..25 ]))
  rest = c.int(1...denominator)
  improper = (whole * denominator) + rest
  to_mixed = c.coin

  c.q(
    text: to_mixed ? "Запиши #{improper}/#{denominator} като смесено число." :
                     "Запиши смесеното число #{whole} и #{Num.frac(rest, denominator)} като неправилна дроб (числител/знаменател).",
    answer: to_mixed ? Num.ans(Rational(improper, denominator)) : "#{improper}/#{denominator}",
    explanation: Explain.build(
      idea: to_mixed ? "Делим числителя на знаменателя: частното е цялата част, остатъкът остава в дробта." :
                       "Цялата част се превръща в толкова #{denominator}-ти, колкото са ѝ нужни, и се добавя към дробната част.",
      steps: to_mixed ?
        [ "#{improper} : #{denominator} = #{whole} и остатък #{rest}.",
          "Значи #{improper}/#{denominator} = #{whole} цяло и #{rest}/#{denominator}." ] :
        [ "#{whole} цели = #{whole} · #{denominator} = #{whole * denominator} #{denominator}-ти.",
          "#{whole * denominator} + #{rest} = #{improper}, значи дробта е #{improper}/#{denominator}." ],
      answer: to_mixed ? "#{whole} #{Num.frac(rest, denominator)}" : "#{improper}/#{denominator}",
      check: "#{whole} · #{denominator} + #{rest} = #{improper} — двата записа са едно и също число.",
      watch: "Знаменателят не се променя при превръщането."
    )
  )
end

Authoring.family "frac.reverse_whole", topic: "Дроби", area: "fractions",
                 rungs: [ 1080, 1170, 1260, 1350, 1440, 1540 ] do |c|
  spec = c.by_level([ [ 2..4, 2..8 ], [ 2..5, 3..12 ], [ 3..6, 4..15 ],
                      [ 3..8, 5..25 ], [ 4..10, 6..40 ], [ 5..12, 8..60 ] ])
  denominator = c.int(spec[0])
  numerator = c.int(1...denominator)
  unit = c.int(spec[1])
  part = numerator * unit
  whole = denominator * unit

  c.q(
    text: "#{Num.frac(numerator, denominator)} от едно число #{numerator == 1 ? 'е' : 'са'} #{part}. Кое е числото?",
    answer: Num.ans(whole),
    explanation: Explain.build(
      idea: "Обратната задача: от част към цяло. Първо намираме една част, после ги събираме всичките.",
      steps: [
        "#{numerator} части струват #{part}, значи една част е #{part} : #{numerator} = #{unit}.",
        "Цялото е от #{denominator} части: #{unit} · #{denominator} = #{whole}."
      ],
      answer: Num.ans(whole),
      check: "#{Num.frac(numerator, denominator)} от #{whole} е #{whole} : #{denominator} · #{numerator} = #{part}.",
      watch: "Тук се дели на числителя и се умножава по знаменателя — обратно на правата задача."
    )
  )
end

Authoring.family "frac.of_fraction", topic: "Дроби", area: "fractions",
                 rungs: [ 1150, 1240, 1330, 1420, 1510, 1610 ] do |c|
  spec = c.by_level([ 2..4, 2..6, 3..8, 3..10, 4..12, 5..16 ])
  d1 = c.int(spec)
  d2 = c.int(spec)
  n1 = c.int(1...d1)
  n2 = c.int(1...d2)
  result = Rational(n1, d1) * Rational(n2, d2)
  who = c.person

  c.q(
    text: "#{who} прочита #{Num.frac(n1, d1)} от книга през първия ден, а на втория — #{Num.frac(n2, d2)} от прочетеното. " \
          "Каква част от книгата е прочетена на втория ден?",
    answer: Num.frac(result),
    explanation: Explain.build(
      idea: "„Част от част“ означава умножение на двете дроби.",
      steps: [
        "Втория ден: #{Num.frac(n2, d2)} от #{Num.frac(n1, d1)}, тоест #{Num.frac(n2, d2)} · #{Num.frac(n1, d1)}.",
        "Числител по числител и знаменател по знаменател: #{n2} · #{n1} = #{n1 * n2}, #{d2} · #{d1} = #{d1 * d2}.",
        "#{n1 * n2}/#{d1 * d2} = #{Num.frac(result)} след съкращаване."
      ],
      answer: Num.frac(result),
      check: "Резултатът е по-малък от #{Num.frac(n1, d1)}, защото се взема само част от него.",
      watch: "Двете дроби не се събират — втората се отнася към прочетеното, не към цялата книга."
    )
  )
end

Authoring.family "frac.remaining_two_steps", topic: "Дроби", area: "fractions",
                 rungs: [ 1250, 1340, 1430, 1520, 1610, 1710 ] do |c|
  spec = c.by_level([ [ 2..3, 2..3, 12..40 ], [ 2..4, 2..4, 20..60 ], [ 2..5, 2..5, 30..90 ],
                      [ 3..6, 3..6, 60..180 ], [ 3..8, 3..8, 90..360 ], [ 4..10, 4..10, 120..600 ] ])
  d1 = c.int(spec[0])
  d2 = c.int(spec[1])
  base = c.int(spec[2])
  total = base - (base % (d1 * d2)) + (d1 * d2)
  first = total / d1
  rest = total - first
  raise Authoring::Duplicate unless (rest % d2).zero?

  second = rest / d2
  left = rest - second

  c.q(
    text: "В кутия има #{total} бонбона. Изяждат #{Num.frac(1, d1)} от тях, а после #{Num.frac(1, d2)} от останалите. " \
          "Колко бонбона остават?",
    answer: Num.ans(left),
    explanation: Explain.build(
      idea: "Втората дроб се отнася към остатъка, не към началното количество — затова се работи на две стъпки.",
      steps: [
        "Първо: #{total} : #{d1} = #{first} изядени, остават #{total} − #{first} = #{rest}.",
        "После: #{rest} : #{d2} = #{second} изядени, остават #{rest} − #{second} = #{left}."
      ],
      answer: "#{left} бонбона",
      check: "Изядени са общо #{first + second}, а #{first + second} + #{left} = #{total}.",
      watch: "#{Num.frac(1, d1)} + #{Num.frac(1, d2)} от началното количество би дало #{Num.ans((total / d1) + (total / d2))} — това е друг, грешен отговор."
    )
  )
end

# --------------------------------------------------------- Десетични числа ---

Authoring.family "dec.add_sub", topic: "Десетични числа", area: "fractions",
                 rungs: [ 920, 1010, 1100, 1190, 1280, 1380 ] do |c|
  spec = c.by_level([
    { whole: 1..9, places: 1 }, { whole: 2..20, places: 1 }, { whole: 5..40, places: 2 },
    { whole: 10..90, places: 2 }, { whole: 20..300, places: 2 }, { whole: 50..900, places: 3 }
  ])
  scale = 10**spec[:places]
  a = Rational(c.int(spec[:whole]) * scale + c.int(1...scale), scale)
  b = Rational(c.int(spec[:whole]) * scale + c.int(1...scale), scale)
  subtract = c.coin && a > b
  result = subtract ? a - b : a + b

  c.q(
    text: "Пресметни #{Num.dec(a, spec[:places])} #{subtract ? Num::MINUS : '+'} #{Num.dec(b, spec[:places])}.",
    answer: Num.dec(result, spec[:places]),
    explanation: Explain.build(
      idea: "Записваме числата едно под друго така, че запетаите да съвпадат — тогава разредите се срещат правилно.",
      steps: [
        "Целите части: #{a.truncate} #{subtract ? Num::MINUS : '+'} #{b.truncate}.",
        "Дробните части се #{subtract ? 'изваждат' : 'събират'} по разреди (десети, стотни#{spec[:places] > 2 ? ', хилядни' : ''}).",
        "Резултатът е #{Num.dec(result, spec[:places])}."
      ],
      answer: Num.dec(result, spec[:places]),
      check: subtract ? "#{Num.dec(result, spec[:places])} + #{Num.dec(b, spec[:places])} = #{Num.dec(a, spec[:places])}." :
                        "#{Num.dec(result, spec[:places])} − #{Num.dec(b, spec[:places])} = #{Num.dec(a, spec[:places])}.",
      watch: "Запетаята в отговора стои под запетаите на събираемите — не се мести."
    )
  )
end

Authoring.family "dec.multiply_int", topic: "Десетични числа", area: "fractions",
                 rungs: [ 980, 1070, 1160, 1250, 1340, 1440 ] do |c|
  places = c.by_level([ 1, 1, 2, 2, 2, 3 ])
  scale = 10**places
  a = Rational((c.int(1..30) * scale) + c.int(1...scale), scale)
  b = c.int(c.by_level([ 2..5, 2..9, 3..12, 4..20, 6..40, 8..90 ]))
  product = a * b

  c.q(
    text: "Пресметни #{Num.dec(a, places)} · #{b}.",
    answer: Num.dec(product, places),
    explanation: Explain.build(
      idea: "Умножаваме без да гледаме запетаята, после я връщаме на място: толкова знака след нея, колкото има в множителите.",
      steps: [
        "Без запетая: #{(a * scale).to_i} · #{b} = #{(a * scale).to_i * b}.",
        "Множимото има #{places} знака след запетаята, значи и произведението има #{places}.",
        "#{(a * scale).to_i * b} с #{places} знака след запетаята е #{Num.dec(product, places)}."
      ],
      answer: Num.dec(product, places),
      check: "Груба преценка: #{a.round} · #{b} ≈ #{a.round * b} — отговорът #{Num.dec(product, places)} е около толкова.",
      watch: "Броят знаци след запетаята се запазва — не се закръгля наум."
    )
  )
end

Authoring.family "dec.multiply_decimal", topic: "Десетични числа", area: "fractions",
                 rungs: [ 1120, 1210, 1300, 1390, 1480, 1580 ] do |c|
  a_places = c.by_level([ 1, 1, 1, 2, 2, 2 ])
  b_places = c.by_level([ 1, 1, 2, 2, 2, 3 ])
  a = Rational((c.int(1..12) * (10**a_places)) + c.int(1...(10**a_places)), 10**a_places)
  b = Rational((c.int(1..9) * (10**b_places)) + c.int(1...(10**b_places)), 10**b_places)
  product = a * b
  total_places = a_places + b_places

  c.q(
    text: "Пресметни #{Num.dec(a, a_places)} · #{Num.dec(b, b_places)}.",
    answer: Num.dec(product, total_places),
    explanation: Explain.build(
      idea: "Умножаваме като цели числа и накрая отделяме толкова знака след запетаята, колкото са общо в двата множителя.",
      steps: [
        "#{(a * (10**a_places)).to_i} · #{(b * (10**b_places)).to_i} = #{(a * (10**a_places)).to_i * (b * (10**b_places)).to_i}.",
        "Знаци след запетаята: #{a_places} + #{b_places} = #{total_places}.",
        "Значи произведението е #{Num.dec(product, total_places)}."
      ],
      answer: Num.dec(product, total_places),
      check: "#{a.round} · #{b.round} ≈ #{a.round * b.round} — същият порядък.",
      watch: "Двата множителя са под #{a.ceil} и #{b.ceil}, затова произведението е под #{a.ceil * b.ceil}."
    )
  )
end

Authoring.family "dec.divide_int", topic: "Десетични числа", area: "fractions",
                 rungs: [ 1060, 1150, 1240, 1330, 1420, 1520 ] do |c|
  divisor = c.int(c.by_level([ 2..5, 2..8, 3..9, 4..12, 5..20, 6..40 ]))
  places = c.by_level([ 1, 1, 2, 2, 2, 3 ])
  quotient = Rational((c.int(1..20) * (10**places)) + c.int(1...(10**places)), 10**places)
  dividend = quotient * divisor
  raise Authoring::Duplicate if dividend.denominator == 1

  c.q(
    text: "Пресметни #{Num.dec(dividend, places)} : #{divisor}.",
    answer: Num.dec(quotient, places),
    explanation: Explain.build(
      idea: "Делим както при цели числа, а запетаята в частното застава точно над запетаята в делимото.",
      steps: [
        "Целите: #{dividend.truncate} : #{divisor} дава #{quotient.truncate} и остатък, който продължава след запетаята.",
        "Продължаваме с десетите (и стотните), докато делението свърши.",
        "Частното е #{Num.dec(quotient, places)}."
      ],
      answer: Num.dec(quotient, places),
      check: "#{Num.dec(quotient, places)} · #{divisor} = #{Num.dec(dividend, places)}.",
      watch: "Ако запетаята се пропусне, отговорът излиза #{10**places} пъти по-голям."
    )
  )
end

Authoring.family "dec.divide_by_decimal", topic: "Десетични числа", area: "fractions",
                 rungs: [ 1200, 1290, 1380, 1470, 1560, 1660 ] do |c|
  divisor_places = c.by_level([ 1, 1, 1, 2, 2, 2 ])
  divisor = Rational(c.int(1..9) * (10**divisor_places) + c.int(1...(10**divisor_places)), 10**divisor_places)
  quotient = c.int(c.by_level([ 2..9, 3..15, 4..25, 5..40, 6..80, 8..150 ]))
  dividend = divisor * quotient
  shift = 10**divisor_places

  c.q(
    text: "Пресметни #{Num.dec(dividend, divisor_places + 1)} : #{Num.dec(divisor, divisor_places)}.",
    answer: Num.ans(quotient),
    explanation: Explain.build(
      idea: "Умножаваме делимото и делителя по една и съща степен на 10, докато делителят стане цяло число — частното не се променя.",
      steps: [
        "Умножаваме по #{shift}: #{Num.dec(dividend * shift, 1)} : #{(divisor * shift).to_i}.",
        "#{Num.dec(dividend * shift, 1)} : #{(divisor * shift).to_i} = #{quotient}."
      ],
      answer: Num.ans(quotient),
      check: "#{Num.dec(divisor, divisor_places)} · #{quotient} = #{Num.dec(dividend, divisor_places + 1)}.",
      watch: "И двете числа се умножават по #{shift} — ако само едното, отговорът се разминава #{shift} пъти."
    )
  )
end

Authoring.family "dec.round", topic: "Десетични числа", area: "fractions",
                 rungs: [ 940, 1030, 1120, 1210, 1300, 1400 ] do |c|
  places = c.by_level([ 0, 0, 1, 1, 2, 2 ])
  source_places = places + c.int(1..2)
  scale = 10**source_places
  value = Rational((c.int(1..80) * scale) + c.int(1...scale), scale)
  rounded = (value * (10**places)).round / Rational(10**places)
  name = { 0 => "цели", 1 => "десети", 2 => "стотни" }.fetch(places)

  c.q(
    text: "Закръгли #{Num.dec(value, source_places)} до #{name}.",
    answer: Num.dec(rounded, [ places, 1 ].max),
    explanation: Explain.build(
      idea: "Гледаме първата цифра след разряда, до който закръгляме: 5 или повече качва, по-малко — оставя.",
      steps: [
        "Разрядът е #{name}; цифрата след него е #{((value * (10**(places + 1))).to_i % 10)}.",
        ((value * (10**(places + 1))).to_i % 10) >= 5 ? "Тя е 5 или повече, затова качваме." : "Тя е под 5, затова оставяме разряда както е.",
        "Резултатът е #{Num.dec(rounded, [ places, 1 ].max)}."
      ],
      answer: Num.dec(rounded, [ places, 1 ].max),
      check: "Разликата |#{Num.dec(value, source_places)} − #{Num.dec(rounded, [ places, 1 ].max)}| = #{Num.dec((value - rounded).abs, source_places)} е под половин разряд.",
      watch: "Закръглява се наведнъж, не цифра по цифра отдясно наляво."
    )
  )
end

Authoring.family "dec.compare", topic: "Десетични числа", area: "fractions",
                 rungs: [ 900, 990, 1080, 1170, 1260, 1360 ] do |c|
  places_a = c.by_level([ 1, 1, 2, 2, 3, 3 ])
  places_b = c.by_level([ 1, 2, 1, 3, 2, 4 ])
  whole = c.int(0..40)
  a = Rational((whole * (10**places_a)) + c.int(1...(10**places_a)), 10**places_a)
  b = Rational((whole * (10**places_b)) + c.int(1...(10**places_b)), 10**places_b)
  raise Authoring::Duplicate if a == b

  bigger = [ a, b ].max
  places = [ places_a, places_b ].max

  c.q(
    text: "Кое число е по-голямо: #{Num.dec(a, places_a)} или #{Num.dec(b, places_b)}? Запиши по-голямото.",
    answer: Num.dec(bigger, bigger == a ? places_a : places_b),
    explanation: Explain.build(
      idea: "Изравняваме броя знаци след запетаята с нули и сравняваме разред по разред.",
      steps: [
        "#{Num.dec(a, places_a)} = #{Num.dec(a, places)} и #{Num.dec(b, places_b)} = #{Num.dec(b, places)}.",
        "Целите части са равни (#{whole}), затова решават десетите, после стотните.",
        "По-голямо е #{Num.dec(bigger, places)}."
      ],
      answer: Num.dec(bigger, bigger == a ? places_a : places_b),
      check: "Разликата им е #{Num.dec((a - b).abs, places)}, положителна в полза на #{Num.dec(bigger, places)}.",
      watch: "Повече цифри след запетаята не значи по-голямо число: 0,3 е по-голямо от 0,29."
    )
  )
end

Authoring.family "dec.to_fraction", topic: "Десетични числа", area: "fractions",
                 rungs: [ 1010, 1100, 1190, 1280, 1370, 1470 ] do |c|
  places = c.by_level([ 1, 1, 2, 2, 2, 3 ])
  scale = 10**places
  numerator = c.int(1...scale)
  raise Authoring::Duplicate if (numerator % 10).zero? && places > 1

  # A whole part from the second rung up, both to make the exercise harder and
  # to keep the one-decimal rungs from asking the same nine questions twice.
  whole = c.level >= 1 ? c.int(0..c.by_level([ 0, 9, 4, 12, 30, 60 ])) : 0
  value = whole + Rational(numerator, scale)

  c.q(
    text: "Запиши #{Num.dec(value, places)} като съкратена дроб.",
    answer: Num.frac(value),
    explanation: Explain.build(
      idea: "Десетичната дроб се чете направо: толкова #{places == 1 ? 'десети' : places == 2 ? 'стотни' : 'хилядни'}, колкото показват цифрите след запетаята.",
      steps: [
        whole.zero? ? "#{Num.dec(value, places)} = #{numerator}/#{scale}." :
                      "#{Num.dec(value, places)} = #{whole} цели и #{numerator}/#{scale} = #{(whole * scale) + numerator}/#{scale}.",
        Num.gcd((whole * scale) + numerator, scale) > 1 ?
          "Съкращаваме с #{Num.gcd((whole * scale) + numerator, scale)}: #{Num.frac(value)}." : "Дробта вече е несъкратима."
      ],
      answer: Num.frac(value),
      check: "#{Num.frac(value)} = #{Num.dec(value, places)} при обратното деление.",
      watch: "Знаменателят е 10, 100 или 1000 според броя знаци — не се брои самата цифра."
    )
  )
end

Authoring.family "dec.money_story", topic: "Десетични числа", area: "fractions",
                 rungs: [ 1000, 1090, 1180, 1270, 1360, 1460 ] do |c|
  spec = c.by_level([ 2..3, 2..4, 3..5, 3..6, 4..8, 5..12 ])
  count = c.int(spec)
  item, band = c.goods
  price = Rational((c.int(band) * 100) + c.pick([ 20, 45, 50, 70, 80, 90, 99 ]), 100)
  total = price * count
  paid = total.ceil + c.pick([ 0, 1, 5, 10 ])
  change = paid - total
  who = c.person

  c.q(
    text: "#{who} купува #{item.count(count)} по #{Num.money(price)} и плаща с #{Num.money(paid)}. Колко лева е рестото?",
    answer: Num.dec2(change),
    explanation: Explain.build(
      idea: "Стойността на покупката е цена по брой; рестото е платеното минус стойността.",
      steps: [
        "#{count} · #{Num.money(price)} = #{Num.money(total)}.",
        "#{Num.money(paid)} − #{Num.money(total)} = #{Num.money(change)}."
      ],
      answer: Num.money(change),
      check: "#{Num.money(total)} + #{Num.money(change)} = #{Num.money(paid)}.",
      watch: "Стотинките се изваждат от стотинките — при нужда се заема 1 лев = 100 стотинки."
    )
  )
end

Authoring.family "dec.units_convert", topic: "Десетични числа", area: "fractions",
                 rungs: [ 1040, 1130, 1220, 1310, 1400, 1500 ] do |c|
  pair = c.by_level([
    [ "м", "см", 100 ], [ "кг", "г", 1000 ], [ "м", "мм", 1000 ],
    [ "км", "м", 1000 ], [ "л", "мл", 1000 ], [ "т", "кг", 1000 ]
  ])
  big, small, factor = pair
  places = factor == 100 ? 2 : 3
  value = Rational((c.int(1..40) * (10**places)) + c.int(1...(10**places)), 10**places)
  converted = value * factor

  c.q(
    text: "Колко #{small} са #{Num.dec(value, places)} #{big}?",
    answer: Num.ans(converted),
    explanation: Explain.build(
      idea: "Преминаването към по-малка мерна единица е умножение — числото става по-голямо.",
      steps: [
        "1 #{big} = #{factor} #{small}.",
        "#{Num.dec(value, places)} · #{factor} = #{Num.ans(converted)} #{small} — запетаята се мести с #{Math.log10(factor).round} места надясно."
      ],
      answer: "#{Num.ans(converted)} #{small}",
      check: "Обратно: #{Num.ans(converted)} : #{factor} = #{Num.dec(value, places)} #{big}.",
      watch: "По-малка единица — по-голямо число. Ако отговорът е по-малък, посоката е сгрешена."
    )
  )
end

Authoring.family "dec.average", topic: "Десетични числа", area: "fractions",
                 rungs: [ 1120, 1210, 1300, 1390, 1480, 1580 ] do |c|
  count = c.by_level([ 2, 3, 3, 4, 4, 5 ])
  places = 1
  values = Array.new(count) { Rational((c.int(2..20) * 10) + c.int(0..9), 10) }
  sum = values.sum
  average = sum / count
  raise Authoring::Duplicate unless (average * 100).denominator == 1

  c.q(
    text: "Намери средното аритметично на числата #{values.map { |v| Num.dec(v, places) }.join(', ')}.",
    answer: Num.dec(average, 2),
    explanation: Explain.build(
      idea: "Средното аритметично е сборът, разделен на броя на числата.",
      steps: [
        "Сбор: #{values.map { |v| Num.dec(v, places) }.join(' + ')} = #{Num.dec(sum, places)}.",
        "Брой: #{count}.",
        "#{Num.dec(sum, places)} : #{count} = #{Num.dec(average, 2)}."
      ],
      answer: Num.dec(average, 2),
      check: "Средното стои между най-малкото (#{Num.dec(values.min, places)}) и най-голямото (#{Num.dec(values.max, places)}).",
      watch: "Дели се на броя на числата, не на най-голямото от тях."
    )
  )
end

# ----------------------------------------------------------------- Проценти ---

Authoring.family "pct.of_amount", topic: "Проценти", area: "fractions",
                 rungs: [ 970, 1060, 1150, 1240, 1330, 1430 ] do |c|
  percent = c.by_level([ [ 10, 50 ], [ 10, 20, 25, 50 ], [ 5, 15, 20, 40, 75 ],
                         [ 12, 18, 35, 60, 80 ], [ 8, 16, 24, 45, 65 ], [ 6, 14, 22, 38, 84 ] ])
  pct = c.pick(percent)
  base = c.int(c.by_level([ 2..12, 2..20, 4..40, 5..80, 8..200, 12..600 ])) * (100 / Num.gcd(pct, 100))
  raise Authoring::Duplicate if base > 20_000

  result = base * pct / 100
  what = c.pick([ "ученици", "лева", "километра", "гласа", "точки", "минути" ])

  c.q(
    text: "Колко са #{pct}% от #{base} #{what}?",
    answer: Num.ans(result),
    explanation: Explain.build(
      idea: "Процентът е стотна част: #{pct}% значи #{pct} от всеки 100.",
      steps: [
        "1% от #{base} е #{base} : 100 = #{Num.dec(Rational(base, 100), 2)}.",
        "#{pct}% са #{pct} пъти повече: #{Num.dec(Rational(base, 100), 2)} · #{pct} = #{result}.",
        "По-кратко: #{base} · #{pct} : 100 = #{result}."
      ],
      answer: Num.ans(result),
      check: "#{result} : #{base} = #{Num.dec(Rational(result, base), 2)} = #{pct}%.",
      watch: "50% е половината, 25% е четвъртинката — грубата преценка пази от груба грешка."
    )
  )
end

Authoring.family "pct.discount", topic: "Проценти", area: "fractions",
                 rungs: [ 1050, 1140, 1230, 1320, 1410, 1510 ] do |c|
  pct = c.pick(c.by_level([ [ 10, 50 ], [ 10, 20, 25 ], [ 15, 20, 30, 40 ],
                            [ 12, 18, 35, 45 ], [ 8, 16, 24, 65 ], [ 6, 14, 22, 38 ] ]))
  price = c.int(c.by_level([ 2..12, 2..25, 4..50, 5..120, 10..400, 20..900 ])) * (100 / Num.gcd(pct, 100))
  raise Authoring::Duplicate if price > 5000

  discount = price * pct / 100
  final = price - discount
  item, = c.goods

  c.q(
    text: "#{item.one.capitalize} струва #{price} лв. Цената пада с #{pct}%. Колко лева струва след намалението?",
    answer: Num.ans(final),
    explanation: Explain.build(
      idea: "Намалението се смята от старата цена, а новата цена е това, което остава от нея.",
      steps: [
        "Намалението: #{price} · #{pct} : 100 = #{discount} лв.",
        "Новата цена: #{price} − #{discount} = #{final} лв.",
        "Или наведнъж: остават #{100 - pct}% от цената, #{price} · #{100 - pct} : 100 = #{final} лв."
      ],
      answer: "#{final} лв.",
      check: "#{final} + #{discount} = #{price} лв.",
      watch: "#{pct}% е размерът на намалението, а не новата цена."
    )
  )
end

Authoring.family "pct.increase", topic: "Проценти", area: "fractions",
                 rungs: [ 1080, 1170, 1260, 1350, 1440, 1540 ] do |c|
  pct = c.pick(c.by_level([ [ 10, 50 ], [ 10, 20, 25 ], [ 15, 30, 40 ],
                            [ 12, 35, 45 ], [ 8, 24, 65 ], [ 6, 22, 38, 44, 72 ] ]))
  base = c.int(c.by_level([ 2..12, 2..25, 4..50, 5..120, 10..400, 20..1500 ])) * (100 / Num.gcd(pct, 100))
  raise Authoring::Duplicate if base > 5000

  increase = base * pct / 100
  result = base + increase

  c.q(
    text: "Заплатата е #{base} лв. и се увеличава с #{pct}%. Колко лева става новата заплата?",
    answer: Num.ans(result),
    explanation: Explain.build(
      idea: "Увеличението се смята от старата стойност и после се добавя към нея.",
      steps: [
        "Увеличението: #{base} · #{pct} : 100 = #{increase} лв.",
        "Новата стойност: #{base} + #{increase} = #{result} лв.",
        "Или наведнъж: #{100 + pct}% от #{base} = #{base} · #{100 + pct} : 100 = #{result} лв."
      ],
      answer: "#{result} лв.",
      check: "#{result} − #{base} = #{increase}, а #{increase} : #{base} = #{Num.dec(Rational(increase, base), 2)} = #{pct}%.",
      watch: "Увеличение с #{pct}% значи умножение по #{Num.dec(Rational(100 + pct, 100), 2)}, не по #{Num.dec(Rational(pct, 100), 2)}."
    )
  )
end

Authoring.family "pct.what_percent", topic: "Проценти", area: "fractions",
                 rungs: [ 1100, 1190, 1280, 1370, 1460, 1560 ] do |c|
  pct = c.pick(c.by_level([ [ 10, 25, 50 ], [ 20, 40, 75 ], [ 5, 15, 60 ],
                            [ 12, 35, 80 ], [ 8, 45, 65 ], [ 6, 28, 92 ] ]))
  unit = c.int(c.by_level([ 1..5, 1..8, 2..12, 2..20, 3..40, 4..90 ]))
  part = pct * unit
  whole = 100 * unit

  c.q(
    text: "Колко процента е #{part} от #{whole}?",
    answer: Num.ans(pct),
    explanation: Explain.build(
      idea: "Отношението част : цяло се превръща в проценти чрез умножение по 100.",
      steps: [
        "#{part} : #{whole} = #{Num.frac(part, whole)}.",
        "#{Num.frac(part, whole)} · 100 = #{pct}%."
      ],
      answer: "#{pct}%",
      check: "#{pct}% от #{whole} = #{whole} · #{pct} : 100 = #{part}.",
      watch: "Дели се на цялото (#{whole}), не на частта — обратното дава #{Num.dec(Rational(whole * 100, part), 1)}%."
    )
  )
end

Authoring.family "pct.reverse_whole", topic: "Проценти", area: "fractions",
                 rungs: [ 1180, 1270, 1360, 1450, 1540, 1640 ] do |c|
  pct = c.pick(c.by_level([ [ 10, 50 ], [ 20, 25 ], [ 15, 40, 75 ], [ 12, 35, 60 ], [ 8, 45, 80 ], [ 6, 24, 65 ] ]))
  unit = c.int(c.by_level([ 1..6, 1..10, 2..15, 2..30, 3..60, 4..120 ]))
  part = pct * unit
  whole = 100 * unit

  c.q(
    text: "#{pct}% от едно число са #{part}. Кое е числото?",
    answer: Num.ans(whole),
    explanation: Explain.build(
      idea: "От част към цяло: намираме на колко е равен 1%, после умножаваме по 100.",
      steps: [
        "#{pct}% са #{part}, значи 1% е #{part} : #{pct} = #{unit}.",
        "100% са #{unit} · 100 = #{whole}."
      ],
      answer: Num.ans(whole),
      check: "#{pct}% от #{whole} = #{whole} · #{pct} : 100 = #{part}.",
      watch: "Цялото е по-голямо от частта — отговор, по-малък от #{part}, е сигурна грешка."
    )
  )
end

Authoring.family "pct.two_discounts", topic: "Проценти", area: "fractions",
                 rungs: [ 1300, 1390, 1480, 1570, 1660, 1760 ] do |c|
  first = c.pick([ 10, 20, 25, 50 ])
  second = c.pick([ 10, 20, 25, 40 ])
  price = c.int(c.by_level([ 4..20, 5..40, 8..80, 10..200, 20..500, 40..1200 ])) * 100
  after_first = price * (100 - first) / 100
  final = after_first * (100 - second) / 100
  total_drop = price - final
  naive = price * (100 - first - second) / 100

  c.q(
    text: "Цена от #{price} лв. се намалява с #{first}%, а след това новата цена — с още #{second}%. " \
          "Колко лева струва стоката накрая?",
    answer: Num.ans(final),
    explanation: Explain.build(
      idea: "Второто намаление се смята от вече намалената цена, не от началната.",
      steps: [
        "След първото: #{price} · #{100 - first} : 100 = #{after_first} лв.",
        "След второто: #{after_first} · #{100 - second} : 100 = #{final} лв.",
        "Общото намаление е #{price} − #{final} = #{total_drop} лв., тоест #{Num.dec(Rational(total_drop * 100, price), 1)}%."
      ],
      answer: "#{final} лв.",
      check: "#{Num.dec(Rational(100 - first, 100), 2)} · #{Num.dec(Rational(100 - second, 100), 2)} = #{Num.dec(Rational((100 - first) * (100 - second), 10_000), 4)} от началната цена.",
      watch: "Двете намаления не се събират: #{first}% + #{second}% = #{first + second}% би дало #{naive} лв., което е грешно."
    )
  )
end

Authoring.family "pct.interest", topic: "Проценти", area: "fractions",
                 rungs: [ 1250, 1340, 1430, 1520, 1610, 1710 ] do |c|
  rate = c.pick(c.by_level([ [ 5, 10 ], [ 4, 5, 10 ], [ 3, 6, 8 ], [ 2, 4, 7 ], [ 3, 5, 9 ], [ 2, 6, 12 ] ]))
  years = c.by_level([ 1, 1, 2, 2, 3, 4 ])
  principal = c.int(c.by_level([ 2..10, 3..20, 4..40, 5..80, 8..200, 10..500 ])) * 100
  interest = principal * rate * years / 100
  total = principal + interest

  c.q(
    text: "Влог от #{principal} лв. носи проста лихва #{rate}% годишно. " \
          "Колко лева има по влога след #{years} #{years == 1 ? 'година' : 'години'}?",
    answer: Num.ans(total),
    explanation: Explain.build(
      idea: "Простата лихва се начислява всяка година върху началната сума.",
      steps: [
        "Лихвата за една година: #{principal} · #{rate} : 100 = #{principal * rate / 100} лв.",
        years > 1 ? "За #{years} години: #{principal * rate / 100} · #{years} = #{interest} лв." : "Общата лихва е #{interest} лв.",
        "Сумата става #{principal} + #{interest} = #{total} лв."
      ],
      answer: "#{total} лв.",
      check: "#{interest} : #{principal} = #{Num.dec(Rational(interest, principal), 3)}, тоест #{rate * years}% за целия период.",
      watch: "При проста лихва основата не расте — не се смята лихва върху лихвата."
    )
  )
end

Authoring.family "pct.fraction_percent", topic: "Проценти", area: "fractions",
                 rungs: [ 1020, 1110, 1200, 1290, 1380, 1480 ] do |c|
  fraction = c.pick(c.by_level([
    [ Rational(1, 2), Rational(1, 4), Rational(3, 4), Rational(1, 5), Rational(2, 5), Rational(1, 10) ],
    [ Rational(3, 5), Rational(4, 5), Rational(3, 10), Rational(7, 10), Rational(9, 10), Rational(1, 20) ],
    [ Rational(1, 8), Rational(3, 8), Rational(5, 8), Rational(7, 8), Rational(3, 20), Rational(9, 20) ],
    [ Rational(7, 20), Rational(11, 20), Rational(13, 20), Rational(17, 20), Rational(1, 25), Rational(2, 25) ],
    [ Rational(9, 25), Rational(13, 25), Rational(21, 25), Rational(3, 50), Rational(13, 50), Rational(31, 50) ],
    [ Rational(11, 40), Rational(17, 40), Rational(29, 40), Rational(3, 16), Rational(7, 16), Rational(13, 16) ]
  ]))
  percent = fraction * 100

  c.q(
    text: "Колко процента е #{Num.frac(fraction)}?",
    answer: Num.dec(percent, 2),
    explanation: Explain.build(
      idea: "Дробта се превръща в проценти чрез умножение по 100 — процентът е стотна част.",
      steps: [
        "#{Num.frac(fraction)} · 100 = #{Num.dec(percent, 2)}.",
        "Значи #{Num.frac(fraction)} = #{Num.dec(percent, 2)}%."
      ],
      answer: "#{Num.dec(percent, 2)}%",
      check: "#{Num.dec(percent, 2)}% от 100 е #{Num.dec(percent, 2)} — точно #{Num.frac(fraction)} от 100.",
      watch: "Процентът не е числителят: #{Num.frac(fraction)} не е #{fraction.numerator}%."
    )
  )
end

Authoring.family "pct.exam_score", topic: "Проценти", area: "fractions",
                 rungs: [ 1140, 1230, 1320, 1410, 1500, 1600 ] do |c|
  total = c.int(c.by_level([ 10..20, 20..25, 25..40, 40..50, 50..80, 60..120 ]))
  pct = c.pick([ 40, 50, 60, 70, 75, 80, 85, 90 ])
  raise Authoring::Duplicate unless ((total * pct) % 100).zero?

  correct = total * pct / 100

  c.q(
    text: "Тестът има #{total} въпроса. За успешно преминаване са нужни поне #{pct}% верни отговора. " \
          "Колко най-малко верни отговора са нужни?",
    answer: Num.ans(correct),
    explanation: Explain.build(
      idea: "Процентът се смята от общия брой въпроси.",
      steps: [
        "#{pct}% от #{total} = #{total} · #{pct} : 100 = #{correct}.",
        "Значи трябват поне #{correct} верни отговора."
      ],
      answer: "#{correct} верни отговора",
      check: "#{correct} : #{total} = #{Num.dec(Rational(correct, total), 2)} = #{pct}%.",
      watch: "Останалите #{total - correct} въпроса са #{100 - pct}% — двата дяла заедно дават 100%."
    )
  )
end
