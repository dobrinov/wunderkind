# Числа: разредни единици и редици, делимост, прости числа, НОД/НОК, остатъци.

# ------------------------------------------------------------ Числа и редици ---

Authoring.family "numbers.place_value", topic: "Числа и редици", area: "numbers",
                 rungs: [ 680, 760, 840, 930, 1020, 1120 ] do |c|
  places = [ [ "единиците", 1 ], [ "десетиците", 10 ], [ "стотиците", 100 ],
             [ "хилядите", 1000 ], [ "десетохилядните", 10_000 ], [ "стохилядните", 100_000 ] ]
  size = c.by_level([ 2, 3, 3, 4, 5, 6 ])
  number = c.int((10**(size - 1))..((10**size) - 1))
  place_index = c.int(0...[ size, 6 ].min)
  name, unit = places[place_index]
  digit = (number / unit) % 10

  c.q(
    text: "Коя цифра стои в разряда на #{name} в числото #{number}?",
    answer: Num.ans(digit),
    explanation: Explain.build(
      idea: "Разредите се броят отдясно наляво: единици, десетици, стотици, хиляди и нататък.",
      steps: [
        "Записваме числото по разреди: #{number.to_s.chars.reverse.each_with_index.map { |d, i| "#{d} · #{10**i}" }.reverse.join(' + ')}.",
        "Разредът на #{name} е този с множител #{unit}, а там стои цифрата #{digit}."
      ],
      answer: Num.ans(digit),
      check: "Стойността на тази цифра в числото е #{digit} · #{unit} = #{digit * unit}.",
      watch: "Пита се за цифрата, не за стойността ѝ (#{digit * unit})."
    )
  )
end

Authoring.family "numbers.expanded_form", topic: "Числа и редици", area: "numbers",
                 rungs: [ 720, 800, 890, 980, 1070, 1170 ] do |c|
  size = c.by_level([ 3, 3, 4, 4, 5, 6 ])
  number = c.int((10**(size - 1))..((10**size) - 1))
  digits = number.to_s.chars.map(&:to_i)
  parts = digits.each_with_index.map { |d, i| d * (10**(digits.size - 1 - i)) }.reject(&:zero?)
  correct = parts.join(" + ")
  wrong_one = (parts[0...-1] + [ digits.last * 10 ]).join(" + ")
  wrong_two = digits.join(" + ")

  c.q(
    text: "Кой запис е разложението на числото #{number} по разредни единици?",
    options: c.options(correct, wrong_one, wrong_two, (parts.reverse).join(" + ")),
    answer: correct,
    explanation: Explain.build(
      idea: "Всяка цифра носи стойност според разреда си: цифрата по 1, 10, 100 и така нататък.",
      steps: [
        digits.each_with_index.map { |d, i| "#{d} в разряда на #{10**(digits.size - 1 - i)}" }.join(", ") + ".",
        "Записът е #{correct}."
      ],
      answer: correct,
      check: "Сборът #{correct} = #{number}.",
      watch: "Само цифрите (#{wrong_two}) дават #{digits.sum} — това е сборът им, не самото число."
    )
  )
end

Authoring.family "numbers.compare", topic: "Числа и редици", area: "numbers",
                 rungs: [ 660, 740, 820, 910, 1000, 1100 ] do |c|
  spec = c.by_level([ 10..99, 100..999, 1000..9999, 10_000..99_999, 100_000..999_999, 1_000_000..9_999_999 ])
  a = c.int(spec)
  b = c.int(spec)
  raise Authoring::Duplicate if a == b
  raise Authoring::Duplicate if a.to_s.size != b.to_s.size

  bigger = [ a, b ].max

  c.q(
    text: "Кое от двете числа е по-голямо: #{a} или #{b}?",
    answer: Num.ans(bigger),
    explanation: Explain.build(
      idea: "Числата с еднакъв брой цифри се сравняват отляво надясно — първата различна цифра решава.",
      steps: [
        "#{a} и #{b} имат по #{a.to_s.size} цифри.",
        (0...a.to_s.size).find { |i| a.to_s[i] != b.to_s[i] }.then do |i|
          "Първата разлика е в разряда с множител #{10**(a.to_s.size - 1 - i)}: #{a.to_s[i]} срещу #{b.to_s[i]}."
        end,
        "По-голямото е #{bigger}."
      ],
      answer: Num.ans(bigger),
      check: "Разликата им е #{(a - b).abs}, което потвърждава кое е по-голямото.",
      watch: "Сравняват се разредите, не сборът на цифрите."
    )
  )
end

Authoring.family "numbers.round", topic: "Числа и редици", area: "numbers",
                 rungs: [ 780, 860, 950, 1040, 1130, 1230 ] do |c|
  spec = c.by_level([
    { range: 11..99, unit: 10 }, { range: 105..995, unit: 10 },
    { range: 120..980, unit: 100 }, { range: 1050..9950, unit: 100 },
    { range: 1200..9800, unit: 1000 }, { range: 12_000..98_000, unit: 1000 }
  ])
  unit = spec[:unit]
  number = c.int(spec[:range])
  rest = number % unit
  rounded = rest >= unit / 2.0 ? number - rest + unit : number - rest
  place = { 10 => "десетици", 100 => "стотици", 1000 => "хиляди" }.fetch(unit)

  c.q(
    text: "Закръгли #{number} до #{place}.",
    answer: Num.ans(rounded),
    explanation: Explain.build(
      idea: "Гледаме цифрата точно след разряда, до който закръгляме: 5 и нагоре качва, под 5 оставя.",
      steps: [
        "#{number} стои между #{number - rest} и #{number - rest + unit}.",
        "Остатъкът над #{number - rest} е #{rest}, а половината от #{unit} е #{unit / 2}.",
        rest >= unit / 2.0 ? "#{rest} ≥ #{unit / 2}, затова качваме до #{rounded}." : "#{rest} < #{unit / 2}, затова оставаме на #{rounded}."
      ],
      answer: Num.ans(rounded),
      check: "Разликата |#{number} − #{rounded}| = #{(number - rounded).abs} е по-малка от половин #{unit}.",
      watch: "Закръгляването гледа само следващата цифра, не целия остатък."
    )
  )
end

Authoring.family "numbers.sequence_step", topic: "Числа и редици", area: "numbers",
                 rungs: [ 700, 780, 870, 960, 1050, 1150 ] do |c|
  spec = c.by_level([ [ 1..10, 2..5 ], [ 2..20, 3..9 ], [ 5..40, 4..12 ],
                      [ 10..80, 6..20 ], [ 20..150, 9..35 ], [ 40..400, 12..75 ] ])
  start = c.int(spec[0])
  step = c.int(spec[1])
  down = c.level >= 3 && c.coin
  step = -step if down
  terms = (0..3).map { |i| start + (i * step) }
  raise Authoring::Duplicate if terms.any?(&:negative?)

  nxt = start + (4 * step)

  c.q(
    text: "Продължи редицата: #{terms.join(', ')}, ...",
    answer: Num.ans(nxt),
    explanation: Explain.build(
      idea: "Търсим правилото: с колко се променя всеки следващ член.",
      steps: [
        "#{terms[1]} − #{terms[0]} = #{Num.bg(step)} и #{terms[2]} − #{terms[1]} = #{Num.bg(step)} — стъпката е постоянна.",
        "Следващият член: #{terms[3]} #{step.negative? ? Num::MINUS : '+'} #{step.abs} = #{Num.bg(nxt)}."
      ],
      answer: Num.bg(nxt),
      check: "Назад: #{Num.bg(nxt)} #{step.negative? ? '+' : Num::MINUS} #{step.abs} = #{terms[3]}.",
      watch: "Правилото се проверява поне на две съседни двойки, преди да се приложи."
    )
  )
end

Authoring.family "numbers.sequence_multiply", topic: "Числа и редици", area: "numbers",
                 rungs: [ 900, 990, 1080, 1170, 1260, 1360 ] do |c|
  base = c.by_level([ 1..3, 1..5, 2..7, 2..10, 3..15, 4..25 ])
  ratio = c.by_level([ 2..2, 2..3, 2..3, 3..4, 3..5, 4..6 ])
  start = c.int(base)
  q = c.int(ratio)
  terms = (0..3).map { |i| start * (q**i) }
  nxt = start * (q**4)

  c.q(
    text: "Продължи редицата: #{terms.join(', ')}, ...",
    answer: Num.ans(nxt),
    explanation: Explain.build(
      idea: "Разликите не са постоянни — проверяваме частните на съседните членове.",
      steps: [
        "#{terms[1]} : #{terms[0]} = #{q} и #{terms[2]} : #{terms[1]} = #{q} — всеки член е #{q} пъти по-голям.",
        "#{terms[3]} · #{q} = #{nxt}."
      ],
      answer: Num.ans(nxt),
      check: "#{nxt} : #{q} = #{terms[3]} — връщаме се към предишния член.",
      watch: "Ако се търси разлика, тя расте (#{terms[1] - terms[0]}, #{terms[2] - terms[1]}, #{terms[3] - terms[2]}) — правилото е умножение."
    )
  )
end

Authoring.family "numbers.sequence_pattern", topic: "Числа и редици", area: "numbers",
                 rungs: [ 1000, 1090, 1180, 1270, 1360, 1460 ] do |c|
  kind = c.by_level([ :growing, :growing, :squares, :squares, :triangular, :fibonacci ])
  case kind
  when :growing
    start = c.int(c.level.zero? ? 1..12 : 13..40)
    step = c.int(1..5)
    increment = c.int(1..4)
    terms = [ start ]
    4.times { |i| terms << terms.last + step + (i * increment) }
    nxt = terms.last + step + (4 * increment)
    idea = "Разликите между съседните членове сами образуват редица."
    steps = [
      "Разлики: #{(1...terms.size).map { |i| terms[i] - terms[i - 1] }.join(', ')} — те растат с #{increment}.",
      "Следващата разлика е #{step + (4 * increment)}, затова следващият член е #{terms.last} + #{step + (4 * increment)} = #{nxt}."
    ]
  when :squares
    start = c.int(c.level >= 3 ? 7..14 : 1..6)
    terms = (0..3).map { |i| (start + i)**2 }
    nxt = (start + 4)**2
    idea = "Членовете са точни квадрати."
    steps = [
      "#{terms.map.with_index { |t, i| "#{start + i}#{Num.sup(2)} = #{t}" }.join(', ')}.",
      "Следва #{start + 4}#{Num.sup(2)} = #{nxt}."
    ]
  when :triangular
    start = c.int(1..8)
    tri = ->(n) { n * (n + 1) / 2 }
    terms = (0..3).map { |i| tri.call(start + i) }
    nxt = tri.call(start + 4)
    idea = "Всеки следващ член добавя с едно повече от предишния път — това са триъгълните числа."
    steps = [
      "Разлики: #{(1...terms.size).map { |i| terms[i] - terms[i - 1] }.join(', ')} — растат с 1.",
      "Следващата разлика е #{start + 4}, значи #{terms.last} + #{start + 4} = #{nxt}."
    ]
  else
    a = c.int(1..9)
    b = c.int(a..(a + 9))
    terms = [ a, b, a + b, a + (2 * b) ]
    nxt = terms[-1] + terms[-2]
    idea = "Всеки член е сборът на двата преди него."
    steps = [
      "#{terms[0]} + #{terms[1]} = #{terms[2]} и #{terms[1]} + #{terms[2]} = #{terms[3]}.",
      "#{terms[2]} + #{terms[3]} = #{nxt}."
    ]
  end

  c.q(
    text: "Продължи редицата: #{terms.join(', ')}, ...",
    answer: Num.ans(nxt),
    explanation: Explain.build(
      idea: idea,
      steps: steps,
      answer: Num.ans(nxt),
      check: "Правилото трябва да пасва на всички дадени членове, не само на последния.",
      watch: "Постоянна разлика тук няма — не търсете една и съща стъпка."
    )
  )
end

Authoring.family "numbers.midpoint", topic: "Числа и редици", area: "numbers",
                 rungs: [ 820, 910, 1000, 1090, 1180, 1280 ] do |c|
  spec = c.by_level([ 10..60, 20..200, 100..900, 500..5000, 2000..20_000, 10_000..90_000 ])
  a = c.int(spec)
  gap = c.int(2..(spec.max / 4)) * 2
  b = a + gap
  middle = (a + b) / 2

  c.q(
    text: "Кое число стои точно по средата между #{a} и #{b}?",
    answer: Num.ans(middle),
    explanation: Explain.build(
      idea: "Средата на две числа е техният сбор, разделен на две.",
      steps: [
        "#{a} + #{b} = #{a + b}.",
        "#{a + b} : 2 = #{middle}."
      ],
      answer: Num.ans(middle),
      check: "#{middle} − #{a} = #{middle - a} и #{b} − #{middle} = #{b - middle} — разстоянията са равни.",
      watch: "Средата не е разликата (#{gap}), а числото на равни разстояния от двете."
    )
  )
end

Authoring.family "numbers.digit_sum", topic: "Числа и редици", area: "numbers",
                 rungs: [ 740, 830, 920, 1010, 1100, 1200 ] do |c|
  size = c.by_level([ 2, 3, 3, 4, 5, 6 ])
  number = c.int((10**(size - 1))..((10**size) - 1))
  digits = number.to_s.chars.map(&:to_i)

  c.q(
    text: "Колко е сборът на цифрите на числото #{number}?",
    answer: Num.ans(digits.sum),
    explanation: Explain.build(
      idea: "Събираме самите цифри, без да гледаме разредите им.",
      steps: [
        "#{digits.join(' + ')} = #{digits.sum}."
      ],
      answer: Num.ans(digits.sum),
      check: "Сборът на цифрите е между #{digits.size} · 0 = 0 и #{digits.size} · 9 = #{digits.size * 9} — #{digits.sum} е в границите.",
      watch: "Сборът на цифрите (#{digits.sum}) няма нищо общо със самото число (#{number}); той обаче издава делимост на 3 и 9."
    )
  )
end

Authoring.family "numbers.build_extreme", topic: "Числа и редици", area: "numbers",
                 rungs: [ 860, 950, 1040, 1130, 1220, 1320 ] do |c|
  count = c.by_level([ 3, 3, 4, 4, 5, 5 ])
  digits = c.sample((1..9).to_a, count)
  biggest = digits.sort.reverse.join.to_i
  smallest = digits.sort.join.to_i
  want_big = c.coin

  c.q(
    text: "От цифрите #{digits.join(', ')} (всяка се използва точно веднъж) съставяме число. " \
          "Кое е най-#{want_big ? 'голямото' : 'малкото'} възможно число?",
    answer: Num.ans(want_big ? biggest : smallest),
    explanation: Explain.build(
      idea: "Най-старшият разред тежи най-много, затова там отива #{want_big ? 'най-голямата' : 'най-малката'} цифра.",
      steps: [
        "Подредени цифри: #{digits.sort.join(', ')}.",
        want_big ? "Слагаме ги в намаляващ ред: #{biggest}." : "Слагаме ги в растящ ред: #{smallest}."
      ],
      answer: Num.ans(want_big ? biggest : smallest),
      check: "Другата крайност е #{want_big ? smallest : biggest}, а разликата между двете е #{biggest - smallest}.",
      watch: "Всяка цифра се използва по веднъж — не се повтаря най-удобната."
    )
  )
end

Authoring.family "numbers.negative_compare", topic: "Числа и редици", area: "numbers",
                 rungs: [ 980, 1070, 1160, 1250, 1340, 1440 ] do |c|
  spec = c.by_level([ 1..9, 2..15, 3..30, 5..60, 10..150, 20..400 ])
  a = -c.int(spec)
  b = c.level >= 2 && c.coin ? c.int(spec) : -c.int(spec)
  raise Authoring::Duplicate if a == b

  bigger = [ a, b ].max

  c.q(
    text: "Кое от числата е по-голямо: #{Num.bg(a)} или #{Num.bg(b)}?",
    answer: Num.ans(bigger),
    explanation: Explain.build(
      idea: "По числовата ос по-голямото число стои по-надясно. Всяко положително е по-голямо от всяко отрицателно.",
      steps: [
        a.negative? && b.negative? ? "И двете са отрицателни: по-голямо е това с по-малка абсолютна стойност (#{a.abs} и #{b.abs})." : "Едното е отрицателно, другото не — отрицателното е по-малкото.",
        "По-голямото е #{Num.bg(bigger)}."
      ],
      answer: Num.bg(bigger),
      check: "Разликата #{Num.bg(bigger)} − #{Num.bg([ a, b ].min)} = #{bigger - [ a, b ].min} е положителна.",
      watch: "При отрицателните числата се подреждат наопаки: #{Num::MINUS}9 е по-малко от #{Num::MINUS}2."
    )
  )
end

# --------------------------------------------------------------- Делимост ---

Authoring.family "divis.rule_2_5_10", topic: "Делимост", area: "numbers",
                 rungs: [ 860, 940, 1030, 1120, 1210, 1310 ] do |c|
  divisor = c.by_level([ 2, 5, 2, 10, 5, 2 ])
  size = c.by_level([ 2, 3, 3, 4, 4, 5 ])
  number = c.int((10**(size - 1))..((10**size) - 1))
  correct = number - (number % divisor)
  # Distractors are near neighbours that just miss the rule, so the student has
  # to apply it rather than spot the odd one out.
  wrong = []
  20.times do
    candidate = correct + c.int(-9..9)
    wrong << candidate if candidate.positive? && !(candidate % divisor).zero? && !wrong.include?(candidate)
    break if wrong.size == 3
  end
  raise Authoring::Duplicate if wrong.size < 3

  c.q(
    text: "Кое от числата #{([ correct ] + wrong).sort.join(', ')} се дели на #{divisor} без остатък?",
    options: c.options(correct, wrong),
    answer: Num.ans(correct),
    explanation: Explain.build(
      idea: "Признакът за делимост на #{divisor} гледа само последната цифра.",
      steps: [
        divisor == 2 ? "На 2 се делят числата, които завършват на 0, 2, 4, 6 или 8." :
          (divisor == 5 ? "На 5 се делят числата, които завършват на 0 или 5." : "На 10 се делят числата, които завършват на 0."),
        "#{correct} завършва на #{correct % 10} — условието е изпълнено.",
        "#{correct} : #{divisor} = #{correct / divisor}, без остатък."
      ],
      answer: Num.ans(correct),
      check: "#{divisor} · #{correct / divisor} = #{correct}.",
      watch: "Останалите числа дават остатък — например #{wrong.first} : #{divisor} оставя #{wrong.first % divisor}."
    )
  )
end

Authoring.family "divis.rule_3_9", topic: "Делимост", area: "numbers",
                 rungs: [ 920, 1010, 1100, 1190, 1280, 1380 ] do |c|
  divisor = c.by_level([ 3, 3, 9, 3, 9, 9 ])
  size = c.by_level([ 2, 3, 3, 4, 4, 5 ])
  multiple = c.int((10**(size - 1) / divisor)..(((10**size) - 1) / divisor)) * divisor
  wrong = (1..3).map { multiple + c.pick([ 1, 2, 4, 5, 7, 8 ]) }.uniq
  raise Authoring::Duplicate if wrong.size < 2

  digits = multiple.to_s.chars.map(&:to_i)

  c.q(
    text: "Кое от числата #{([ multiple ] + wrong).sort.join(', ')} се дели на #{divisor} без остатък?",
    options: c.options(multiple, wrong),
    answer: Num.ans(multiple),
    explanation: Explain.build(
      idea: "Число се дели на #{divisor} тогава и само тогава, когато сборът на цифрите му се дели на #{divisor}.",
      steps: [
        "За #{multiple}: #{digits.join(' + ')} = #{digits.sum}.",
        "#{digits.sum} : #{divisor} = #{digits.sum / divisor} — дели се, значи и самото число се дели.",
        "#{multiple} : #{divisor} = #{multiple / divisor}."
      ],
      answer: Num.ans(multiple),
      check: "#{divisor} · #{multiple / divisor} = #{multiple}.",
      watch: "Признакът важи за 3 и 9, но не за 2, 4 или 5 — там се гледат последните цифри."
    )
  )
end

Authoring.family "divis.missing_digit", topic: "Делимост", area: "numbers",
                 rungs: [ 1050, 1140, 1230, 1320, 1410, 1510 ] do |c|
  divisor = c.by_level([ 3, 3, 9, 9, 3, 9 ])
  prefix = c.int(c.by_level([ 10..49, 20..99, 30..99, 100..499, 200..999, 500..999 ]))
  base_sum = prefix.to_s.chars.map(&:to_i).sum
  digit = (0..9).find { |d| ((base_sum + d) % divisor).zero? }
  raise Authoring::Duplicate if digit.nil?

  number = (prefix * 10) + digit

  c.q(
    text: "Коя е най-малката цифра, която може да застане на мястото на ☐, така че числото #{prefix}☐ да се дели на #{divisor}?",
    answer: Num.ans(digit),
    explanation: Explain.build(
      idea: "Делимостта на #{divisor} зависи от сбора на цифрите, затова търсим каква добавка му липсва.",
      steps: [
        "Сборът на известните цифри е #{prefix.to_s.chars.map(&:to_i).join(' + ')} = #{base_sum}.",
        "#{base_sum} : #{divisor} дава остатък #{base_sum % divisor}.",
        (base_sum % divisor).zero? ? "Остатък няма, затова най-малката подходяща цифра е 0." :
                                     "Липсват #{divisor - (base_sum % divisor)} до следващото кратно, значи цифрата е #{digit}."
      ],
      answer: Num.ans(digit),
      check: "#{number} : #{divisor} = #{number / divisor}, точно.",
      watch: "Търси се най-малката цифра — по-нататък има и други (например #{digit + divisor <= 9 ? digit + divisor : 'няма друга едноцифрена'})."
    )
  )
end

Authoring.family "divis.count_multiples", topic: "Делимост", area: "numbers",
                 rungs: [ 1000, 1090, 1180, 1270, 1360, 1460 ] do |c|
  limit = c.int(c.by_level([ 20..50, 40..100, 80..200, 150..400, 300..800, 600..2000 ]))
  divisor = c.int(c.by_level([ 2..5, 3..7, 4..9, 6..12, 7..15, 9..24 ]))
  count = limit / divisor
  raise Authoring::Duplicate if count < 3

  c.q(
    text: "Колко са числата от 1 до #{limit}, които се делят на #{divisor}?",
    answer: Num.ans(count),
    explanation: Explain.build(
      idea: "Кратните на #{divisor} са #{divisor}, #{2 * divisor}, #{3 * divisor}, ... — броят им е цялата част от #{limit} : #{divisor}.",
      steps: [
        "#{limit} : #{divisor} = #{count}#{(limit % divisor).zero? ? '' : " и остатък #{limit % divisor}"}.",
        "Последното кратно, което влиза, е #{count * divisor}.",
        "Значи такива числа са #{count}."
      ],
      answer: Num.ans(count),
      check: "#{count} · #{divisor} = #{count * divisor} ≤ #{limit}, а #{(count + 1) * divisor} вече надхвърля границата.",
      watch: "Броим кратните, не самите числа — отговорът е много по-малък от #{limit}."
    )
  )
end

Authoring.family "divis.divisors_of", topic: "Делимост", area: "numbers",
                 rungs: [ 960, 1050, 1140, 1230, 1320, 1420 ] do |c|
  number = c.int(c.by_level([ 6..24, 10..40, 16..60, 24..100, 36..200, 48..400 ]))
  divisors = Num.divisors(number)
  raise Authoring::Duplicate if divisors.size < 4

  c.q(
    text: "Колко делителя има числото #{number}?",
    answer: Num.ans(divisors.size),
    explanation: Explain.build(
      idea: "Делителите вървят по двойки: ако d дели числото, то и числото : d го дели.",
      steps: [
        "Търсим двойките: #{divisors.take(divisors.size / 2 + (divisors.size.odd? ? 1 : 0)).map { |d| "#{d} · #{number / d}" }.join(', ')}.",
        "Всички делители са: #{divisors.join(', ')}.",
        "Броят им е #{divisors.size}."
      ],
      answer: Num.ans(divisors.size),
      check: "Разлагането е #{number} = #{Num.factor_string(number)}, което дава точно #{divisors.size} делителя.",
      watch: "1 и самото число също са делители — лесно се пропускат."
    )
  )
end

Authoring.family "divis.largest_proper", topic: "Делимост", area: "numbers",
                 rungs: [ 1030, 1120, 1210, 1300, 1390, 1490 ] do |c|
  number = c.int(c.by_level([ 12..40, 20..70, 30..120, 60..250, 100..500, 200..900 ]))
  divisors = Num.divisors(number)
  raise Authoring::Duplicate if divisors.size < 3

  largest = divisors[-2]
  smallest_prime = Num.factorize(number).keys.min

  c.q(
    text: "Кой е най-големият делител на #{number}, различен от самото число?",
    answer: Num.ans(largest),
    explanation: Explain.build(
      idea: "Най-големият собствен делител се получава, като разделим числото на най-малкия му прост делител.",
      steps: [
        "Най-малкият прост делител на #{number} е #{smallest_prime}.",
        "#{number} : #{smallest_prime} = #{largest}.",
        "По-голям делител няма, защото следващият кандидат би имал още по-малък съделител."
      ],
      answer: Num.ans(largest),
      check: "#{smallest_prime} · #{largest} = #{number}.",
      watch: "Търси се делител, различен от #{number} — самото число винаги се дели на себе си."
    )
  )
end

# ----------------------------------------------------------- Прости числа ---

Authoring.family "prime.identify", topic: "Прости числа", area: "numbers",
                 rungs: [ 950, 1040, 1130, 1220, 1310, 1410 ] do |c|
  band = c.by_level([ 2..30, 10..60, 20..100, 50..200, 100..400, 200..900 ])
  primes = Num.primes_upto(band.max).select { |p| band.include?(p) }
  raise Authoring::Duplicate if primes.size < 4

  prime = c.pick(primes)
  composites = (band.to_a - primes).select { |n| n > 3 }
  wrong = c.sample(composites, 3)
  raise Authoring::Duplicate if wrong.size < 3

  c.q(
    text: "Кое от числата #{([ prime ] + wrong).sort.join(', ')} е просто?",
    options: c.options(prime, wrong),
    answer: Num.ans(prime),
    explanation: Explain.build(
      idea: "Просто е числото с точно два делителя — 1 и самото себе си. Проверяваме до корена му.",
      steps: [
        "Достатъчно е да пробваме прости делители до #{Integer.sqrt(prime)}, защото по-голям делител би имал по-малък съделител.",
        "#{prime} не се дели на #{Num.primes_upto(Integer.sqrt(prime)).join(', ').then { |s| s.empty? ? '2' : s }} — значи е просто.",
        "Останалите се разлагат: #{wrong.map { |n| "#{n} = #{Num.factor_string(n)}" }.join('; ')}."
      ],
      answer: Num.ans(prime),
      check: "#{prime} има точно два делителя: 1 и #{prime}.",
      watch: "1 не е просто число, а всяко четно число над 2 е съставно."
    )
  )
end

Authoring.family "prime.next_after", topic: "Прости числа", area: "numbers",
                 rungs: [ 1000, 1090, 1180, 1270, 1360, 1460 ] do |c|
  from = c.int(c.by_level([ 5..30, 20..60, 40..120, 90..250, 200..500, 400..900 ]))
  nxt = (from + 1..(from + 60)).find { |n| Num.prime?(n) }
  skipped = ((from + 1)...nxt).to_a

  c.q(
    text: "Кое е най-малкото просто число, по-голямо от #{from}?",
    answer: Num.ans(nxt),
    explanation: Explain.build(
      idea: "Проверяваме числата едно по едно нагоре, докато срещнем такова без делители освен 1 и себе си.",
      steps: [
        skipped.empty? ? "#{nxt} е веднага след #{from}." :
          "Отпадат #{skipped.map { |n| "#{n} (= #{Num.factor_string(n)})" }.join(', ')}.",
        "#{nxt} не се дели на нито едно просто число до #{Integer.sqrt(nxt)} — значи е просто."
      ],
      answer: Num.ans(nxt),
      check: "#{nxt} : 2, : 3, : 5 ... всички дават остатък.",
      watch: "Простите числа се разреждат нагоре — разстоянието до следващото не е постоянно."
    )
  )
end

Authoring.family "prime.factorize", topic: "Прости числа", area: "numbers",
                 rungs: [ 1080, 1170, 1260, 1350, 1440, 1540 ] do |c|
  number = c.int(c.by_level([ 8..40, 20..80, 40..150, 80..300, 150..600, 300..1200 ]))
  raise Authoring::Duplicate if Num.prime?(number)

  factors = Num.factorize(number)
  correct = Num.factor_string(number)
  wrong = [
    Num.factor_string(number + 1),
    factors.keys.join(" · "),
    Num.divisors(number)[1..2]&.join(" · ")
  ].compact.reject { |value| value == correct }

  c.q(
    text: "Кое е разлагането на #{number} на прости множители?",
    options: c.options(correct, wrong),
    answer: correct,
    explanation: Explain.build(
      idea: "Делим последователно на най-малкото просто число, което пасва, докато остане 1.",
      steps: factors.flat_map { |base, power| [ base ] * power }.each_with_object([ number ]) { |f, acc| acc << acc.last / f }.each_cons(2).map { |from, to| "#{from} : #{Num.factorize(from).keys.min} = #{to}" },
      answer: "#{number} = #{correct}",
      check: "Произведението #{correct} = #{number}.",
      watch: "Всички множители трябва да са прости — #{factors.keys.join(' · ')} = #{factors.keys.reduce(:*)} обикновено не стига."
    )
  )
end

Authoring.family "prime.smallest_factor", topic: "Прости числа", area: "numbers",
                 rungs: [ 1120, 1210, 1300, 1390, 1480, 1580 ] do |c|
  candidates = (c.by_level([ 20..90, 40..150, 80..300, 150..500, 300..900, 500..2000 ])).
                 reject { |n| Num.prime?(n) }.
                 select { |n| Num.factorize(n).keys.min >= (c.level >= 3 ? 7 : 3) }
  raise Authoring::Duplicate if candidates.empty?

  number = c.pick(candidates)
  smallest = Num.factorize(number).keys.min

  c.q(
    text: "Кой е най-малкият прост делител на #{number}?",
    answer: Num.ans(smallest),
    explanation: Explain.build(
      idea: "Пробваме простите числа поред: 2, 3, 5, 7, 11, ... докато делението стане точно.",
      steps: [
        "#{number} е #{number.even? ? 'четно' : 'нечетно'}#{number.even? ? '' : ', значи 2 отпада'}.",
        "Сборът на цифрите е #{number.to_s.chars.map(&:to_i).sum}#{(number.to_s.chars.map(&:to_i).sum % 3).zero? ? ', което се дели на 3' : ', което не се дели на 3'}.",
        "Първото просто число, което дели #{number}, е #{smallest}: #{number} : #{smallest} = #{number / smallest}."
      ],
      answer: Num.ans(smallest),
      check: "#{smallest} · #{number / smallest} = #{number}.",
      watch: "Търси се прост делител — 1 не се брои, а най-малкият делител над 1 винаги е прост."
    )
  )
end

Authoring.family "prime.count_between", topic: "Прости числа", area: "numbers",
                 rungs: [ 1060, 1150, 1240, 1330, 1420, 1520 ] do |c|
  from = c.int(c.by_level([ 1..20, 10..40, 20..70, 40..120, 80..200, 150..400 ]))
  width = c.int(c.by_level([ 10..15, 12..20, 15..25, 20..30, 25..40, 30..50 ]))
  to = from + width
  primes = (from..to).select { |n| Num.prime?(n) }
  raise Authoring::Duplicate if primes.empty?

  c.q(
    text: "Колко прости числа има между #{from} и #{to} (включително двете)?",
    answer: Num.ans(primes.size),
    explanation: Explain.build(
      idea: "Отсяваме: махаме четните над 2, кратните на 3, на 5 и на 7, и проверяваме какво остава.",
      steps: [
        "Кандидатите са #{to - from + 1} на брой.",
        "Простите сред тях са #{primes.join(', ')}.",
        "Броят им е #{primes.size}."
      ],
      answer: Num.ans(primes.size),
      check: "Всяко от изброените се дели само на 1 и на себе си.",
      watch: "Простите числа не се редуват по правило — единственият сигурен начин е проверката."
    )
  )
end

# --------------------------------------------------------------- НОД и НОК ---

Authoring.family "gcd.pair", topic: "НОД и НОК", area: "numbers",
                 rungs: [ 1020, 1110, 1200, 1290, 1380, 1480 ] do |c|
  spec = c.by_level([ [ 2..6, 2..6 ], [ 2..9, 2..9 ], [ 3..12, 2..12 ],
                      [ 4..15, 3..15 ], [ 6..24, 4..20 ], [ 8..40, 5..30 ] ])
  common = c.int(spec[0])
  first = c.int(spec[1])
  second = c.int(spec[1])
  raise Authoring::Duplicate if Num.gcd(first, second) != 1 || first == second

  a = common * first
  b = common * second
  answer = Num.gcd(a, b)

  c.q(
    text: "Намери най-големия общ делител на #{a} и #{b}.",
    answer: Num.ans(answer),
    explanation: Explain.build(
      idea: "Разлагаме двете числа на прости множители и вземаме общите с най-малките степени.",
      steps: [
        "#{a} = #{Num.factor_string(a)}.",
        "#{b} = #{Num.factor_string(b)}.",
        "Общите множители дават НОД(#{a}, #{b}) = #{answer}."
      ],
      answer: "НОД = #{answer}",
      check: "#{a} : #{answer} = #{a / answer} и #{b} : #{answer} = #{b / answer}, а тези две числа вече нямат общ делител.",
      watch: "НОД е делител и на двете числа, затова не може да е по-голям от по-малкото (#{[ a, b ].min})."
    )
  )
end

Authoring.family "lcm.pair", topic: "НОД и НОК", area: "numbers",
                 rungs: [ 1060, 1150, 1240, 1330, 1420, 1520 ] do |c|
  spec = c.by_level([ 2..8, 3..12, 4..16, 5..24, 6..36, 8..60 ])
  a = c.int(spec)
  b = c.int(spec)
  raise Authoring::Duplicate if a == b

  answer = Num.lcm(a, b)
  gcd = Num.gcd(a, b)

  c.q(
    text: "Намери най-малкото общо кратно на #{a} и #{b}.",
    answer: Num.ans(answer),
    explanation: Explain.build(
      idea: "НОК се получава от произведението, разделено на НОД — общата част не бива да се брои два пъти.",
      steps: [
        "НОД(#{a}, #{b}) = #{gcd}.",
        "#{a} · #{b} = #{a * b}.",
        "#{a * b} : #{gcd} = #{answer}."
      ],
      answer: "НОК = #{answer}",
      check: "#{answer} : #{a} = #{answer / a} и #{answer} : #{b} = #{answer / b} — дели се и на двете.",
      watch: "НОК не е винаги произведението: то е #{a * b}, а най-малкото общо кратно е #{answer}."
    )
  )
end

Authoring.family "gcd.story_pieces", topic: "НОД и НОК", area: "numbers",
                 rungs: [ 1150, 1240, 1330, 1420, 1510, 1610 ] do |c|
  spec = c.by_level([ [ 2..6, 2..5 ], [ 3..8, 2..7 ], [ 4..12, 3..8 ],
                      [ 5..15, 3..10 ], [ 6..24, 4..12 ], [ 8..36, 5..15 ] ])
  piece = c.int(spec[0])
  first = c.int(spec[1])
  second = c.int(spec[1])
  raise Authoring::Duplicate if Num.gcd(first, second) != 1 || first == second

  a = piece * first
  b = piece * second
  answer = Num.gcd(a, b)

  c.q(
    text: "Две ленти са дълги #{a} см и #{b} см. Разрязват се на еднакви парчета с най-голяма възможна цяла дължина, без остатък. " \
          "Колко сантиметра е дълго едно парче?",
    answer: Num.ans(answer),
    explanation: Explain.build(
      idea: "Дължината на парчето трябва да дели и двете ленти — търси се най-големият общ делител.",
      steps: [
        "#{a} = #{Num.factor_string(a)}, #{b} = #{Num.factor_string(b)}.",
        "НОД(#{a}, #{b}) = #{answer} см.",
        "Тогава парчетата са #{a / answer} от първата лента и #{b / answer} от втората, общо #{(a / answer) + (b / answer)}."
      ],
      answer: "#{answer} см",
      check: "#{answer} · #{a / answer} = #{a} и #{answer} · #{b / answer} = #{b} — нищо не остава.",
      watch: "По-голямо парче не става: то вече няма да дели едната лента точно."
    )
  )
end

Authoring.family "lcm.story_buses", topic: "НОД и НОК", area: "numbers",
                 rungs: [ 1180, 1270, 1360, 1450, 1540, 1640 ] do |c|
  spec = c.by_level([ 2..8, 3..12, 4..15, 5..20, 6..30, 8..45 ])
  a = c.int(spec)
  b = c.int(spec)
  raise Authoring::Duplicate if a == b

  answer = Num.lcm(a, b)
  hour = c.int(6..9)

  c.q(
    text: "Един автобус тръгва на всеки #{a} минути, друг — на всеки #{b} минути. " \
          "В #{hour}:00 ч тръгват заедно. След колко минути ще тръгнат заедно отново?",
    answer: Num.ans(answer),
    explanation: Explain.build(
      idea: "Заедно тръгват в моменти, кратни едновременно на #{a} и на #{b} — това е НОК.",
      steps: [
        "Кратните на #{a}: #{(1..4).map { |i| i * a }.join(', ')}, ...",
        "Кратните на #{b}: #{(1..4).map { |i| i * b }.join(', ')}, ...",
        "Първото общо е #{answer} минути (НОД(#{a}, #{b}) = #{Num.gcd(a, b)}, затова #{a} · #{b} : #{Num.gcd(a, b)} = #{answer})."
      ],
      answer: "след #{answer} минути",
      check: "#{answer} : #{a} = #{answer / a} курса на първия и #{answer} : #{b} = #{answer / b} курса на втория.",
      watch: "Сборът #{a} + #{b} = #{a + b} не значи нищо тук — двата автобуса не се редуват."
    )
  )
end

Authoring.family "gcd.product_rule", topic: "НОД и НОК", area: "numbers",
                 rungs: [ 1280, 1370, 1460, 1550, 1640, 1740 ] do |c|
  spec = c.by_level([ 2..8, 3..12, 4..18, 6..24, 8..36, 10..60 ])
  a = c.int(spec)
  b = c.int(spec)
  raise Authoring::Duplicate if a == b

  gcd = Num.gcd(a, b)
  lcm = Num.lcm(a, b)
  ask_lcm = c.coin

  c.q(
    text: ask_lcm ? "За две числа е известно, че произведението им е #{a * b}, а най-големият им общ делител е #{gcd}. Колко е най-малкото им общо кратно?" :
                    "За две числа е известно, че произведението им е #{a * b}, а най-малкото им общо кратно е #{lcm}. Колко е най-големият им общ делител?",
    answer: Num.ans(ask_lcm ? lcm : gcd),
    explanation: Explain.build(
      idea: "За всеки две числа е в сила НОД · НОК = произведението на числата.",
      steps: [
        "НОД · НОК = #{a * b}.",
        ask_lcm ? "НОК = #{a * b} : #{gcd} = #{lcm}." : "НОД = #{a * b} : #{lcm} = #{gcd}."
      ],
      answer: Num.ans(ask_lcm ? lcm : gcd),
      check: "#{gcd} · #{lcm} = #{gcd * lcm} = #{a * b} — правилото е изпълнено.",
      watch: "Правилото важи за две числа; за три вече не е вярно."
    )
  )
end

# ---------------------------------------------------------------- Остатъци ---

Authoring.family "rem.basic", topic: "Остатъци", area: "numbers",
                 rungs: [ 1080, 1170, 1260, 1350, 1440, 1540 ] do |c|
  divisor = c.int(c.by_level([ 3..6, 3..8, 4..9, 5..12, 6..20, 7..40 ]))
  quotient = c.int(c.by_level([ 2..9, 4..15, 6..25, 10..40, 15..80, 20..200 ]))
  rest = c.int(1...divisor)
  dividend = (divisor * quotient) + rest

  c.q(
    text: "Какъв е остатъкът при деление на #{dividend} на #{divisor}?",
    answer: Num.ans(rest),
    explanation: Explain.build(
      idea: "Търсим най-голямото кратно на #{divisor}, което не надминава #{dividend}, и гледаме колко остава.",
      steps: [
        "#{divisor} · #{quotient} = #{divisor * quotient} ≤ #{dividend}.",
        "#{dividend} − #{divisor * quotient} = #{rest}.",
        "Значи #{dividend} = #{divisor} · #{quotient} + #{rest}."
      ],
      answer: Num.ans(rest),
      check: "Остатъкът е по-малък от делителя: #{rest} < #{divisor}.",
      watch: "Ако получите остатък, по-голям от #{divisor - 1}, значи частното е взето твърде малко."
    )
  )
end

Authoring.family "rem.weekday", topic: "Остатъци", area: "numbers",
                 rungs: [ 1150, 1240, 1330, 1420, 1510, 1610 ] do |c|
  days = %w[понеделник вторник сряда четвъртък петък събота неделя]
  today = c.int(0..6)
  ahead = c.int(c.by_level([ 8..30, 20..60, 40..120, 100..300, 200..800, 500..3000 ]))
  index = (today + ahead) % 7

  c.q(
    text: "Днес е #{days[today]}. Кой ден от седмицата ще бъде след #{ahead} дни?",
    options: c.options(days[index], c.sample(days - [ days[index] ], 3)),
    answer: days[index],
    explanation: Explain.build(
      idea: "Дните се повтарят на всеки 7 — значи ни интересува само остатъкът от делението на 7.",
      steps: [
        "#{ahead} : 7 = #{ahead / 7} и остатък #{ahead % 7}.",
        "Пълните седмици не променят деня; остават #{ahead % 7} дни.",
        "#{ahead % 7} дни след #{days[today]} е #{days[index]}."
      ],
      answer: days[index],
      check: "След #{(ahead / 7) * 7} дни отново е #{days[today]}, а после броим #{ahead % 7} напред.",
      watch: "Не се брои целият брой дни напред — само остатъкът след пълните седмици."
    )
  )
end

Authoring.family "rem.last_digit", topic: "Остатъци", area: "numbers",
                 rungs: [ 1300, 1390, 1480, 1570, 1660, 1760 ] do |c|
  base = c.pick([ 2, 3, 4, 7, 8, 9, 12, 13 ])
  exponent = c.int(c.by_level([ 3..8, 5..15, 8..30, 12..60, 20..150, 30..500 ]))
  cycle = []
  value = 1
  4.times do
    value = (value * base) % 10
    cycle << value
  end
  cycle = cycle.uniq
  digit = cycle[(exponent - 1) % cycle.size]

  c.q(
    text: "Коя е последната цифра на числото #{Num.power(base, exponent)}?",
    answer: Num.ans(digit),
    explanation: Explain.build(
      idea: "Последните цифри на степените се повтарят периодично, затова гледаме къде попада показателят в периода.",
      steps: [
        "Последните цифри на #{base}#{Num.sup(1)}, #{base}#{Num.sup(2)}, #{base}#{Num.sup(3)}, ... са #{cycle.join(', ')} и после се повтарят.",
        "Периодът е #{cycle.size}, а #{exponent} : #{cycle.size} дава остатък #{exponent % cycle.size}#{(exponent % cycle.size).zero? ? " (значи последното място в периода)" : ''}.",
        "Значи последната цифра е #{digit}."
      ],
      answer: Num.ans(digit),
      check: "#{base}#{Num.sup(cycle.size)} завършва на #{cycle.last} — оттам периодът тръгва отначало.",
      watch: "Не се смята цялата степен — тя има десетки цифри; работи се само с последната."
    )
  )
end

Authoring.family "rem.find_number", topic: "Остатъци", area: "numbers",
                 rungs: [ 1220, 1310, 1400, 1490, 1580, 1680 ] do |c|
  divisor = c.int(c.by_level([ 3..6, 4..8, 5..10, 6..14, 7..20, 9..30 ]))
  rest = c.int(1...divisor)
  floor = c.int(c.by_level([ 10..30, 20..60, 40..120, 80..250, 150..600, 300..1500 ]))
  number = ((floor / divisor) + 1) * divisor + rest
  number -= divisor if number - divisor > floor

  c.q(
    text: "Кое е най-малкото число, по-голямо от #{floor}, което при деление на #{divisor} дава остатък #{rest}?",
    answer: Num.ans(number),
    explanation: Explain.build(
      idea: "Числата с остатък #{rest} при деление на #{divisor} са #{rest}, #{rest + divisor}, #{rest + (2 * divisor)}, ... — през #{divisor}.",
      steps: [
        "#{floor} : #{divisor} = #{floor / divisor} и остатък #{floor % divisor}.",
        "Първото кратно на #{divisor} над #{floor} е #{((floor / divisor) + 1) * divisor}, а търсеното число е с #{rest} повече или #{divisor} по-малко.",
        "Най-малкото подходящо е #{number}: #{number} : #{divisor} = #{number / divisor} и остатък #{number % divisor}."
      ],
      answer: Num.ans(number),
      check: "#{number} > #{floor} и #{number} − #{divisor} = #{number - divisor} вече не е по-голямо от #{floor}.",
      watch: "Остатъкът е #{rest}, не частното — не се търси кратно на #{divisor}."
    )
  )
end

Authoring.family "rem.adjust_to_divide", topic: "Остатъци", area: "numbers",
                 rungs: [ 1180, 1270, 1360, 1450, 1540, 1640 ] do |c|
  divisor = c.int(c.by_level([ 3..6, 4..9, 5..12, 6..16, 8..24, 9..40 ]))
  number = c.int(c.by_level([ 20..60, 40..120, 80..250, 150..500, 300..1200, 600..3000 ]))
  rest = number % divisor
  raise Authoring::Duplicate if rest.zero?

  subtract = c.coin
  answer = subtract ? rest : divisor - rest

  c.q(
    text: subtract ? "Колко най-малко трябва да се извади от #{number}, за да се дели на #{divisor}?" :
                     "Колко най-малко трябва да се добави към #{number}, за да се дели на #{divisor}?",
    answer: Num.ans(answer),
    explanation: Explain.build(
      idea: "Гледаме остатъка: изваждаме точно него, или добавяме толкова, колкото липсва до следващото кратно.",
      steps: [
        "#{number} : #{divisor} = #{number / divisor} и остатък #{rest}.",
        subtract ? "Изваждаме остатъка: #{number} − #{rest} = #{number - rest}." :
                   "До следващото кратно #{(number / divisor + 1) * divisor} липсват #{divisor - rest}."
      ],
      answer: Num.ans(answer),
      check: subtract ? "#{number - rest} : #{divisor} = #{(number - rest) / divisor}, точно." :
                        "#{number + (divisor - rest)} : #{divisor} = #{(number + (divisor - rest)) / divisor}, точно.",
      watch: "Добавяне и изваждане дават различни числа: тук сборът им е #{divisor}."
    )
  )
end
