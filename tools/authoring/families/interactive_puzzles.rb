# Състезателни задачи, направени интерактивни.
#
# The types here are the ones competition papers actually use — magic squares,
# cryptarithms, Nim, tilings, invariants, pigeonhole, lattice geometry — and each
# is asked through a widget, so the student builds the answer instead of
# recognising it among four options.
#
# Ratings run from 1550 (a strong 6th-grader) to 2800 (olympiad selection). The
# rungs are 150 points apart, so a student who stalls meets the same type of
# puzzle with smaller numbers rather than a different puzzle.

COMP = [ 1550, 1700, 1850, 2000, 2150, 2300, 2450 ].freeze
HARD = [ 1750, 1900, 2050, 2200, 2350, 2500, 2650 ].freeze
ELITE = [ 1900, 2050, 2200, 2350, 2500, 2650, 2800 ].freeze

# ------------------------------------------------------------ Магически квадрати ---

Authoring.family "puzzle.magic_square", topic: "Логически задачи", area: "interactive_puzzles", variants: 11,
                 rungs: COMP do |c|
  # A 3x3 magic square is fixed by its centre and two more numbers: build it
  # from the standard pattern and scale it.
  centre = c.int(c.by_level([ 5..9, 5..15, 6..25, 8..40, 10..80, 12..150, 15..300 ]))
  step = c.int(c.by_level([ 1..2, 1..3, 2..5, 2..8, 3..12, 4..20, 5..40 ]))
  pattern = [ [ 8, 1, 6 ], [ 3, 5, 7 ], [ 4, 9, 2 ] ]
  answers = pattern.map { |row| row.map { |value| centre + ((value - 5) * step) } }
  raise Authoring::Duplicate if answers.flatten.min <= 0

  blanks = c.sample((0..8).to_a, c.by_level([ 3, 4, 4, 5, 5, 6, 6 ]))
  rows = answers.each_with_index.map { |row, r| row.each_with_index.map { |value, cc| blanks.include?((r * 3) + cc) ? nil : value } }
  magic = answers[0].sum

  c.q(
    text: "Попълни магическия квадрат: всеки ред, всяка колона и всеки от двата диагонала трябва да дават сбор #{magic}.",
    widget: WidgetKit.grid_fill(rows: rows, answers: answers),
    hints: [
      "В магически квадрат сборът по всеки ред, всяка колона и двата диагонала е един и същ.",
      "Затова започни от реда или колоната, в която липсва само едно число.",
      "Централното число е точно една трета от сбора на реда — това е ключът, когато никъде не липсва само едно."
    ],
    explanation: Explain.build(
      idea: "Магическата константа е 3 пъти централното число, а срещуположните на центъра клетки се допълват до 2 пъти центъра.",
      steps: [
        "Центърът е #{answers[1][1]}, значи сборът е 3 · #{answers[1][1]} = #{magic}.",
        "Всяка двойка клетки, симетрични спрямо центъра, дава #{2 * answers[1][1]}.",
        "Оттам всяка празна клетка се получава от реда, колоната или диагонала, в който има две известни числа."
      ],
      answer: answers.map { |row| row.join(" ") }.join(" / "),
      check: "Сборът на всички девет числа е 9 · #{answers[1][1]} = #{9 * answers[1][1]} = 3 · #{magic}.",
      watch: "Започва се от реда с най-много известни числа, не от произволна клетка."
    )
  )
end

Authoring.family "puzzle.latin_square", topic: "Логически задачи", area: "interactive_puzzles", variants: 6,
                 rungs: COMP do |c|
  size = c.by_level([ 3, 3, 4, 4, 4, 5, 5 ])
  shift = c.int(0...size)
  answers = (0...size).map { |r| (0...size).map { |cc| ((r + cc + shift) % size) + 1 } }
  blanks = c.sample((1...(size * size)).to_a, c.by_level([ 3, 4, 5, 6, 7, 8, 10 ]))
  rows = answers.each_with_index.map { |row, r| row.each_with_index.map { |value, cc| blanks.include?((r * size) + cc) ? nil : value } }
  raise Authoring::Duplicate if rows.flatten.compact.empty?

  c.q(
    text: "Попълни квадрата #{size} на #{size} така, че всяко от числата от 1 до #{size} да се среща " \
          "точно по веднъж във всеки ред и във всяка колона. Дадени са #{(size * size) - blanks.size} числа, " \
          "а горният ляв ъгъл е #{answers[0][0]}.",
    widget: WidgetKit.grid_fill(rows: rows, answers: answers),
    hints: [
      "Всяко число се среща точно по веднъж във всеки ред и във всяка колона.",
      "Затова в ред с #{size - 1} известни числа липсва точно това, което още не се среща в него.",
      "Всяка клетка се проверява и по реда, и по колоната — само едното не стига."
    ],
    explanation: Explain.build(
      idea: "Латински квадрат: всеки ред и всяка колона съдържат всички числа по веднъж — липсващото се намира по изключване.",
      steps: [
        "В ред с #{size - 1} известни числа липсва точно едно — това, което още не се среща.",
        "Същото важи и за колоните; двете проверки заедно определят всяка клетка.",
        "Готовият квадрат е #{answers.map { |row| row.join('') }.join(' / ')}."
      ],
      answer: answers.map { |row| row.join(" ") }.join(" / "),
      check: "Всеки ред и всяка колона имат сбор #{(1..size).sum}.",
      watch: "Числото се проверява едновременно по ред и по колона — само едното не стига."
    )
  )
end

Authoring.family "puzzle.cage_sum", topic: "Логически задачи", area: "interactive_puzzles", variants: 11,
                 rungs: HARD do |c|
  size = 3
  answers = (0...size).map { |r| (0...size).map { |cc| ((r + cc) % size) + 1 } }
  scale = c.int(c.by_level([ 1..2, 1..3, 2..5, 2..8, 3..12, 4..20, 5..40 ]))
  answers = answers.map { |row| row.map { |value| value * scale } }
  row_sums = answers.map(&:sum)
  blanks = c.sample((0...9).to_a, c.by_level([ 3, 4, 4, 5, 5, 6, 6 ]))
  rows = answers.each_with_index.map { |row, r| row.each_with_index.map { |value, cc| blanks.include?((r * 3) + cc) ? nil : value } }

  c.q(
    text: "Всеки ред на таблицата има сбор #{row_sums.first}, а числата във всеки ред са #{answers.first.sort.join(', ')} " \
          "в някакъв ред. Попълни празните клетки, като всяка колона също съдържа трите различни числа.",
    widget: WidgetKit.grid_fill(rows: rows, answers: answers, row_headers: row_sums.map(&:to_s)),
    hints: [
      "Числата във всеки ред са едни и същи, само наредени различно.",
      "Затова в ред или колона, в която липсва само едно число, то е сборът минус другите две."
    ],
    explanation: Explain.build(
      idea: "Всеки ред и всяка колона са пермутация на #{answers.first.sort.join(', ')} — сборът потвърждава, а изключването определя.",
      steps: [
        "Сборът на реда е #{row_sums.first}, затова липсващото в ред с две известни числа е #{row_sums.first} минус тях.",
        "Ако в реда липсват две числа, колоната казва кое къде отива.",
        "Готовата таблица е #{answers.map { |row| row.join(' ') }.join(' / ')}."
      ],
      answer: answers.map { |row| row.join(" ") }.join(" / "),
      check: "Всяка колона също дава сбор #{row_sums.first}.",
      watch: "Сборът сам по себе си не определя реда — нужна е и проверката по колони."
    )
  )
end

Authoring.family "puzzle.addition_pyramid", topic: "Логически задачи", area: "interactive_puzzles", variants: 11,
                 rungs: COMP do |c|
  base = Array.new(4) { c.int(c.by_level([ 1..9, 1..15, 2..25, 3..50, 5..100, 8..250, 10..600 ])) }
  level2 = base.each_cons(2).map(&:sum)
  level3 = level2.each_cons(2).map(&:sum)
  top = level3.sum
  answers = [ base, level2 + [ nil ], level3 + [ nil, nil ], [ top, nil, nil, nil ] ]
  visible = answers.map(&:dup)
  hidden = c.sample([ [ 0, 0 ], [ 0, 1 ], [ 0, 2 ], [ 0, 3 ], [ 1, 0 ], [ 1, 1 ], [ 1, 2 ], [ 2, 0 ], [ 2, 1 ] ],
                    c.by_level([ 3, 3, 4, 4, 5, 5, 6 ]))
  hidden.each { |r, cc| visible[r][cc] = nil }
  visible[3][0] = top

  rows = visible.map { |row| row.map { |value| value.nil? ? nil : value } }
  full = [ base, level2 + [ "" ], level3 + [ "", "" ], [ top, "", "", "" ] ]
  # Cells that were never part of the pyramid must not be asked for.
  rows = rows.each_with_index.map { |row, r| row.each_with_index.map { |value, cc| cc >= 4 - r ? "" : value } }
  raise Authoring::Duplicate if rows.flatten.count(nil) < 3

  c.q(
    text: "В сборната пирамида всяко число е сборът на двете под него, а на върха стои #{top}. Попълни празните клетки.",
    widget: WidgetKit.grid_fill(rows: rows, answers: full),
    hints: [
      "Всяко число е сборът на двете под него — значи надолу се работи с изваждане.",
      "Тръгни оттам, където две съседни числа вече са известни.",
      "Средните числа на долния ред влизат по три пъти във върха #{top}, крайните — по веднъж."
    ],
    explanation: Explain.build(
      idea: "Пирамидата се решава и нагоре (със събиране), и надолу (с изваждане) — тръгва се оттам, където има две известни съседни числа.",
      steps: [
        "Долен ред: #{base.join(', ')}.",
        "Втори ред: #{level2.join(', ')} (всяко е сбор на двете под него).",
        "Трети ред: #{level3.join(', ')}, а върхът е #{level3.first} + #{level3.last} = #{top}."
      ],
      answer: "долен ред #{base.join(', ')}",
      check: "Върхът може да се получи и направо: #{base[0]} + 3 · #{base[1]} + 3 · #{base[2]} + #{base[3]} = #{top}.",
      watch: "Средните числа на долния ред влизат по три пъти във върха — затова той расте бързо."
    )
  )
end

# ------------------------------------------------------------------ Цифрови ребуси ---

Authoring.family "puzzle.cryptarithm_reverse", topic: "Числа и редици", area: "interactive_puzzles", variants: 2,
                 rungs: COMP do |c|
  a = c.int(1..9)
  b = c.int(1..9)
  raise Authoring::Duplicate if a == b

  sum = (11 * (a + b))
  raise Authoring::Duplicate if sum > 187 || (a + b) > 17

  c.q(
    text: "Двуцифреното число AB и обърнатото му BA дават сбор #{sum}. " \
          "Попълни по-малката и по-голямата цифра (A и B са различни цифри).",
    widget: WidgetKit.blanks([ [ "small", "по-малката цифра", [ a, b ].min ], [ "big", "по-голямата цифра", [ a, b ].max ] ]),
    hints: [
      "AB значи 10A + B, а BA значи 10B + A.",
      "Сборът им е 11 · (A + B), затова раздели #{sum} на 11.",
      "Остава да намериш двете различни цифри с този сбор."
    ],
    explanation: Explain.build(
      idea: "AB = 10A + B и BA = 10B + A, значи сборът им е 11(A + B) — винаги кратен на 11.",
      steps: [
        "#{sum} : 11 = #{a + b}, значи A + B = #{a + b}.",
        "Цифрите са различни и всяка е между 1 и 9, което оставя двойката #{[ a, b ].min} и #{[ a, b ].max}#{(a + b).even? ? " (двойката #{(a + b) / 2} и #{(a + b) / 2} отпада, защото цифрите са различни)" : ''}."
      ],
      answer: "#{[ a, b ].min} и #{[ a, b ].max}",
      check: "#{10 * a + b} + #{10 * b + a} = #{sum}.",
      watch: "Сборът на две обърнати двуцифрени числа винаги се дели на 11 — това е ключът, не пробването."
    )
  )
end

Authoring.family "puzzle.digit_difference", topic: "Числа и редици", area: "interactive_puzzles", variants: 2,
                 rungs: [ 1750, 1900, 2050, 2200 ] do |c|
  difference = c.int(1..8) * 9
  a = c.int((difference / 9 + 1)..9)
  b = a - (difference / 9)
  raise Authoring::Duplicate if b < 1

  c.q(
    text: "Двуцифрено число е с #{difference} по-голямо от числото, записано с неговите цифри в обратен ред. " \
          "Попълни цифрата на десетиците и цифрата на единиците на по-голямото число (единиците са възможно най-малки).",
    widget: WidgetKit.blanks([ [ "tens", "десетици", a ], [ "ones", "единици", b ] ]),
    hints: [
      "(10A + B) − (10B + A) = 9 · (A − B), затова разликата винаги се дели на 9.",
      "Раздели #{difference} на 9 — това е разликата между двете цифри.",
      "Единиците трябва да са възможно най-малки, а и двете цифри са поне 1."
    ],
    explanation: Explain.build(
      idea: "(10A + B) − (10B + A) = 9(A − B), затова разликата винаги е кратна на 9.",
      steps: [
        "#{difference} : 9 = #{difference / 9}, значи A − B = #{difference / 9}.",
        "Най-малката възможна цифра за единиците е #{b}, откъдето десетиците са #{a}."
      ],
      answer: "#{a} и #{b}",
      check: "#{10 * a + b} − #{10 * b + a} = #{difference}.",
      watch: "Разлика, която не се дели на 9, е невъзможна при разместване на две цифри."
    )
  )
end

Authoring.family "puzzle.digits_sum_product", topic: "Числа и редици", area: "interactive_puzzles", variants: 6,
                 rungs: HARD do |c|
  a = c.int(1..9)
  b = c.int(1..9)
  raise Authoring::Duplicate if a == b

  total = a + b
  product = a * b
  # Only if the pair is the unique one with this sum and product.
  matches = (1..9).to_a.product((1..9).to_a).select { |x, y| x + y == total && x * y == product }
  raise Authoring::Duplicate if matches.map { |pair| pair.sort }.uniq.size > 1

  c.q(
    text: "Двуцифрено число има сбор на цифрите #{total} и произведение на цифрите #{product}. " \
          "Попълни по-малката и по-голямата цифра.",
    widget: WidgetKit.blanks([ [ "small", "по-малка", [ a, b ].min ], [ "big", "по-голяма", [ a, b ].max ] ]),
    hints: [
      "Изброй двойките цифри със сбор #{total}.",
      "После остави само тази двойка, чието произведение е #{product}."
    ],
    explanation: Explain.build(
      idea: "Търсим две цифри с даден сбор и дадено произведение — това е задача, еквивалентна на квадратно уравнение.",
      steps: [
        "Двойките със сбор #{total}: #{(1..[ total - 1, 9 ].min).select { |x| total - x <= 9 && total - x >= 1 }.map { |x| "#{x} и #{total - x}" }.uniq.join(', ')}.",
        "От тях произведение #{product} дава само #{[ a, b ].min} и #{[ a, b ].max}."
      ],
      answer: "#{[ a, b ].min} и #{[ a, b ].max}",
      check: "#{[ a, b ].min} + #{[ a, b ].max} = #{total} и #{[ a, b ].min} · #{[ a, b ].max} = #{product}.",
      watch: "Цифрите са между 0 и 9 — двойки извън този обхват отпадат, дори да пасват аритметично."
    )
  )
end

Authoring.family "puzzle.diophantine_pair", topic: "Уравнения", area: "interactive_puzzles", variants: 11,
                 rungs: HARD do |c|
  a = c.pick([ 3, 4, 5, 7 ])
  b = c.pick([ 5, 7, 8, 11 ])
  raise Authoring::Duplicate if a == b || Num.gcd(a, b) != 1

  x = c.int(1..c.by_level([ 4, 5, 6, 8, 10, 14, 20 ]))
  y = c.int(1..c.by_level([ 4, 5, 6, 8, 10, 14, 20 ]))
  total = (a * x) + (b * y)
  solutions = (1..(total / a)).filter_map { |xx| [ xx, (total - (a * xx)) / b ] if ((total - (a * xx)) % b).zero? && total - (a * xx) > 0 }
  raise Authoring::Duplicate if solutions.size != 1

  c.q(
    text: "Билети за #{a} лв. и за #{b} лв. струват общо #{total} лв. " \
          "Попълни колко са билетите по #{a} лв. и колко по #{b} лв. (и от двата вида има поне един).",
    widget: WidgetKit.blanks([ [ "x", "по #{a} лв.", x ], [ "y", "по #{b} лв.", y ] ]),
    hints: [
      "Търсим цели положителни x и y с #{a}x + #{b}y = #{total}.",
      "Пробвай y = 1, 2, 3, ... и гледай кога #{total} − #{b}y се дели на #{a}."
    ],
    explanation: Explain.build(
      idea: "Уравнението #{a}x + #{b}y = #{total} се решава в цели положителни числа — пробваме по остатъци.",
      steps: [
        "#{a}x = #{total} − #{b}y, значи #{total} − #{b}y трябва да се дели на #{a}.",
        "Проверяваме y = 1, 2, 3, ... — първата стойност, която върши работа, е y = #{y}.",
        "Тогава x = (#{total} − #{b} · #{y}) : #{a} = #{x}."
      ],
      answer: "#{x} и #{y}",
      check: "#{a} · #{x} + #{b} · #{y} = #{total}.",
      watch: "Решението в цели числа е единствено тук — дробни отговори не се броят."
    )
  )
end

Authoring.family "puzzle.consecutive_sum", topic: "Числа и редици", area: "interactive_puzzles", variants: 11,
                 rungs: HARD do |c|
  count = c.int(c.by_level([ 3..4, 3..5, 3..6, 4..8, 4..10, 5..14, 6..20 ]))
  first = c.int(c.by_level([ 1..10, 2..20, 3..40, 5..80, 8..150, 10..400, 15..900 ]))
  total = (count * first) + (count * (count - 1) / 2)
  # Only when this is the unique way with more than two terms.
  ways = (2..40).count do |k|
    numerator = total - (k * (k - 1) / 2)
    numerator.positive? && (numerator % k).zero?
  end
  raise Authoring::Duplicate if ways > 3

  c.q(
    text: "Числото #{total} е записано като сбор на #{count} последователни цели положителни числа. " \
          "Попълни най-малкото и най-голямото от тях.",
    widget: WidgetKit.blanks([ [ "min", "най-малко", first ], [ "max", "най-голямо", first + count - 1 ] ]),
    hints: [
      "Ако най-малкото число е n, сборът е #{count} · n + #{count * (count - 1) / 2}.",
      "Извади добавката #{count * (count - 1) / 2} от #{total} и раздели на #{count}."
    ],
    explanation: Explain.build(
      idea: "Сборът на #{count} последователни числа е #{count} пъти средното им; при нечетен брой средното е самото средно число.",
      steps: [
        "Ако най-малкото е n, сборът е #{count}n + #{count * (count - 1) / 2} = #{total}.",
        "#{count}n = #{total} − #{count * (count - 1) / 2} = #{count * first}.",
        "n = #{first}, значи числата са от #{first} до #{first + count - 1}."
      ],
      answer: "от #{first} до #{first + count - 1}",
      check: "(#{first} + #{first + count - 1}) · #{count} : 2 = #{total}.",
      watch: "Броят на числата умножава и средното, и добавката #{count * (count - 1) / 2} — тя не бива да се забравя."
    )
  )
end

# ------------------------------------------------------ Остатъци и периодичност ---

Authoring.family "puzzle.last_digit_cycle", topic: "Остатъци", area: "interactive_puzzles", variants: 11,
                 rungs: COMP do |c|
  base = c.pick([ 2, 3, 4, 7, 8, 9, 12, 13, 17, 23 ])
  exponent = c.int(c.by_level([ 5..20, 8..40, 10..80, 15..150, 20..400, 30..900, 50..2000 ]))
  cycle = []
  value = 1
  4.times do
    value = (value * base) % 10
    cycle << value
  end
  cycle = cycle.uniq
  digit = cycle[(exponent - 1) % cycle.size]

  c.q(
    text: "Попълни дължината на периода на последната цифра на степените на #{base} и последната цифра на #{Num.power(base, exponent)}.",
    widget: WidgetKit.blanks([ [ "period", "период", cycle.size ], [ "digit", "последна цифра", digit ] ]),
    hints: [
      "Последната цифра на степените на #{base} се повтаря циклично.",
      "Изпиши последните цифри на първите няколко степени и виж след колко се повтарят.",
      "После раздели показателя на дължината на периода и гледай остатъка."
    ],
    explanation: Explain.build(
      idea: "Последните цифри на степените се повтарят циклично; интересува ни само остатъкът на показателя спрямо дължината на цикъла.",
      steps: [
        "Последни цифри на #{base}#{Num.sup(1)}, #{base}#{Num.sup(2)}, ...: #{cycle.join(', ')} — период #{cycle.size}.",
        "#{exponent} : #{cycle.size} дава остатък #{exponent % cycle.size}#{(exponent % cycle.size).zero? ? " (значи последният член на периода)" : ''}.",
        "Последната цифра е #{digit}."
      ],
      answer: "период #{cycle.size}, цифра #{digit}",
      check: "#{base}#{Num.sup(cycle.size)} завършва на #{cycle.last}, откъдето цикълът тръгва отначало.",
      watch: "Цялата степен не се смята — тя има стотици цифри."
    )
  )
end

Authoring.family "puzzle.remainder_pair", topic: "Остатъци", area: "interactive_puzzles", variants: 11,
                 rungs: COMP do |c|
  first = c.pick([ 3, 4, 5, 6, 7, 8, 9, 11 ])
  second = c.pick([ 3, 4, 5, 6, 7, 8, 9, 11 ])
  raise Authoring::Duplicate if first == second

  number = c.int(c.by_level([ 20..60, 40..150, 80..400, 150..900, 300..2000, 600..5000, 1000..20_000 ]))

  c.q(
    text: "Попълни остатъка при деление на #{number} на #{first} и остатъка при деление на #{number} на #{second}.",
    widget: WidgetKit.blanks([ [ "r1", "на #{first}", number % first ], [ "r2", "на #{second}", number % second ] ]),
    hints: [
      "Остатъкът е това, което остава от #{number}, след като извадиш най-голямото кратно на делителя, което се побира в него.",
      "Направи го за всеки от двата делителя поотделно: колко пъти се съдържа и колко остава след това."
    ],
    explanation: Explain.build(
      idea: "Остатъкът е това, което остава след най-голямото кратно, което се побира.",
      steps: [
        "#{number} : #{first} = #{number / first} и остатък #{number % first}.",
        "#{number} : #{second} = #{number / second} и остатък #{number % second}."
      ],
      answer: "#{number % first} и #{number % second}",
      check: "#{first} · #{number / first} + #{number % first} = #{number}.",
      watch: "Остатъкът винаги е под делителя — иначе частното е взето твърде малко."
    )
  )
end

Authoring.family "puzzle.weekday_shift", topic: "Остатъци", area: "interactive_puzzles", variants: 11,
                 rungs: COMP do |c|
  ahead = c.int(c.by_level([ 20..80, 50..200, 100..500, 200..1200, 400..3000, 800..8000, 1500..20_000 ]))

  c.q(
    text: "След #{ahead} дни. Попълни колко пълни седмици има в #{ahead} дни и колко дни остават над тях.",
    widget: WidgetKit.blanks([ [ "weeks", "седмици", ahead / 7 ], [ "days", "остатък", ahead % 7 ] ]),
    hints: [
      "Денят от седмицата се повтаря на всеки 7 дни.",
      "Раздели #{ahead} на 7: частното са пълните седмици, а остатъкът е изместването."
    ],
    explanation: Explain.build(
      idea: "Денят от седмицата се повтаря на всеки 7 дни, затова цялата информация е в остатъка при деление на 7.",
      steps: [
        "#{ahead} : 7 = #{ahead / 7} и остатък #{ahead % 7}.",
        "Пълните седмици връщат същия ден; денят се измества с #{ahead % 7}."
      ],
      answer: "#{ahead / 7} седмици и #{ahead % 7} дни",
      check: "7 · #{ahead / 7} + #{ahead % 7} = #{ahead}.",
      watch: "Само остатъкът мести деня — броят седмици няма значение за отговора."
    )
  )
end

Authoring.family "puzzle.divisor_count", topic: "Делимост", area: "interactive_puzzles", variants: 11,
                 rungs: HARD do |c|
  number = c.int(c.by_level([ 12..60, 20..120, 30..250, 50..500, 80..1200, 150..3000, 250..9000 ]))
  factors = Num.factorize(number)
  raise Authoring::Duplicate if factors.size < 2

  count = factors.values.map { |power| power + 1 }.reduce(:*)

  c.q(
    text: "За числото #{number} попълни броя на различните му прости множители и общия брой на делителите му.",
    widget: WidgetKit.blanks([ [ "primes", "прости множители", factors.size ], [ "divisors", "делители", count ] ]),
    hints: [
      "Разложи #{number} на прости множители.",
      "Броят на делителите е произведение на (степен + 1) за всеки прост множител — не сбор."
    ],
    explanation: Explain.build(
      idea: "От разлагането #{number} = #{factors.map { |base, power| power == 1 ? base.to_s : "#{base}#{Num.sup(power)}" }.join(' · ')} " \
            "броят на делителите се получава като произведение на (степен + 1).",
      steps: [
        "#{number} = #{Num.factor_string(number)}.",
        "Различни прости множители: #{factors.keys.join(', ')} — #{factors.size} на брой.",
        "Делители: #{factors.values.map { |power| "(#{power} + 1)" }.join(' · ')} = #{count}."
      ],
      answer: "#{factors.size} и #{count}",
      check: "Изброяване: #{Num.divisors(number).join(', ')} — точно #{count}.",
      watch: "Степените се увеличават с 1 преди умножението — иначе 1 и самото число изпадат."
    )
  )
end

# ------------------------------------------------------------- Игри и стратегии ---

Authoring.family "puzzle.nim_move", topic: "Логически задачи", area: "interactive_puzzles", variants: 11,
                 rungs: HARD do |c|
  max_take = c.int(c.by_level([ 2..3, 2..4, 2..5, 3..6, 3..7, 4..8, 4..9 ]))
  period = max_take + 1
  pile = c.int(c.by_level([ 7..20, 10..40, 15..80, 20..150, 30..400, 50..900, 80..2000 ]))
  raise Authoring::Duplicate if (pile % period).zero?

  take = pile % period

  c.q(
    text: "В купчина има #{pile} камъчета. Двама играчи се редуват и всеки взема от 1 до #{max_take} камъчета; " \
          "печели този, който вземе последното. Ти си на ход. Попълни колко камъчета да вземеш " \
          "и колко ще останат след хода ти.",
    widget: WidgetKit.blanks([ [ "take", "взимаш", take ], [ "left", "остават", pile - take ] ]),
    hints: [
      "Позициите, кратни на #{period} = #{max_take} + 1, са губещи за играча на ход.",
      "Значи остави на противника кратно на #{period}.",
      "Колко е остатъкът на #{pile} при деление на #{period}? Точно толкова взимаш."
    ],
    explanation: Explain.build(
      idea: "Губещи са позициите, кратни на #{period} = #{max_take} + 1: каквото и да вземе противникът, ти допълваш до #{period}.",
      steps: [
        "#{pile} : #{period} дава остатък #{take}.",
        "Взимаш точно остатъка: #{count_noun(take, 'камъче', 'камъчета')}.",
        "Остават #{pile - take}, което е кратно на #{period} — вече противникът е в губеща позиция."
      ],
      answer: "взимаш #{take}, остават #{pile - take}",
      check: "#{pile - take} : #{period} = #{(pile - take) / period} — точно кратно.",
      watch: "Ако вземеш повече или по-малко, оставяш непълна група и противникът може да поеме стратегията."
    )
  )
end

Authoring.family "puzzle.nim_positions", topic: "Логически задачи", area: "interactive_puzzles", variants: 11,
                 rungs: ELITE do |c|
  max_take = c.int(2..5)
  period = max_take + 1
  losing = c.sample((1..12).map { |k| k * period }, 2)
  winning = c.sample((2..60).reject { |n| (n % period).zero? }, 3)
  options = (losing + winning).sort.map { |n| [ n.to_s, losing.include?(n) ] }
  raise Authoring::Duplicate if options.size < 5

  c.q(
    text: "В игра с една купчина всеки ход взима от 1 до #{max_take} камъчета и печели този, който вземе последното. " \
          "Кои от позициите #{options.map(&:first).join(', ')} са губещи за играча на ход? Избери всички.",
    widget: WidgetKit.multi_select(options),
    hints: [
      "Губеща е позицията, от която всеки възможен ход дава на противника печеливша.",
      "Такива са точно кратните на #{period} — провери всяка позиция за делимост на #{period}."
    ],
    explanation: Explain.build(
      idea: "Позицията е губеща точно когато броят камъчета се дели на #{period} — тогава всеки ход отваря печеливша позиция за противника.",
      steps: [
        "Кратните на #{period}: #{losing.sort.join(', ')} — губещи.",
        "Останалите позволяват ход до кратно на #{period}, затова са печеливши."
      ],
      answer: losing.sort.join(", "),
      check: "0 камъчета е губеща позиция (играчът на ход вече е загубил) и е кратно на #{period}.",
      watch: "Голяма купчина не значи печеливша позиция — важен е само остатъкът при деление на #{period}."
    )
  )
end

Authoring.family "puzzle.hanoi_moves", topic: "Логически задачи", area: "interactive_puzzles", variants: 11,
                 rungs: COMP do |c|
  disks = c.int(c.by_level([ 3..5, 4..7, 5..9, 6..12, 7..15, 8..18, 10..24 ]))
  moves = (2**disks) - 1

  c.q(
    text: "Ханойска кула с #{disks} диска. Попълни най-малкия брой ходове за #{disks} диска " \
          "и най-малкия брой ходове за #{disks - 1} диска.",
    widget: WidgetKit.blanks([ [ "n", "за #{disks} диска", moves ], [ "prev", "за #{disks - 1} диска", (2**(disks - 1)) - 1 ] ]),
    hints: [
      "За да преместиш n диска: местиш n − 1 настрани, после най-долния, после пак n − 1.",
      "Значи T(n) = 2 · T(n − 1) + 1, а T(1) = 1 — смятай нагоре от един диск."
    ],
    explanation: Explain.build(
      idea: "За да преместим n диска, местим n − 1 диска настрани, после най-долния, после пак n − 1: T(n) = 2·T(n−1) + 1.",
      steps: [
        "T(1) = 1, T(2) = 3, T(3) = 7 — всеки път двойно плюс едно.",
        "Формулата е T(n) = 2#{Num.sup('n')} − 1.",
        "T(#{disks}) = #{2**disks} − 1 = #{moves}, а T(#{disks - 1}) = #{(2**(disks - 1))} − 1 = #{(2**(disks - 1)) - 1}."
      ],
      answer: "#{moves} и #{(2**(disks - 1)) - 1}",
      check: "2 · #{(2**(disks - 1)) - 1} + 1 = #{moves}.",
      watch: "Броят ходове расте двойно с всеки диск — не линейно."
    )
  )
end

Authoring.family "puzzle.pigeonhole_pair", topic: "Логически задачи", area: "interactive_puzzles", variants: 11,
                 rungs: HARD do |c|
  groups = c.int(c.by_level([ 3..5, 3..7, 4..9, 5..12, 6..20, 8..40, 10..90 ]))
  want = c.by_level([ 2, 2, 3, 3, 4, 4, 5 ])
  guarantee = (groups * (want - 1)) + 1

  c.q(
    text: "В чекмедже има чорапи в #{groups} цвята. Попълни колко чорапа може да извадим в най-лошия случай " \
          "без да получим #{want} с еднакъв цвят, и колко трябва да извадим, за да сме сигурни.",
    widget: WidgetKit.blanks([ [ "worst", "най-лош случай", groups * (want - 1) ], [ "sure", "за сигурност", guarantee ] ]),
    hints: [
      "Мисли за най-лошия случай: колко може да извадиш, без още да имаш #{want} с еднакъв цвят?",
      "Всяка от групите се пълни до #{want - 1} — това е най-лошото, което може да ти се случи.",
      "Следващото изваждане вече задължително прелива някоя група."
    ],
    explanation: Explain.build(
      idea: "Принципът на Дирихле: най-лошият случай пълни всяка група до #{want - 1}, а следващият избор задължително прелива.",
      steps: [
        "#{groups} цвята по #{want - 1} чорапа = #{groups * (want - 1)} чорапа без успех.",
        "Още един чорап допълва някой цвят до #{want}: #{groups * (want - 1)} + 1 = #{guarantee}."
      ],
      answer: "#{groups * (want - 1)} и #{guarantee}",
      check: "С #{guarantee - 1} чорапа е възможно да няма #{want} еднакви, значи по-малко не гарантира нищо.",
      watch: "Гаранцията е за най-лошия случай — късметът не се брои."
    )
  )
end

Authoring.family "puzzle.weighings", topic: "Логически задачи", area: "interactive_puzzles", variants: 11,
                 rungs: ELITE do |c|
  coins = c.int(c.by_level([ 4..9, 6..27, 9..40, 12..80, 20..200, 40..700, 80..2000 ]))
  weighings = Math.log(coins, 3).ceil
  weighings += 1 if 3**weighings < coins

  c.q(
    text: "Сред #{coins} монети има една по-лека; останалите тежат еднакво. С везна с две блюда " \
          "попълни най-малкия гарантиран брой претегляния и колко монети най-много могат да се проверят с толкова претегляния.",
    widget: WidgetKit.blanks([ [ "w", "претегляния", weighings ], [ "max", "максимум монети", 3**weighings ] ]),
    hints: [
      "Всяко претегляне има три изхода: наляво, надясно или равновесие.",
      "Затова с k претегляния се различават най-много 3 на степен k случая.",
      "Търси най-малкото k, при което 3 на степен k стига за всички монети."
    ],
    explanation: Explain.build(
      idea: "Всяко претегляне има три изхода (ляво, дясно, равновесие), затова с k претегляния се различават най-много 3ᵏ случая.",
      steps: [
        "Разделяме монетите на три възможно равни групи и претегляме две от тях.",
        "3#{Num.sup(weighings - 1)} = #{3**(weighings - 1)} < #{coins} ≤ #{3**weighings} = 3#{Num.sup(weighings)}.",
        "Значи стигат #{weighings} претегляния."
      ],
      answer: "#{weighings} претегляния, до #{3**weighings} монети",
      check: "С #{weighings - 1} претегляния се проверяват само #{3**(weighings - 1)} монети — по-малко от #{coins}.",
      watch: "Делението е на три групи, не на две — равновесието също е информация."
    )
  )
end

# ---------------------------------------------------------- Мрежа и инварианти ---

Authoring.family "puzzle.knight_moves", topic: "Логически задачи", area: "interactive_puzzles", variants: 11,
                 rungs: COMP do |c|
  size = c.by_level([ 5, 5, 6, 6, 7, 7, 8 ])
  r = c.int(0...size)
  cc = c.int(0...size)
  jumps = [ [ 1, 2 ], [ 2, 1 ], [ -1, 2 ], [ -2, 1 ], [ 1, -2 ], [ 2, -1 ], [ -1, -2 ], [ -2, -1 ] ]
  targets = jumps.map { |dr, dc| [ r + dr, cc + dc ] }.
                  select { |nr, nc| nr.between?(0, size - 1) && nc.between?(0, size - 1) }.
                  map { |nr, nc| "#{nr},#{nc}" }
  raise Authoring::Duplicate if targets.size < 4 || targets.size > 6

  c.q(
    text: "Конят от шаха стои на оцветеното поле в дъска #{size} на #{size} (ред #{r + 1}, колона #{cc + 1}). " \
          "Оцвети всички полета, на които може да отиде с един ход (#{targets.size} на брой).",
    widget: WidgetKit.grid_shade(rows: size, cols: size, given: [ "#{r},#{cc}" ], cells: targets),
    hints: [
      "Конят се мести на буквата „Г“: две полета в една посока и едно перпендикулярно.",
      "Обиколи наум всичките осем възможни хода в двете посоки.",
      "После махни онези, които излизат извън дъската #{size} на #{size}."
    ],
    explanation: Explain.build(
      idea: "Конят се мести на буквата „Г“: две полета в една посока и едно перпендикулярно.",
      steps: [
        "Осемте възможни хода са (±1, ±2) и (±2, ±1) спрямо текущото поле.",
        "От ред #{r + 1}, колона #{cc + 1} извън дъската излизат #{8 - targets.size} от тях.",
        "Остават #{targets.size} валидни полета."
      ],
      answer: "#{targets.size} полета",
      check: "Конят винаги сменя цвета на полето — всички цели са с цвят, различен от изходния.",
      watch: "Ходът е точно 2 + 1, не 2 + 2 и не 1 + 1."
    )
  )
end

Authoring.family "puzzle.domino_parity", topic: "Логически задачи", area: "interactive_puzzles", variants: 11,
                 rungs: HARD do |c|
  boards = []
  8.times do
    rows = c.int(2..6)
    cols = c.int(2..6)
    removed = c.pick([ 0, 1, 2 ])
    cells = (rows * cols) - removed
    label = removed.zero? ? "#{rows} на #{cols}" : "#{rows} на #{cols} без #{removed} ъглови полета"
    boards << [ label, cells.even? && (removed != 2 || (rows * cols).even?) ]
  end
  options = boards.uniq(&:first).first(5)
  raise Authoring::Duplicate if options.count { |_, ok| ok } < 2 || options.count { |_, ok| !ok } < 2

  c.q(
    text: "Кои от дъските #{options.map(&:first).join('; ')} могат да се покрият изцяло с плочки домино 1 на 2 " \
          "(без застъпване и без излизане)? Избери всички.",
    widget: WidgetKit.multi_select(options),
    hints: [
      "Всяко домино покрива точно 2 полета.",
      "Значи броят на полетата трябва да е четен — това е първото, което се проверява."
    ],
    explanation: Explain.build(
      idea: "Всяко домино покрива точно 2 полета, затова броят на полетата трябва да е четен — това е необходимо условие.",
      steps: [
        "Броим полетата на всяка дъска.",
        "Нечетен брой полета изключва покриване веднага.",
        "При четен брой правоъгълна дъска винаги се покрива на редове."
      ],
      answer: options.select(&:last).map(&:first).join("; "),
      check: "Брой плочки = брой полета : 2.",
      watch: "Четният брой полета не е винаги достатъчен — при махнати полета от един и същи цвят покриване няма (класическата осакатена дъска)."
    )
  )
end

Authoring.family "puzzle.chessboard_colour", topic: "Логически задачи", area: "interactive_puzzles", variants: 6,
                 rungs: COMP do |c|
  rows = c.int(c.by_level([ 3..4, 4..5, 4..6, 5..6, 5..7, 6..7, 6..8 ]))
  cols = c.int(c.by_level([ 3..5, 4..6, 4..7, 5..7, 5..8, 6..8, 6..9 ]))
  parity = c.int(0..1)
  cells = (0...rows).flat_map { |r| (0...cols).map { |cc| [ r, cc ] } }.
          select { |r, cc| (r + cc) % 2 == parity }.map { |r, cc| "#{r},#{cc}" }
  raise Authoring::Duplicate if cells.size > 28

  c.q(
    text: "Оцвети дъската #{rows} на #{cols} като шахматна: оцвети всички полета, за които сборът на номера на реда " \
          "и номера на колоната е #{parity.zero? ? 'четен' : 'нечетен'} (броим от 0). Такива полета са #{cells.size}.",
    widget: WidgetKit.grid_shade(rows: rows, cols: cols, cells: cells),
    hints: [
      "Шахматното оцветяване се определя от четността на сбора ред + колона.",
      "Провери поле по поле дали сборът на номерата е четен или нечетен."
    ],
    explanation: Explain.build(
      idea: "Шахматното оцветяване се задава от четността на сбора ред + колона — това е инвариантът зад много състезателни задачи.",
      steps: [
        "Полето (0, 0) има сбор 0 — #{parity.zero? ? 'оцветява се' : 'не се оцветява'}.",
        "Съседните полета сменят четността, затова цветовете се редуват.",
        "При дъска #{rows} на #{cols} полетата с #{parity.zero? ? 'четен' : 'нечетен'} сбор са #{cells.size}."
      ],
      answer: "#{cells.size} полета",
      check: "Двата цвята заедно дават #{rows * cols} полета.",
      watch: "Всеки ход на кон, всяко домино и всяка обиколка по съседни полета сменят цвета — оттам идват невъзможностите."
    )
  )
end

Authoring.family "puzzle.lattice_rectangle", topic: "Площ", area: "interactive_puzzles", variants: 11,
                 rungs: COMP do |c|
  x1 = c.int(-4..1)
  y1 = c.int(-4..1)
  width = c.int(2..4)
  height = c.int(2..4)
  raise Authoring::Duplicate unless (x1 + width).between?(-5, 5) && (y1 + height).between?(-5, 5)

  area = width * height

  c.q(
    text: "Правоъгълник с върхове върху решетката има лице #{area} квадратни единици. Два съседни върха са " \
          "(#{Num.bg(x1)}; #{Num.bg(y1)}) и (#{Num.bg(x1 + width)}; #{Num.bg(y1)}), а другите два са отгоре. " \
          "Постави ги.",
    widget: WidgetKit.plot(points: [ [ x1, y1 + height ], [ x1 + width, y1 + height ] ],
                           fixed: [ [ x1, y1, "A" ], [ x1 + width, y1, "B" ] ]),
    hints: [
      "Основата се чете направо от двата дадени върха.",
      "Височината излиза от лицето #{area}, разделено на основата.",
      "Другите два върха стоят точно над дадените, на тази височина."
    ],
    explanation: Explain.build(
      idea: "Основата се чете от дадените върхове, а височината идва от лицето.",
      steps: [
        "Основата е #{Num.bg(x1 + width)} − #{Num.signed(x1)} = #{width} единици.",
        "Височина = лице : основа = #{area} : #{width} = #{height}.",
        "Върховете отгоре са (#{Num.bg(x1)}; #{Num.bg(y1 + height)}) и (#{Num.bg(x1 + width)}; #{Num.bg(y1 + height)})."
      ],
      answer: "(#{Num.bg(x1)}; #{Num.bg(y1 + height)}) и (#{Num.bg(x1 + width)}; #{Num.bg(y1 + height)})",
      check: "#{width} · #{height} = #{area} квадратни единици.",
      watch: "„Отгоре“ значи по-голяма ордината — надолу лицето е същото, но условието е друго."
    )
  )
end

Authoring.family "puzzle.pick_theorem", topic: "Площ", area: "interactive_puzzles", variants: 2,
                 rungs: ELITE do |c|
  width = c.int(2..5)
  height = c.int(2..5)
  interior = (width - 1) * (height - 1)
  boundary = 2 * (width + height)
  area = width * height

  c.q(
    text: "Правоъгълник със страни #{width} и #{height} единици е нарисуван върху решетка. " \
          "Попълни броя на решетъчните точки строго вътре в него и броя на точките по контура му.",
    widget: WidgetKit.blanks([ [ "i", "вътрешни", interior ], [ "b", "по контура", boundary ] ]),
    hints: [
      "Вътрешните точки образуват решетка, всяка от страните на която е с 1 по-малка.",
      "По контура се броят и четирите върха, но всеки само по веднъж."
    ],
    explanation: Explain.build(
      idea: "Формулата на Пик: S = I + B/2 − 1. Тук лицето се знае, а точките се броят направо.",
      steps: [
        "Вътрешни точки: (#{width} − 1) · (#{height} − 1) = #{interior}.",
        "По контура: 2 · (#{width} + #{height}) = #{boundary}.",
        "Проверка по Пик: #{interior} + #{boundary} : 2 − 1 = #{interior + (boundary / 2) - 1} = #{area}."
      ],
      answer: "#{interior} вътрешни и #{boundary} гранични точки",
      check: "Лицето по формулата съвпада с #{width} · #{height} = #{area}.",
      watch: "Върховете се броят по контура, не вътре."
    )
  )
end

# ----------------------------------------------------------- Редици и суми ---

Authoring.family "puzzle.gauss_sum", topic: "Числа и редици", area: "interactive_puzzles", variants: 11,
                 rungs: COMP do |c|
  n = c.int(c.by_level([ 10..40, 20..80, 30..150, 50..300, 80..700, 120..2000, 200..5000 ]))
  total = n * (n + 1) / 2

  c.q(
    text: "Попълни сбора 1 + 2 + ... + #{n} и броя на двойките с еднакъв сбор, които се получават при " \
          "сдвояване на първото с последното число.",
    widget: WidgetKit.blanks([ [ "sum", "сбор", total ], [ "pairs", "двойки", n / 2 ] ]),
    hints: [
      "Сдвои 1 с #{n}, 2 с #{n - 1} и така навътре — всяка двойка дава един и същ сбор #{n + 1}.",
      "Колко такива двойки се получават?"
    ],
    explanation: Explain.build(
      idea: "Сдвояваме 1 с #{n}, 2 с #{n - 1} и така нататък — всяка двойка дава #{n + 1}.",
      steps: [
        "Двойки: #{n} : 2 = #{n / 2}#{n.odd? ? " (средното число #{(n + 1) / 2} остава само)" : ''}.",
        "Сбор: #{n} · #{n + 1} : 2 = #{total}."
      ],
      answer: "#{total} и #{n / 2}",
      check: "#{n / 2} · #{n + 1}#{n.odd? ? " + #{(n + 1) / 2}" : ''} = #{total}.",
      watch: "При нечетно #{n} едно число остава без двойка — формулата обаче го включва."
    )
  )
end

Authoring.family "puzzle.square_sum_pattern", topic: "Числа и редици", area: "interactive_puzzles", variants: 11,
                 rungs: HARD do |c|
  n = c.int(c.by_level([ 3..8, 4..12, 5..20, 6..30, 8..60, 10..120, 12..300 ]))
  odd_sum = n * n
  even_sum = n * (n + 1)

  c.q(
    text: "Попълни сбора на първите #{n} нечетни числа (1 + 3 + 5 + ...) и сбора на първите #{n} четни числа (2 + 4 + 6 + ...).",
    widget: WidgetKit.blanks([ [ "odd", "нечетни", odd_sum ], [ "even", "четни", even_sum ] ]),
    hints: [
      "Пресметни за малки стойности: 1, после 1 + 3, после 1 + 3 + 5 — какво разпознаваш?",
      "Всяко четно число е с 1 по-голямо от съответното нечетно, а те са #{n} — толкова е и разликата между двата сбора."
    ],
    explanation: Explain.build(
      idea: "Първите n нечетни числа дават точен квадрат n², а четните — n(n + 1).",
      steps: [
        "Нечетни: 1 + 3 + ... + #{(2 * n) - 1} = #{n}² = #{odd_sum}.",
        "Четни: 2 + 4 + ... + #{2 * n} = 2 · (1 + 2 + ... + #{n}) = 2 · #{n * (n + 1) / 2} = #{even_sum}."
      ],
      answer: "#{odd_sum} и #{even_sum}",
      check: "Разликата между двата сбора е #{even_sum - odd_sum} = #{n} — по едно повече във всяка двойка.",
      watch: "Последното нечетно число е #{(2 * n) - 1}, не #{n}."
    )
  )
end

Authoring.family "puzzle.telescoping", topic: "Дроби", area: "interactive_puzzles", variants: 11,
                 rungs: ELITE do |c|
  n = c.int(c.by_level([ 3..8, 4..12, 5..20, 6..40, 8..80, 10..200, 12..500 ]))
  value = Rational(n, n + 1)

  c.q(
    text: "Сборът 1/(1·2) + 1/(2·3) + ... + 1/(#{n}·#{n + 1}) се съкращава телескопично. " \
          "Попълни числителя и знаменателя на резултата (несъкратима дроб).",
    widget: WidgetKit.blanks([ [ "num", "числител", value.numerator ], [ "den", "знаменател", value.denominator ] ]),
    hints: [
      "1/(k · (k + 1)) е същото като 1/k − 1/(k + 1).",
      "Изпиши няколко члена така: съседните се унищожават и остават само първият и последният."
    ],
    explanation: Explain.build(
      idea: "1/(k(k+1)) = 1/k − 1/(k+1), затова съседните членове се унищожават.",
      steps: [
        "Сборът става (1 − 1/2) + (1/2 − 1/3) + ... + (1/#{n} − 1/#{n + 1}).",
        "Остават само първият и последният член: 1 − 1/#{n + 1}.",
        "1 − 1/#{n + 1} = #{Num.frac(value)}."
      ],
      answer: Num.frac(value),
      check: "При #{n} = 1 сборът е 1/2, а формулата дава 1/2 ✓.",
      watch: "Резултатът винаги е под 1 и расте към 1 с увеличаване на n."
    )
  )
end

Authoring.family "puzzle.fibonacci_step", topic: "Числа и редици", area: "interactive_puzzles", variants: 11,
                 rungs: COMP do |c|
  a = c.int(c.by_level([ 1..4, 1..8, 2..15, 3..30, 5..60, 8..150, 10..400 ]))
  b = c.int(c.by_level([ 1..5, 2..10, 3..18, 4..35, 6..70, 10..180, 12..500 ]))
  terms = [ a, b ]
  6.times { terms << terms[-1] + terms[-2] }
  hidden = c.sample((2..7).to_a, 2).sort

  c.q(
    text: "В редицата всеки член е сборът на двата преди него: #{terms.each_with_index.map { |value, i| hidden.include?(i) ? '☐' : value }.join(', ')}. " \
          "Попълни двете липсващи числа отляво надясно.",
    widget: WidgetKit.blanks(hidden.each_with_index.map { |index, i| [ "t#{i}", "#{index + 1}-ти член", terms[index] ] }),
    hints: [
      "Правилото важи и назад: липсващото число се получава и с изваждане.",
      "Тръгни от място, където две съседни числа вече са известни."
    ],
    explanation: Explain.build(
      idea: "Правилото важи във всяка посока: напред се събира, назад се изважда.",
      steps: [
        "#{terms[0]} + #{terms[1]} = #{terms[2]}, #{terms[1]} + #{terms[2]} = #{terms[3]}, и така нататък.",
        hidden.map { |index| "#{index + 1}-ти член: #{terms[index - 2]} + #{terms[index - 1]} = #{terms[index]}." }.join(" ")
      ],
      answer: hidden.map { |index| terms[index] }.join(" и "),
      check: "Последният член #{terms.last} = #{terms[-3]} + #{terms[-2]}.",
      watch: "Ако едно число липсва по средата, то се намира и с изваждане: следващият минус предишния."
    )
  )
end

# ------------------------------------------------------------------- Групиране ---

Authoring.family "puzzle.sort_possible", topic: "Логически задачи", area: "interactive_puzzles", variants: 11,
                 rungs: HARD do |c|
  n = c.int(c.by_level([ 5..12, 8..20, 10..40, 15..80, 20..150, 30..400, 50..900 ]))
  possible = [ "сборът на #{n} нечетни числа да е #{n.even? ? 'четен' : 'нечетен'}",
               "произведението на #{n} числа да е четно" ]
  impossible = [ "сборът на #{n} нечетни числа да е #{n.even? ? 'нечетен' : 'четен'}",
                 "сборът на две нечетни числа да е нечетен" ]
  items = (possible + impossible).each_with_index.map { |label, i| [ "s#{i}", label, possible.include?(label) ? "yes" : "no" ] }
  raise Authoring::Duplicate if items.size < 4

  c.q(
    text: "Разпредели твърденията на възможни и невъзможни: #{items.map { |_, label, _| label }.join('; ')}.",
    widget: WidgetKit.categorize(bins: [ [ "yes", "възможно" ], [ "no", "невъзможно" ] ], items: items),
    hints: [
      "Четността е инвариант: сборът на нечетни числа зависи само от това колко са те.",
      "Проверявай всяко твърдение по четност, не с пробване на примери."
    ],
    explanation: Explain.build(
      idea: "Четността е инвариант: сборът на #{n} нечетни числа има същата четност като #{n}.",
      steps: [
        "Нечетно + нечетно = четно, значи двойките се неутрализират.",
        "#{n} нечетни числа дават #{n.even? ? 'четен' : 'нечетен'} сбор.",
        "Произведение е четно, щом поне един множител е четен."
      ],
      answer: possible.join("; "),
      check: "Проверка с малък пример: 1 + 3 = 4 (четно), 1 + 3 + 5 = 9 (нечетно).",
      watch: "Невъзможността тук не е въпрос на пробване — четността я забранява напълно."
    )
  )
end

Authoring.family "puzzle.match_base_two", topic: "Числа и редици", area: "interactive_puzzles", variants: 11,
                 rungs: HARD do |c|
  numbers = c.sample((c.by_level([ 3..15, 5..31, 8..63, 12..127, 20..255, 30..511, 50..1023 ])).to_a, 3)
  raise Authoring::Duplicate if numbers.uniq.size < 3

  pairs = numbers.map { |n| [ n.to_s, n.to_s(2) ] }

  c.q(
    text: "Свържи всяко число #{numbers.join(', ')} с двоичния му запис.",
    widget: WidgetKit.matcher(pairs),
    hints: [
      "Двоичният запис се получава с последователно деление на 2, а остатъците се четат отдолу нагоре.",
      "Проверка наум: всяка единица в записа е степен на 2, а сборът им дава числото."
    ],
    explanation: Explain.build(
      idea: "Двоичният запис се получава чрез последователно деление на 2, като остатъците се четат отдолу нагоре.",
      steps: numbers.map do |n|
        "#{n} = #{n.to_s(2).chars.each_with_index.map { |bit, i| bit == '1' ? (2**(n.to_s(2).size - 1 - i)).to_s : nil }.compact.join(' + ')} → #{n.to_s(2)}"
      end,
      answer: pairs.map { |decimal, binary| "#{decimal} = #{binary}₂" }.join(", "),
      check: "Броят цифри в двоичния запис расте с 1 при всяко удвояване.",
      watch: "Водещата цифра е винаги 1 — двоичен запис не започва с нула."
    )
  )
end

Authoring.family "puzzle.pick_perfect_squares", topic: "Степени и корени", area: "interactive_puzzles", variants: 11,
                 rungs: COMP do |c|
  band = c.by_level([ 10..80, 20..150, 40..400, 80..900, 150..2500, 300..6000, 500..12_000 ])
  squares = (2..120).map { |n| n * n }.select { |value| band.include?(value) }
  raise Authoring::Duplicate if squares.size < 2

  good = c.sample(squares, 2)
  bad = c.sample((band.to_a - squares), 3)
  options = (good + bad).sort.map { |value| [ value.to_s, good.include?(value) ] }

  c.q(
    text: "Кои от числата #{options.map(&:first).join(', ')} са точни квадрати? Избери всички.",
    widget: WidgetKit.multi_select(options),
    hints: [
      "Точен квадрат е число, което може да се запише като n · n.",
      "Изпиши 1, 4, 9, 16, 25, 36, ... и виж кои от числата се срещат в списъка."
    ],
    explanation: Explain.build(
      idea: "Точен квадрат е числото, чийто корен е цяло — проверява се със степените в разлагането: всички трябва да са четни.",
      steps: [
        good.map { |value| "#{value} = #{Integer.sqrt(value)}²" }.join(", ") + ".",
        bad.first(2).map { |value| "#{value} = #{Num.factor_string(value)} — има нечетна степен" }.join("; ") + "."
      ],
      answer: good.sort.join(", "),
      check: "Точните квадрати завършват само на 0, 1, 4, 5, 6 или 9.",
      watch: "Числа, завършващи на 2, 3, 7 или 8, никога не са точни квадрати — това е бърза проверка."
    )
  )
end
