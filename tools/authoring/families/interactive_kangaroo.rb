# Типове, дошли от състезателни листовки (Кенгуру и подобни).
#
# Each family here was built from one pasted competition problem, generalised
# into a ladder: the same idea with smaller numbers below it and bigger ones
# above. Where the reasoning is a search (the circle puzzle, the two kinds of
# creature), the builder enumerates every candidate and keeps the problem only
# if exactly one survives.

KANGAROO = [ 1100, 1250, 1400, 1550, 1700, 1850, 2000 ].freeze

# --------------------------------------- Произведение на цифрите (нулата) ---

Authoring.family "digits.sum_and_product", topic: "Числа и редици", area: "interactive_kangaroo", variants: 9,
                 rungs: [ 900, 1030, 1160, 1290, 1420, 1550, 1680 ] do |c|
  size = c.by_level([ 3, 3, 4, 4, 5, 6, 7 ])
  # Zeros become common as the numbers get longer — the whole point of the type.
  digits = Array.new(size) { c.int(c.by_level([ 1..9, 0..9, 0..9, 0..9, 0..9, 0..9, 0..9 ])) }
  digits[0] = c.int(1..9)
  number = digits.join.to_i
  product = digits.reduce(:*)
  sum = digits.sum

  c.q(
    text: "Попълни сбора и произведението на цифрите на числото #{number}.",
    widget: WidgetKit.blanks([ [ "sum", "сбор", sum ], [ "product", "произведение", product ] ]),
    hints: [
      "Разпиши цифрите поотделно: #{digits.join(', ')}.",
      "Сборът се получава със събиране, произведението с умножение — и погледни дали сред цифрите има нула."
    ],
    explanation: Explain.build(
      idea: "Сборът събира цифрите една по една; произведението ги умножава — и една-единствена нула " \
            "унищожава цялото произведение.",
      steps: [
        "Сбор: #{digits.join(' + ')} = #{sum}.",
        digits.include?(0) ?
          "Произведение: сред цифрите има 0, а всяко умножение с 0 дава 0 — значи произведението е 0." :
          "Произведение: #{digits.join(' · ')} = #{product}."
      ],
      answer: "сбор #{sum}, произведение #{product}",
      check: digits.include?(0) ? "Нулата стои на #{digits.index(0) + 1}-та позиция — достатъчна е една." :
                                  "Всяка цифра участва точно веднъж и в двете сметки.",
      watch: digits.include?(0) ?
        "Нулата не пречи на сбора, но занулява произведението — това е капанът в такива задачи." :
        "Тук няма нула, затова произведението е голямо; една нула сред цифрите щеше да го направи 0."
    )
  )
end

Authoring.family "digits.zero_product_pick", topic: "Числа и редици", area: "interactive_kangaroo", variants: 9,
                 rungs: [ 1000, 1130, 1260, 1390, 1520, 1650, 1780 ] do |c|
  size = c.by_level([ 3, 3, 4, 4, 5, 5, 6 ])
  make = lambda do |with_zero|
    digits = Array.new(size) { c.int(1..9) }
    digits[c.int(1...size)] = 0 if with_zero
    digits.join.to_i
  end
  zeros = 2.times.map { make.call(true) }.uniq
  others = 3.times.map { make.call(false) }.uniq
  raise Authoring::Duplicate if zeros.size < 2 || others.size < 3

  options = (zeros + others).sort.map { |value| [ value.to_s, zeros.include?(value) ] }

  c.q(
    text: "За кои от числата #{options.map(&:first).join(', ')} произведението на цифрите е 0? Избери всички.",
    widget: WidgetKit.multi_select(options),
    hints: [
      "Произведение става 0 само ако някой множител е 0 — тук множителите са цифрите.",
      "Затова не смятай нищо: прегледай всяко число цифра по цифра и търси нула."
    ],
    explanation: Explain.build(
      idea: "Произведението на цифрите е 0 точно когато поне една от цифрите е 0 — не е нужно да се смята нищо.",
      steps: [
        "С нула: #{zeros.sort.join(', ')} — достатъчно е окото да я намери.",
        "Без нула: #{others.sort.join(', ')} — там произведението е положително " \
        "(например #{others.first} дава #{others.first.to_s.chars.map(&:to_i).reduce(:*)})."
      ],
      answer: zeros.sort.join(", "),
      check: "Произведението е 0 само при множител 0; сборът на същите цифри си остава положителен.",
      watch: "Числото не става 0 — само произведението на цифрите му."
    )
  )
end

# ------------------------------------------------- Два вида по два признака ---

Authoring.family "logic.two_creatures", topic: "Логически задачи", area: "interactive_kangaroo", variants: 9,
                 rungs: KANGAROO do |c|
  eyes_a = c.int(1..3)
  eyes_b = c.int(1..4)
  legs_a = c.int(2..6)
  legs_b = c.int(2..6)
  raise Authoring::Duplicate if (eyes_a * legs_b) - (eyes_b * legs_a) == 0

  first = c.int(c.by_level([ 1..4, 1..5, 1..7, 2..9, 2..14, 3..20, 4..40 ]))
  second = c.int(c.by_level([ 1..4, 1..5, 1..7, 2..9, 2..14, 3..20, 4..40 ]))
  eyes = (first * eyes_a) + (second * eyes_b)
  legs = (first * legs_a) + (second * legs_b)

  # A second solution in non-negative integers would make the puzzle unfair.
  solutions = (0..(eyes / [ eyes_a, 1 ].max)).filter_map do |x|
    rest_eyes = eyes - (x * eyes_a)
    next if rest_eyes.negative? || (rest_eyes % eyes_b) != 0

    y = rest_eyes / eyes_b
    [ x, y ] if (x * legs_a) + (y * legs_b) == legs
  end
  raise Authoring::Duplicate unless solutions == [ [ first, second ] ]

  c.q(
    text: "В едно село има два вида чудовища. Първият вид са с по #{eyes_a} #{eyes_a == 1 ? 'око' : 'очи'} " \
          "и по #{legs_a} крака, а вторият — с по #{eyes_b} #{eyes_b == 1 ? 'око' : 'очи'} и по #{legs_b} крака. " \
          "Общо чудовищата имат #{eyes} очи и #{legs} крака. Попълни по колко чудовища има от всеки вид.",
    widget: WidgetKit.blanks([ [ "a", "първи вид", first ], [ "b", "втори вид", second ] ]),
    hints: [
      "Означи с x броя чудовища от първия вид и с y от втория.",
      "Очите дават #{eyes_a}x + #{eyes_b}y = #{eyes}, а краката — #{legs_a}x + #{legs_b}y = #{legs}.",
      "Две уравнения с две неизвестни: изрази x от първото и замести във второто."
    ],
    explanation: Explain.build(
      idea: "Двете суми дават две уравнения с две неизвестни: очите и краката броят едни и същи чудовища по различен начин.",
      steps: [
        "#{eyes_a}x + #{eyes_b}y = #{eyes} (очите) и #{legs_a}x + #{legs_b}y = #{legs} (краката).",
        "Изразяваме от първото и заместваме във второто — остава едно уравнение с едно неизвестно.",
        "Получава се x = #{first} и y = #{second}."
      ],
      answer: "#{first} от първия вид и #{second} от втория",
      check: "Очи: #{first} · #{eyes_a} + #{second} · #{eyes_b} = #{eyes}. Крака: #{first} · #{legs_a} + #{second} · #{legs_b} = #{legs}.",
      watch: "Броят на чудовищата не е даден — затова тук не важи трикът „ако всички бяха от единия вид“ " \
             "с глави, а трябват двете уравнения."
    )
  )
end

# -------------------------------------------------- Екстремална стойност ---

Authoring.family "logic.extremal_share", topic: "Логически задачи", area: "interactive_kangaroo", variants: 9,
                 rungs: KANGAROO do |c|
  count = c.int(c.by_level([ 3..5, 4..6, 4..8, 5..10, 6..15, 8..25, 10..50 ]))
  minimum = c.int(c.by_level([ 1..2, 1..3, 2..4, 2..5, 3..7, 3..10, 4..20 ]))
  extra = c.int(c.by_level([ 2..6, 3..10, 4..15, 5..25, 8..50, 10..120, 15..300 ]))
  total = (count * minimum) + extra
  biggest = total - ((count - 1) * minimum)
  animal = c.pick([ [ "катерички", "жълъда" ], [ "деца", "стикера" ], [ "мравки", "трохи" ],
                    [ "пингвини", "риби" ], [ "приятели", "бонбона" ] ])

  c.q(
    text: "#{count} #{animal[0]} изядоха общо #{total} #{animal[1]}, като всяка изяде поне #{minimum}. " \
          "Попълни колко най-малко са изяли останалите #{count - 1} заедно и колко най-много може да е изяла една от тях.",
    widget: WidgetKit.blanks([ [ "others", "останалите заедно", (count - 1) * minimum ],
                               [ "max", "най-много една", biggest ] ]),
    hints: [
      "За да изяде една възможно най-много, всички останали трябва да са на минимума си.",
      "Останалите са #{count - 1} и всяка изяжда поне #{minimum} — колко правят заедно?",
      "Каквото остане от #{total}, отива при едната."
    ],
    explanation: Explain.build(
      idea: "За да е максимален делът на едната, всички останали трябва да са на минимума си — това е цялата идея " \
            "на екстремалните задачи.",
      steps: [
        "Останалите са #{count - 1} и всяка изяжда поне #{minimum}: #{count - 1} · #{minimum} = #{(count - 1) * minimum}.",
        "Останалото отива при едната: #{total} − #{(count - 1) * minimum} = #{biggest}."
      ],
      answer: "#{(count - 1) * minimum} и #{biggest}",
      check: "#{biggest} + #{count - 1} · #{minimum} = #{total}, а #{biggest} ≥ #{minimum} — условието е спазено.",
      watch: "Максимумът за едната се получава от минимума за всички други, не от разделяне поравно " \
             "(#{Num.dec(Rational(total, count), 2)} на глава)."
    )
  )
end

# --------------------------------------------- Аритметика върху фигури ---

Authoring.family "fig.square_line_equation", topic: "Логически задачи", area: "interactive_kangaroo", variants: 7,
                 rungs: [ 1150, 1300, 1450, 1600, 1750, 1900, 2050 ] do |c|
  first = c.int(c.by_level([ 2..3, 2..4, 3..5, 3..6, 4..7, 4..8, 5..9 ]))
  second = c.int(1..(first - 1))
  third = c.int(1..c.by_level([ 2, 3, 3, 4, 5, 6, 7 ]))
  result = first - second + third
  raise Authoring::Duplicate if result > 9 || result < 1

  c.q(
    text: "Всеки квадрат на чертежа е разделен с прави линии. Първият има #{first} " \
          "#{first == 1 ? 'линия' : 'линии'}, вторият — #{second}, третият — #{third}. " \
          "Колко разделителни линии има квадратът на мястото на въпросителния знак?",
    answer: Num.ans(result),
    figure: Figures.square_equation(cuts: [ first, second, third ], operations: [ Num::MINUS, "+" ]),
    hints: [
      "Всяко квадратче се брои по линиите в него, а не по частите, на които е разделено.",
      "Знаците между квадратчетата се четат като обикновена сметка: #{first} #{Num::MINUS} #{second} + #{third}."
    ],
    explanation: Explain.build(
      idea: "Действието е върху броя на разделителните линии, а не върху броя на частите — това е ключът към " \
            "този тип задачи с фигури.",
      steps: [
        "Линии: #{first} − #{second} + #{third} = #{result}.",
        "За сравнение по части щеше да излезе #{first + 1} − #{second + 1} + #{third + 1} = #{result + 1} части, " \
        "тоест #{result} линии — същият квадрат, различен начин на броене."
      ],
      answer: "#{result} #{result == 1 ? 'линия' : 'линии'} (#{result + 1} части)",
      check: "Квадрат с #{result} успоредни линии се разделя на #{result + 1} равни ивици.",
      watch: "k линии правят k + 1 части — объркването между двете дава отговор, който е с единица встрани."
    )
  )
end

# ------------------------------------------------- Подредба в кръг ---

CIRCLE_LADDER = [ 1250, 1400, 1550, 1700, 1850, 2000 ].freeze

module Circle
  module_function

  # Every seating with the first person fixed: rotations are the same circle,
  # but reflections are not, because the clues say "clockwise".
  def seatings(people)
    (people[1..] || []).permutation.map { |rest| [ people.first ] + rest }
  end

  def neighbours(seating, person)
    index = seating.index(person)
    [ seating[index - 1], seating[(index + 1) % seating.size] ].sort
  end

  def after?(seating, person, other)
    seating[(seating.index(other) + 1) % seating.size] == person
  end
end

Authoring.family "logic.circle_neighbours", topic: "Логически задачи", area: "interactive_kangaroo", variants: 9,
                 rungs: CIRCLE_LADDER do |c|
  size = c.by_level([ 5, 5, 5, 6, 6, 7 ])
  people = c.sample(Props::NAMES, size)
  seating = [ people.first ] + (people[1..] || []).shuffle(random: c.rng)

  pairs = seating.each_with_index.map { |person, index| [ seating[(index + 1) % size], person ] }
  after_clues = c.sample(pairs, c.by_level([ 2, 2, 2, 2, 2, 3 ])).map do |follower, leader|
    { text: "#{follower} стои непосредствено след #{leader}",
      test: ->(candidate) { Circle.after?(candidate, follower, leader) } }
  end

  far = people.product(people).select { |a, b| a != b && !Circle.neighbours(seating, a).include?(b) }
  raise Authoring::Duplicate if far.empty?

  apart = c.pick(far)
  clues = (after_clues + [ { text: "#{apart[0]} и #{apart[1]} не са съседи",
                             test: ->(candidate) { !Circle.neighbours(candidate, apart[0]).include?(apart[1]) } } ]).
          uniq { |clue| clue[:text] }

  fits = Circle.seatings(people).select { |candidate| clues.all? { |clue| clue[:test].call(candidate) } }
  raise Authoring::Duplicate if fits.empty?

  # The lower rungs pin the whole circle; the upper ones leave several seatings
  # standing, so the student has to see that the neighbours are the same in all
  # of them — which is exactly what the original competition problem asks.
  raise Authoring::Duplicate if c.level <= 1 && fits.size != 1
  raise Authoring::Duplicate if c.level >= 3 && fits.size < 2

  # Ask only about someone whose neighbours every surviving seating agrees on.
  askable = people.select { |person| fits.map { |candidate| Circle.neighbours(candidate, person) }.uniq.size == 1 }
  named = after_clues.flat_map { |clue| people.select { |person| clue[:text].include?(person) } }.uniq
  # Someone named in both adjacency clues has their neighbours handed to them;
  # the puzzle is only a puzzle for the people the clues reach indirectly.
  indirect = askable - named
  raise Authoring::Duplicate if indirect.empty?

  asked = c.pick(indirect)
  answer = Circle.neighbours(seating, asked)
  options = people.reject { |person| person == asked }.map { |person| [ person, answer.include?(person) ] }
  raise Authoring::Duplicate if options.size < 4

  rejected = Circle.seatings(people).reject { |candidate| fits.include?(candidate) }.filter_map do |candidate|
    broken = clues.find { |clue| !clue[:test].call(candidate) }
    next unless broken

    "подредбата #{candidate.join(' → ')} → #{candidate.first} нарушава „#{broken[:text]}“"
  end.first(2)

  c.q(
    text: "#{name_list(people)} стоят в кръг. Гледано по посока на часовниковата стрелка: " \
          "#{clue_sentence(clues.map { |clue| { text: clue[:text] } }.map { |clue| Clue.new(text: clue[:text]) })}. " \
          "Кои са двамата съседи на #{asked}? Избери и двамата.",
    widget: WidgetKit.multi_select(options),
    hints: [
      "Нареждай по посока на часовниковата стрелка: „непосредствено след“ залепва двама души в определен ред.",
      "Първо подреди залепените двойки, после отхвърли подредбите, в които двамата „не са съседи“ се допират.",
      "В кръг всеки има точно двама съседи — последният в изброяването се допира до първия."
    ],
    explanation: Explain.build(
      idea: "Подреждаме кръга по посока на часовниковата стрелка. „Непосредствено след“ залепва двама души в " \
            "определен ред, а „не са съседи“ отхвърля подредби.",
      steps: [
        fits.size == 1 ?
          "Условията оставят една-единствена подредба: #{seating.join(' → ')} → #{seating.first}." :
          "Условията оставят #{fits.size} възможни подредби: #{fits.map { |candidate| candidate.join(' → ') }.join('; ')}.",
        fits.size == 1 ? nil :
          "Във всяка от тях съседите на #{asked} са едни и същи — затова въпросът има отговор, макар кръгът да не е " \
          "определен докрай.",
        rejected.first ? "За сравнение, #{rejected.first}." : nil
      ].compact,
      answer: answer.join(" и "),
      check: "В подредбата #{seating.join(' → ')} → #{seating.first} съседите на #{asked} са #{answer.join(' и ')}.",
      watch: "В кръг всеки има точно двама съседи — последният в изброяването се допира до първия."
    )
  )
end

# --------------------------------------- Броене с ограничения върху цифрите ---

Authoring.family "count.digit_choices", topic: "Броене и комбинаторика", area: "interactive_kangaroo", variants: 9,
                 rungs: KANGAROO do |c|
  tens_shift = c.int(c.by_level([ 1..1, 1..2, 1..3, 1..4, 2..5, 2..6, 3..7 ]))
  units_shift = c.int(c.by_level([ 1..2, 1..3, 2..4, 2..5, 3..6, 3..7, 4..8 ]))
  tens_down = c.coin
  units_up = c.coin
  tens_options = 9 - tens_shift
  units_options = 10 - units_shift
  total = tens_options * units_options

  c.q(
    text: "Мария написала двуцифрено число m, а Рая написала до него двуцифреното число n, " \
          "чиято цифра на десетиците е с #{tens_shift} #{tens_down ? 'по-малка' : 'по-голяма'} от " \
          "цифрата на десетиците на m, а цифрата на единиците е с #{units_shift} " \
          "#{units_up ? 'по-голяма' : 'по-малка'} от цифрата на единиците на m. " \
          "Попълни колко възможности има за цифрата на десетиците, колко за цифрата на единиците " \
          "и колко са всички възможни числа m.",
    widget: WidgetKit.blanks([ [ "tens", "десетици", tens_options ], [ "units", "единици", units_options ],
                               [ "total", "общо", total ] ]),
    hints: [
      "Гледай двете цифри поотделно: колко стойности може да има цифрата на десетиците и колко — на единиците.",
      "Цифрата на десетиците не може да е 0, затова възможностите за нея са с една по-малко.",
      "Броят на числата е произведение на двете възможности, а не сбор."
    ],
    explanation: Explain.build(
      idea: "Двете цифри се избират независимо, затова броят на числата е произведение — стига всяка цифра " \
            "да остане позволена след промяната.",
      steps: [
        tens_down ?
          "Десетиците на n са с #{tens_shift} по-малки и трябва да са поне 1, значи десетиците на m са от #{tens_shift + 1} до 9 — #{tens_options} възможности." :
          "Десетиците на n са с #{tens_shift} по-големи и трябва да са най-много 9, значи десетиците на m са от 1 до #{9 - tens_shift} — #{tens_options} възможности.",
        units_up ?
          "Единиците на n са с #{units_shift} по-големи и трябва да са най-много 9, значи единиците на m са от 0 до #{9 - units_shift} — #{units_options} възможности." :
          "Единиците на n са с #{units_shift} по-малки и трябва да са поне 0, значи единиците на m са от #{units_shift} до 9 — #{units_options} възможности.",
        "Общо: #{tens_options} · #{units_options} = #{total} числа."
      ],
      answer: "#{tens_options}, #{units_options} и #{total}",
      check: "Най-малкото възможно m е #{tens_down ? tens_shift + 1 : 1}#{units_up ? 0 : units_shift}, " \
             "а най-голямото — #{tens_down ? 9 : 9 - tens_shift}#{units_up ? 9 - units_shift : 9}.",
      watch: "Цифрата на десетиците не може да е 0 (иначе числото не е двуцифрено), а на единиците — може."
    )
  )
end

# ------------------------------------------------ Редица със съседно условие ---
#
# "Ten children in a row, boys at both ends, every other child stands between a
# girl and a boy." The condition is about a child's *neighbours*, so it says
# p(i-1) != p(i+1): positions two apart alternate, and the row falls apart into
# the odd chain and the even chain. Everything else follows from that, including
# the lengths for which no such row exists at all.

module Row
  module_function

  BOY = 0
  GIRL = 1

  # Each chain alternates, so a whole row is fixed by the two chain starts.
  def rows(length, first, last)
    [ 0, 1 ].product([ 0, 1 ]).filter_map do |odd_start, even_start|
      row = (1..length).map do |position|
        position.odd? ? (odd_start + (position / 2)) % 2 : (even_start + ((position - 2) / 2)) % 2
      end
      row if row.first == first && row.last == last
    end
  end

  def kind(value) = value == GIRL ? "момиче" : "момче"

  def ends_text(first, last)
    first == last ? "в двата края са #{first == GIRL ? 'момичета' : 'момчета'}" :
                    "в единия край е #{kind(first)}, а в другия — #{kind(last)}"
  end

  # Why the chains behave the way they do — the sentence a student can reuse.
  def chain_steps(length, first, last, rows)
    odd_length = (length + 1) / 2
    even_length = length / 2
    [
      "Условието е за съседите на детето, тоест лявото и дясното дете се различават: " \
      "местата през едно се редуват.",
      "Значи нечетните места (1, 3, 5, ...) образуват една редуваща се верига от #{odd_length} деца, " \
      "а четните (2, 4, 6, ...) — втора от #{even_length}.",
      length.even? ?
        "Краят вляво определя първата верига, а краят вдясно — втората, затова редът е точно един." :
        "И двата края са на нечетни места, затова първата верига е определена, а втората може да започне " \
        "и с момче, и с момиче — оттам са #{rows.size} възможни подредби."
    ]
  end
end

Authoring.family "logic.row_between", topic: "Логически задачи", area: "interactive_kangaroo", variants: 9,
                 rungs: [ 1200, 1350, 1500, 1650, 1800, 1950, 2100 ] do |c|
  spec = c.by_level([
    { lengths: (4..8).select(&:even?), ends: [ [ Row::BOY, Row::BOY ] ] },
    { lengths: (6..12).select(&:even?), ends: [ [ Row::BOY, Row::BOY ], [ Row::GIRL, Row::GIRL ] ] },
    { lengths: (8..16).select(&:even?), ends: [ [ Row::BOY, Row::BOY ], [ Row::GIRL, Row::GIRL ] ] },
    { lengths: (8..18).select(&:even?), ends: [ [ Row::BOY, Row::GIRL ], [ Row::GIRL, Row::BOY ] ] },
    { lengths: (9..21).select(&:odd?), ends: [ [ Row::BOY, Row::BOY ], [ Row::GIRL, Row::GIRL ] ] },
    { lengths: (12..30).select(&:even?), ends: [ [ Row::BOY, Row::BOY ], [ Row::BOY, Row::GIRL ] ] },
    { lengths: (13..41).select(&:odd?), ends: [ [ Row::BOY, Row::BOY ], [ Row::GIRL, Row::GIRL ] ] }
  ])
  length = c.pick(spec[:lengths])
  first, last = c.pick(spec[:ends])
  rows = Row.rows(length, first, last)
  raise Authoring::Duplicate if rows.empty?

  girls = rows.map { |row| row.count(Row::GIRL) }.uniq
  raise Authoring::Duplicate if girls.size != 1

  girls = girls.first

  c.q(
    text: "#{length} деца са подредени в редица, като #{Row.ends_text(first, last)}. " \
          "Всяко дете, което не е в края, стои между момиче и момче. " \
          "Попълни колко момичета и колко момчета има в редицата.",
    widget: WidgetKit.blanks([ [ "girls", "момичета", girls ], [ "boys", "момчета", length - girls ] ]),
    hints: [
      "Условието е за съседите на всяко вътрешно дете, значи местата *през едно* се редуват.",
      "Така редицата се разпада на две вериги — една тръгва от левия край, друга от десния.",
      "Проследи всяка верига поотделно и после преброй."
    ],
    explanation: Explain.build(
      idea: "Условието свързва не съседите, а през едно: щом лявото и дясното дете се различават, " \
            "местата през едно се редуват.",
      steps: Row.chain_steps(length, first, last, rows) + [
        "Броим: #{rows.first.map { |value| value == Row::GIRL ? '○' : '●' }.join} " \
        "(○ = момиче, ● = момче) — #{girls} момичета и #{length - girls} момчета."
      ],
      answer: "#{girls} момичета и #{length - girls} момчета",
      check: "#{girls} + #{length - girls} = #{length}#{rows.size > 1 ? ", а и при другата подредба броят е същият" : ''}.",
      watch: "Децата не се редуват едно по едно — редуват се през едно, затова момичетата вървят по двойки."
    )
  )
end

Authoring.family "shade.row_between", topic: "Логически задачи", area: "interactive_kangaroo", variants: 9,
                 rungs: [ 1150, 1300, 1450, 1600, 1750, 1900 ] do |c|
  length = c.pick(c.by_level([ (4..8).select(&:even?), (6..10).select(&:even?), (8..12).select(&:even?),
                               (10..14).select(&:even?), (12..16).select(&:even?), (14..20).select(&:even?) ]))
  first, last = c.pick([ [ Row::BOY, Row::BOY ], [ Row::GIRL, Row::GIRL ], [ Row::BOY, Row::GIRL ] ])
  rows = Row.rows(length, first, last)
  # Shading needs one arrangement and one only.
  raise Authoring::Duplicate unless rows.size == 1

  row = rows.first
  girls = row.each_index.select { |index| row[index] == Row::GIRL }.map { |index| "0,#{index}" }
  raise Authoring::Duplicate if girls.empty? || girls.size == length

  c.q(
    text: "#{length} деца стоят в редица (местата са номерирани отляво надясно) и #{Row.ends_text(first, last)}. " \
          "Всяко дете, което не е в края, стои между момиче и момче. " \
          "Оцвети местата, на които стоят момичетата (#{row.count(Row::GIRL)} на брой).",
    widget: WidgetKit.grid_shade(rows: 1, cols: length, cells: girls),
    hints: [
      "Съседите на всяко вътрешно дете се различават, значи местата през едно се редуват.",
      "Тръгни от двата края наведнъж: всеки край определя своята верига.",
      "Момичетата се оказват по двойки, защото редуването е през едно, а не едно по едно."
    ],
    explanation: Explain.build(
      idea: "Съседите на всяко вътрешно дете се различават, значи местата през едно се редуват — " \
            "две вериги, които тръгват от двата края.",
      steps: Row.chain_steps(length, first, last, rows) + [
        "Подредбата излиза #{row.map { |value| value == Row::GIRL ? '○' : '●' }.join} (○ = момиче): " \
        "момичетата са на места #{row.each_index.select { |i| row[i] == Row::GIRL }.map { |i| i + 1 }.join(', ')}."
      ],
      answer: "места #{row.each_index.select { |i| row[i] == Row::GIRL }.map { |i| i + 1 }.join(', ')}",
      check: "Проверка на едно вътрешно място: съседите му са едно момиче и едно момче.",
      watch: "Момичетата не се редуват през едно с момчетата — иначе вътрешните деца щяха да са между две момичета " \
             "или между две момчета."
    )
  )
end

Authoring.family "pick.row_possible", topic: "Логически задачи", area: "interactive_kangaroo", variants: 9,
                 rungs: [ 1600, 1750, 1900, 2050, 2200, 2350 ] do |c|
  band = c.by_level([ 4..13, 4..17, 6..21, 8..29, 10..41, 12..61 ])
  first = c.pick([ Row::BOY, Row::GIRL ])
  possible = band.select { |length| Row.rows(length, first, first).any? }
  impossible = band.reject { |length| Row.rows(length, first, first).any? }
  raise Authoring::Duplicate if possible.size < 2 || impossible.size < 2

  options = (c.sample(possible, 3) + c.sample(impossible, 2)).sort.map do |length|
    [ length.to_s, possible.include?(length) ]
  end

  c.q(
    text: "Деца стоят в редица, в двата края има #{first == Row::GIRL ? 'момичета' : 'момчета'}, " \
          "а всяко дете, което не е в края, стои между момиче и момче. " \
          "За кои от броевете #{options.map(&:first).join(', ')} е възможна такава редица? Избери всички.",
    widget: WidgetKit.multi_select(options),
    hints: [
      "Местата през едно образуват две редуващи се вериги; възможността зависи само от дължините им.",
      "При четен брой деца двата края попадат в различни вериги и всяка се определя от своя край.",
      "При нечетен брой двата края са в една верига — тя започва и завършва еднакво само при нечетен брой места в нея."
    ],
    explanation: Explain.build(
      idea: "Местата през едно се редуват, затова нечетните места образуват една редуваща се верига, " \
            "а четните — втора. Възможността зависи само от дължините на веригите.",
      steps: [
        "При четен брой деца двата края са в различни вериги и всяка се определя от своя край — винаги става.",
        "При нечетен брой деца двата края са в една и съща верига. Тя се редува, затова започва и завършва " \
        "еднакво само ако има нечетен брой места.",
        "Нечетните места са (n + 1) : 2 — това е нечетно число точно когато n дава остатък 1 при деление на 4.",
        "Затова стават #{options.select(&:last).map(&:first).join(', ')}, а " \
        "#{options.reject(&:last).map(&:first).join(', ')} са невъзможни."
      ],
      answer: options.select(&:last).map(&:first).join(", "),
      check: "Проверка с малък случай: 7 деца с #{first == Row::GIRL ? 'момичета' : 'момчета'} в двата края " \
             "е невъзможно, 9 — възможно.",
      watch: "Невъзможността тук не се вижда с пробване — тя следва от четността на веригата."
    )
  )
end

# ------------------------------------------------------ Възраст с изместване ---
#
# "Their ages add up to 9. How old is Boby, if in 2 years Ani will be 4?" The
# step everybody skips is going *back* from the future age before using the sum.

Authoring.family "logic.age_shift", topic: "Логически задачи", area: "interactive_kangaroo", variants: 9,
                 rungs: [ 1000, 1150, 1300, 1450, 1600, 1750, 1900 ] do |c|
  first, second = c.people(2)
  younger = c.int(c.by_level([ 1..5, 1..8, 2..12, 2..18, 3..30, 4..50, 5..90 ]))
  older = c.int((younger + 1)..(younger + c.by_level([ 6, 10, 15, 25, 40, 70, 120 ])))
  shift = c.int(c.by_level([ 1..3, 1..4, 2..6, 2..9, 3..15, 4..25, 5..40 ]))
  ahead = c.coin
  raise Authoring::Duplicate if !ahead && younger <= shift

  future = ahead ? younger + shift : younger - shift
  total = younger + older

  c.q(
    text: "Сборът от годините на #{first} и #{second} сега е #{total}. " \
          "#{ahead ? "След" : "Преди"} #{count_noun(shift, 'година', 'години')} #{first} " \
          "#{ahead ? 'ще бъде' : 'е била'} на #{future}. Попълни на колко години са сега #{first} и #{second}.",
    widget: WidgetKit.blanks([ [ "a", first, younger ], [ "b", second, older ] ]),
    hints: [
      "#{ahead ? "След" : "Преди"} #{count_noun(shift, 'година', 'години')} не е сега — първо върни възрастта на #{first} към днес.",
      "После извади днешната възраст на #{first} от сбора #{total}."
    ],
    explanation: Explain.build(
      idea: "Първо се връщаме към сегашния момент, чак после се използва сборът.",
      steps: [
        ahead ? "#{first} ще бъде на #{future} след #{count_noun(shift, 'година', 'години')}, значи сега е на #{future} − #{shift} = #{younger}." :
                "#{first} е била на #{future} преди #{count_noun(shift, 'година', 'години')}, значи сега е на #{future} + #{shift} = #{younger}.",
        "Сборът сега е #{total}, затова #{second} е на #{total} − #{younger} = #{older}."
      ],
      answer: "#{first} — #{younger}, #{second} — #{older}",
      check: "#{younger} + #{older} = #{total}, а #{ahead ? "след" : "преди"} #{count_noun(shift, 'година', 'години')} #{first} #{ahead ? "ще е на #{younger + shift}" : "е била на #{younger - shift}"} = #{future}.",
      watch: "Сборът #{total} е за сега — не за #{ahead ? 'след' : 'преди'} #{count_noun(shift, 'година', 'години')}."
    )
  )
end

Authoring.family "logic.age_sum_shift", topic: "Логически задачи", area: "interactive_kangaroo", variants: 9,
                 rungs: [ 1250, 1400, 1550, 1700, 1850, 2000, 2150 ] do |c|
  count = c.by_level([ 2, 2, 3, 3, 4, 4, 5 ])
  people = c.people(count)
  total = c.int(c.by_level([ 8..20, 10..40, 15..70, 20..120, 30..250, 40..500, 60..900 ]))
  shift = c.int(c.by_level([ 2..4, 2..6, 3..8, 3..12, 4..20, 5..30, 6..50 ]))
  future = total + (count * shift)

  c.q(
    text: "Сборът от годините на #{name_list(people)} сега е #{total}. " \
          "Попълни с колко ще се увеличи сборът след #{shift} години и колко ще бъде той тогава.",
    widget: WidgetKit.blanks([ [ "growth", "увеличение", count * shift ], [ "future", "нов сбор", future ] ]),
    hints: [
      "След #{shift} години всеки от тях е с #{shift} години по-стар — а те са #{count}.",
      "Затова сборът расте по веднъж за всеки човек, не с #{shift} общо."
    ],
    explanation: Explain.build(
      idea: "След #{shift} години *всеки* от тях е с #{shift} години повече, затова сборът расте #{count} пъти по #{shift}.",
      steps: [
        "Хората са #{count}, всеки печели #{shift} години: #{count} · #{shift} = #{count * shift}.",
        "#{total} + #{count * shift} = #{future}."
      ],
      answer: "с #{count * shift} повече, тоест #{future}",
      check: "Обратно: #{future} − #{count * shift} = #{total}.",
      watch: "Сборът не расте с #{shift}, а с #{count} · #{shift} — по веднъж за всеки човек."
    )
  )
end

# ------------------------------------------------- Най-много покупки в бюджет ---

Authoring.family "logic.max_items_budget", topic: "Текстови задачи", area: "interactive_kangaroo", variants: 9,
                 rungs: [ 1150, 1300, 1450, 1600, 1750, 1900, 2050 ] do |c|
  kinds = c.int(c.by_level([ 4..5, 4..6, 5..7, 5..8, 6..9, 6..10, 7..12 ]))
  prices = (1..kinds).to_a
  prices = prices.map { |price| price * c.int(1..2) }.uniq.sort if c.level >= 3
  raise Authoring::Duplicate if prices.size < 4

  small_coins = c.int(1..4)
  big_coin = c.pick([ 2, 5 ])
  big_coins = c.int(1..c.by_level([ 3, 4, 5, 6, 8, 10, 14 ]))
  budget = small_coins + (big_coin * big_coins)
  bought = (0..prices.size).select { |count| prices.first(count).sum <= budget }.max
  raise Authoring::Duplicate if bought < 2 || bought == prices.size

  spent = prices.first(bought).sum

  c.q(
    text: "#{c.person} разполага с #{small_coins} #{small_coins == 1 ? 'монета' : 'монети'} по 1 лев и " \
          "#{big_coins} #{big_coins == 1 ? 'монета' : 'монети'} по #{big_coin} лева. В магазина се продават " \
          "#{prices.size} различни вида шоколад на цени #{prices.join(', ')} лева. " \
          "Попълни най-големия брой различни шоколада, които може да купи, и колко лева ще му останат.",
    widget: WidgetKit.blanks([ [ "count", "шоколада", bought ], [ "left", "остават", budget - spent, "лв." ] ]),
    hints: [
      "Първо пресметни парите: #{small_coins} · 1 + #{big_coins} · #{big_coin} лева.",
      "За най-много на брой се взимат най-евтините — подреди цените и добавяй, докато парите стигат.",
      "Спри на първата цена, която не се вмества, и виж какво остава."
    ],
    explanation: Explain.build(
      idea: "За да са най-много на брой, се вземат най-евтините — всяка по-скъпа замяна само отнема пари.",
      steps: [
        "Пари: #{small_coins} · 1 + #{big_coins} · #{big_coin} = #{budget} лв.",
        "Най-евтините #{bought}: #{prices.first(bought).join(' + ')} = #{spent} лв. ≤ #{budget} лв.",
        "Още един (#{prices[bought]} лв.) прави #{spent + prices[bought]} лв. — над парите, затова #{bought} е максимумът.",
        "Остават #{budget} − #{spent} = #{budget - spent} лв."
      ],
      answer: "#{bought} шоколада, остават #{budget - spent} лв.",
      check: "#{spent} + #{budget - spent} = #{budget} лв.",
      watch: "Търси се брой, не стойност — най-скъпите шоколади дават по-малко на брой за същите пари."
    )
  )
end

Authoring.family "pick.affordable_sets", topic: "Текстови задачи", area: "interactive_kangaroo", variants: 9,
                 rungs: [ 1300, 1450, 1600, 1750, 1900, 2050 ] do |c|
  prices = (1..c.int(c.by_level([ 5..6, 5..7, 6..8, 6..9, 7..10, 8..12 ]))).to_a
  budget = c.int(c.by_level([ 6..10, 8..14, 10..20, 12..28, 15..40, 20..60 ]))
  sets = []
  14.times do
    size = c.int(2..[ prices.size, 5 ].min)
    set = c.sample(prices, size).sort
    sets << set unless sets.include?(set)
  end
  affordable = sets.select { |set| set.sum <= budget }.first(3)
  too_dear = sets.select { |set| set.sum > budget }.first(2)
  raise Authoring::Duplicate if affordable.size < 2 || too_dear.size < 2

  options = (affordable + too_dear).map { |set| [ set.join(" + "), affordable.include?(set) ] }

  c.q(
    text: "#{c.person} има #{budget} лева, а шоколадите струват #{prices.join(', ')} лева " \
          "(по един от всеки вид). Кои от покупките може да си позволи? Избери всички.",
    widget: WidgetKit.multi_select(options),
    hints: [
      "Всяка покупка се проверява поотделно: събери цените в нея и сравни с #{budget} лева.",
      "Повече шоколади не значи по-скъпо — решава сборът на цените, не броят им."
    ],
    explanation: Explain.build(
      idea: "Всяка покупка се проверява поотделно: сборът на цените срещу парите.",
      steps: [
        affordable.map { |set| "#{set.join(' + ')} = #{set.sum} ≤ #{budget}" }.join("; ") + " — стигат.",
        too_dear.map { |set| "#{set.join(' + ')} = #{set.sum} > #{budget}" }.join("; ") + " — не стигат."
      ],
      answer: affordable.map { |set| set.join(" + ") }.join(" | "),
      check: "Най-скъпата достъпна покупка тук е #{affordable.max_by(&:sum).sum} лв. от #{budget} лв.",
      watch: affordable.map(&:size).max > too_dear.map(&:size).min ?
        "Повече шоколада не значи по-скъпо: #{affordable.max_by(&:size).join(' + ')} " \
        "(#{affordable.max_by(&:size).size} броя) е по-евтино от #{too_dear.min_by(&:size).join(' + ')} " \
        "(#{too_dear.min_by(&:size).size} броя)." :
        "Броят на шоколадите не решава — важен е сборът на цените."
    )
  )
end

Authoring.family "pick.exact_payment", topic: "Логически задачи", area: "interactive_kangaroo", variants: 9,
                 rungs: [ 1250, 1400, 1550, 1700, 1850, 2000 ] do |c|
  # Coin sets deliberately without a 1, so some amounts cannot be paid exactly.
  coins = c.by_level([
    [ 2, 2, 5 ], [ 2, 2, 5, 5 ], [ 2, 5, 5, 10 ], [ 5, 5, 10, 20 ], [ 2, 2, 10, 20, 50 ], [ 5, 10, 10, 20, 50 ]
  ])
  reachable = coins.each_with_object([ 0 ]) { |coin, sums| sums.concat(sums.map { |sum| sum + coin }) }.uniq.sort
  payable = reachable.reject(&:zero?)
  unpayable = (1..coins.sum).to_a - payable
  raise Authoring::Duplicate if payable.size < 3 || unpayable.size < 2

  options = (c.sample(payable, 3) + c.sample(unpayable, 2)).sort.map { |amount| [ "#{amount} лв.", payable.include?(amount) ] }

  c.q(
    text: "#{c.person} има монети #{coins.map { |coin| "#{coin} лв." }.join(', ')} и не получава ресто. " \
          "Кои от сумите може да плати точно? Избери всички.",
    widget: WidgetKit.multi_select(options),
    hints: [
      "Точно плащане значи, че сумата е сбор на част от монетите — ресто няма.",
      "Всички монети заедно правят #{coins.sum} лв., значи по-голяма сума е невъзможна.",
      "Тук няма монета от 1 лев, затова и някои по-малки суми не се събират."
    ],
    explanation: Explain.build(
      idea: "Точно плащане значи, че сумата е сбор на част от монетите — проверяваме кои сборове са възможни.",
      steps: [
        "Възможните сборове са #{payable.join(', ')}.",
        "Останалите суми не се получават от никоя част от монетите — например " \
        "#{unpayable.first} лв. няма как да се събере от #{coins.join(', ')}."
      ],
      answer: options.select(&:last).map(&:first).join(", "),
      check: "Всички монети заедно правят #{coins.sum} лв. — най-голямата възможна сума.",
      watch: "Без монета от 1 лев не всяка сума е достижима, дори да е по-малка от парите в джоба."
    )
  )
end

# ------------------------------------- Броене на пътища в стълбовидна фигура ---

STAIRCASE_LADDER = [ 1150, 1280, 1410, 1540, 1670, 1800, 1930 ].freeze
STAIRCASE_TABLE_LADDER = [ 1050, 1180, 1310, 1440, 1570 ].freeze
STAIRCASE_MOVES_LADDER = [ 1200, 1330, 1460, 1590, 1720, 1850 ].freeze

# A figure of unit squares, left aligned and never narrowing downwards, with А
# in the top-left square and Б in the bottom-right one; the kangaroo walks from
# square to square only right and down.
#
# Two ways into a square (from above, from the left) is the whole method: the
# paths into a square are the sum of the paths into those two, and a square
# outside the figure — or a crossed-out one — contributes nothing. The builder
# computes the count twice, once by that table and once by walking every path,
# and drops the variant if the two disagree: with a hole in the staircase there
# is no binomial coefficient to fall back on, so the table is a solver and a
# solver gets checked.
module Staircase
  ROW_IN = [ "в първия", "във втория", "в третия", "в четвъртия", "в петия" ].freeze
  ROW_OF = %w[първия втория третия четвъртия петия].freeze
  ROW_NOM = %w[Първи Втори Трети Четвърти Пети].freeze
  COL_OF = %w[първата втората третата четвъртата петата шестата].freeze

  Region = Struct.new(:widths, :blocked) do
    def rows = widths.size
    def cols = widths.max
    def target = [ rows - 1, widths.last - 1 ]

    # Every path has the same length: the figure is walked once across and once
    # down, whichever order the steps come in.
    def moves = (rows - 1) + (widths.last - 1)

    def present?(row, col) = row.between?(0, rows - 1) && col.between?(0, widths[row] - 1)
    def inside?(row, col) = present?(row, col) && !blocked.include?([ row, col ])

    # How many paths reach each square — the table the explanation walks through.
    def table
      counts = Array.new(rows) { Array.new(cols, 0) }
      rows.times do |row|
        widths[row].times do |col|
          next unless inside?(row, col)

          counts[row][col] = if [ row, col ] == [ 0, 0 ]
                               1
          else
                               (inside?(row - 1, col) ? counts[row - 1][col] : 0) +
                                 (inside?(row, col - 1) ? counts[row][col - 1] : 0)
          end
        end
      end
      counts
    end

    def count = table.dig(*target)

    def paths_into(square)
      row, col = square
      [ inside?(row - 1, col) ? table[row - 1][col] : 0, inside?(row, col - 1) ? table[row][col - 1] : 0 ]
    end

    # The same number the long way round: every path, walked. Small figures, so
    # this costs nothing and it is the check on the table.
    def all_paths(at = [ 0, 0 ], trail = [ [ 0, 0 ] ], found = [])
      return found << trail if at == target

      [ [ at[0], at[1] + 1 ], [ at[0] + 1, at[1] ] ].each do |step|
        all_paths(step, trail + [ step ], found) if inside?(*step)
      end
      found
    end

    def turns(path) = path.each_cons(3).count { |a, _, c| a[0] != c[0] && a[1] != c[1] }

    def row_words = rows.times.map { |row| "#{ROW_IN[row]} — #{widths[row]}" }.join(", ")

    def blocked_words
      blocked.map { |row, col| "#{ROW_OF[row]} ред и #{COL_OF[col]} колона" }.join("; ")
    end
  end

  module_function

  # Draws a figure for a rung. Widths never narrow downwards, so Б exists and is
  # reachable; above the bottom rung the figure has a real step in it, because a
  # rectangle's answer is a binomial coefficient rather than a piece of
  # reasoning; and the count has to land in the band this rung asks for — two
  # paths is not a question, and nobody verifies a hundred and fifty.
  # `min_last` is what keeps a rung's figures out of the rung below's: two rungs
  # drawing from the same space of shapes would produce the same texts, and the
  # importer keys questions by their text, so the upper rung would come out
  # empty rather than merely repetitive.
  def region_for(context, rows:, max_width:, band:, holes: 0, stepped: true, min_last: 3)
    widths = []
    rows.times { widths << context.int((widths.last || 2)..max_width) }
    raise Authoring::Duplicate if widths.last < min_last || (stepped && widths.uniq.size == 1)

    # A hole in the first or the last row would only shorten the figure, and one
    # in the left column would break the column of 1s the method starts from —
    # so it sits strictly inside, where a path might have wanted to go.
    inner = (1...(rows - 1)).flat_map { |row| (1...widths[row]).map { |col| [ row, col ] } }
    raise Authoring::Duplicate if inner.size < holes

    region = Region.new(widths, holes.zero? ? [] : context.sample(inner, holes).sort)
    raise Authoring::Duplicate unless band.cover?(region.count)
    raise Authoring::Duplicate unless region.count == region.all_paths.size

    region
  end

  # One path to draw in, the way the sheet prints one: a zigzag if the figure
  # has one, because a path that only turns once teaches the wrong lesson.
  def example_path(context, region)
    paths = region.all_paths
    bendy = paths.select { |path| region.turns(path) >= 2 }
    context.pick(bendy.empty? ? paths : bendy)
  end

  def story(region)
    blocked = region.blocked.empty? ? "" : "Зачертаното квадратче (#{region.blocked_words}) е заето " \
                                           "и през него не се минава. "
    "Фигурата е съставена от квадратчета, подравнени отляво: #{region.row_words}. Кенгурчето е в " \
      "квадратчето А (горе вляво), а майка му — в квадратчето Б (долу вдясно). #{blocked}Кенгурчето се движи " \
      "от квадратче в квадратче само надясно и надолу."
  end

  # The table, read out row by row: the steps of the worked solution.
  def table_steps(region)
    counts = region.table
    region.rows.times.map do |row|
      values = region.widths[row].times.map { |col| region.inside?(row, col) ? counts[row][col] : "×" }
      "#{ROW_NOM[row]} ред: #{values.join(', ')}."
    end
  end

  def method_steps(region)
    [ "В А записваме 1. По горния ред и по лявата колона се стига само по един път, значи там навсякъде е 1." ] +
      table_steps(region) +
      [ region.blocked.empty? ? nil : "Заетото квадратче се брои за 0 и не пуска път напред, затова " \
                                      "квадратче, до което се стига само през него, също остава 0." ]
  end

  # Б usually has no square above it — the row above is narrower, which is what
  # makes the figure a staircase — so the check has to say that rather than
  # quietly add a zero the student cannot see.
  def check_line(region)
    above, left = region.paths_into(region.target)
    row, col = region.target

    if !region.present?(row - 1, col)
      "Над Б няма квадратче от фигурата, затова в Б се влиза само отляво: #{left} пътя."
    elsif !region.inside?(row - 1, col)
      "Квадратчето над Б е заето, затова в Б се влиза само отляво: #{left} пътя."
    else
      "Числото в Б е сборът на числото над него (#{above}) и числото вляво от него (#{left}): " \
        "#{above} + #{left} = #{region.count}."
    end
  end

  def hint_ladder
    [ "В едно квадратче се влиза само от горното или от лявото съседно квадратче — друг път навътре няма.",
      "Напиши в А единица и попълни целия горен ред и цялата лява колона: дотам се стига само по един път.",
      "После попълвай ред по ред — във всяко квадратче сборът на числото отгоре и числото отляво. " \
      "Квадратче извън фигурата или зачертано дава нула." ]
  end
end

Authoring.family "paths.staircase", topic: "Броене и комбинаторика", area: "interactive_kangaroo", variants: 6,
                 rungs: STAIRCASE_LADDER do |c|
  region = Staircase.region_for(
    c,
    rows: c.by_level([ 2, 3, 3, 4, 4, 4, 5 ]),
    max_width: c.by_level([ 6, 4, 5, 5, 6, 6, 6 ]),
    min_last: c.by_level([ 3, 3, 5, 4, 6, 4, 5 ]),
    holes: c.by_level([ 0, 0, 0, 0, 0, 1, 1 ]),
    band: c.by_level([ 3..6, 4..15, 6..30, 8..45, 12..80, 8..60, 15..130 ]),
    stepped: !c.bottom?
  )
  # The bottom rungs print one path in, as the competition sheet does: it says
  # what "a path" means without saying how many there are.
  shown = c.level <= 1 ? Staircase.example_path(c, region) : nil

  c.q(
    text: "#{Staircase.story(region)} #{shown ? 'Показан е един от възможните пътища. ' : ''}" \
          "По колко различни пътя може да стигне до майка си?",
    answer: Num.ans(region.count),
    figure: Figures.staircase_grid(widths: region.widths, blocked: region.blocked, path: shown),
    hints: Staircase.hint_ladder,
    explanation: Explain.build(
      idea: "В едно квадратче се влиза само отгоре или отляво, затова пътищата до него са сбор от пътищата " \
            "до тези две квадратчета.",
      steps: Staircase.method_steps(region),
      answer: "#{region.count} различни пътя",
      check: Staircase.check_line(region),
      watch: "Всеки път е от #{region.moves} хода — това число е едно и също за всички пътища и не е " \
             "отговорът. Пътищата се събират, не се умножават."
    )
  )
end

# The same type with the table itself as the answer: the method made visible,
# for the rungs where the grid still fits the widget (at most 5x5, at most eight
# blanks — beyond that filling it in stops being mathematics).
Authoring.family "paths.staircase_table", topic: "Броене и комбинаторика", area: "interactive_kangaroo", variants: 6,
                 rungs: STAIRCASE_TABLE_LADDER do |c|
  region = Staircase.region_for(
    c,
    rows: c.by_level([ 3, 3, 4, 3, 4 ]),
    max_width: c.by_level([ 4, 5, 4, 5, 4 ]),
    min_last: c.by_level([ 3, 5, 4, 4, 4 ]),
    holes: c.by_level([ 0, 0, 0, 1, 1 ]),
    band: c.by_level([ 3..12, 4..20, 6..30, 4..30, 4..30 ]),
    stepped: true
  )
  counts = region.table
  shown = Array.new(region.rows) do |row|
    Array.new(region.cols) do |col|
      # Everything outside the figure, and the crossed-out square, is a 0 the
      # student is given; the first row and the first column are the 1s the
      # method starts from; the rest is theirs to fill.
      if !region.inside?(row, col) then 0
      elsif row.zero? || col.zero? then counts[row][col]
      end
    end
  end
  blanks = shown.sum { |row| row.count(nil) }
  raise Authoring::Duplicate unless (4..8).cover?(blanks)

  c.q(
    text: "#{Staircase.story(region)} В таблицата е започнато броенето: където се стига само по един път, " \
          "е записано 1, а извън фигурата — 0. Попълни останалите квадратчета — във всяко напиши по колко " \
          "различни пътя стига кенгурчето до него.",
    widget: WidgetKit.grid_fill(rows: shown, answers: counts),
    figure: Figures.staircase_grid(widths: region.widths, blocked: region.blocked),
    hints: Staircase.hint_ladder,
    explanation: Explain.build(
      idea: "Всяко квадратче получава сбора на числата в квадратчето отгоре и в квадратчето отляво — " \
            "това са единствените два входа към него.",
      steps: Staircase.method_steps(region),
      answer: "в Б — #{region.count} пътя",
      check: Staircase.check_line(region),
      watch: region.blocked.empty? ?
        "Празно квадратче не значи нула — нула стои само извън фигурата. Числата растат надолу и надясно." :
        "Нула стои извън фигурата, в заетото квадратче — и в квадратче, до което се стига само през " \
        "заетото. Такова квадратче е празно в таблицата, но отговорът за него е 0."
    )
  )
end

# Paths and moves in one problem, because "по колко пътя" and "по колко хода" is
# the confusion this type is built on: the number of moves is the same for every
# path, and it is not the answer.
Authoring.family "paths.staircase_moves", topic: "Броене и комбинаторика", area: "interactive_kangaroo", variants: 6,
                 rungs: STAIRCASE_MOVES_LADDER do |c|
  region = Staircase.region_for(
    c,
    rows: c.by_level([ 2, 3, 3, 4, 4, 5 ]),
    max_width: c.by_level([ 6, 4, 5, 5, 6, 6 ]),
    min_last: c.by_level([ 3, 3, 5, 4, 5, 5 ]),
    holes: c.by_level([ 0, 0, 0, 0, 1, 1 ]),
    band: c.by_level([ 3..6, 4..15, 6..30, 10..60, 8..60, 15..130 ]),
    stepped: !c.bottom?
  )

  c.q(
    text: "#{Staircase.story(region)} Попълни по колко различни пътя може да стигне до майка си и от " \
          "колко хода се състои всеки такъв път.",
    widget: WidgetKit.blanks([ [ "paths", "различни пътища", region.count ],
                              [ "moves", "хода в един път", region.moves ] ]),
    figure: Figures.staircase_grid(widths: region.widths, blocked: region.blocked),
    hints: Staircase.hint_ladder +
           [ "Ходовете са едни и същи за всеки път: толкова надясно, колкото са колоните без една, и " \
             "толкова надолу, колкото са редовете без един." ],
    explanation: Explain.build(
      idea: "Двете числа се намират по различен начин: пътищата се събират квадратче по квадратче, а " \
            "ходовете се броят наведнъж.",
      steps: Staircase.method_steps(region) +
             [ "Ходове: #{region.widths.last - 1} надясно и #{region.rows - 1} надолу правят " \
               "#{region.widths.last - 1} + #{region.rows - 1} = #{region.moves} хода, и то за всеки път." ],
      answer: "#{region.count} пътя, всеки от #{region.moves} хода",
      check: Staircase.check_line(region),
      watch: "Броят на ходовете е един и същ за всички пътища — затова той не може да е отговорът на " \
             "въпроса колко са пътищата."
    )
  )
end

# ------------------------------------------ Махнати квадратчета от квадрат ---

# The punched square from the competition sheet: a square cut into n x n little
# squares with a piece of it taken away, and the question is how many little
# squares are gone. The missing ones are not drawn — only a dashed outline says
# how big the square was — so the problem is not a count but a choice between
# two counts: the holes, against a grid the student has to impose themselves, or
# what is left, subtracted from n². The second is the method worth learning, and
# the wrong answer the type is built to catch is the number of shaded squares.
PUNCHED_LADDER = [ 700, 820, 940, 1060, 1180, 1310 ].freeze

# The same pictures, asked as two boxes instead of one number, which walks the
# student through the method rather than only marking the end of it — so the
# same grid sits a rung lower.
PUNCHED_PARTS_LADDER = [ 660, 780, 900, 1020, 1140, 1260 ].freeze

module PunchedSquare
  # Long form for the first mention, counting form, definite form. All feminine
  # or neuter, so the plural after a number is the plural — a masculine noun
  # would need "3 стикера" beside "стикерите" and buys nothing here.
  PIECES = [
    [ "еднакви малки квадратчета", "квадратчета", "квадратчетата" ],
    [ "еднакви квадратни плочки", "плочки", "плочките" ],
    [ "еднакви квадратни листчета", "листчета", "листчетата" ],
    [ "еднакви квадратни картончета", "картончета", "картончетата" ],
    [ "еднакви квадратни марки", "марки", "марките" ],
    [ "еднакви квадратни лепенки", "лепенки", "лепенките" ]
  ].freeze

  SIZES = [ 3, 4, 4, 5, 5, 6 ].freeze
  HOLES = [ 2..4, 4..6, 6..9, 9..12, 12..15, 15..21 ].freeze

  Region = Struct.new(:size, :kept, :gone, keyword_init: true) do
    def total = size * size
    def kept_by_row = (0...size).map { |row| kept.count { |r, _| r == row } }
    def gone_by_row = (0...size).map { |row| gone.count { |r, _| r == row } }
  end

  module_function

  def region_for(c, size:, holes:)
    cells = (0...size).to_a.product((0...size).to_a)
    gone = c.sample(cells, c.int(holes)).sort
    rows_hit = gone.map(&:first).uniq
    cols_hit = gone.map(&:last).uniq

    # Holes down one row or one column read as a stripe and can be counted
    # without imposing the grid; holes filling a rectangle make the answer a
    # multiplication. Both are rejected rather than shipped as an easy variant.
    raise Authoring::Duplicate if rows_hit.size < 2 || cols_hit.size < 2
    raise Authoring::Duplicate if gone.size == (rows_hit.max - rows_hit.min + 1) * (cols_hit.max - cols_hit.min + 1)
    # And at least one hole has to reach an edge, or the dashed outline is
    # decoration: the shape's own bounding box would already give the size away.
    raise Authoring::Duplicate unless gone.any? { |row, col| [ row, col ].include?(0) || [ row, col ].include?(size - 1) }

    Region.new(size: size, kept: cells - gone, gone: gone)
  end

  # The grid over the empty part is scaffolding, so it goes away after the
  # second rung — from there on the dashed contour is the only witness that a
  # row with nothing left in it is still a row of the square.
  def figure_for(c, region) = Figures.punched_square(size: region.size, kept: region.kept, guides: c.level <= 1)

  def method_steps(region)
    [ "Целият квадрат: #{region.size} реда по #{region.size} квадратчета правят " \
      "#{region.size} · #{region.size} = #{region.total}.",
      "Останали са оцветените — по редове отгоре надолу: #{region.kept_by_row.join(' + ')} = #{region.kept.size}.",
      "Махнати са тези, които не достигат до #{region.total}: #{region.total} − #{region.kept.size} = " \
      "#{region.gone.size}." ]
  end

  # The method with no number of its own in it: what to look at, how to count it
  # without losing your place, and only then the subtraction.
  def hint_ladder(region)
    [ "Махнатите не са начертани — пунктираният контур показва докъде е стигал целият квадрат.",
      "Преброй оцветените ред по ред, за да не пропуснеш нито едно и да не броиш едно два пъти. " \
      "Целият квадрат има #{region.total} квадратчета.",
      "Махнатите са толкова, колкото не достигат: извади преброените оцветени от #{region.total}." ]
  end
end

Authoring.family "count.punched_square", topic: "Броене и комбинаторика", area: "interactive_kangaroo", variants: 8,
                 rungs: PUNCHED_LADDER do |c|
  region = PunchedSquare.region_for(c, size: c.by_level(PunchedSquare::SIZES), holes: c.by_level(PunchedSquare::HOLES))
  size = region.size
  total = region.total
  long, short, definite = c.pick(PunchedSquare::PIECES)

  c.q(
    text: c.pick([
      "Голям квадрат е съставен от #{total} #{long}, наредени #{size} по #{size}. Част от тях са махнати, " \
      "а на чертежа са оцветени само останалите. Колко #{short} са махнати?",
      "На чертежа са оцветени #{definite}, които са останали от квадрат, съставен от #{total} #{long} в " \
      "#{size} реда по #{size}. Колко #{short} са махнати от квадрата?",
      "Квадрат е направен от #{total} #{long} — #{size} реда по #{size}. Част от тях са махнати; оцветените " \
      "на чертежа са останалите. Колко #{short} са махнати?",
      "Оцветените на чертежа #{short} са останали от квадрат, съставен от #{total} #{long} — #{size} реда " \
      "по #{size}. Колко #{short} са махнати от него?"
    ]),
    answer: Num.ans(region.gone.size),
    figure: PunchedSquare.figure_for(c, region),
    hints: PunchedSquare.hint_ladder(region),
    explanation: Explain.build(
      idea: "Махнатите квадратчета не се виждат, затова се броят наопаки: колко са всичките и колко са " \
            "останали — разликата са махнатите.",
      steps: PunchedSquare.method_steps(region),
      answer: "#{region.gone.size} #{short}",
      check: "Ако дупките се преброят направо, по редове се получава #{region.gone_by_row.join(' + ')} = " \
             "#{region.gone.size} — същото число.",
      watch: "Оцветените са #{region.kept.size}, но въпросът не е за тях. И ред, от който не е останало нищо, " \
             "си остава ред от квадрата — пунктираната линия го показва."
    )
  )
end

# The same type with both counts asked for, the way paths.staircase_moves asks
# for the paths and the moves: the two boxes are the method made visible, and
# they give the student the check the single number cannot — the two of them have
# to add up to the whole square.
Authoring.family "count.punched_square_parts", topic: "Броене и комбинаторика", area: "interactive_kangaroo",
                 variants: 8, rungs: PUNCHED_PARTS_LADDER do |c|
  region = PunchedSquare.region_for(c, size: c.by_level(PunchedSquare::SIZES), holes: c.by_level(PunchedSquare::HOLES))
  size = region.size
  total = region.total
  long, short, definite = c.pick(PunchedSquare::PIECES)

  c.q(
    text: c.pick([
      "Голям квадрат е съставен от #{total} #{long}, наредени #{size} по #{size}. Част от тях са махнати, " \
      "а на чертежа са оцветени само останалите. Попълни колко #{short} са останали и колко са махнати.",
      "На чертежа са оцветени #{definite}, които са останали от квадрат, съставен от #{total} #{long} в " \
      "#{size} реда по #{size}. Попълни колко #{short} са останали и колко са махнати.",
      "Квадрат е направен от #{total} #{long} — #{size} реда по #{size}. Част от тях са махнати; оцветените " \
      "на чертежа са останалите. Попълни колко #{short} са останали и колко са махнати.",
      "Оцветените на чертежа #{short} са останали от квадрат, съставен от #{total} #{long} — #{size} реда " \
      "по #{size}. Попълни колко са останали и колко са махнати."
    ]),
    widget: WidgetKit.blanks([ [ "kept", "останали", region.kept.size ],
                              [ "gone", "махнати", region.gone.size ] ]),
    figure: PunchedSquare.figure_for(c, region),
    hints: PunchedSquare.hint_ladder(region),
    explanation: Explain.build(
      idea: "Едното число се брои, другото се изважда: оцветените се преброяват, а махнатите са тези, които " \
            "не достигат до целия квадрат.",
      steps: PunchedSquare.method_steps(region),
      answer: "останали #{region.kept.size}, махнати #{region.gone.size}",
      check: "#{region.kept.size} + #{region.gone.size} = #{total} — двете числа заедно трябва да дават " \
             "целия квадрат.",
      watch: "Ако сборът на двете числа не е #{total}, някое квадратче е преброено два пъти или е пропуснато — " \
             "най-често в ред, от който не е останало нищо."
    )
  )
end

# ------------------------------------------- Слепени кубчета: коя не става ---

# Two little constructions of glued unit cubes are given — one of 3 cubes, one
# of 2 — and five bodies are drawn below them: which one cannot be built by
# putting the two together? The type is spatial, not arithmetic: every body has
# the same number of cubes, so counting decides nothing and the student has to
# look for the *cut*, two adjacent cubes whose removal leaves exactly the bigger
# piece.
#
# The builder needs a solver rather than a formula, and it is the honest kind:
# it assembles the two pieces in every orientation and every glued position and
# collects what comes out, so "cannot be built" means the enumeration never
# built it.
module Cubes
  # The 24 rotations of the cube: axis permutations with determinant +1.
  # Reflections are deliberately absent — a physical piece can be turned, not
  # mirrored. (A *planar* piece is mirrored by a 3D rotation anyway, which is
  # why the pieces here are all flat: it keeps the set of buildable bodies
  # closed under mirroring, so no body is impossible merely for being the wrong
  # way round — that would be a trap about handedness, not about assembly.)
  ROTATIONS = [ 0, 1, 2 ].permutation.flat_map { |perm|
    [ 1, -1 ].product([ 1, -1 ], [ 1, -1 ]).map { |signs| [ perm, signs ] }
  }.select { |perm, signs|
    inversions = perm.each_with_index.sum { |value, index| (0...index).count { |j| perm[j] > value } }
    signs.reduce(:*) * (inversions.even? ? 1 : -1) == 1
  }.freeze

  NEIGHBOURS = [ [ 1, 0, 0 ], [ -1, 0, 0 ], [ 0, 1, 0 ], [ 0, -1, 0 ], [ 0, 0, 1 ], [ 0, 0, -1 ] ].freeze

  PIECES = {
    2 => [ [ 0, 0, 0 ], [ 1, 0, 0 ] ],                                     # двойка
    3 => [ [ 0, 0, 0 ], [ 1, 0, 0 ], [ 1, 1, 0 ] ],                        # ъгъл
    4 => [ [ 0, 0, 0 ], [ 1, 0, 0 ], [ 2, 0, 0 ], [ 2, 1, 0 ] ]            # Г-образна от 4
  }.freeze

  # What the pieces are called in the question, so the stem and the explanation
  # can name them instead of describing coordinates.
  NAMES = { 2 => "двойката", 3 => "ъгъла", 4 => "Г-образната фигура" }.freeze
  SUBJECTS = { 2 => "двойката", 3 => "ъгълът", 4 => "Г-образната фигура" }.freeze
  SHAPES = { 2 => "две кубчета едно до друго", 3 => "ъгъл от 3 кубчета",
             4 => "Г-образна фигура от 4 кубчета" }.freeze

  module_function

  def rotate(cell, rotation)
    perm, signs = rotation
    3.times.map { |axis| cell[perm[axis]] * signs[axis] }
  end

  def to_origin(cells)
    mins = 3.times.map { |axis| cells.map { |cell| cell[axis] }.min }
    cells.map { |cell| 3.times.map { |axis| cell[axis] - mins[axis] } }
  end

  # One name per body, so two drawings of the same construction are recognised
  # as the same construction.
  def canon(cells)
    @canons ||= {}
    @canons[cells] ||= orientations(cells).min
  end

  def orientations(cells)
    ROTATIONS.map { |rotation| to_origin(cells.map { |cell| rotate(cell, rotation) }).sort }.uniq
  end

  def mirror(cells) = canon(cells.map { |x, y, z| [ -x, y, z ] })

  def flat?(cells) = 3.times.any? { |axis| cells.map { |cell| cell[axis] }.uniq.size == 1 }

  def bbox(cells) = 3.times.map { |axis| cells.map { |cell| cell[axis] }.minmax.then { |lo, hi| hi - lo + 1 } }.sort

  def connected?(cells)
    seen = [ cells.first ]
    queue = [ cells.first ]
    until queue.empty?
      cell = queue.shift
      NEIGHBOURS.each do |step|
        nb = [ cell[0] + step[0], cell[1] + step[1], cell[2] + step[2] ]
        next unless cells.include?(nb) && !seen.include?(nb)

        seen << nb
        queue << nb
      end
    end
    seen.size == cells.size
  end

  # The orientation the figure is drawn in: no cube may be hidden (a cube whose
  # +x, +y and +z neighbours are all present shows none of its three visible
  # faces and disappears from the picture, and a body the reader cannot count is
  # not a question). Among the honest orientations, the one lying flattest with
  # the most cubes on the ground, so the bodies stand rather than float.
  def display(cells)
    @displays ||= {}
    key = canon(cells)
    return @displays[key] if @displays.key?(key)

    honest = orientations(cells).select { |shape| Figures.hidden_cubes(shape).zero? }
    @displays[key] =
      honest.min_by { |shape| [ shape.map { |cell| cell[2] }.max, -shape.count { |cell| cell[2].zero? }, shape ] }
  end

  # Every body that can be built, found by gluing: piece B is placed so that one
  # of its cubes lands on a face neighbour of one of A's cubes, which is exactly
  # what "glued along a whole face" means, and covers every possible assembly.
  def buildable(small, big)
    @buildable ||= {}
    @buildable[[ small, big ]] ||= begin
      a = PIECES[big]
      found = {}
      touching = a.flat_map { |cell| NEIGHBOURS.map { |step| [ cell[0] + step[0], cell[1] + step[1], cell[2] + step[2] ] } }
                  .uniq.reject { |cell| a.include?(cell) }
      orientations(PIECES[small]).each do |b|
        b.each do |anchor|
          touching.each do |target|
            shift = [ target[0] - anchor[0], target[1] - anchor[1], target[2] - anchor[2] ]
            moved = b.map { |x, y, z| [ x + shift[0], y + shift[1], z + shift[2] ] }
            next if moved.any? { |cell| a.include?(cell) }

            found[canon(a + moved)] = true
          end
        end
      end
      found.keys
    end
  end

  # Bodies of the same size that cannot be built, grown at random and sieved.
  # The growth is seeded from the sizes alone, so the pool is the same on every
  # rebuild; a family draws from it with its own rung's RNG.
  def unbuildable(small, big)
    @unbuildable ||= {}
    @unbuildable[[ small, big ]] ||= begin
      can = buildable(small, big).to_h { |shape| [ shape, true ] }
      rng = Random.new(90_000 + (small * 100) + big)
      found = {}
      1200.times do
        cells = [ [ 0, 0, 0 ] ]
        while cells.size < small + big
          cell = cells[rng.rand(cells.size)]
          step = NEIGHBOURS[rng.rand(6)]
          nb = [ cell[0] + step[0], cell[1] + step[1], cell[2] + step[2] ]
          cells << nb unless cells.include?(nb)
        end
        shape = canon(cells)
        found[shape] = true unless can.key?(shape)
      end
      found.keys
    end
  end

  # Where the smaller piece can sit inside a body, and what is left when it is
  # lifted out: the whole method, and the whole explanation.
  def cuts(body, small, big)
    # Every placement of the small piece inside the body has its first cube on
    # some cube of the body, so anchoring there finds them all — and looks at a
    # couple of hundred positions rather than a lattice full of them.
    placements = orientations(PIECES[small]).flat_map do |piece|
      body.map do |cell|
        shift = [ cell[0] - piece[0][0], cell[1] - piece[0][1], cell[2] - piece[0][2] ]
        piece.map { |x, y, z| [ x + shift[0], y + shift[1], z + shift[2] ] }
      end
    end
    fits = placements.select { |piece| piece.all? { |cell| body.include?(cell) } }.uniq { |piece| piece.sort }
    fits.map do |piece|
      rest = body - piece
      verdict =
        if !connected?(rest) then :split
        elsif canon(rest) == canon(PIECES[big]) then :fits
        else :other
        end
      [ piece, verdict ]
    end
  end

  def cut_tally(body, small, big)
    @tallies ||= {}
    @tallies[[ body, small, big ]] ||= begin
      verdicts = cuts(body, small, big).map(&:last)
      { places: verdicts.size, fits: verdicts.count(:fits), split: verdicts.count(:split),
        other: verdicts.count(:other) }
    end
  end
end

# The letters the choices are shown under. One image per question, so the five
# bodies live in one figure and the answer is the letter beneath one of them.
CUBE_LETTERS = %w[А Б В Г Д].freeze

# What the cubes are made of, purely so eight variants of one rung are eight
# different questions: the importer keys questions by their text.
CUBE_STUFF = %w[еднакви дървени пластмасови захарни цветни малки].freeze

# Rung -> [size of the small piece, size of the big one, flat bodies only?].
CUBE_RUNGS = [ [ 2, 3, true ], [ 2, 3, false ], [ 2, 4, true ],
               [ 2, 4, false ], [ 3, 4, true ], [ 3, 4, false ] ].freeze

CUBE_PICK_LADDER = [ 1150, 1250, 1360, 1470, 1590, 1700 ].freeze
CUBE_MULTI_LADDER = [ 1200, 1310, 1420, 1530, 1650, 1760 ].freeze

module CubeChoice
  module_function

  # The five bodies: `wrong` of them impossible, the rest buildable, all of one
  # flatness (a rung that mixed flat and stacked bodies would let the odd one
  # out be spotted without any assembling), and every impossible body paired
  # with a buildable one of the same bounding box — otherwise the answer is the
  # one that is a different size and the question is about nothing.
  def bodies(c, small, big, flat_only, wrong)
    class_wanted = flat_only || c.coin
    keep = ->(list) { list.select { |shape| Cubes.flat?(shape) == class_wanted && Cubes.display(shape) } }
    can = keep.call(Cubes.buildable(small, big))
    cannot = keep.call(Cubes.unbuildable(small, big))
    by_box = can.group_by { |shape| Cubes.bbox(shape) }

    impossible = c.sample(cannot.select { |shape| by_box.key?(Cubes.bbox(shape)) }, wrong)
    raise Authoring::Duplicate if impossible.size < wrong

    # One look-alike per *size* of impossible body — two impossible bodies of the
    # same bounding box share a twin, which is what makes three of them fit
    # beside only two buildable ones.
    boxes = impossible.map { |shape| Cubes.bbox(shape) }.uniq
    raise Authoring::Duplicate if boxes.size > 5 - wrong

    chosen = []
    boxes.each { |box| chosen << c.pick(by_box[box] - chosen) }
    chosen += c.sample(can - chosen, 5 - wrong - chosen.size)
    raise Authoring::Duplicate if chosen.size != 5 - wrong

    all = (chosen + impossible).map { |shape| Cubes.display(shape) }
    # Two bodies that are mirror images differ, but not on paper: they are the
    # same drawing seen the other way round, and the reader would be guessing.
    raise Authoring::Duplicate if all.combination(2).any? { |a, b| Cubes.mirror(a) == Cubes.canon(b) }

    order = c.sample(all, 5)
    [ order, order.map { |body| impossible.any? { |shape| Cubes.canon(body) == Cubes.canon(shape) } } ]
  end

  def figure(bodies, small, big)
    Figures.cube_choices(pieces: [ Cubes.display(Cubes::PIECES[big]), Cubes.display(Cubes::PIECES[small]) ],
                         candidates: bodies, labels: CUBE_LETTERS)
  end

  # "двойката може да се сложи на 4 места; при 3 от тях тялото се разпада, при 1
  # остават 3 кубчета в друга форма" — the case analysis, from the solver.
  def cut_sentence(body, small, big, letter)
    tally = Cubes.cut_tally(body, small, big)
    parts = []
    parts << "при #{tally[:split]} от тях тялото се разпада на две части" if tally[:split].positive?
    parts << "при #{tally[:other]} остават #{big} кубчета в друга форма" if tally[:other].positive?
    parts << "при #{tally[:fits]} остава точно #{Cubes::NAMES[big]}" if tally[:fits].positive?
    "#{letter}: #{Cubes::NAMES[small]} се слага на #{tally[:places]} места — #{parts.join(', ')}"
  end

  def stem(c, small, big, question)
    stuff = c.pick(CUBE_STUFF)
    total = small + big
    c.pick([
      "Горе на чертежа са показани две фигури — от #{big} и от #{small} #{stuff} кубчета, залепени по цели " \
      "стени. #{question}",
      "Дадени са две фигури от #{stuff} кубчета — една от #{big} и една от #{small} кубчета (горе на " \
      "чертежа). Под черта има пет тела, всяко от #{total} кубчета. #{question}",
      "От #{stuff} кубчета са слепени две фигури: #{Cubes::SHAPES[big]} и #{Cubes::SHAPES[small]} (горе на " \
      "чертежа). #{question}",
      "Горе на чертежа са двете фигури — от #{big} и от #{small} #{stuff} кубчета. Под черта всяко тяло е от " \
      "#{total} кубчета. #{question}"
    ])
  end

  def hint_ladder(small, big)
    [ "Всички тела са от по #{small + big} кубчета — броенето няма да реши задачата.",
      "Разрезът е #{big} + #{small}: намери в тялото #{Cubes::NAMES[small]} и я махни.",
      "Останалите #{big} кубчета трябва да образуват точно #{Cubes::NAMES[big]} — не просто да са #{big} на " \
      "брой. Пробвай всички места, на които #{Cubes::NAMES[small]} се слага." ]
  end
end

Authoring.family "solids.glue_impossible", topic: "Логически задачи", area: "interactive_kangaroo", variants: 8,
                 rungs: CUBE_PICK_LADDER do |c|
  small, big, flat_only = c.by_level(CUBE_RUNGS)
  bodies, impossible = CubeChoice.bodies(c, small, big, flat_only, 1)
  answer = CUBE_LETTERS[impossible.index(true)]
  good = bodies.each_index.reject { |index| impossible[index] }

  c.q(
    text: CubeChoice.stem(c, small, big,
                          "Кое от телата А, Б, В, Г и Д НЕ може да се получи, като двете фигури се долепят " \
                          "една до друга?"),
    options: CUBE_LETTERS.dup,
    answer: answer,
    figure: CubeChoice.figure(bodies, small, big),
    hints: CubeChoice.hint_ladder(small, big),
    explanation: Explain.build(
      idea: "Кубчетата навсякъде са по #{small + big}, затова броят не различава телата. Търси се разрез " \
            "#{big} + #{small}: къде в тялото стои #{Cubes::NAMES[small]} така, че останалите #{big} кубчета " \
            "да образуват точно #{Cubes::NAMES[big]}.",
      steps: [
        CubeChoice.cut_sentence(bodies[impossible.index(true)], small, big, answer) +
          ". #{Cubes::SUBJECTS[big]} не остава при нито едно от тях.",
        "При останалите тела разрезът се намира: " +
          good.map { |index|
            "#{CUBE_LETTERS[index]} — #{Cubes.cut_tally(bodies[index], small, big)[:fits]} начина"
          }.join(", ") + ".",
        "Значи всички освен #{answer} се сглобяват от двете фигури."
      ],
      answer: answer,
      check: CubeChoice.cut_sentence(bodies[good.first], small, big, CUBE_LETTERS[good.first]) +
             " — така изглежда разрез, който става.",
      watch: "Броят на кубчетата не подсказва нищо: и петте тела са от по #{small + big}. И #{big} кубчета в " \
             "друга форма не са #{Cubes::NAMES[big]} — фигурата може да се върти, но не и да се преогъва."
    )
  )
end

# The same picture, asked so that every body has to be judged: with one letter to
# find, a student who spots it stops looking, and four of the five bodies are
# never thought about.
Authoring.family "solids.glue_buildable_pick", topic: "Логически задачи", area: "interactive_kangaroo",
                 variants: 8, rungs: CUBE_MULTI_LADDER do |c|
  small, big, flat_only = c.by_level(CUBE_RUNGS)
  wrong = c.pick(flat_only ? [ 1, 2 ] : [ 1, 2, 3 ])
  bodies, impossible = CubeChoice.bodies(c, small, big, flat_only, wrong)
  good = bodies.each_index.reject { |index| impossible[index] }

  c.q(
    text: CubeChoice.stem(c, small, big,
                          "Избери всички тела от А до Д, които МОГАТ да се получат, като двете фигури се " \
                          "долепят една до друга."),
    widget: WidgetKit.multi_select(CUBE_LETTERS.each_with_index.map { |letter, index| [ letter, !impossible[index] ] }),
    figure: CubeChoice.figure(bodies, small, big),
    hints: CubeChoice.hint_ladder(small, big),
    explanation: Explain.build(
      idea: "Всяко тяло се проверява поотделно, по един и същ начин: махни #{Cubes::NAMES[small]} и гледай " \
            "дали останалите #{big} кубчета образуват точно #{Cubes::NAMES[big]}.",
      steps: [
        "Получават се: " + good.map { |index| CubeChoice.cut_sentence(bodies[index], small, big, CUBE_LETTERS[index]) }
                               .join("; ") + ".",
        "Не се получават: " + impossible.each_index.select { |index| impossible[index] }
                                        .map { |index| CubeChoice.cut_sentence(bodies[index], small, big, CUBE_LETTERS[index]) }
                                        .join("; ") + ". При тях #{Cubes::SUBJECTS[big]} не остава при нито един разрез.",
        "Затова отговорът е #{good.map { |index| CUBE_LETTERS[index] }.join(', ')}."
      ],
      answer: good.map { |index| CUBE_LETTERS[index] }.join(", "),
      check: "Броят на кубчетата е един и същ при всички тела (#{small + big}) — той не отделя нито едно, " \
             "решава единствено разрезът.",
      watch: "Тук не стига да се намери едно тяло: " +
             (wrong == 1 ? "не се получава само едно от петте, " : "не се получават #{wrong} от петте, ") +
             "а всяко от останалите трябва да е проверено поотделно."
    )
  )
end

# ----------------------------------------------- Колко триъгълника има тук ---

# The type: a square (or a rectangle, or a triangle) with a few more segments
# drawn across it — how many triangles are in the figure? Nothing is measured
# and nothing is calculated; the whole difficulty is *systematic* counting, and
# the mistake the type is built on is missing the big triangles, the ones with
# a line running through them.
#
# The geometry is exact rational arithmetic. In floating point, whether three
# lines meet at one point is decided by rounding — and that decision changes the
# answer.
TRIANGLE_COUNT_LADDER = [ 950, 1080, 1200, 1320, 1450, 1580 ].freeze

module Arrangement
  FRACTIONS = [ Rational(1, 3), Rational(2, 5), Rational(1, 2), Rational(3, 5), Rational(2, 3) ].freeze
  # Where a free point is moved to when the count is tested for depending on it.
  PROBES = [ Rational(1, 4), Rational(2, 5), Rational(3, 5), Rational(3, 4) ].freeze
  SIDE_LETTERS = %w[E F G H I].freeze
  INSIDE_LETTERS = %w[M N P Q R S T U V].freeze
  BASE_NAMES = { square: "квадрата", rect: "правоъгълника", triangle: "триъгълника" }.freeze

  Figure = Struct.new(:kind, :letters, :nodes, :segments, :drawn, :triangles, keyword_init: true) do
    def count = triangles.size
    def base = BASE_NAMES[kind]
    def outline = letters.join

    # The triangles grouped by size, smallest first — the order the explanation
    # counts them in, and the order a child should.
    def by_size
      triangles.group_by { |_, area,| area }.sort_by(&:first).map { |area, group| [ area, group.map(&:first).sort ] }
    end

    def whole = triangles.reject { |_, _, divided| divided }.map(&:first).sort
    def split = triangles.select { |_, _, divided| divided }.map(&:first).sort
    # The biggest triangle with a line through it: the one that gets missed.
    def biggest_split = triangles.select { |_, _, divided| divided }.max_by { |_, area,| area }&.first
  end

  # A place on the boundary: a corner, or a point along a side. A half is
  # *pinned* — "the middle of BC" says exactly where it is. Any other fraction is
  # described only as "a point on BC", which is honest only if the answer does
  # not depend on where exactly it sits.
  Spot = Struct.new(:corner, :side, :frac, keyword_init: true) do
    def pinned? = !corner.nil? || frac == Rational(1, 2)
  end
  Cut = Struct.new(:from, :to)

  module_function

  # --- the geometry ---------------------------------------------------------

  # Where two drawn segments cross, or nil: parallel, or crossing only outside
  # one of them. Endpoints count — that is what makes the corners corners.
  def meet(one, other)
    (p, p2), (q, q2) = one, other
    r = [ p2[0] - p[0], p2[1] - p[1] ]
    s = [ q2[0] - q[0], q2[1] - q[1] ]
    denominator = (r[0] * s[1]) - (r[1] * s[0])
    return nil if denominator.zero?

    t = (((q[0] - p[0]) * s[1]) - ((q[1] - p[1]) * s[0])) / denominator
    u = (((q[0] - p[0]) * r[1]) - ((q[1] - p[1]) * r[0])) / denominator
    return nil unless t.between?(0, 1) && u.between?(0, 1)

    [ p[0] + (t * r[0]), p[1] + (t * r[1]) ]
  end

  # Every triangle in the figure: three of the drawn segments whose three
  # pairwise crossings are three different points. Each side of it then runs
  # between two points of one drawn segment, so it is drawn — that is the whole
  # argument, and it is why nothing here has to trace regions.
  def triangles(segments)
    segments.combination(3).filter_map do |one, other, third|
      corners = [ meet(one, other), meet(one, third), meet(other, third) ]
      next if corners.any?(&:nil?) || corners.uniq.size < 3

      corners.sort
    end.uniq
  end

  def area(triangle)
    a, b, c = triangle
    ((((b[0] - a[0]) * (c[1] - a[1])) - ((b[1] - a[1]) * (c[0] - a[0]))).abs / 2)
  end

  def crossings(segments) = segments.combination(2).filter_map { |one, other| meet(one, other) }.uniq

  def inside?(point, corners)
    signs = corners.each_with_index.map do |corner, index|
      other = corners[(index + 1) % 3]
      ((other[0] - corner[0]) * (point[1] - corner[1])) - ((other[1] - corner[1]) * (point[0] - corner[0]))
    end
    signs.all?(&:positive?) || signs.all?(&:negative?)
  end

  # Is a line drawn through this triangle? A segment that crosses the boundary
  # twice with the middle of those two crossings strictly inside divides it;
  # one that merely runs along a side does not. This is the trap of the whole
  # type — a divided triangle is still a triangle — so the explanation says it
  # only when it is true.
  def divided?(corners, segments)
    sides = [ [ corners[0], corners[1] ], [ corners[1], corners[2] ], [ corners[2], corners[0] ] ]
    segments.any? do |segment|
      hits = sides.filter_map { |side| meet(segment, side) }.uniq
      next false if hits.size < 2

      hits.combination(2).any? do |one, other|
        inside?([ (one[0] + other[0]) / 2, (one[1] + other[1]) / 2 ], corners)
      end
    end
  end

  def apart(a, b) = Math.sqrt((((a[0] - b[0])**2) + ((a[1] - b[1])**2)).to_f)

  # --- the figure ------------------------------------------------------------

  def pt(x, y) = [ Rational(x), Rational(y) ]

  def shape(kind)
    case kind
    when :square then [ %w[A B C D], [ pt(0, 0), pt(1, 0), pt(1, 1), pt(0, 1) ] ]
    when :rect then [ %w[A B C D], [ pt(0, 0), pt(Rational(7, 5), 0), pt(Rational(7, 5), 1), pt(0, 1) ] ]
    when :triangle then [ %w[A B C], [ pt(0, 0), pt(Rational(6, 5), 0), pt(Rational(11, 20), 1) ] ]
    end
  end

  def along(from, to, frac) = [ from[0] + ((to[0] - from[0]) * frac), from[1] + ((to[1] - from[1]) * frac) ]

  def place(spot, points)
    return points[spot.corner] if spot.corner

    along(points[spot.side], points[(spot.side + 1) % points.size], spot.frac)
  end

  # One more segment across the shape: corner to corner (a diagonal, and only
  # where the two corners are not neighbours — otherwise it is a side), corner to
  # a point on a side it does not touch, or point on a side to point on another.
  def cut(c, sides, diagonals)
    kinds = [ :corner_side, :side_side ]
    kinds << :diagonal if diagonals && sides == 4
    case c.pick(kinds)
    when :diagonal
      corner = c.int(0...sides)
      Cut.new(Spot.new(corner: corner), Spot.new(corner: (corner + 2) % sides))
    when :corner_side
      corner = c.int(0...sides)
      side = c.pick((0...sides).reject { |index| [ corner, (corner - 1) % sides ].include?(index) })
      Cut.new(Spot.new(corner: corner), Spot.new(side: side, frac: c.pick(FRACTIONS)))
    else
      first, second = c.sample((0...sides).to_a, 2)
      Cut.new(Spot.new(side: first, frac: c.pick(FRACTIONS)),
              Spot.new(side: second, frac: c.pick(FRACTIONS)))
    end
  end

  # Most draws are thrown away — a figure whose crossings nearly coincide, or
  # whose triangle count is outside the rung's band, is not worth printing — so
  # the drawing is retried here rather than costing the builder a whole variant.
  # Every draw comes from the rung's own RNG, so a rebuild redraws the same
  # figures.
  def build(c, kind:, cuts:, band:, tries: 24)
    tries.times do
      begin
        return attempt(c, kind: kind, cuts: cuts, band: band)
      rescue Authoring::Duplicate
        next
      end
    end
    raise Authoring::Duplicate
  end

  def attempt(c, kind:, cuts:, band:)
    letters, points = shape(kind)
    sides = letters.size
    drawn = Array.new(cuts) { cut(c, sides, kind != :triangle) }
    frame = (0...sides).map { |index| [ points[index], points[(index + 1) % sides] ] }
    segments = drawn.map { |line| [ place(line.from, points), place(line.to, points) ] }

    raise Authoring::Duplicate if segments.any? { |from, to| from == to }
    raise Authoring::Duplicate if segments.map(&:sort).uniq.size < cuts
    # A segment lying along a side of the shape draws nothing new.
    raise Authoring::Duplicate if segments.any? { |line| frame.any? { |side| collinear?(line, side) } }

    all = frame + segments
    found = triangles(all)
    raise Authoring::Duplicate unless band.cover?(found.size)

    nodes = crossings(all)
    # Two crossings that nearly coincide make a drawing nobody can read.
    raise Authoring::Duplicate if nodes.combination(2).any? { |a, b| apart(a, b) < 0.11 }

    named = name(letters, points, drawn, nodes)
    raise Authoring::Duplicate if named.nil?
    # The answer has to be a property of the *figure*, not of where exactly a
    # free point sits, because "a point on BC" is all the question says about it.
    raise Authoring::Duplicate unless steady?(kind, drawn, found.size)

    Figure.new(
      kind: kind, letters: letters, nodes: named, segments: all,
      # Every end stays tied to its own letter, and the pair is read out in
      # alphabetical order — a diagonal is written AC, never CA.
      drawn: drawn.map { |line|
        [ line, [ line.from, line.to ].map { |spot| [ spot, named.key(place(spot, points)) ] }.sort_by(&:last) ]
      }.sort_by { |_, ends| ends.map(&:last) },
      triangles: found.map { |triangle|
        [ triangle.map { |corner| named.key(corner) }.sort.join, area(triangle), divided?(triangle, all) ]
      }
    )
  end

  def collinear?(one, other)
    (p, p2), (q, q2) = one, other
    cross = ->(a, b, o) { ((a[0] - o[0]) * (b[1] - o[1])) - ((a[1] - o[1]) * (b[0] - o[0])) }
    cross.call(p2, q, p).zero? && cross.call(p2, q2, p).zero?
  end

  # Every free point moved to four other places along its side: if the number of
  # triangles survives all of that, the figure is generic and the question can
  # say "a point on BC" and mean it.
  def steady?(kind, drawn, count)
    letters, points = shape(kind)
    sides = letters.size
    frame = (0...sides).map { |index| [ points[index], points[(index + 1) % sides] ] }

    drawn.flat_map { |line| [ line.from, line.to ] }.reject(&:pinned?).all? do |spot|
      PROBES.all? do |probe|
        was = spot.frac
        spot.frac = probe
        moved = drawn.map { |line| [ place(line.from, points), place(line.to, points) ] }
        same = triangles(frame + moved).size == count
        spot.frac = was
        same
      end
    end
  end

  # Corners keep their letters, points on the sides get E, F, G..., crossings
  # inside get M, N, P... top to bottom, left to right.
  def name(letters, points, drawn, nodes)
    named = {}
    letters.each_with_index { |letter, index| named[letter] = points[index] }
    drawn.flat_map { |line| [ line.from, line.to ] }.reject(&:corner).each do |spot|
      spot_at = place(spot, points)
      next if named.value?(spot_at)

      letter = SIDE_LETTERS[named.size - letters.size]
      return nil if letter.nil?

      named[letter] = spot_at
    end
    inside = nodes.reject { |node| named.value?(node) }.sort_by { |x, y| [ -y, x ] }
    return nil if inside.size > INSIDE_LETTERS.size

    inside.each_with_index { |node, index| named[INSIDE_LETTERS[index]] = node }
    named
  end

  # --- the words -------------------------------------------------------------

  def list(items, join = "и")
    return items.first.to_s if items.size == 1

    "#{items[0..-2].join(', ')} #{join} #{items.last}"
  end

  # "диагоналите AC и BD и отсечката EF" — a corner-to-corner cut of a
  # quadrilateral is a diagonal and is worth calling one.
  def segments_phrase(figure)
    diagonals, plain = figure.drawn.partition { |line, _| figure.kind != :triangle && line.from.corner && line.to.corner }
    name = ->(group) { list(group.map { |_, ends| ends.map(&:last).join }) }
    parts = []
    parts << "#{diagonals.size == 1 ? 'диагоналът' : 'диагоналите'} #{name.call(diagonals)}" if diagonals.any?
    parts << "#{plain.size == 1 ? 'отсечката' : 'отсечките'} #{name.call(plain)}" if plain.any?
    list(parts)
  end

  # "E е точка от страната BC, а F е средата на CD" — every free end named and
  # placed, because the reader has only the letters to go on.
  def spots_phrase(figure)
    letters = figure.letters
    parts = figure.drawn.flat_map { |_, ends| ends }
                  .reject { |spot, _| spot.corner }.uniq { |_, name| name }.sort_by(&:last)
                  .map do |spot, name|
      side = "#{letters[spot.side]}#{letters[(spot.side + 1) % letters.size]}"
      spot.frac == Rational(1, 2) ? "#{name} е средата на #{side}" : "#{name} е точка от страната #{side}"
    end
    return nil if parts.empty?

    parts.size == 1 ? parts.first : "#{parts[0..-2].join(', ')}, а #{parts.last}"
  end

  def figure_of(figure)
    Figures.segment_art(
      nodes: figure.nodes.map { |name, point| [ name, point, Arrangement::INSIDE_LETTERS.include?(name) ] },
      segments: figure.segments
    )
  end

  def hint_ladder(figure)
    [ "Броят на триъгълниците не се вижда наведнъж — брои по системата, а не наслуки.",
      "Първо най-малките триъгълници, тези, през които не минава никаква линия.",
      "После по-големите: триъгълник, разделен от линия на две части, пак е триъгълник и се брои. " \
      "Върви по върховете #{figure.letters.join(', ')} и гледай кои три точки са свързани." ]
  end
end

Authoring.family "count.triangles_in_figure", topic: "Логически задачи", area: "interactive_kangaroo",
                 variants: 8, rungs: TRIANGLE_COUNT_LADDER do |c|
  figure = Arrangement.build(
    c,
    # The triangle base is dropped from the top rung: with four more segments
    # across it the crossings crowd together and the figure stops being readable
    # long before it stops being countable.
    kind: c.pick(c.by_level([ [ :square ], [ :square, :rect, :triangle ], [ :square, :rect ],
                              [ :square, :rect, :triangle ], [ :square, :rect, :triangle ],
                              [ :square, :rect ] ])),
    cuts: c.by_level([ 2, 2, 3, 3, 3, 4 ]),
    band: c.by_level([ 3..5, 6..8, 7..10, 10..12, 13..16, 17..26 ])
  )
  where = Arrangement.spots_phrase(figure)
  drawn = "#{Arrangement.segments_phrase(figure)}#{where ? ", където #{where}" : ''}"
  sizes = figure.by_size

  c.q(
    text: c.pick([
      "В #{figure.base} #{figure.outline} са начертани #{drawn}. Колко триъгълника има на чертежа?",
      "На чертежа в #{figure.base} #{figure.outline} са начертани #{drawn}. Колко триъгълника се виждат?"
    ]),
    answer: Num.ans(figure.count),
    figure: Arrangement.figure_of(figure),
    hints: Arrangement.hint_ladder(figure),
    explanation: Explain.build(
      idea: "Триъгълниците се броят по системата — от най-малките към най-големите — защото този, който " \
            "брои наслуки, пропуска големите: триъгълник, разделен от линия, пак е триъгълник.",
      steps: [
        "Освен страните на #{figure.base} #{figure.outline} са начертани #{drawn}. Всички пресечни точки на " \
        "чертежа са означени с букви.",
        "Триъгълниците по големина, от най-малкия нататък: " +
          sizes.map { |_, names| names.join(", ") }.join("; ") + ".",
        "Общо: #{sizes.map { |_, names| names.size }.join(' + ')} = #{figure.count}."
      ],
      answer: "#{figure.count} триъгълника",
      check: figure.split.empty? ?
        "През нито един от тях не минава линия — затова всички са „цели“ и никой не се брои два пъти." :
        "От тях #{figure.whole.size} са цели, а #{figure.split.size} са разделени от линия " \
        "(#{figure.split.join(', ')}) — и едните, и другите са триъгълници.",
      watch: figure.biggest_split ?
        "Най-често се пропуска голям триъгълник, през който минава линия — например #{figure.biggest_split}. " \
        "Линията вътре не го прави по-малко триъгълник." :
        "Всяка тройка букви се проверява: трите точки трябва да са свързани по две с начертани отсечки."
    )
  )
end

# ------------------------------------ Схема на светлините: колко минути общо ---

# The type: a lighting plan drawn as bars on a minute axis — three lights, each
# switching on and off — and the question is how many minutes *exactly two* of
# them are lit. The whole problem turns on that word: the minutes when all three
# are lit are not among them, and they are the ones a quick reader adds in
# anyway.
#
# The schedule is spelled out in the stem as well as drawn. That is the corpus
# rule — the views render question images with an empty alt — and it moves the
# work from reading a chart to the interval logic, which is what the type is
# actually about. It also makes every stem different, since the schedule is.
SCHEDULE_LADDER = [ 900, 1020, 1140, 1260, 1380, 1500 ].freeze
SCHEDULE_SPLIT_LADDER = [ 960, 1080, 1200, 1320, 1440, 1560 ].freeze

module Schedule
  LETTERS = %w[А Б В Г].freeze
  ALL_OF = { 2 => "и двете", 3 => "и трите", 4 => "и четирите" }.freeze
  # The label on the last box of the breakdown: "и трите" reads as a conjunction
  # in a list of boxes, so the box says "всичките три".
  ALL_BOX = { 2 => "двете едновременно", 3 => "всичките три", 4 => "всичките четири" }.freeze
  EXACTLY = { 1 => "точно една", 2 => "точно две", 3 => "точно три" }.freeze
  COUNT_WORD = { 0 => "нито една", 1 => "една", 2 => "две", 3 => "три", 4 => "четири" }.freeze

  # Who is switching what on and off, with the words each context needs: the
  # plural, the singular, the verb in both numbers, and how it is switched.
  SCENES = [
    { who: "Осветител в театъра", switch: "запалва и гаси", things: "светлините", one: "светлина",
      many: "светлини", verb: "светят", verb_one: "свети" },
    { who: "Техник в концертна зала", switch: "включва и изключва", things: "прожекторите",
      one: "прожектор", many: "прожектора", verb: "светят", verb_one: "свети" },
    { who: "Градинар", switch: "включва и изключва", things: "поливачките", one: "поливачка",
      many: "поливачки", verb: "работят", verb_one: "работи" },
    { who: "Пазачът на парка", switch: "включва и изключва", things: "фонтаните", one: "фонтан",
      many: "фонтана", verb: "работят", verb_one: "работи" },
    { who: "Майстор в цеха", switch: "включва и изключва", things: "машините", one: "машина",
      many: "машини", verb: "работят", verb_one: "работи" }
  ].freeze

  Plan = Struct.new(:span, :lanes, :question, :asked, keyword_init: true) do
    def size = lanes.size

    # How many lanes are on during each single minute of the plan. Every
    # endpoint is a whole minute, so a minute is either fully on or fully off —
    # that is what makes the answer a count and not a measurement.
    def per_minute
      (0...span).map { |minute| lanes.count { |_, runs| runs.any? { |from, to| minute >= from && minute < to } } }
    end

    def minutes_with(count) = per_minute.count(count)

    # The minutes with exactly this many lanes on, merged back into intervals —
    # "1–2, 3–5, 10–12" — because that is how the answer gets added up.
    def spans_with(count)
      per_minute.each_with_index.select { |on, _| on == count }.map(&:last)
                .slice_when { |a, b| b != a + 1 }.map { |run| [ run.first, run.last + 1 ] }
    end

    def answer
      case question
      when :none then minutes_with(0)
      when :any then span - minutes_with(0)
      when :all then minutes_with(size)
      else minutes_with(asked)
      end
    end
  end

  module_function

  # A lane: runs of at least a minute with gaps of at least a minute, walked
  # from the start of the plan to its end. Run lengths scale with the span, so a
  # twenty-minute plan does not end in five minutes of empty chart.
  def lane(c, span, runs)
    list = []
    at = c.int(0..1)
    longest = [ (span / 4.0).ceil, 5 ].min
    while list.size < runs && at < span
      finish = [ at + c.int(1..longest), span ].min
      list << [ at, finish ]
      at = finish + c.int(1..2)
    end
    raise Authoring::Duplicate if list.empty?

    list
  end

  def build(c, span:, lanes:, runs:, question:, asked: nil, least: 2, tries: 30)
    tries.times do
      plan = Plan.new(span: span, question: question, asked: asked,
                      lanes: LETTERS.first(lanes).map { |letter| [ letter, lane(c, span, runs) ] })
      next if plan.lanes.map(&:last).uniq.size < lanes
      # A plan nobody would print: an answer of nought or of the whole span, or
      # a lane that is on almost all of the time or almost none.
      next unless plan.answer.between?(least, span - 2)
      # The chart has to use the axis it draws: nothing on in the last minutes
      # reads as a broken picture rather than as a plan that ends early.
      next if plan.per_minute.last(2).sum.zero?
      next unless plan.lanes.all? { |_, list|
        lit = list.sum { |from, to| to - from }
        lit.between?((span * 0.3).ceil, (span * 0.8).floor)
      }
      # "Exactly two" is only a question when some minute has more than two on.
      # Otherwise it means "at least two" and the word the problem turns on does
      # no work at all.
      next if asked && plan.per_minute.none? { |on| on > asked }

      return plan
    end
    raise Authoring::Duplicate
  end

  # "светлина А свети от 1 до 5 и от 6 до 9; светлина Б — от 2 до 6 и от 7 до 12"
  def schedule_phrase(plan, scene)
    plan.lanes.each_with_index.map do |(letter, runs), index|
      runs_text = runs.map { |from, to| "от #{from} до #{to}" }.then { |list| Arrangement.list(list) }
      head = index.zero? ? "#{scene[:one]} #{letter} #{scene[:verb_one]}" : "#{scene[:one]} #{letter} —"
      "#{head} #{runs_text}"
    end.join("; ")
  end

  def question_phrase(plan, scene)
    case plan.question
    when :none then "Колко минути не #{scene[:verb_one]} нито една от #{scene[:things]}?"
    when :any then "Колко минути общо #{scene[:verb_one]} поне една от #{scene[:things]}?"
    when :all then "Колко минути #{ALL_OF[plan.size]} #{scene[:verb]} едновременно?"
    else "Колко минути общо #{EXACTLY[plan.asked]} от #{scene[:things]} #{scene[:verb]} едновременно?"
    end
  end

  def figure_of(plan)
    Figures.timeline_bars(lanes: plan.lanes, span: plan.span)
  end

  def minute_row(plan) = plan.per_minute.join(" ")

  def spans_sentence(plan, count)
    runs = plan.spans_with(count)
    return nil if runs.empty?

    "#{Arrangement.list(runs.map { |from, to| "#{from}–#{to}" })} — " \
      "#{runs.map { |from, to| to - from }.join(' + ')} = #{plan.minutes_with(count)} минути"
  end

  def parts_check(plan)
    parts = (0..plan.size).map { |count| "#{COUNT_WORD[count]} — #{plan.minutes_with(count)}" }
    "По части: #{parts.join(', ')}; заедно " \
      "#{(0..plan.size).map { |count| plan.minutes_with(count) }.join(' + ')} = #{plan.span} минути, " \
      "колкото е цялата схема."
  end

  def hint_ladder(plan, scene)
    [ "Гледай минута по минута: от 0 до 1, от 1 до 2 и така нататък. В рамките на една минута нищо не се " \
      "променя — всяка #{scene[:one]} или #{scene[:verb_one]} цялата минута, или не #{scene[:verb_one]} никак.",
      "Напиши над всяка минута по колко от #{scene[:things]} #{scene[:verb]} в нея.",
      "После събери само минутите с точно толкова, колкото пита задачата — минута с повече не се брои." ]
  end
end

Authoring.family "count.overlap_minutes", topic: "Логически задачи", area: "interactive_kangaroo",
                 variants: 8, rungs: SCHEDULE_LADDER do |c|
  scene = c.pick(Schedule::SCENES)
  span = c.int(c.by_level([ 8..10, 10..12, 12..12, 13..16, 16..16, 17..20 ]))
  lanes = c.by_level([ 2, 3, 3, 3, 4, 4 ])
  question, asked = c.pick(c.by_level([
    [ [ :all, nil ], [ :none, nil ] ],
    [ [ :all, nil ], [ :none, nil ], [ :any, nil ] ],
    [ [ :exactly, 2 ] ],
    [ [ :exactly, 2 ], [ :all, nil ] ],
    [ [ :exactly, 2 ], [ :exactly, 3 ] ],
    [ [ :exactly, 3 ], [ :exactly, 2 ] ]
  ]))
  plan = Schedule.build(c, span: span, lanes: lanes, runs: c.by_level([ 2, 3, 3, 4, 4, 4 ]),
                        question: question, asked: asked, least: c.by_level([ 2, 2, 3, 3, 4, 4 ]))
  wanted = asked || (question == :all ? plan.size : nil)

  c.q(
    text: "#{scene[:who]} #{scene[:switch]} #{scene[:things]} по показаната схема: " \
          "#{Schedule.schedule_phrase(plan, scene)} (в минути). #{Schedule.question_phrase(plan, scene)}",
    answer: Num.ans(plan.answer),
    figure: Schedule.figure_of(plan),
    hints: Schedule.hint_ladder(plan, scene),
    explanation: Explain.build(
      idea: "Всяка минута е или цяла в едно състояние, или цяла в друго, защото всички включвания и " \
            "изключвания са на цели минути. Затова се брои минута по минута, а не се мери по чертежа.",
      steps: [
        "По минути от 0 до #{plan.span} колко от #{scene[:things]} #{scene[:verb]}: #{Schedule.minute_row(plan)}.",
        case question
        when :none then "Нула #{scene[:verb]} в #{Schedule.spans_sentence(plan, 0)}."
        when :any then "Поне една #{scene[:verb_one]} навсякъде освен в минутите с нула " \
                       "(#{plan.minutes_with(0)}): #{plan.span} − #{plan.minutes_with(0)} = #{plan.answer} минути."
        else "#{Schedule::EXACTLY[wanted].capitalize} #{scene[:verb]} в #{Schedule.spans_sentence(plan, wanted)}."
        end,
        "Отговорът е сборът на тези минути: #{plan.answer}."
      ],
      answer: "#{plan.answer} минути",
      check: Schedule.parts_check(plan),
      watch: wanted && wanted < plan.size ?
        "\u201E#{Schedule::EXACTLY[wanted].capitalize}\u201C не значи \u201Eпоне " \
        "#{Schedule::COUNT_WORD[wanted]}\u201C: минутите, в които #{scene[:verb]} повече " \
        "(тук #{plan.minutes_with(plan.size)}), не се броят." :
        "Схемата се чете по минути, а не на око по чертежа: едно деление е една минута, не разстояние, " \
        "което се мери."
    )
  )
end

# The same chart with the whole breakdown asked for at once. With one number to
# find, a student can stop at the first interval that looks right; with a box per
# count, the plan has to be read minute by minute — and the boxes have to add up
# to the span, which is the check the single number cannot offer.
Authoring.family "count.overlap_split", topic: "Логически задачи", area: "interactive_kangaroo",
                 variants: 8, rungs: SCHEDULE_SPLIT_LADDER do |c|
  scene = c.pick(Schedule::SCENES)
  span = c.int(c.by_level([ 8..10, 10..12, 12..12, 12..14, 14..16, 16..18 ]))
  lanes = c.by_level([ 2, 2, 3, 3, 3, 3 ])
  plan = Schedule.build(c, span: span, lanes: lanes, runs: c.by_level([ 2, 3, 3, 3, 4, 4 ]),
                        question: :exactly, asked: lanes - 1, least: c.by_level([ 2, 2, 2, 3, 3, 3 ]))
  counts = (1..lanes).map { |count| plan.minutes_with(count) }
  # A row of boxes where only one has a number in it is not a breakdown.
  raise Authoring::Duplicate if counts.count(&:positive?) < 2

  labels = (1..lanes).map { |count| count == lanes ? Schedule::ALL_BOX[count] : Schedule::EXACTLY[count] }

  c.q(
    text: "#{scene[:who]} #{scene[:switch]} #{scene[:things]} по показаната схема: " \
          "#{Schedule.schedule_phrase(plan, scene)} (в минути). Попълни по колко минути " \
          "#{scene[:verb]} #{Arrangement.list(labels)}.",
    widget: WidgetKit.blanks((1..lanes).map { |count| [ "n#{count}", labels[count - 1], counts[count - 1] ] }),
    figure: Schedule.figure_of(plan),
    hints: Schedule.hint_ladder(plan, scene),
    explanation: Explain.build(
      idea: "Едно преброяване дава всички отговори наведнъж: минута по минута се записва колко " \
            "#{scene[:verb]}, а после се преброява колко минути има от всеки вид.",
      steps: [
        "По минути от 0 до #{plan.span} колко от #{scene[:things]} #{scene[:verb]}: #{Schedule.minute_row(plan)}.",
        (1..lanes).filter_map { |count|
          runs = Schedule.spans_sentence(plan, count)
          "#{labels[count - 1].capitalize}: #{runs}" if runs
        }.join("; ") + ".",
        (1..lanes).select { |count| counts[count - 1].zero? }.then { |missing|
          missing.empty? ? "Всеки вид минути се среща в схемата." :
            "#{missing.map { |count| labels[count - 1] }.join(' и ')} — няма такива минути, значи 0."
        }
      ],
      answer: labels.each_with_index.map { |label, index| "#{label} — #{counts[index]}" }.join(", "),
      check: Schedule.parts_check(plan),
      watch: "Числата в кутийките заедно с минутите, в които не #{scene[:verb_one]} нищо " \
             "(#{plan.minutes_with(0)}), трябва да дадат #{plan.span} — цялата схема. Ако не дадат, някоя " \
             "минута е броена два пъти или е пропусната."
    )
  )
end

# ------------------------------------------- Везната и тежестта без надпис ---

# The type: weights of 1, 2, ... n kilograms, all different, most of them on a
# balance that is level, one standing beside it — and the question is which
# weight is the one beside it. Nothing is weighed and nothing is measured: the
# lever is exact, so the two pans hold equal sums, and that single equation plus
# the parity of the total is the whole method.
#
# The picture cannot be trusted to name the weights: some carry their number,
# some are blank, and the answer has to be *forced* by what is shown. The builder
# enumerates every arrangement consistent with the picture and keeps the puzzle
# only when they all agree about the weight in question.
BALANCE_LADDER = [ 1000, 1120, 1240, 1360, 1480, 1600 ].freeze
# Four rungs rather than six: this version keeps at most one blank weight per
# pan (two blanks on one pan would be interchangeable, and a letter nobody can
# pin down is not a question), so the only thing left to raise is how many
# weights there are.
BALANCE_FILL_LADDER = [ 1060, 1210, 1360, 1510 ].freeze

module Balance
  LETTERS = %w[А Б В].freeze
  MORE = { 1 => "още една без надпис", 2 => "още две без надпис", 3 => "още три без надпис",
           4 => "още четири без надпис" }.freeze

  Puzzle = Struct.new(:values, :left, :right, :aside, :shown, keyword_init: true) do
    def total = values.sum
    def half = (total - aside) / 2
    def free = values.reject { |value| shown.include?(value) }
    def blanks(pan) = pan.count { |value| !shown.include?(value) }
    def labelled(pan) = pan.select { |value| shown.include?(value) }.sort
  end

  module_function

  # The ways the weights on the scale can be split into two level pans of two to
  # four weights each — every picture this type can draw.
  def splits(rest)
    @splits ||= {}
    @splits[rest] ||= begin
      found = []
      (2..[ rest.size - 2, 4 ].min).each do |size|
        rest.combination(size).each do |left|
          right = rest - left
          next unless right.size.between?(2, 4) && left.sum == right.sum

          found << [ left.sort, right.sort ]
        end
      end
      found.uniq
    end
  end

  # Every weight that could be the one standing beside the scale, as far as the
  # picture says. The pans are level, so each holds half of what is on the scale;
  # and once the *left* pan can be made to reach that half with the number of
  # blanks it has, the right pan holds the rest and reaches it too — which is why
  # testing one pan is enough.
  def possible_asides(puzzle)
    free = puzzle.free
    blanks = puzzle.blanks(puzzle.left)
    shown = puzzle.labelled(puzzle.left).sum

    free.select do |aside|
      rest = puzzle.total - aside
      next false unless rest.even?

      (free - [ aside ]).combination(blanks).any? { |fill| shown + fill.sum == rest / 2 }
    end
  end

  def build(c, weights:, blanks:, per_pan: nil, tries: 80)
    values = (1..weights).to_a
    tries.times do
      aside = c.pick(values)
      options = splits(values - [ aside ])
      next if options.empty?

      left, right = c.pick(options)
      hidden = c.sample(left + right, blanks)
      # A pan with no number on it at all is a picture that says nothing.
      next if (left - hidden).empty? || (right - hidden).empty?
      next if per_pan && [ left, right ].any? { |pan| (pan & hidden).size > per_pan }

      puzzle = Puzzle.new(values: values, left: left, right: right, aside: aside,
                          shown: (left + right) - hidden)
      # Parity on its own must not settle it, or there is nothing to work out.
      next if puzzle.free.count { |value| (puzzle.total - value).even? } < 2
      next unless possible_asides(puzzle) == [ aside ]

      return puzzle
    end
    raise Authoring::Duplicate
  end

  # "тежестта от 5 кг и още две без надпис"
  def pan_phrase(puzzle, pan)
    shown = puzzle.labelled(pan)
    parts = []
    parts << (shown.size == 1 ? "тежестта от #{shown.first} кг" : "тежестите от #{Arrangement.list(shown)} кг")
    parts << MORE[puzzle.blanks(pan)] if puzzle.blanks(pan).positive?
    Arrangement.list(parts)
  end

  # The same, for the version where every blank weight carries a letter.
  def lettered_phrase(puzzle, pan, letters)
    shown = puzzle.labelled(pan)
    mine = pan.reject { |value| puzzle.shown.include?(value) }.map { |value| letters[value] }
    parts = [ shown.size == 1 ? "тежестта от #{shown.first} кг" : "тежестите от #{Arrangement.list(shown)} кг" ]
    parts << "тежестта #{Arrangement.list(mine)}" if mine.any?
    Arrangement.list(parts)
  end

  def figure_of(puzzle, labels)
    Figures.balance_scale(left: puzzle.left.map { |value| labels[value] },
                          right: puzzle.right.map { |value| labels[value] },
                          aside: labels[puzzle.aside])
  end

  # Why a candidate for the weight beside the scale does not work: the left pan
  # cannot be made to reach half of what is on the scale.
  def refusal(puzzle, candidate)
    half = (puzzle.total - candidate) / 2
    blanks = puzzle.blanks(puzzle.left)
    shown = puzzle.labelled(puzzle.left).sum
    pool = puzzle.free - [ candidate ]
    sums = pool.combination(blanks).map(&:sum).uniq.sort
    "при #{candidate} кг всяко блюдо трябва да е (#{puzzle.total} − #{candidate}) : 2 = #{half}, " \
      "а лявото блюдо има вече #{shown} кг и още #{count_noun(blanks, 'тежест', 'тежести')} без надпис: " \
      "сборът им може да е #{Arrangement.list(sums.map(&:to_s), 'или')}, но не #{half - shown}"
  end

  def hint_ladder(puzzle)
    [ "Везната е в равновесие, значи двете блюда са с еднакъв сбор — колкото и тежести да има на тях.",
      "Сборът на всички тежести е #{puzzle.total} кг. Ако извън везната остане една тежест, останалите се " \
      "делят на две равни блюда — помисли какво значи това за сбора им.",
      "Пробвай стойностите една по една: за всяка гледай може ли лявото блюдо да стигне точно до половината " \
      "с толкова тежести, колкото има." ]
  end
end

Authoring.family "logic.balance_aside", topic: "Логически задачи", area: "interactive_kangaroo",
                 variants: 8, rungs: BALANCE_LADDER do |c|
  weights = c.by_level([ 5, 6, 6, 7, 7, 8 ])
  puzzle = Balance.build(c, weights: weights, blanks: c.by_level([ 2, 2, 3, 3, 4, 4 ]))
  labels = puzzle.values.to_h { |value| [ value, puzzle.shown.include?(value) ? value.to_s : "" ] }
  labels[puzzle.aside] = "?"
  candidates = puzzle.free.select { |value| (puzzle.total - value).even? }.sort
  person = c.person

  c.q(
    text: "#{person} има тежести от #{Arrangement.list((1..weights).to_a)} килограма — всяка различна. " \
          "#{person} балансира везната с #{weights - 1} от тях и оставя една встрани. На лявото блюдо са " \
          "#{Balance.pan_phrase(puzzle, puzzle.left)}, а на дясното — " \
          "#{Balance.pan_phrase(puzzle, puzzle.right)}. Колко килограма е тежестта извън везната " \
          "(отбелязана с ?)?",
    answer: Num.ans(puzzle.aside),
    figure: Balance.figure_of(puzzle, labels),
    hints: Balance.hint_ladder(puzzle),
    explanation: Explain.build(
      idea: "Везната в равновесие значи едно уравнение: двете блюда имат равни сборове. Оттам и от " \
            "четността на общия сбор излиза кое може да остане встрани — и остава само една стойност.",
      steps: [
        "Сборът на всички тежести е #{puzzle.total} кг. Ако встрани остане тежест от x кг, върху везната са " \
        "#{puzzle.total} − x кг и те се делят на две равни блюда, значи #{puzzle.total} − x е четно число.",
        "Тежестите с надпис вече са на везната, затова x може да е само " \
        "#{Arrangement.list(candidates.map(&:to_s), 'или')} — останалите биха дали нечетен остатък.",
        candidates.reject { |value| value == puzzle.aside }
                  .map { |value| Balance.refusal(puzzle, value) }.join("; ").capitalize + ".",
        "Остава #{puzzle.aside} кг: тогава всяко блюдо е #{puzzle.half} кг и наистина " \
        "#{puzzle.left.join(' + ')} = #{puzzle.half} = #{puzzle.right.join(' + ')}."
      ],
      answer: "#{puzzle.aside} кг",
      check: "#{puzzle.half} + #{puzzle.half} + #{puzzle.aside} = #{puzzle.total} — двете блюда и тежестта " \
             "встрани дават всички тежести.",
      watch: "Не всяка тежест може да остане встрани: ако #{puzzle.total} − x е нечетно, блюдата не могат да " \
             "са равни. Първо четността, после пробите — иначе се пробва всичко напразно."
    )
  )
end

# The same picture with every unlabelled weight given a letter and every letter
# asked for. It is a different piece of reasoning: once the weight beside the
# scale is known, each pan has one blank left and its value comes out by
# subtraction — which is why this version keeps at most one blank per pan.
Authoring.family "logic.balance_fill", topic: "Логически задачи", area: "interactive_kangaroo",
                 variants: 8, rungs: BALANCE_FILL_LADDER do |c|
  weights = c.by_level([ 5, 6, 7, 8 ])
  puzzle = Balance.build(c, weights: weights, blanks: 2, per_pan: 1)
  # The letters go left pan, right pan, then the one standing aside, so the
  # question reads in the order the picture does.
  order = (puzzle.left + puzzle.right + [ puzzle.aside ]).reject { |value| puzzle.shown.include?(value) }
  letters = order.each_with_index.to_h { |value, index| [ value, Balance::LETTERS[index] ] }
  labels = puzzle.values.to_h { |value| [ value, puzzle.shown.include?(value) ? value.to_s : letters[value] ] }
  candidates = puzzle.free.select { |value| (puzzle.total - value).even? }.sort
  person = c.person

  c.q(
    text: "#{person} има тежести от #{Arrangement.list((1..weights).to_a)} килограма — всяка различна. " \
          "Везната е в равновесие, а една тежест стои встрани. Тежестите без число са означени с " \
          "#{Arrangement.list(order.map { |value| letters[value] })}. На лявото блюдо са " \
          "#{Balance.lettered_phrase(puzzle, puzzle.left, letters)}, на дясното — " \
          "#{Balance.lettered_phrase(puzzle, puzzle.right, letters)}, а встрани стои " \
          "#{letters[puzzle.aside]}. Попълни по колко килограма е всяка от тях.",
    widget: WidgetKit.blanks(order.each_with_index.map { |value, index|
      [ "w#{index + 1}", letters[value], value, "кг" ]
    }),
    figure: Balance.figure_of(puzzle, labels),
    hints: Balance.hint_ladder(puzzle),
    explanation: Explain.build(
      idea: "Първо се намира тежестта встрани — от четността на общия сбор — а след това всяко блюдо трябва да " \
            "стигне точно до половината, което определя останалите с изваждане.",
      steps: [
        "Сборът на всички тежести е #{puzzle.total} кг. Извън везната е #{letters[puzzle.aside]}; върху " \
        "везната са #{puzzle.total} − #{letters[puzzle.aside]} кг и се делят на две равни блюда, значи " \
        "#{puzzle.total} − #{letters[puzzle.aside]} е четно.",
        "Затова #{letters[puzzle.aside]} може да е само #{Arrangement.list(candidates.map(&:to_s), 'или')}. " +
          (candidates.size > 1 ?
            candidates.reject { |value| value == puzzle.aside }.map { |value| Balance.refusal(puzzle, value) }
                      .join("; ").capitalize + " — остава #{puzzle.aside}." :
            "Другите стойности дават нечетен остатък, затова #{letters[puzzle.aside]} = #{puzzle.aside}."),
        "Значи всяко блюдо е (#{puzzle.total} − #{puzzle.aside}) : 2 = #{puzzle.half} кг. " +
          [ puzzle.left, puzzle.right ].filter_map { |pan|
            blank = pan.find { |value| !puzzle.shown.include?(value) }
            next if blank.nil?

            "#{letters[blank]} = #{puzzle.half} − #{puzzle.labelled(pan).sum} = #{blank}"
          }.join("; ") + "."
      ],
      answer: order.map { |value| "#{letters[value]} = #{value}" }.join(", "),
      check: "#{puzzle.left.join(' + ')} = #{puzzle.half} = #{puzzle.right.join(' + ')}, а всички тежести " \
             "заедно дават #{puzzle.total}.",
      watch: "Двете блюда са равни по сбор, не по брой тежести — на едното може да има повече, но по-леки."
    )
  )
end

# ------------------------------------------ Два пътя през острова: колко са ---

# The type: two roads cross an island and the houses are counted by *side* — so
# many north of road A, so many east of road B — and one of the four counts is
# missing. Nothing is measured and no house is drawn: the two roads make a two by
# two table whose margins are given, and every question here is a margin the
# table forces.
#
# The point worth teaching, and the one the type is built on: the four quarters
# are *not* determined by the sides. The answer is, which is why the builder
# checks it by linear algebra rather than by trusting the shape of the question.
ROADS_LADDER = [ 1000, 1100, 1210, 1320, 1430, 1540 ].freeze
ROADS_QUARTERS_LADDER = [ 1150, 1290, 1430, 1570 ].freeze

module Roads
  # Where it happens, what is counted, and what the roads are called.
  SCENES = [
    { things: "къщи", one: "къща", every: "всяка къща", place: "острова", road: "път" },
    { things: "дървета", one: "дърво", every: "всяко дърво", place: "парка", road: "алея" },
    { things: "палатки", one: "палатка", every: "всяка палатка", place: "лагера", road: "пътека" },
    { things: "магазини", one: "магазин", every: "всеки магазин", place: "квартала", road: "улица" }
  ].freeze

  QUARTER_NAMES = { [ 0, 0 ] => "северозападната", [ 0, 1 ] => "североизточната",
                    [ 1, 0 ] => "югозападната", [ 1, 1 ] => "югоизточната" }.freeze
  QUARTER_SHORT = { [ 0, 0 ] => "СЗ", [ 0, 1 ] => "СИ", [ 1, 0 ] => "ЮЗ", [ 1, 1 ] => "ЮИ" }.freeze

  Table = Struct.new(:cells, :bands, :scene, keyword_init: true) do
    def width = 2
    def at(band, side) = cells[(band * 2) + side]
    def band(index) = [ at(index, 0), at(index, 1) ].sum
    def side(index) = (0...bands).sum { |b| at(b, index) }
    def total = cells.sum
  end

  module_function

  # Only the first letter: String#capitalize would turn "път A" into "Път a" and
  # rename the road.
  def cap(text) = text.sub(/\A./) { |letter| letter.upcase }

  # --- is the answer forced? --------------------------------------------------
  #
  # Each fact is which cells it adds up ("north of A" adds the two cells of the
  # top band), so a fact is a row of zeros and ones. The asked count is forced
  # exactly when its own row is a combination of the given rows — which is what
  # a student does by hand when they add and subtract the given numbers.
  def reduce(basis, vector)
    row = vector.map { |value| Rational(value) }
    basis.each do |column, pivot|
      next if row[column].zero?

      factor = row[column] / pivot[column]
      row = row.each_index.map { |index| row[index] - (factor * pivot[index]) }
    end
    row
  end

  def basis_of(vectors)
    basis = []
    vectors.each do |vector|
      row = reduce(basis, vector)
      column = row.index { |value| !value.zero? }
      basis << [ column, row ] if column
    end
    basis
  end

  def forced?(given, asked) = reduce(basis_of(given), asked).all?(&:zero?)

  # --- the facts --------------------------------------------------------------

  def band_vector(bands, index) = (0...(bands * 2)).map { |cell| cell / 2 == index ? 1 : 0 }
  def side_vector(bands, index) = (0...(bands * 2)).map { |cell| (cell % 2) == index ? 1 : 0 }
  def cell_vector(bands, band, side) = (0...(bands * 2)).map { |cell| cell == (band * 2) + side ? 1 : 0 }
  def total_vector(bands) = Array.new(bands * 2, 1)

  # --- the picture ------------------------------------------------------------

  def figure_of(table, seed:, quarters: false)
    road = table.scene[:road].capitalize
    lanes =
      if table.bands == 2
        [ [ "#{road} A", :horizontal, 0.0 ] ]
      else
        [ [ "#{road} A", :horizontal, -0.42 ], [ "#{road} C", :horizontal, 0.4 ] ]
      end
    Figures.island_roads(roads: lanes + [ [ "#{road} B", :vertical, 0.06 ] ],
                         quarters: quarters ? { [ -1, -1 ] => "СЗ", [ 1, -1 ] => "СИ",
                                                [ -1, 1 ] => "ЮЗ", [ 1, 1 ] => "ЮИ" } : {},
                         seed: seed)
  end

  # --- the words --------------------------------------------------------------

  def band_phrase(table, index)
    road = table.scene[:road]
    if table.bands == 2
      index.zero? ? "на север от #{road} A" : "на юг от #{road} A"
    else
      [ "на север от #{road} A", "между #{road} A и #{road} C", "на юг от #{road} C" ][index]
    end
  end

  def side_phrase(table, index) = "на #{index.zero? ? 'запад' : 'изток'} от #{table.scene[:road]} B"

  # Two forms, because Bulgarian needs both: one that answers "where" and can
  # follow "има", and one that is a plain noun phrase for "числото за …".
  def quarter_at(table, band, side)
    return "в #{QUARTER_NAMES[[ band, side ]]} четвърт" if table.bands == 2

    "#{band_phrase(table, band)} и #{side_phrase(table, side)}"
  end

  def quarter_of(table, band, side)
    return "#{QUARTER_NAMES[[ band, side ]]} четвърт" if table.bands == 2

    "частта #{band_phrase(table, band)} и #{side_phrase(table, side)}"
  end

  def hint_ladder(table)
    scene = table.scene
    [ "Пътищата делят #{scene[:place]} на части и всяка #{scene[:one]} е в точно една от тях.",
      "Всяко дадено число е сбор от няколко части — виж кои точно.",
      "Всички #{scene[:things]} могат да се преброят по два начина: по посоката север–юг и по посоката " \
      "изток–запад. Двата сбора са равни, и оттам излиза търсеното число." ]
  end
end

Authoring.family "logic.roads_sides", topic: "Логически задачи", area: "interactive_kangaroo",
                 variants: 8, rungs: ROADS_LADDER do |c|
  shape = c.by_level([ :sides2, :sides2, :quarter2, :sides3, :sides3, :sides3_extra ])
  bands = shape.to_s.include?("3") ? 3 : 2
  scene = c.pick(Roads::SCENES)
  band = c.by_level([ 2..5, 4..11, 2..7, 2..5, 5..12, 4..10 ])
  table = Roads::Table.new(bands: bands, scene: scene,
                           cells: Array.new(bands * 2) { c.int(band) })
  # A count of nothing reads oddly in a stem, and the answer has to be a number
  # worth asking for.
  raise Authoring::Duplicate if table.cells.any?(&:zero?)

  given = []
  asked = nil
  case shape
  when :sides2, :sides3
    (0...bands).each { |index| given << [ Roads.band_phrase(table, index), table.band(index), Roads.band_vector(bands, index) ] }
    given << [ Roads.side_phrase(table, 1), table.side(1), Roads.side_vector(bands, 1) ]
    asked = [ Roads.side_phrase(table, 0), table.side(0), Roads.side_vector(bands, 0) ]
  when :sides3_extra
    (0...bands).each { |index| given << [ Roads.band_phrase(table, index), table.band(index), Roads.band_vector(bands, index) ] }
    given << [ Roads.side_phrase(table, 1), table.side(1), Roads.side_vector(bands, 1) ]
    # One number more than the question needs: deciding what to ignore is the
    # work at this rung.
    given << [ Roads.quarter_at(table, 0, 1), table.at(0, 1), Roads.cell_vector(bands, 0, 1) ]
    asked = [ Roads.side_phrase(table, 0), table.side(0), Roads.side_vector(bands, 0) ]
  when :quarter2
    given << [ Roads.band_phrase(table, 1), table.band(1), Roads.band_vector(bands, 1) ]
    given << [ Roads.side_phrase(table, 1), table.side(1), Roads.side_vector(bands, 1) ]
    given << [ Roads.quarter_at(table, 0, 1), table.at(0, 1), Roads.cell_vector(bands, 0, 1) ]
    asked = [ Roads.quarter_at(table, 1, 0), table.at(1, 0), Roads.cell_vector(bands, 1, 0) ]
  end
  # The guard the whole type rests on: the question has an answer, and it is the
  # one the family thinks it is.
  raise Authoring::Duplicate unless Roads.forced?(given.map(&:last), asked.last)

  facts = given.map { |phrase, value,| "#{phrase} има #{value} #{scene[:things]}" }
  # Bulgarian puts a comma before "а", which Arrangement.list does not.
  sentence = Roads.cap([ facts[0..-2].join(", "), facts.last ].join(", а "))
  steps =
    case shape
    when :quarter2
      [ "#{Roads.cap(Roads.side_phrase(table, 1))} има #{table.side(1)} #{scene[:things]}, а " \
        "#{table.at(0, 1)} от тях са #{Roads.quarter_at(table, 0, 1)} — значи " \
        "#{Roads.quarter_at(table, 1, 1)} са #{table.side(1)} − #{table.at(0, 1)} = #{table.at(1, 1)}.",
        "#{Roads.cap(Roads.band_phrase(table, 1))} има #{table.band(1)} #{scene[:things]}, а " \
        "#{table.at(1, 1)} от тях са #{Roads.side_phrase(table, 1)} — остават " \
        "#{table.band(1)} − #{table.at(1, 1)} = #{asked[1]}." ]
    else
      [ "#{Roads.cap(scene[:every])} е в точно една от #{bands == 2 ? 'двете половини' : 'трите ленти'}, " \
        "затова всички #{scene[:things]} са " \
        "#{(0...bands).map { |index| table.band(index) }.join(' + ')} = #{table.total}.",
        "#{Roads.cap(scene[:every])} е също или #{Roads.side_phrase(table, 1)}, или " \
        "#{Roads.side_phrase(table, 0)}. " \
        "Първите са #{table.side(1)}, значи вторите са #{table.total} − #{table.side(1)} = #{asked[1]}." ] +
        (shape == :sides3_extra ?
          [ "Числото за #{Roads.quarter_of(table, 0, 1)} (#{table.at(0, 1)}) не участва: то е част от " \
            "лентата и от страната, които вече са преброени." ] : [])
    end

  c.q(
    text: "#{sentence}. Колко #{scene[:things]} има #{asked[0]}?",
    answer: Num.ans(asked[1]),
    figure: Roads.figure_of(table, seed: table.cells.sum + table.cells.first, quarters: shape == :quarter2),
    hints: Roads.hint_ladder(table),
    explanation: Explain.build(
      idea: shape == :quarter2 ?
        "Всяко дадено число е сбор от части на #{scene[:place]}. Като се извади познатата част, остава " \
        "търсената — по един и същи начин по редовете и по колоните." :
        "Пътищата броят едни и същи #{scene[:things]} по два различни начина. Сборът им е един и същ, " \
        "затова липсващата страна е разликата.",
      steps: steps,
      answer: "#{asked[1]} #{scene[:things]}",
      check: shape == :quarter2 ?
        "#{asked[1]} + #{table.at(1, 1)} = #{table.band(1)} и #{table.at(0, 1)} + #{table.at(1, 1)} = " \
        "#{table.side(1)} — и двете дадени числа излизат." :
        "#{table.side(1)} + #{asked[1]} = #{table.total} = " \
        "#{(0...bands).map { |index| table.band(index) }.join(' + ')} — двете броения дават едно и също.",
      watch: shape == :quarter2 ?
        "Числата се изваждат, не се събират: една четвърт се брои и в „#{Roads.band_phrase(table, 1)}“, и в " \
        "„#{Roads.side_phrase(table, 1)}“." :
        "Колко #{scene[:things]} има в отделните части не се знае — и не е нужно. Питат се само двете страни " \
        "на #{scene[:road]} B, а те се допълват до всички #{table.total}."
    )
  )
end

# The same island with a number for one quarter as well, which is exactly enough
# to pin all four: each one comes out of a single subtraction, in a chain.
Authoring.family "logic.roads_quarters", topic: "Логически задачи", area: "interactive_kangaroo",
                 variants: 8, rungs: ROADS_QUARTERS_LADDER do |c|
  scene = c.pick(Roads::SCENES)
  table = Roads::Table.new(bands: 2, scene: scene,
                           cells: Array.new(4) { c.int(c.by_level([ 2..6, 4..10, 6..16, 8..24 ])) })
  raise Authoring::Duplicate if table.cells.any?(&:zero?)

  given = [ Roads.band_vector(2, 0), Roads.band_vector(2, 1), Roads.side_vector(2, 1),
            Roads.cell_vector(2, 0, 1) ]
  raise Authoring::Duplicate unless (0...2).to_a.product((0...2).to_a)
                                           .all? { |band, side| Roads.forced?(given, Roads.cell_vector(2, band, side)) }

  c.q(
    text: "#{Roads.cap(Roads.band_phrase(table, 0))} има #{table.band(0)} #{scene[:things]}, " \
          "#{Roads.band_phrase(table, 1)} има #{table.band(1)}, #{Roads.side_phrase(table, 1)} има " \
          "#{table.side(1)}, а #{Roads.quarter_at(table, 0, 1)} има #{table.at(0, 1)}. Попълни по " \
          "колко #{scene[:things]} има в четирите четвърти — северозападната (СЗ), североизточната (СИ), " \
          "югозападната (ЮЗ) и югоизточната (ЮИ).",
    widget: WidgetKit.blanks([ [ "nw", "СЗ", table.at(0, 0) ], [ "ne", "СИ", table.at(0, 1) ],
                              [ "sw", "ЮЗ", table.at(1, 0) ], [ "se", "ЮИ", table.at(1, 1) ] ]),
    figure: Roads.figure_of(table, seed: table.total + table.cells.last, quarters: true),
    hints: Roads.hint_ladder(table),
    explanation: Explain.build(
      idea: "Четирите четвърти се намират една след друга: всяко дадено число е сбор от две четвърти, а " \
            "едната от тях вече е известна.",
      steps: [
        "СИ е дадено: #{table.at(0, 1)}. На север са #{table.band(0)}, значи СЗ = #{table.band(0)} − " \
        "#{table.at(0, 1)} = #{table.at(0, 0)}.",
        "На изток са #{table.side(1)}, от тях #{table.at(0, 1)} са на север, значи ЮИ = #{table.side(1)} − " \
        "#{table.at(0, 1)} = #{table.at(1, 1)}.",
        "На юг са #{table.band(1)}, от тях #{table.at(1, 1)} са на изток, значи ЮЗ = #{table.band(1)} − " \
        "#{table.at(1, 1)} = #{table.at(1, 0)}."
      ],
      answer: "СЗ #{table.at(0, 0)}, СИ #{table.at(0, 1)}, ЮЗ #{table.at(1, 0)}, ЮИ #{table.at(1, 1)}",
      check: "#{table.cells.join(' + ')} = #{table.total}, а на запад от #{scene[:road]} B са " \
             "#{table.at(0, 0)} + #{table.at(1, 0)} = #{table.side(0)}.",
      watch: "Без числото за една четвърт задачата няма единствен отговор: страните не определят четвъртите. " \
             "Тук то е дадено и точно затова всичко останало излиза."
    )
  )
end

# ------------------------------------------- Лабиринт от стаи: в какъв ред ---

# The type: a maze of rooms on one or two floors, doors between some of them,
# staircases between the floors, a way in and a way out, and stickers on the
# walls of a few rooms — in what order does the walker meet them?
#
# The maze is carved as a *spanning tree* over the rooms, so between any two
# rooms there is exactly one route with no going back on itself. That is what
# makes the answer a fact rather than a choice: with every sticker on that one
# route, the order they are met in is the same however the walker wanders,
# because the dead ends hold nothing.
#
# This is the one type in the catalogue whose figure is load-bearing: a maze
# cannot be put into a sentence, so the stem describes the rules and the plan
# carries the layout. See §5j.
MAZE_ORDER_LADDER = [ 950, 1070, 1190, 1310, 1430, 1550 ].freeze
MAZE_WALK_LADDER = [ 1100, 1240, 1380, 1520 ].freeze

module Maze
  STICKERS = %w[акула жаба носорог кон мишка сова пчела риба лисица].freeze
  # Captions for two plans. One plan gets none — there is no ground floor unless
  # there is a floor above it.
  FLOOR_NAMES = [ "партер", "първи етаж" ].freeze
  SIDES = { north: [ -1, 0 ], south: [ 1, 0 ], west: [ 0, -1 ], east: [ 0, 1 ] }.freeze

  Layout = Struct.new(:floors, :rows, :cols, :edges, :entrance, :exit, :path, :stickers, keyword_init: true) do
    def doors
      edges.filter_map do |(f1, r1, c1), (_, r2, c2)|
        next if r1 == r2 && c1 == c2

        r1 == r2 ? [ f1, r1, [ c1, c2 ].min, :east ] : [ f1, [ r1, r2 ].min, c1, :south ]
      end
    end

    def stairs = edges.select { |a, b| a[0] != b[0] }.flatten(1).uniq
    def steps = path.each_cons(2).count { |a, b| a[0] != b[0] }
    def order = stickers.sort_by { |cell, _| path.index(cell) }.map(&:last)
  end

  module_function

  def neighbours(cell, floors, rows, cols)
    floor, row, col = cell
    list = SIDES.values.map { |dr, dc| [ floor, row + dr, col + dc ] }
                .select { |_, r, c| r.between?(0, rows - 1) && c.between?(0, cols - 1) }
    list << [ floor - 1, row, col ] if floor.positive?
    list << [ floor + 1, row, col ] if floor < floors - 1
    list
  end

  # Randomised depth-first carving: the classic perfect maze, every room reached
  # exactly once, so the doors form a tree.
  def carve(c, floors, rows, cols)
    rooms = (0...floors).to_a.product((0...rows).to_a, (0...cols).to_a)
    seen = { c.pick(rooms) => true }
    stack = [ seen.keys.first ]
    edges = []
    until stack.empty?
      fresh = neighbours(stack.last, floors, rows, cols).reject { |room| seen[room] }
      if fresh.empty?
        stack.pop
        next
      end
      room = c.pick(fresh)
      seen[room] = true
      edges << [ stack.last, room ]
      stack << room
    end
    edges
  end

  def route(edges, from, to)
    links = {}
    edges.each do |a, b|
      (links[a] ||= []) << b
      (links[b] ||= []) << a
    end
    came = { from => nil }
    queue = [ from ]
    until queue.empty?
      room = queue.shift
      break if room == to

      (links[room] || []).each do |next_room|
        next if came.key?(next_room)

        came[next_room] = room
        queue << next_room
      end
    end
    path = [ to ]
    path.unshift(came[path.first]) while came[path.first]
    path
  end

  OPPOSITE = { north: :south, south: :north, west: :east, east: :west }.freeze

  # A door in an outside wall, on the ground floor. The way in and the way out go
  # on opposite sides of the building, the way the printed sheet places them:
  # it reads better and it keeps the route from being three rooms long.
  def doorway(c, rows, cols, side)
    case side
    when :north then [ 0, 0, c.int(0...cols), :north ]
    when :south then [ 0, rows - 1, c.int(0...cols), :south ]
    when :west then [ 0, c.int(0...rows), 0, :west ]
    else [ 0, c.int(0...rows), cols - 1, :east ]
    end
  end

  def build(c, floors:, rows:, cols:, stickers:, min_path: 0, tries: 140)
    tries.times do
      edges = carve(c, floors, rows, cols)
      side = c.pick(SIDES.keys)
      way_in = doorway(c, rows, cols, side)
      way_out = doorway(c, rows, cols, OPPOSITE[side])
      next if way_in[0, 3] == way_out[0, 3]

      path = route(edges, way_in[0, 3], way_out[0, 3])
      next if path.size < [ stickers + 2, min_path ].max
      # On two floors the route has to use the stairs, or the upper floor is
      # decoration.
      next if floors > 1 && path.each_cons(2).none? { |a, b| a[0] != b[0] }

      # Every sticker goes on the route, and never in the first or last room:
      # a sticker in a dead end would never be met, and the answer would depend
      # on how far the walker wandered.
      spots = c.sample(path[1..-2], stickers)
      next if spots.size < stickers

      layout = Layout.new(floors: floors, rows: rows, cols: cols, edges: edges,
                          entrance: way_in, exit: way_out, path: path,
                          stickers: spots.zip(c.sample(STICKERS, stickers)))
      # On two floors, at least one sticker upstairs — otherwise the stairs are
      # in the picture for nothing.
      next if floors > 1 && stickers.positive? && layout.stickers.none? { |cell,| cell[0].positive? }

      return layout
    end
    raise Authoring::Duplicate
  end

  def figure_of(layout)
    Figures.maze_floors(
      floors: (0...layout.floors).map { |floor|
        [ layout.floors > 1 ? FLOOR_NAMES[floor] : "", layout.rows, layout.cols ]
      },
      doors: layout.doors, stairs: layout.stairs,
      stickers: layout.stickers.to_h,
      ways: [ layout.entrance + [ "вход", :in ], layout.exit + [ "изход", :out ] ]
    )
  end

  # The route in words: what a reader can check against the plan.
  def moves(layout)
    layout.path.each_cons(2).map do |(f1, r1, c1), (f2, r2, c2)|
      if f1 != f2 then f2 > f1 ? "по стълбите на горния етаж" : "по стълбите на долния етаж"
      elsif c2 > c1 then "надясно"
      elsif c2 < c1 then "наляво"
      elsif r2 > r1 then "надолу по плана"
      else "нагоре по плана"
      end
    end
  end

  def rules(layout, person)
    house = layout.floors > 1 ? "Двуетажен лабиринт" : "Лабиринт"
    per_floor = layout.rows * layout.cols
    stairs =
      if layout.floors > 1
        " Стълбите свързват стаите на едно и също място на двата етажа; стълбищата са " \
          "#{layout.stairs.size / 2}."
      else
        ""
      end
    rooms = layout.floors > 1 ? "от стаи, по #{per_floor} на етаж" : "от #{per_floor} стаи"
    "#{house} #{rooms}: врата има там, където стената на плана е прекъсната.#{stairs} Между всеки две стаи " \
      "има само един път без връщане назад. #{person} влиза през входа и излиза през изхода."
  end

  def hint_ladder(layout)
    [ "Тръгни от входа и минавай само там, където стената е прекъсната.",
      "На всяко разклонение виж накъде води: до изхода води само един път, останалите свършват в задънена стая.",
      layout.floors > 1 ?
        "Стълбите също са път: от стая със стълби се минава в стаята на същото място на другия етаж." :
        "Отбелязвай стикерите, докато минаваш — важен е редът, в който ги виждаш." ]
  end
end

Authoring.family "logic.maze_order", topic: "Логически задачи", area: "interactive_kangaroo",
                 variants: 8, rungs: MAZE_ORDER_LADDER do |c|
  floors, rows, cols, count = c.by_level([ [ 1, 3, 3, 3 ], [ 1, 3, 4, 3 ], [ 2, 2, 3, 3 ],
                                           [ 2, 3, 3, 3 ], [ 2, 3, 3, 4 ], [ 2, 3, 4, 4 ] ])
  person = c.person
  layout = Maze.build(c, floors: floors, rows: rows, cols: cols, stickers: count)
  order = layout.order
  spots = layout.stickers.sort_by { |cell, _| layout.path.index(cell) }

  c.q(
    text: "#{Maze.rules(layout, person)} По стените на #{count} от стаите има по един стикер: " \
          "#{Arrangement.list(layout.stickers.map(&:last).sort)} (виж плана). Подреди стикерите в реда, " \
          "в който #{person} ще ги срещне.",
    widget: WidgetKit.ordering(order.each_with_index.map { |name, index| [ "s#{index}", name ] }),
    figure: Maze.figure_of(layout),
    hints: Maze.hint_ladder(layout),
    explanation: Explain.build(
      idea: "Лабиринтът е направен така, че между входа и изхода има само един път. Той се проследява " \
            "стая по стая и стикерите се отбелязват в реда, в който се появяват.",
      steps: [
        "Пътят от входа до изхода: #{Maze.moves(layout).join(', ')} — общо #{layout.path.size} стаи.",
        spots.map { |cell, name| "#{name} — в #{layout.path.index(cell) + 1}-та стая по пътя" }
             .join("; ").sub(/\A./) { |letter| letter.upcase } + ".",
        "Значи редът е #{order.join(' → ')}."
      ],
      answer: order.join(" → "),
      check: "Задънените стаи не съдържат стикери, затова редът не зависи от лутането: дори #{person} да " \
             "влезе в грешна стая и да се върне, стикерите се появяват в същия ред.",
      watch: "Редът е по пътя, а не по плана и не по етажите: стикер, който на плана изглежда близо до изхода, " \
             "може да се срещне първи."
    )
  )
end

# The same maze counted rather than ordered: how many rooms the route passes
# through and how many times it changes floor. Two floors only — with one floor
# the second number is always nought.
Authoring.family "logic.maze_walk", topic: "Логически задачи", area: "interactive_kangaroo",
                 variants: 8, rungs: MAZE_WALK_LADDER do |c|
  rows, cols, least = c.by_level([ [ 2, 3, 5 ], [ 3, 3, 6 ], [ 3, 4, 8 ], [ 3, 4, 10 ] ])
  person = c.person
  layout = Maze.build(c, floors: 2, rows: rows, cols: cols, stickers: 0, min_path: least)

  c.q(
    text: "#{Maze.rules(layout, person)} Попълни през колко стаи минава #{person} (заедно с първата и " \
          "последната) и колко пъти минава по стълби.",
    widget: WidgetKit.blanks([ [ "rooms", "стаи", layout.path.size ], [ "stairs", "по стълби", layout.steps ] ]),
    figure: Maze.figure_of(layout),
    hints: Maze.hint_ladder(layout) +
           [ "Броят на стаите включва и стаята на входа, и стаята на изхода." ],
    explanation: Explain.build(
      idea: "Единственият път се проследява веднъж и се брои по две неща наведнъж: стаите, през които минава, " \
            "и преходите между етажите.",
      steps: [
        "Пътят от входа до изхода: #{Maze.moves(layout).join(', ')}.",
        "Стаите се броят със входната и изходната: #{layout.path.size}.",
        "Преходите по стълби са #{layout.steps} — толкова пъти пътят сменя етажа."
      ],
      answer: "#{layout.path.size} стаи, #{layout.steps} по стълби",
      check: "Ходовете по пътя са #{layout.path.size - 1}, от които #{layout.steps} по стълби и " \
             "#{layout.path.size - 1 - layout.steps} през врати — заедно дават всички преходи.",
      watch: "Стаите са с една повече от ходовете: първата стая се влиза без ход. И задънените стаи не се " \
             "броят — те не са по пътя."
    )
  )
end

# --------------------------------------- Пъзелът: с кои две части се сглобява ---

# The type: four pieces of a jigsaw are drawn, all the same number of squares,
# and exactly one *pair* of them assembles the square (or rectangle) shown
# beside them. Nothing is measured; it is a packing question, and the only way
# through is to try.
#
# Pieces may be turned and turned over — the stem says so, and the solver works
# under the same rule, so a piece is never wrong merely for being the mirror of
# what fits.
TILING_LADDER = [ 950, 1070, 1190, 1310, 1430, 1550 ].freeze
TILING_HOLE_LADDER = [ 900, 1030, 1160, 1290 ].freeze

module Tiling
  module_function

  def normalise(cells)
    rows = cells.map(&:first).min
    cols = cells.map(&:last).min
    cells.map { |row, col| [ row - rows, col - cols ] }.sort
  end

  # The eight ways a flat piece can be laid down: four turns, each of them also
  # face down.
  def orientations(cells)
    turns = [ cells ]
    3.times { turns << turns.last.map { |row, col| [ col, -row ] } }
    (turns + turns.map { |shape| shape.map { |row, col| [ row, -col ] } }).map { |shape| normalise(shape) }.uniq
  end

  def canon(cells) = orientations(cells).min

  def connected?(cells)
    seen = [ cells.first ]
    queue = [ cells.first ]
    until queue.empty?
      row, col = queue.shift
      [ [ row - 1, col ], [ row + 1, col ], [ row, col - 1 ], [ row, col + 1 ] ].each do |nb|
        next unless cells.include?(nb) && !seen.include?(nb)

        seen << nb
        queue << nb
      end
    end
    seen.size == cells.size
  end

  def box(cells) = [ cells.map(&:first).max + 1, cells.map(&:last).max + 1 ]

  def fits?(cells, rows, cols)
    orientations(cells).any? { |shape| box(shape).then { |h, w| h <= rows && w <= cols } }
  end

  # Every way the piece can be laid inside the board, as a set of cells.
  def placements(cells, rows, cols)
    orientations(cells).flat_map do |shape|
      height, width = box(shape)
      next [] if height > rows || width > cols

      (0..(rows - height)).flat_map do |dr|
        (0..(cols - width)).map { |dc| shape.map { |row, col| [ row + dr, col + dc ] }.sort }
      end
    end
  end

  # The two placements that fill the board: the piece here, everything else
  # there. Comparing the leftover with the other piece's canonical form is the
  # whole test — no search over the second piece is needed.
  def fillings(one, other, rows, cols)
    board = (0...rows).to_a.product((0...cols).to_a).map { |row, col| [ row, col ] }
    goal = canon(other)
    placements(one, rows, cols).select { |spot| canon(board - spot) == goal }
  end

  def tile?(one, other, rows, cols) = fillings(one, other, rows, cols).any?

  # A piece cut out of the board itself, so the pair is known to fit: grow a
  # connected blob of the right size and keep it only if what is left is
  # connected too.
  def cut(c, rows, cols, size)
    board = (0...rows).to_a.product((0...cols).to_a).map { |row, col| [ row, col ] }
    piece = [ c.pick(board) ]
    while piece.size < size
      edge = piece.flat_map { |row, col| [ [ row - 1, col ], [ row + 1, col ], [ row, col - 1 ], [ row, col + 1 ] ] }
                  .uniq.select { |cell| board.include?(cell) && !piece.include?(cell) }
      raise Authoring::Duplicate if edge.empty?

      piece << c.pick(edge)
    end
    rest = board - piece
    raise Authoring::Duplicate unless connected?(rest)
    # A piece that is a plain rectangle gives the answer away: the reader sees
    # the cut without trying anything.
    raise Authoring::Duplicate if [ piece, rest ].any? { |part| box(part).inject(:*) == part.size }

    [ normalise(piece), normalise(rest) ]
  end

  # Another piece of the same size that still fits on the board — a candidate
  # distractor, grown at random rather than cut from the board.
  def loose(c, rows, cols, size)
    piece = [ [ 0, 0 ] ]
    while piece.size < size
      edge = piece.flat_map { |row, col| [ [ row - 1, col ], [ row + 1, col ], [ row, col - 1 ], [ row, col + 1 ] ] }
                  .uniq.reject { |cell| piece.include?(cell) }
      piece << c.pick(edge)
    end
    piece = normalise(piece)
    raise Authoring::Duplicate unless fits?(piece, rows, cols)
    raise Authoring::Duplicate if box(piece).inject(:*) == piece.size

    piece
  end

  # The whole plate: `count` pieces of which exactly one pair fills the board.
  def build(c, rows:, cols:, count:, tries: 60)
    size = (rows * cols) / 2
    tries.times do
      pieces = begin
        cut(c, rows, cols, size)
      rescue Authoring::Duplicate
        next
      end
      begin
        pieces << loose(c, rows, cols, size) while pieces.size < count
      rescue Authoring::Duplicate
        next
      end
      next if pieces.map { |piece| canon(piece) }.uniq.size < count

      order = c.sample(pieces, count)
      pairs = (0...count).to_a.combination(2).select { |a, b| tile?(order[a], order[b], rows, cols) }
      next unless pairs.size == 1

      return [ order, pairs.first ]
    end
    raise Authoring::Duplicate
  end

  # "част 1 — 3 на 4" — the bounding box of each piece, which is what a reader
  # can check against the drawing and what keeps two plates from sharing a stem.
  def boxes_phrase(pieces)
    pieces.each_with_index.map { |piece, index| "част #{index + 1} — #{box(piece).join(' на ')}" }.join(", ")
  end

  def hint_ladder(pieces, rows, cols)
    [ "Всяка част е от по #{pieces.first.size} квадратчета, а #{rows == cols ? 'квадратът' : 'правоъгълникът'} " \
      "е от #{rows * cols} — значи две части го покриват точно, без да се застъпват.",
      "Не пробвай напосоки: погледни ъглите. В ъгъла на пъзела трябва да легне ъгъл на някоя част.",
      "Частите могат да се въртят и да се обръщат — една част има до 8 положения, но само някои се вписват " \
      "в #{rows} на #{cols}." ]
  end
end

Authoring.family "logic.puzzle_pair", topic: "Логически задачи", area: "interactive_kangaroo",
                 variants: 8, rungs: TILING_LADDER do |c|
  rows, cols, count = c.by_level([ [ 3, 4, 4 ], [ 4, 4, 4 ], [ 4, 5, 4 ], [ 4, 6, 4 ], [ 4, 5, 5 ], [ 4, 6, 5 ] ])
  pieces, pair = Tiling.build(c, rows: rows, cols: cols, count: count)
  shape = rows == cols ? "квадрат" : "правоъгълник"

  c.q(
    text: "Разполагате с #{count} части от пъзел (на чертежа). Всяка част е от по #{(rows * cols) / 2} " \
          "квадратчета и се вписва в правоъгълник: #{Tiling.boxes_phrase(pieces)}. Частите могат да се въртят " \
          "и да се обръщат. С кои две от тях може да се сглоби #{shape}ът #{rows} на #{cols} от чертежа? " \
          "Избери двете части.",
    widget: WidgetKit.multi_select((0...count).map { |index| [ (index + 1).to_s, pair.include?(index) ] }),
    figure: Figures.puzzle_pieces(target: [ rows, cols ], pieces: pieces),
    hints: Tiling.hint_ladder(pieces, rows, cols),
    explanation: Explain.build(
      idea: "Двете части трябва да покрият #{rows * cols} квадратчета без застъпване. Броят е верен за всяка " \
            "двойка, затова решава само формата — и се проверява двойка по двойка.",
      steps: [
        "Части #{pair.map { |index| index + 1 }.join(' и ')} се сглобяват: сложи част " \
        "#{pair.first + 1} в #{shape}а и остава точно място за част #{pair.last + 1} — това става на " \
        "#{Tiling.fillings(pieces[pair.first], pieces[pair.last], rows, cols).size} разположения, " \
        "заедно със завъртените и обърнатите.",
        (0...count).to_a.combination(2).reject { |a, b| [ a, b ] == pair }
                  .map { |a, b| "#{a + 1} и #{b + 1}" }.join(", ") +
          " не се сглобяват: при всяко разположение остава дупка, която другата част не покрива.",
        "Затова отговорът е #{pair.map { |index| index + 1 }.join(' и ')}."
      ],
      answer: "части #{pair.map { |index| index + 1 }.join(' и ')}",
      check: "Двете части заедно са #{(rows * cols) / 2} + #{(rows * cols) / 2} = #{rows * cols} квадратчета, " \
             "колкото е #{shape}ът — и всяко квадратче е покрито точно веднъж.",
      watch: "Броят на квадратчетата не различава двойките: всички части са с еднакъв брой. И не забравяй, че " \
             "част може да се обърне — понякога пасва само огледално."
    )
  )
end

# The same pieces asked the other way round, because "shade where piece 1 goes"
# has no single answer: a square board has eight symmetries, so the mirror image
# of any assembly is another placement of the same piece. Here one piece is
# already lying in the board and the hole is what is left — and exactly one of
# the four pieces has that shape, whichever way it is turned.
Authoring.family "logic.puzzle_hole", topic: "Логически задачи", area: "interactive_kangaroo",
                 variants: 8, rungs: TILING_HOLE_LADDER do |c|
  rows, cols = c.by_level([ [ 3, 4 ], [ 4, 4 ], [ 4, 5 ], [ 4, 6 ] ])
  size = (rows * cols) / 2
  placed, hole = Tiling.cut(c, rows, cols, size)
  # The hole sits where it was cut, not normalised: it is a place on the board.
  board = (0...rows).to_a.product((0...cols).to_a).map { |row, col| [ row, col ] }
  laid = board - Tiling.placements(placed, rows, cols).find { |spot| Tiling.canon(board - spot) == Tiling.canon(hole) }
  raise Authoring::Duplicate if laid.nil? || laid.empty?

  wrong = []
  20.times do
    piece = begin
      Tiling.loose(c, rows, cols, size)
    rescue Authoring::Duplicate
      next
    end
    next if Tiling.canon(piece) == Tiling.canon(laid)
    next if wrong.any? { |other| Tiling.canon(other) == Tiling.canon(piece) }

    wrong << piece
    break if wrong.size == 3
  end
  raise Authoring::Duplicate if wrong.size < 3

  pieces = c.sample([ Tiling.normalise(laid) ] + wrong, 4)
  answer = pieces.index { |piece| Tiling.canon(piece) == Tiling.canon(laid) } + 1
  shape = rows == cols ? "квадрат" : "правоъгълник"

  c.q(
    text: "В #{shape} #{rows} на #{cols} вече е сложена една част (тъмната на чертежа) и е останала дупка от " \
          "#{size} квадратчета. Отстрани са четири части, всяка от по #{size} квадратчета, вписани в " \
          "правоъгълници: #{Tiling.boxes_phrase(pieces)}. Частите могат да се въртят и да се обръщат. С коя от " \
          "тях се допълва пъзелът?",
    options: %w[1 2 3 4],
    answer: answer.to_s,
    figure: Figures.puzzle_pieces(target: [ rows, cols ], pieces: pieces,
                                  placed: board - laid),
    hints: [ "Дупката е с форма на част — гледай нея, а не частите една по една.",
             "Преброй колко квадратчета има дупката в всеки ред: същите редове трябва да има и частта.",
             "Частта може да е обърната или завъртяна: сравнявай формата, а не как е нарисувана." ],
    explanation: Explain.build(
      idea: "Дупката има точно една форма. Всяка от частите се сравнява с нея — завъртяна и обърната — и " \
            "пасва само тази, която е същата фигура.",
      steps: [
        "Дупката по редове: " +
          (0...rows).map { |row|
            taken = laid.select { |r,| r == row }.map(&:last).sort
            "ред #{row + 1} — #{taken.empty? ? 'нищо' : taken.map { |col| col + 1 }.join(', ')}"
          }.join("; ") + ".",
        "Тази форма се вписва в правоъгълник #{Tiling.box(laid).join(' на ')} и има " \
        "#{Tiling.orientations(laid).size} различни положения.",
        "Само част #{answer} съвпада с нея; останалите се различават поне по един ред."
      ],
      answer: "част #{answer}",
      check: "Частта и вече сложената заедно са #{size} + #{size} = #{rows * cols} квадратчета, колкото е " \
             "#{shape}ът.",
      watch: "Не сравнявай по брой квадратчета — всички части са с еднакъв брой. Сравнявай по форма, и не " \
             "забравяй, че частта може да се обърне."
    )
  )
end

# ------------------------------------------ Точки в мрежата: правоъгълникът ---

# The type: dots are marked on the crossings of squared paper, and exactly four
# of them are the vertices of a rectangle — what is its perimeter? Nothing is
# measured off the drawing; the side of a square is 1 cm and the sides of the
# rectangle are counted.
#
# The solver looks for rectangles in *any* orientation, not only the upright
# ones, and that is not for show: a tilted rectangle among the dots would give
# the question a second answer, so the only way to promise "four of them" means
# one rectangle is to look for all of them. (A tilted rectangle on a lattice has
# an integer perimeter only in the 3-4-5 cases, so it is never the answer here —
# it is a hazard to be excluded, not a question to be asked.)
LATTICE_LADDER = [ 900, 1020, 1140, 1260, 1380, 1500 ].freeze
LATTICE_PICK_LADDER = [ 960, 1090, 1220, 1350 ].freeze

module Lattice
  module_function

  # Every rectangle among these points, in any orientation: two pairs of points
  # that share a midpoint and a distance are the diagonals of one.
  def rectangles(dots)
    groups = {}
    dots.combination(2) do |(x1, y1), (x2, y2)|
      key = [ x1 + x2, y1 + y2, ((x1 - x2)**2) + ((y1 - y2)**2) ]
      (groups[key] ||= []) << [ [ x1, y1 ], [ x2, y2 ] ]
    end
    groups.values.select { |pairs| pairs.size > 1 }
          .flat_map { |pairs| pairs.combination(2).map { |one, other| one + other } }
  end

  # The sides of a rectangle given as two diagonals: from one corner to each of
  # the two corners next to it.
  def sides(rect)
    a, c, b, d = rect
    [ [ a, b ], [ a, d ] ].map { |(x1, y1), (x2, y2)| Math.sqrt((((x1 - x2)**2) + ((y1 - y2)**2)).to_f) }
  end

  def perimeter(rect) = sides(rect).sum * 2

  def upright?(rect)
    xs = rect.map(&:first).uniq
    ys = rect.map(&:last).uniq
    xs.size == 2 && ys.size == 2
  end

  # An upright rectangle inside the grid, and then dots scattered around it —
  # each one kept only if it does not complete a second rectangle, which is what
  # makes "four of them" true.
  def build(c, cols:, rows:, dots:, least: 1, tries: 60)
    tries.times do
      width = c.int(1..cols)
      height = c.int(1..rows)
      # A one-square-wide sliver is spotted without looking; the upper rungs ask
      # for a rectangle with some body to it.
      next if [ width, height ].min < least

      left = c.int(0..(cols - width))
      bottom = c.int(0..(rows - height))
      corners = [ [ left, bottom ], [ left + width, bottom ],
                  [ left + width, bottom + height ], [ left, bottom + height ] ]
      marked = corners.dup
      spare = (0..cols).to_a.product((0..rows).to_a).map { |x, y| [ x, y ] } - corners
      c.sample(spare, spare.size).each do |dot|
        break if marked.size == dots
        # One rectangle, and it is the one the question is about.
        next unless rectangles(marked + [ dot ]).size == 1

        marked << dot
      end
      next unless marked.size == dots

      found = rectangles(marked)
      next unless found.size == 1 && upright?(found.first)

      return [ marked.sort, found.first ]
    end
    raise Authoring::Duplicate
  end

  def hint_ladder(cols, rows)
    [ "Правоъгълникът има четири върха сред отбелязаните точки — търси четири точки, а не всички наведнъж.",
      "Две от точките трябва да са една над друга (същата колона), а други две — на същите редове. Тръгни от " \
      "две точки в един ред и питай има ли под тях две точки в друг ред.",
      "Обиколката е два пъти сборът на двете страни, а страната на квадратче е 1 см — мери в квадратчета по " \
      "мрежата #{cols} на #{rows}." ]
  end
end

Authoring.family "logic.lattice_rectangle", topic: "Логически задачи", area: "interactive_kangaroo",
                 variants: 8, rungs: LATTICE_LADDER do |c|
  cols, rows, band, least = c.by_level([ [ 4, 4, 6..8, 1 ], [ 5, 5, 8..10, 1 ], [ 5, 5, 10..12, 2 ],
                                         [ 6, 6, 11..13, 2 ], [ 6, 6, 13..15, 2 ], [ 7, 7, 14..17, 2 ] ])
  count = c.int(band)
  dots, rect = Lattice.build(c, cols: cols, rows: rows, dots: count, least: least)
  width, height = Lattice.sides(rect).map(&:round)
  person = c.person

  c.q(
    text: "Страната на едно квадратче от мрежата е 1 см. #{person} отбелязва #{count} точки върху мрежата " \
          "#{cols} на #{rows} квадратчета (виж чертежа) и открива, че четири от тях са върхове на " \
          "правоъгълник. Каква е обиколката на този правоъгълник?",
    answer: Num.ans(Lattice.perimeter(rect).round),
    figure: Figures.lattice_dots(cols: cols, rows: rows, dots: dots),
    hints: Lattice.hint_ladder(cols, rows),
    explanation: Explain.build(
      idea: "Правоъгълник в мрежата се разпознава по два реда и две колони: две точки в един ред и точно под " \
            "тях две точки в друг ред. Обиколката се брои в квадратчета, по 1 см всяко.",
      steps: [
        "Върховете са #{rect.sort.map { |x, y| "(#{x}; #{y})" }.join(', ')} — по две точки в редове " \
        "#{rect.map(&:last).uniq.sort.join(' и ')} и в колони #{rect.map(&:first).uniq.sort.join(' и ')}.",
        "Страните са #{width} см и #{height} см, защото толкова квадратчета има между колоните и между " \
        "редовете.",
        "Обиколка: 2 · (#{width} + #{height}) = #{Lattice.perimeter(rect).round} см."
      ],
      answer: "#{Lattice.perimeter(rect).round} см",
      check: "Другите отбелязани точки не образуват правоъгълник — затова четворката е единствена, а " \
             "обиколката е точно тази.",
      watch: "Обиколката не е сборът на двете страни, а двойният сбор. И не всяка четворка точки е " \
             "правоъгълник: нужни са две точки в един ред и две точно под тях."
    )
  )
end

# The same lattice without a figure at all: the widget draws the marked points
# and the four to be found are clicked on it.
Authoring.family "logic.lattice_rectangle_pick", topic: "Логически задачи", area: "interactive_kangaroo",
                 variants: 8, rungs: LATTICE_PICK_LADDER do |c|
  cols, rows, band, least = c.by_level([ [ 4, 4, 6..8, 1 ], [ 5, 5, 8..10, 1 ],
                                         [ 6, 6, 10..13, 2 ], [ 6, 6, 13..16, 2 ] ])
  count = c.int(band)
  dots, rect = Lattice.build(c, cols: cols, rows: rows, dots: count, least: least)
  width, height = Lattice.sides(rect).map(&:round)
  person = c.person

  c.q(
    text: "#{person} отбелязва #{count} точки върху мрежата #{cols} на #{rows} квадратчета (показани в " \
          "полето). Точно четири от тях са върхове на правоъгълник. Щракни върху тези четири точки.",
    widget: WidgetKit.plot(points: rect.sort, x_range: (0..cols), y_range: (0..rows), fixed: dots),
    hints: Lattice.hint_ladder(cols, rows),
    explanation: Explain.build(
      idea: "Търсят се два реда и две колони, в които има точки: две точки в един ред и точно под тях две " \
            "точки в друг ред правят правоъгълник.",
      steps: [
        "Редовете с по две точки една под друга са #{rect.map(&:last).uniq.sort.join(' и ')}, а колоните — " \
        "#{rect.map(&:first).uniq.sort.join(' и ')}.",
        "Върховете са #{rect.sort.map { |x, y| "(#{x}; #{y})" }.join(', ')}.",
        "Страните му са #{width} и #{height} квадратчета."
      ],
      answer: rect.sort.map { |x, y| "(#{x}; #{y})" }.join(", "),
      check: "Никоя друга четворка от отбелязаните точки не е правоъгълник — затова отговорът е единствен.",
      watch: "Точките трябва да са върхове на правоъгълник, а не просто четири точки в мрежата: срещуположните " \
             "страни трябва да са по един ред и по една колона."
    )
  )
end

# ---------------------------------------- Квадрат от числа: липсващото число ---

# The type: a square of numbers with one cell empty, and one rule — the sum of
# each row equals the sum of *exactly one* column. What is the missing number?
#
# The rule is worth reading twice, and the builder checks it literally: for every
# row, exactly one column has the same sum. Not "the row sums are a permutation
# of the column sums", which is a different and stronger claim, and not "some
# column", which would leave the answer loose.
SUM_SQUARE_LADDER = [ 1000, 1100, 1200, 1300, 1400, 1500 ].freeze
SUM_SQUARE_FILL_LADDER = [ 1150, 1280, 1410, 1540 ].freeze

module SumSquare
  ROW_WORDS = %w[първи втори трети четвърти пети].freeze

  module_function

  def holds?(grid)
    columns = grid.transpose.map(&:sum)
    grid.map(&:sum).all? { |sum| columns.count(sum) == 1 }
  end

  # Every filling of the blanks that obeys the rule, values from 1 up.
  def solutions(grid, blanks, limit)
    found = []
    fill(grid, blanks, limit, 0, found)
    found
  end

  def fill(grid, blanks, limit, index, found)
    if index == blanks.size
      found << blanks.map { |row, col| grid[row][col] } if holds?(grid)
      return
    end

    row, col = blanks[index]
    (1..limit).each do |value|
      grid[row][col] = value
      fill(grid, blanks, limit, index + 1, found)
    end
    grid[row][col] = nil
  end

  # A square whose rows and columns already obey the rule: distinct row sums, and
  # the column sums the same numbers in another order. Then every row matches
  # exactly one column, because the sums are all different.
  #
  # The totals are picked *around the middle* of what the cells can hold — a row
  # summing near the maximum forces cells at the maximum, and there is no room
  # left to make the square look random.
  def square(c, size:, most:)
    middle = size * (most + 1) / 2
    spread = [ size, (most - 1) / 2 ].min
    offsets = c.sample((-spread..spread).to_a, size)
    raise Authoring::Duplicate if offsets.size < size

    sums = offsets.map { |offset| middle + offset }
    raise Authoring::Duplicate if sums.uniq.size < size || sums.any? { |sum| sum < size * 2 }

    columns = c.sample(sums, size)
    raise Authoring::Duplicate if columns == sums && size > 2

    grid = fill_to(c, sums, columns, size, most)
    raise Authoring::Duplicate if grid.nil? || !holds?(grid)

    grid
  end

  # A square with the given row and column totals and every cell between 1 and
  # `most`: start from ones and hand out the surplus one at a time, to a cell
  # picked at random among those that can still take it. Stuck means this draw
  # is no good, not that the totals are impossible.
  def fill_to(c, rows, cols, size, most)
    grid = Array.new(size) { Array.new(size, 1) }
    left_rows = rows.map { |sum| sum - size }
    left_cols = cols.map { |sum| sum - size }
    return nil if (left_rows + left_cols).any?(&:negative?)

    while left_rows.sum.positive?
      spots = (0...size).to_a.product((0...size).to_a)
                        .select { |row, col| left_rows[row].positive? && left_cols[col].positive? && grid[row][col] < most }
      return nil if spots.empty?

      row, col = c.pick(spots)
      grid[row][col] += 1
      left_rows[row] -= 1
      left_cols[col] -= 1
    end
    left_cols.all?(&:zero?) ? grid : nil
  end

  # "първи ред 1, 5, 10; втори ред 7, ?, 3"
  def rows_phrase(grid)
    grid.each_with_index.map do |line, row|
      "#{ROW_WORDS[row]} ред #{line.map { |value| value.nil? ? '?' : value }.join(', ')}"
    end.join("; ")
  end

  # The step that settles it. Either a row whose sum matches none of the *known*
  # columns — then it must be matched by the column with the blank in it, and
  # that fixes the blank — or, when every known row is already matched, the row
  # with the blank in it must match one of the known columns.
  def deduction(grid, blank, answer)
    row, col = blank
    columns = grid.transpose
    known_rows = grid.each_with_index.reject { |_, index| index == row }
    known_cols = columns.each_with_index.reject { |_, index| index == col }
    forced = known_rows.find { |line, _| known_cols.none? { |other, _| other.sum == line.sum } }

    if forced
      line, index = forced
      partial = columns[col].compact.sum
      "Ред #{index + 1} има сбор #{line.sum}, а измежду другите колони такъв сбор няма " \
        "(#{known_cols.map { |other, _| other.sum }.join(', ')}). Значи точно колоната с празното квадратче " \
        "трябва да е #{line.sum}: #{partial} + ? = #{line.sum}, откъдето ? = #{answer}."
    else
      partial = grid[row].compact.sum
      match = known_cols.find { |other, _| other.sum - partial == answer }
      return nil if match.nil?

      "Всеки от другите редове вече си има колона със същия сбор, затова редът с празното квадратче " \
        "(#{partial} + ?) трябва да съвпадне с колона #{match.last + 1}, чийто сбор е #{match.first.sum}: " \
        "#{partial} + ? = #{match.first.sum}, откъдето ? = #{answer}."
    end
  end

  def sums_line(grid)
    "по редове #{grid.map(&:sum).join(', ')}, а по колони #{grid.transpose.map(&:sum).join(', ')}"
  end

  def hint_ladder(grid)
    [ "Сметни сборовете, които вече могат да се сметнат: редовете и колоните без празно квадратче.",
      "Условието е за всеки ред: точно една колона има същия сбор. Погледни ред, чийто сбор не се среща " \
      "между готовите колони — той няма друг избор.",
      "Тогава колоната с празното квадратче трябва да има точно този сбор, а оттам празното квадратче се " \
      "намира с изваждане." ]
  end
end

Authoring.family "logic.sum_square_missing", topic: "Логически задачи", area: "interactive_kangaroo",
                 variants: 8, rungs: SUM_SQUARE_LADDER do |c|
  size, most, centre = c.by_level([ [ 3, 10, true ], [ 3, 12, false ], [ 3, 20, false ],
                                    [ 4, 12, true ], [ 4, 15, false ], [ 4, 25, false ] ])
  full = SumSquare.square(c, size: size, most: most)
  blank = centre && size.odd? ? [ size / 2, size / 2 ] : [ c.int(0...size), c.int(0...size) ]
  answer = full[blank.first][blank.last]
  grid = full.map(&:dup)
  grid[blank.first][blank.last] = nil
  # The rule has to pin the number down: if another value also obeys it, the
  # question has two answers.
  raise Authoring::Duplicate unless SumSquare.solutions(grid, [ blank ], most + 10) == [ [ answer ] ]

  reason = SumSquare.deduction(grid, blank, answer)
  raise Authoring::Duplicate if reason.nil?

  c.q(
    text: "В квадрат #{size} на #{size} са записани числата: #{SumSquare.rows_phrase(grid)}. Сборът на " \
          "числата в кой да е ред е равен на сбора на числата в точно една от колоните. Кое е липсващото " \
          "число на мястото на ?",
    answer: Num.ans(answer),
    figure: Figures.number_square(rows: grid),
    hints: SumSquare.hint_ladder(grid),
    explanation: Explain.build(
      idea: "Условието не казва „сборовете съвпадат по някакъв начин“, а нещо по-точно: за всеки ред има " \
            "точно една колона със същия сбор. Оттам се намира сборът на колоната с празното квадратче.",
      steps: [
        "Готовите сборове: редове без празно квадратче — " \
        "#{grid.each_with_index.reject { |_, index| index == blank.first }.map { |line, index| "ред #{index + 1}: #{line.sum}" }.join(', ')}; " \
        "колони без празно квадратче — " \
        "#{grid.transpose.each_with_index.reject { |_, index| index == blank.last }.map { |line, index| "колона #{index + 1}: #{line.sum}" }.join(', ')}.",
        reason,
        "Проверка на цялото условие при ? = #{answer}: сборовете са #{SumSquare.sums_line(full)} — всеки ред " \
        "има точно една колона със същия сбор."
      ],
      answer: answer.to_s,
      check: "Друго число не става: при по-малко или по-голямо от #{answer} колоната с празното квадратче " \
             "получава сбор, който или не се среща сред редовете, или се среща два пъти.",
      watch: "„Точно една колона“ значи и че не може да са две: ако два сбора се повторят, условието е " \
             "нарушено, дори числата да изглеждат подходящи."
    )
  )
end

# The same rule with more than one cell empty, filled in on the square itself.
Authoring.family "logic.sum_square_fill", topic: "Логически задачи", area: "interactive_kangaroo",
                 variants: 8, rungs: SUM_SQUARE_FILL_LADDER do |c|
  # Four by four and up, and never more than two blanks. A 3x3 with two holes is
  # rarely settled by the rule — three rows do not constrain enough — while a
  # bigger square has more rows each demanding exactly one column, so the answer
  # comes out forced. (Five by five is the widget's ceiling, §3.3.)
  size, most, holes = c.by_level([ [ 4, 10, 2 ], [ 4, 14, 2 ], [ 5, 12, 2 ], [ 5, 16, 2 ] ])
  full = SumSquare.square(c, size: size, most: most)
  blanks = c.sample((0...size).to_a.product((0...size).to_a), holes)
  # Two blanks in one row and column each would be settled by the same step
  # twice; spreading them makes the puzzle a chain.
  raise Authoring::Duplicate if blanks.map(&:first).uniq.size < holes || blanks.map(&:last).uniq.size < holes

  grid = full.map(&:dup)
  blanks.each { |row, col| grid[row][col] = nil }
  wanted = blanks.map { |row, col| full[row][col] }
  raise Authoring::Duplicate unless SumSquare.solutions(grid, blanks, most + 6) == [ wanted ]

  c.q(
    text: "В квадрат #{size} на #{size} са записани числата: #{SumSquare.rows_phrase(grid)}. Сборът на " \
          "числата в кой да е ред е равен на сбора на числата в точно една от колоните. Попълни липсващите " \
          "#{holes} числа.",
    widget: WidgetKit.grid_fill(rows: grid, answers: full),
    hints: SumSquare.hint_ladder(grid),
    explanation: Explain.build(
      idea: "Първо се смятат сборовете, които вече са цели, и се търси ред или колона, за която условието " \
            "оставя само една възможност. Всяко намерено число прави следващото по-лесно.",
      steps: [
        "Цели редове: " \
        "#{grid.each_with_index.select { |line,| line.none?(&:nil?) }.map { |line, index| "ред #{index + 1} — #{line.sum}" }.join(', ')}. " \
        "Цели колони: " \
        "#{grid.transpose.each_with_index.select { |line,| line.none?(&:nil?) }.map { |line, index| "колона #{index + 1} — #{line.sum}" }.join(', ')}.",
        "Числата са " \
        "#{blanks.each_with_index.map { |(row, col), index| "ред #{row + 1}, колона #{col + 1} — #{wanted[index]}" }.join('; ')}.",
        "Проверка: сборовете са #{SumSquare.sums_line(full)} — всеки ред има точно една колона със същия сбор."
      ],
      answer: blanks.each_with_index.map { |(row, col), index| "(#{row + 1}; #{col + 1}) = #{wanted[index]}" }.join(", "),
      check: "Сборът на всички числа в квадрата е #{full.flatten.sum} и по редове, и по колони — това е първата " \
             "проверка, която си струва.",
      watch: "Условието е „точно една колона“ за *всеки* ред. Комбинация, при която два реда се падат на една " \
             "и съща колона, не става, дори сборовете да излизат."
    )
  )
end

# ---------------------------------------------- Часовникът, който звъни често ---

# The type: a striking clock rings the hour on the hour and once, twice, three
# times at a quarter past, half past and a quarter to. How many strikes between
# two moments? Two things make it a problem rather than a sum: the hour count
# runs 1 to 12, so a window across noon or midnight goes 11, 12, 1, 2 — and the
# clock strikes *twelve* at midnight, not nothing — and the ends of the window
# have to be looked at one at a time.
#
# Nothing is drawn: the whole question is two sentences of rules and two times.
CHIMES_LADDER = [ 900, 1010, 1120, 1230, 1340, 1450 ].freeze
CHIMES_SPLIT_LADDER = [ 960, 1080, 1200, 1320 ].freeze

module Chimes
  QUARTERS = { 15 => 1, 30 => 2, 45 => 3 }.freeze
  PLACES = [ "в кухнята на баба", "в хола", "в антрето", "в кабинета на дядо",
             "в чакалнята на гарата", "в дядовата работилница" ].freeze

  Window = Struct.new(:from, :to, keyword_init: true) do
    # Every moment the clock strikes inside the window, with how many times.
    def strikes
      ((from + 1)..(to - 1)).filter_map do |minute|
        rest = minute % 60
        next if (rest % 15).positive?

        [ minute, rest.zero? ? Chimes.hour_count(minute / 60) : QUARTERS[rest] ]
      end
    end

    def hours = strikes.select { |minute,| (minute % 60).zero? }
    def quarters = strikes.reject { |minute,| (minute % 60).zero? }
    def total = strikes.sum(&:last)
    def crosses_noon? = (from / 60) < 12 && (to / 60) >= 12
    def crosses_midnight? = to >= 24 * 60
  end

  module_function

  # A striking clock counts 1 to 12: at noon and at midnight it strikes twelve.
  def hour_count(hour) = (hour % 12).zero? ? 12 : hour % 12

  def clock(minute) = format("%d:%02d", (minute / 60) % 24, minute % 60)

  # A window whose ends are never a striking moment: "from 7:00 to 9:00" would
  # leave a reader guessing whether those two strikes count, and the answer would
  # depend on the guess.
  def window(c, first:, last:, span:)
    hour = c.int(first..last)
    from = (hour * 60) + c.pick([ 5, 10, 20, 25, 35, 40, 50, 55 ])
    to = from + c.int(span)
    to += 5 if (to % 15).zero?
    raise Authoring::Duplicate if (from % 15).zero? || (to % 15).zero?

    Window.new(from: from, to: to)
  end

  def rules_phrase(place)
    "На всеки кръгъл час часовникът #{place} звъни толкова пъти, колкото е часът: в 3 часа — три пъти, в 12 " \
      "часа — дванайсет пъти. Освен това 15 минути след кръгъл час звъни веднъж, половин час след кръгъл час " \
      "— два пъти, а 45 минути след кръгъл час — три пъти."
  end

  # "7 + 8 + 9 + 10 + 11 = 45"
  def hours_sum(window)
    counts = window.hours.map(&:last)
    "#{counts.join(' + ')} = #{counts.sum}"
  end

  # The quarters go six to a full hour; only the ends of the window need looking
  # at one by one.
  def quarters_sum(window)
    grouped = window.quarters.group_by { |minute,| minute / 60 }
    whole = grouped.count { |_, list| list.sum(&:last) == 6 }
    parts = grouped.reject { |_, list| list.sum(&:last) == 6 }
                   .map { |hour, list| "след #{hour % 24} ч. — #{list.map { |minute, times| "#{clock(minute)} (#{times})" }.join(', ')}" }
    total = window.quarters.sum(&:last)
    line = "цели часове с всичките три звънения: #{whole} · 6 = #{whole * 6}"
    line += "; #{parts.join('; ')}" if parts.any?
    "#{line} — общо #{total}"
  end

  def hint_ladder(window)
    [ "Раздели броенето на две: звъненията на кръгъл час и звъненията на 15, 30 и 45 минути.",
      "На кръгъл час звъненията са толкова, колкото е часът — трябва ти сборът на часовете, които попадат " \
      "вътре в интервала.",
      "Всеки цял час вътре в интервала добавя 1 + 2 + 3 = 6 звънения от четвъртите. После погледни само двата " \
      "края: там може да липсва или да остане някое." ]
  end
end

Authoring.family "count.clock_chimes", topic: "Текстови задачи", area: "interactive_kangaroo",
                 variants: 8, rungs: CHIMES_LADDER do |c|
  # The count going 11, 12, 1, 2 is the trap of the type, so which rungs carry it
  # is a decision rather than an accident: the first two never cross noon, the
  # rest always do, and the top rung crosses midnight.
  first, last, span, cross = c.by_level([ [ 5, 7, 150..260, false ], [ 5, 7, 250..330, false ],
                                          [ 9, 11, 200..330, true ], [ 9, 11, 330..500, true ],
                                          [ 8, 11, 500..760, true ], [ 20, 22, 260..430, true ] ])
  window = Chimes.window(c, first: first, last: last, span: span)
  raise Authoring::Duplicate if window.strikes.size < 5
  raise Authoring::Duplicate unless (window.crosses_noon? || window.crosses_midnight?) == cross

  place = c.pick(Chimes::PLACES)
  when_word =
    if window.crosses_midnight? then "през нощта"
    elsif window.crosses_noon? then "днес"
    else "тази сутрин"
    end

  c.q(
    text: "#{Chimes.rules_phrase(place)} Колко пъти ще звъни часовникът #{when_word} във времето от " \
          "#{Chimes.clock(window.from)} до #{Chimes.clock(window.to)} часа?",
    answer: Num.ans(window.total),
    hints: Chimes.hint_ladder(window),
    explanation: Explain.build(
      idea: "Двата вида звънене се броят отделно: на кръгъл час — толкова, колкото е часът, а на четвъртите — " \
            "по 1, 2 и 3, което прави 6 за всеки цял час вътре в интервала.",
      steps: [
        "Кръглите часове в интервала са #{window.hours.map { |minute,| Chimes.clock(minute) }.join(', ')} и " \
        "дават #{Chimes.hours_sum(window)} звънения.",
        "Четвъртите: #{Chimes.quarters_sum(window)}.",
        "Общо: #{window.hours.sum(&:last)} + #{window.quarters.sum(&:last)} = #{window.total}."
      ],
      answer: "#{window.total} пъти",
      check: "Краищата: #{Chimes.clock(window.from)} и #{Chimes.clock(window.to)} не са моменти на звънене, " \
             "затова първото звънене е в #{Chimes.clock(window.strikes.first.first)}, а последното — в " \
             "#{Chimes.clock(window.strikes.last.first)}.",
      watch: window.crosses_noon? || window.crosses_midnight? ?
        "Часовникът брои до 12 и започва отново: в 12 часа звъни дванайсет пъти, а в 13 (1 ч.) — само един " \
        "път. Тъкмо тук се губят звънения." :
        "Краищата на интервала не са кръгли: провери дали първото и последното звънене наистина попадат " \
        "вътре, преди да събираш."
    )
  )
end

# The same clock, counted in two columns: the hour strikes and the quarter
# strikes, which is the split that makes the sum manageable.
Authoring.family "count.clock_chimes_split", topic: "Текстови задачи", area: "interactive_kangaroo",
                 variants: 8, rungs: CHIMES_SPLIT_LADDER do |c|
  first, last, span, cross = c.by_level([ [ 5, 7, 150..260, false ], [ 9, 11, 260..400, true ],
                                          [ 9, 11, 380..560, true ], [ 20, 22, 300..500, true ] ])
  window = Chimes.window(c, first: first, last: last, span: span)
  raise Authoring::Duplicate if window.strikes.size < 6
  raise Authoring::Duplicate unless (window.crosses_noon? || window.crosses_midnight?) == cross

  place = c.pick(Chimes::PLACES)

  c.q(
    text: "#{Chimes.rules_phrase(place)} Във времето от #{Chimes.clock(window.from)} до " \
          "#{Chimes.clock(window.to)} часа попълни по колко пъти звъни часовникът на кръгъл час и по колко " \
          "пъти на 15, 30 и 45 минути.",
    widget: WidgetKit.blanks([ [ "hours", "на кръгъл час", window.hours.sum(&:last) ],
                              [ "quarters", "на четвъртите", window.quarters.sum(&:last) ] ]),
    hints: Chimes.hint_ladder(window),
    explanation: Explain.build(
      idea: "Едно преброяване, две колонки: часовете се събират като числа, а четвъртите се броят по 6 на " \
            "всеки цял час.",
      steps: [
        "Кръгли часове: #{window.hours.map { |minute,| Chimes.clock(minute) }.join(', ')} — " \
        "#{Chimes.hours_sum(window)}.",
        "Четвърти: #{Chimes.quarters_sum(window)}.",
        "Двете заедно правят #{window.total} звънения, но в кутийките отиват поотделно."
      ],
      answer: "на кръгъл час #{window.hours.sum(&:last)}, на четвъртите #{window.quarters.sum(&:last)}",
      check: "Четвъртите винаги се делят на 6, ако интервалът съдържа цели часове: тук " \
             "#{window.quarters.sum(&:last)} = 6 · #{window.quarters.sum(&:last) / 6}" \
             "#{(window.quarters.sum(&:last) % 6).zero? ? '' : " + #{window.quarters.sum(&:last) % 6}"}.",
      watch: "Числата в двете кутийки не са едно и също нещо: на кръгъл час звъненията растат с часа, а на " \
             "четвъртите са винаги 1, 2 и 3."
    )
  )
end

# --------------------------------------------- Точки и черти: символ на число ---

# The type: a dot is 1 and a bar is 5, so a numeral is a few dots above a stack
# of bars — the Maya way of writing numbers, and a competition sheet favourite.
# Which symbol is the number, or which is the sum of the ones shown?
#
# The system has a rule that makes the wrong answers wrong: five dots become a
# bar, so a numeral never carries five of them. That is what the traps are built
# from — and the best of them is the swap, since 2 dots over 1 bar (7) and 1 dot
# over 2 bars (11) look almost the same and are not.
DOT_BAR_LADDER = [ 900, 1000, 1100, 1200, 1300, 1400 ].freeze
DOT_BAR_COUNT_LADDER = [ 950, 1080, 1210, 1340 ].freeze

module DotBar
  LETTERS = %w[А Б В Г Д].freeze
  MOST_DOTS = 4
  MOST_BARS = 3

  module_function

  def symbol(value) = [ value % 5, value / 5 ]
  def value(symbol) = symbol.first + (5 * symbol.last)
  def valid?(symbol) = symbol.first.between?(0, MOST_DOTS) && symbol.last.between?(0, MOST_BARS)

  def dots_words(count)
    { 0 => "без точки", 1 => "една точка" }.fetch(count, "#{count} точки")
  end

  def bars_words(count)
    { 0 => "без черти", 1 => "една черта" }.fetch(count, "#{count} черти")
  end

  # "три точки над една черта" — how the example in the question is spelled out.
  def describe(value)
    dots, bars = symbol(value)
    return dots_words(dots) if bars.zero?
    return bars_words(bars) if dots.zero?

    "#{dots_words(dots)} над #{bars_words(bars)}"
  end

  # Wrong answers that have to be looked at: one dot or one bar out, and the
  # swap, which is the trap of the whole type.
  def near(target)
    dots, bars = symbol(target)
    [ [ dots + 1, bars ], [ dots - 1, bars ], [ dots, bars + 1 ], [ dots, bars - 1 ],
      [ bars, dots ], [ dots + 2, bars ], [ dots - 2, bars ], [ dots + 1, bars - 1 ],
      [ dots - 1, bars + 1 ] ]
      .select { |option| valid?(option) && value(option) != target && value(option).positive? }.uniq
  end

  def options(c, target)
    wrong = c.sample(near(target), 4)
    raise Authoring::Duplicate if wrong.size < 4 || wrong.map { |option| value(option) }.uniq.size < 4

    c.sample([ symbol(target) ] + wrong, 5)
  end

  # An example for the rules sentence, never the number being asked about.
  def example(c, avoid)
    value = c.int(6..19)
    raise Authoring::Duplicate if value == avoid || (value % 5).zero?

    value
  end

  def rules_phrase(c, example)
    c.pick([
      "В символите точката означава 1, а хоризонталната черта означава 5, като чертите се пишат под точките. " \
      "Пет точки се заменят с една черта, затова в символ никога няма 5 точки. Например символът с " \
      "#{describe(example)} е числото #{example}.",
      "Числата се пишат с точки и черти: точката е 1, чертата е 5, а чертите стоят под точките. Пет точки " \
      "винаги се заменят с една черта, така че 5 точки в един символ не се срещат. Например " \
      "#{describe(example)} значи #{example}."
    ])
  end

  def hint_ladder
    [ "Всяка черта е 5, всяка точка е 1 — значи стойността е 5 · (чертите) + (точките).",
      "Обратно: за да напишеш число, вземи колкото се може повече черти, а остатъкът стават точки.",
      "Внимавай да не разменяш точки и черти: 2 точки над 1 черта е 7, а 1 точка над 2 черти е 11." ]
  end
end

Authoring.family "logic.dot_bar_pick", topic: "Числа и редици", area: "interactive_kangaroo",
                 variants: 8, rungs: DOT_BAR_LADDER do |c|
  # The whole system only writes 1 to 19, so the bands overlap rather than sit
  # apart: a rung of four possible numbers would ask the same one three times.
  band, addends, part = c.by_level([ [ 6..11, 0, nil ], [ 10..15, 0, nil ], [ 14..19, 0, nil ],
                                     [ 8..14, 2, 2..9 ], [ 14..19, 2, 5..12 ], [ 12..19, 3, 2..8 ] ])
  parts = addends.zero? ? nil : Array.new(addends) { c.int(part) }
  target = parts ? parts.sum : c.int(band)
  raise Authoring::Duplicate unless band.cover?(target) && DotBar.valid?(DotBar.symbol(target))

  given = parts&.map { |part| DotBar.symbol(part) }
  choices = DotBar.options(c, target)
  answer = DotBar::LETTERS[choices.index { |option| DotBar.value(option) == target }]
  sample = DotBar.example(c, target)

  c.q(
    text: "#{DotBar.rules_phrase(c, sample)} " +
          (given ?
            "Горе на чертежа са показани #{addends} числа. Кой от символите А–Д е символът на техния сбор?" :
            "Кой от символите А–Д е символът на числото #{target}?"),
    options: DotBar::LETTERS.dup,
    answer: answer,
    figure: Figures.dot_bar_plate(symbols: choices, labels: DotBar::LETTERS, given: given),
    hints: DotBar.hint_ladder,
    explanation: Explain.build(
      idea: given ?
        "Първо се четат показаните числа (черти по 5, точки по 1), после се събират, и накрая сборът се " \
        "написва пак с черти и точки." :
        "Числото се написва с колкото се може повече черти по 5, а остатъкът — с точки по 1.",
      steps: [
        given ?
          "Показаните числа са #{given.map { |option| "#{DotBar.describe(DotBar.value(option))} = #{DotBar.value(option)}" }.join(', ')}; " \
          "сборът им е #{given.map { |option| DotBar.value(option) }.join(' + ')} = #{target}." :
          "#{target} = 5 · #{target / 5} + #{target % 5}, значи символът е с #{DotBar.bars_words(target / 5)} и " \
          "#{DotBar.dots_words(target % 5)}.",
        "Символът на #{target} е #{DotBar.describe(target)} — това е #{answer}.",
        "Другите: " + choices.each_with_index.reject { |option,| DotBar.value(option) == target }
                             .map { |option, index| "#{DotBar::LETTERS[index]} е #{DotBar.value(option)}" }
                             .join(", ") + "."
      ],
      answer: answer,
      check: "5 · #{target / 5} + #{target % 5} = #{target} — чертите и точките дават точно търсеното число.",
      watch: "Разменените символи изглеждат почти еднакво: #{DotBar.describe(target)} не е същото като " \
             "#{DotBar.describe(DotBar.value(DotBar.symbol(target).reverse))}, ако второто е символ на друго " \
             "число."
    )
  )
end

# The same system counted rather than chosen: how many dots and how many bars.
Authoring.family "logic.dot_bar_count", topic: "Числа и редици", area: "interactive_kangaroo",
                 variants: 8, rungs: DOT_BAR_COUNT_LADDER do |c|
  band, addends, part = c.by_level([ [ 6..13, 0, nil ], [ 12..19, 0, nil ],
                                     [ 9..17, 2, 2..10 ], [ 12..19, 3, 2..8 ] ])
  parts = addends.zero? ? nil : Array.new(addends) { c.int(part) }
  target = parts ? parts.sum : c.int(band)
  raise Authoring::Duplicate unless band.cover?(target) && DotBar.valid?(DotBar.symbol(target))

  given = parts&.map { |part| DotBar.symbol(part) }
  dots, bars = DotBar.symbol(target)
  sample = DotBar.example(c, target)

  c.q(
    text: "#{DotBar.rules_phrase(c, sample)} " +
          (given ?
            "На чертежа са показани #{addends} числа. Попълни колко точки и колко черти има символът на " \
            "техния сбор." :
            "Попълни колко точки и колко черти има символът на числото #{target}."),
    widget: WidgetKit.blanks([ [ "dots", "точки", dots ], [ "bars", "черти", bars ] ]),
    figure: given ? Figures.dot_bar_plate(symbols: given, labels: nil) : nil,
    hints: DotBar.hint_ladder,
    explanation: Explain.build(
      idea: "Чертите са петиците, точките са единиците: числото се дели на 5 и частното дава чертите, а " \
            "остатъкът — точките.",
      steps: [
        given ?
          "Показаните числа са #{given.map { |option| "#{DotBar.describe(DotBar.value(option))} = #{DotBar.value(option)}" }.join(', ')}, " \
          "а сборът им е #{target}." :
          "Числото е #{target}.",
        "#{target} : 5 = #{target / 5} и остатък #{target % 5}, значи чертите са #{bars}, а точките — #{dots}.",
        "Символът е #{DotBar.describe(target)}."
      ],
      answer: "#{dots} точки, #{bars} черти",
      check: "5 · #{bars} + #{dots} = #{target} — обратната сметка връща числото.",
      watch: "Точките никога не са 5 или повече: пет точки се заменят с черта. Ако в кутийката за точки " \
             "излезе 5, значи чертите са с една по-малко, отколкото трябва."
    )
  )
end

# ------------------------------------------- Кръстословица с числа и действия ---

# The type: a crossword of arithmetic. Cells hold numbers and operators, every
# straight run reads as an equation, and the runs cross — so a number found in
# one equation is a given in the next. What goes where the question mark is?
#
# §3.3 has listed cross-number puzzles as something `grid_fill` is for since it
# was written, and nothing had taken it up; this is that gap.
CROSS_NUMBER_LADDER = [ 950, 1060, 1170, 1280, 1390, 1500 ].freeze
CROSS_SQUARE_LADDER = [ 1000, 1130, 1260, 1390 ].freeze

module CrossNumber
  # Each template is a layout and the equations its straight runs make. A slot is
  # a symbol; "" is a cell whose value the layout takes from a slot elsewhere.
  #
  #   corner: a + b = c, then c ∘ d = e going down from c.
  #   open:   the same with the vertical carried on into a second horizontal.
  #   sheet:  the shape of the printed problem, four equations round a black cell.
  TEMPLATES = {
    corner: {
      grid: [ [ :a, "+", :b, "=", :c ],
              [ nil, nil, nil, nil, :op2 ],
              [ nil, nil, nil, nil, :d ],
              [ nil, nil, nil, nil, "=" ],
              [ nil, nil, nil, nil, :e ] ],
      equations: [ [ :a, "+", :b, :c ], [ :c, :op2, :d, :e ] ],
      given: [ :a, :b, :d ],
      ask: :e
    },
    open: {
      grid: [ [ nil, nil, nil, nil, :z ],
              [ nil, nil, nil, nil, "+" ],
              [ :a, "+", :b, "=", :c ],
              [ nil, nil, nil, nil, "=" ],
              [ nil, nil, :d, "−", :e, "=", :f ] ],
      equations: [ [ :a, "+", :b, :c ], [ :z, "+", :c, :e ], [ :d, "−", :e, :f ] ],
      given: [ :a, :b, :z, :d ],
      ask: :f
    },
    sheet: {
      grid: [ [ nil, nil, nil, nil, :z ],
              [ nil, nil, nil, nil, "+" ],
              [ :a, "+", :b, "=", :c ],
              [ nil, nil, "+", :black, "=" ],
              [ nil, nil, :d, "−", :e, "=", :f ],
              [ nil, nil, "=" ],
              [ nil, nil, :g ] ],
      equations: [ [ :a, "+", :b, :c ], [ :z, "+", :c, :e ], [ :b, "+", :d, :g ],
                   [ :d, "−", :e, :f ] ],
      given: [ :a, :b, :z, :g ],
      ask: :f
    }
  }.freeze

  module_function

  def apply(op, left, right) = op == "+" ? left + right : left - right

  # One unknown at a time, the way it is solved by hand — and the order the steps
  # come out in is the order the explanation uses.
  def solve(equations, known)
    values = known.dup
    steps = []
    loop do
      moved = false
      equations.each do |left, op, right, result|
        operator = op.is_a?(Symbol) ? values[op] : op
        next if operator.nil?

        missing = [ left, right, result ].reject { |slot| values.key?(slot) }
        next unless missing.size == 1

        case missing.first
        when result then values[result] = apply(operator, values[left], values[right])
        when right
          values[right] = operator == "+" ? values[result] - values[left] : values[left] - values[result]
        else
          values[left] = operator == "+" ? values[result] - values[right] : values[result] + values[right]
        end
        steps << [ missing.first, [ left, operator, right, result ] ]
        moved = true
      end
      break unless moved
    end
    [ values, steps ]
  end

  # Why no search for other solutions: a value deduced from an equation in which
  # it is the only unknown is implied by the givens, so any assignment that
  # satisfies the equations agrees with it. A puzzle whose every blank falls out
  # of such a step therefore has exactly one solution, and the propagation is the
  # proof. What has to be checked is that the propagation *finished* — which is
  # what `build` does — and the verification script confirms it independently, by
  # the rank of the linear system.

  # Built forwards along the order the puzzle is solved in, not from independent
  # random numbers: the later equations subtract, so their operands have to be
  # drawn *after* the values they must exceed. (Drawing them independently and
  # hoping left four of the six rungs empty.)
  def build(c, template:, band:)
    shape = TEMPLATES[template]
    a = c.int(band)
    b = c.int(band)
    seed =
      case template
      when :corner
        op = c.pick([ "+", "−" ])
        total = a + b
        d = op == "+" ? c.int(band) : c.int(1..(total - 1))
        raise Authoring::Duplicate if d < 1

        { a: a, b: b, op2: op, d: d }
      else
        z = c.int(0..[ band.max / 3, 2 ].max)
        # d has to clear z + a + b, or the subtraction that follows goes negative.
        step = c.int(2..[ band.max, 4 ].max)
        d = z + a + b + step
        template == :sheet ? { a: a, b: b, z: z, g: b + d } : { a: a, b: b, z: z, d: d }
      end

    values, steps = solve(shape[:equations], seed)
    slots = shape[:equations].flat_map { |left, op, right, result| [ left, right, result ] }.uniq
    raise Authoring::Duplicate unless slots.all? { |slot| values[slot].is_a?(Integer) }
    raise Authoring::Duplicate unless slots.all? { |slot| values[slot].between?(1, band.max * 6) }
    raise Authoring::Duplicate if values[shape[:ask]] < 2

    [ shape, values, steps, slots - shape[:given] ]
  end

  # The layout with the numbers written in: given cells show their value, blank
  # cells are empty, and the asked one carries the question mark.
  def drawn(shape, values)
    shape[:grid].map do |line|
      line.map do |content|
        next content if content.nil? || content == :black
        next content unless content.is_a?(Symbol)
        next values[content] if shape[:given].include?(content)
        next "?" if content == shape[:ask]
        next values[content] if content == :op2

        ""
      end
    end
  end

  # A step reads as the equation it came from, not as the arithmetic that solved
  # it: when the missing number is an operand, "21 + ? = 103 дава 82" is what the
  # square actually says, and "21 + 103 дава 82" is nonsense.
  def step_words(shape, values, steps)
    steps.map do |slot, (left, op, right, result)|
      operator = op.is_a?(Symbol) ? values[op] : op
      line =
        if slot == result
          "#{values[left]} #{operator} #{values[right]} = #{values[result]}"
        elsif slot == right
          "от #{values[left]} #{operator} ? = #{values[result]} излиза #{values[slot]}"
        else
          "от ? #{operator} #{values[right]} = #{values[result]} излиза #{values[slot]}"
        end
      slot == shape[:ask] ? "#{line} — това е числото на мястото на ?" : line
    end
  end

  def hint_ladder
    [ "Всеки ред и всяка колона от съседни квадратчета е едно равенство — намери онова, в което липсва само " \
      "едно число.",
      "Пресечните квадратчета работят за две равенства наведнъж: намереното в едното е дадено в другото.",
      "Върви по реда, в който равенствата се затварят, а не отляво надясно — въпросителният знак обикновено е " \
      "последният." ]
  end
end

Authoring.family "puzzle.cross_number", topic: "Ред на действията", area: "interactive_kangaroo",
                 variants: 8, rungs: CROSS_NUMBER_LADDER do |c|
  template, band = c.by_level([ [ :corner, 4..20 ], [ :corner, 10..40 ], [ :open, 6..25 ],
                                [ :open, 12..45 ], [ :sheet, 8..30 ], [ :sheet, 15..50 ] ])
  shape, values, steps, blanks = CrossNumber.build(c, template: template, band: band)

  c.q(
    text: "На чертежа всеки ред и всяка колона от съседни квадратчета е едно равенство. Дадените числа са " \
          "#{shape[:given].map { |slot| values[slot] }.join(', ')}, а празните квадратчета трябва да се " \
          "попълнят така, че всички равенства да са верни. Кое число трябва да се постави на мястото на " \
          "въпросителния знак?",
    answer: Num.ans(values[shape[:ask]]),
    figure: Figures.cross_number(cells: CrossNumber.drawn(shape, values)),
    hints: CrossNumber.hint_ladder,
    explanation: Explain.build(
      idea: "Всяко равенство се решава само когато в него липсва едно число. Затова редът на действията не е " \
            "отляво надясно, а по реда, в който равенствата се затварят едно след друго.",
      steps: CrossNumber.step_words(shape, values, steps),
      answer: values[shape[:ask]].to_s,
      check: "Обратно: #{shape[:equations].map { |left, op, right, result|
        operator = op.is_a?(Symbol) ? values[op] : op
        "#{values[left]} #{operator} #{values[right]} = #{values[result]}"
      }.join('; ')} — всички равенства излизат.",
      watch: "Празните квадратчета не се пълнят наслуки: всяко от тях участва в две равенства и трябва да " \
             "пасне и на двете. Ако едно равенство има две неизвестни, започни от друго."
    )
  )
end

# The rectangular cousin, which is what `grid_fill` was made for: three rows and
# three columns of additions in one five-by-five square, some cells empty.
Authoring.family "puzzle.cross_square", topic: "Ред на действията", area: "interactive_kangaroo",
                 variants: 8, rungs: CROSS_SQUARE_LADDER do |c|
  band, holes = c.by_level([ [ 2..12, 2 ], [ 4..20, 3 ], [ 6..30, 4 ], [ 10..45, 5 ] ])
  a = c.int(band)
  b = c.int(band)
  d = c.int(band)
  e = c.int(band)
  cells = { a: a, b: b, c: a + b, d: d, e: e, f: d + e,
            g: a + d, h: b + e, i: a + b + d + e }
  order = %i[a b c d e f g h i]
  blanks = c.sample(order, holes)
  # Every blank has to follow from the rest, and by search rather than by hope.
  known = (order - blanks).to_h { |slot| [ slot, cells[slot] ] }
  equations = [ [ :a, "+", :b, :c ], [ :d, "+", :e, :f ], [ :g, "+", :h, :i ],
                [ :a, "+", :d, :g ], [ :b, "+", :e, :h ], [ :c, "+", :f, :i ] ]
  # Every blank has to fall out of an equation with one unknown in it; a square
  # where two blanks only ever appear together is not solvable by a child.
  filled, = CrossNumber.solve(equations, known)
  raise Authoring::Duplicate unless order.all? { |slot| filled[slot] == cells[slot] }

  rows = [ [ :a, "+", :b, "=", :c ], [ "+", "", "+", "", "+" ], [ :d, "+", :e, "=", :f ],
           [ "=", "", "=", "", "=" ], [ :g, "+", :h, "=", :i ] ]
  shown = rows.map { |line| line.map { |slot| slot.is_a?(Symbol) ? (blanks.include?(slot) ? nil : cells[slot]) : slot } }
  answers = rows.map { |line| line.map { |slot| slot.is_a?(Symbol) ? cells[slot] : slot } }

  c.q(
    text: "В квадрата 5 на 5 всеки ред и всяка колона от числа е равенство със събиране — три по редове и " \
          "три по колони. Дадените числа са " \
          "#{(order - blanks).map { |slot| cells[slot] }.join(', ')}, а #{holes} квадратчета са празни. " \
          "Попълни ги така, че всичките шест равенства да са верни.",
    widget: WidgetKit.grid_fill(rows: shown, answers: answers),
    hints: CrossNumber.hint_ladder,
    explanation: Explain.build(
      idea: "Шест равенства в един квадрат: три по редове и три по колони. Всяко празно квадратче участва в " \
            "едно от редовете и в една от колоните, затова се намира от онова равенство, в което е единственото " \
            "неизвестно.",
      steps: [
        "Редовете са #{cells[:a]} + #{cells[:b]} = #{cells[:c]}, #{cells[:d]} + #{cells[:e]} = #{cells[:f]} и " \
        "#{cells[:g]} + #{cells[:h]} = #{cells[:i]}.",
        "Колоните са #{cells[:a]} + #{cells[:d]} = #{cells[:g]}, #{cells[:b]} + #{cells[:e]} = #{cells[:h]} и " \
        "#{cells[:c]} + #{cells[:f]} = #{cells[:i]}.",
        "Липсващите числа са #{blanks.map { |slot| cells[slot] }.join(', ')} — всяко излиза от равенството, в " \
        "което е единственото неизвестно."
      ],
      answer: blanks.map { |slot| cells[slot] }.join(", "),
      check: "Долният десен ъгъл е сборът на всички четири горни числа: " \
             "#{cells[:a]} + #{cells[:b]} + #{cells[:d]} + #{cells[:e]} = #{cells[:i]} — и по редове, и по " \
             "колони се получава същото.",
      watch: "Не пълни квадратче, в което и редът, и колоната имат по две неизвестни — първо потърси " \
             "равенство с едно."
    )
  )
end

# ------------------------------------ Точки по страните: лицето на триъгълника ---

# The type: a square ABCD with points marked on two of its sides, and a triangle
# from the opposite corner to those two points. Its area is a fixed fraction of
# the square's — three eighths when both points are midpoints — so the side comes
# out of one equation.
#
# The fraction is computed, not assumed: the corners and the marked points are
# exact rationals and the area comes from the shoelace formula, which is why the
# family can use any fractions along the sides and any corner as the apex.
SQUARE_AREA_LADDER = [ 1050, 1160, 1270, 1380, 1490, 1600 ].freeze
SQUARE_PART_LADDER = [ 1100, 1230, 1360, 1490 ].freeze

module SquareArea
  CORNERS = { "A" => [ 0r, 0r ], "B" => [ 1r, 0r ], "C" => [ 1r, 1r ], "D" => [ 0r, 1r ] }.freeze
  SIDES = { ab: %w[A B], bc: %w[B C], cd: %w[C D], da: %w[D A] }.freeze
  # The two sides that do not touch the apex, in the order they are met going
  # round the square.
  FAR_SIDES = { "A" => [ :bc, :cd ], "B" => [ :cd, :da ], "C" => [ :da, :ab ], "D" => [ :ab, :bc ] }.freeze
  FRACTIONS = [ Rational(1, 2), Rational(1, 3), Rational(2, 3), Rational(1, 4), Rational(3, 4) ].freeze

  module_function

  def on(side, fraction)
    from, to = SIDES[side].map { |letter| CORNERS[letter] }
    [ from[0] + ((to[0] - from[0]) * fraction), from[1] + ((to[1] - from[1]) * fraction) ]
  end

  # The area of a triangle as a fraction of the whole square — exact, from the
  # shoelace formula over rationals.
  def part(points)
    (a, b, c) = points
    (((b[0] - a[0]) * (c[1] - a[1])) - ((b[1] - a[1]) * (c[0] - a[0]))).abs / 2
  end

  def figure_of(apex, marks, letters)
    Figures.square_marks(marks: letters.zip(marks).to_h, polygon: [ apex ] + letters)
  end

  def side_name(side) = SIDES[side].join

  # "средата на BC" or "точка от BC, която я дели в отношение 1 : 2, считано от B"
  def mark_words(label, side, fraction)
    return "#{label} е средата на #{side_name(side)}" if fraction == Rational(1, 2)

    from = SIDES[side].first
    "#{label} дели #{side_name(side)} в отношение #{fraction.numerator} : " \
      "#{fraction.denominator - fraction.numerator}, считано от #{from}"
  end

  def setup_words(apex, marks, letters)
    parts = letters.each_with_index.map { |label, index| mark_words(label, *marks[index]) }
    "В квадрата ABCD #{parts.join(', а ')}."
  end

  def hint_ladder(apex, letters)
    [ "Лицето на триъгълник се смята с основа и височина — избери страна на квадрата за основа.",
      "Работи с a като страна на квадрата: точките по страните са на половината, на третината или на " \
      "четвъртината от a, а лицето на триъгълника излиза като част от a².",
      "Лицето на триъгълника #{apex}#{letters.join} е една и съща част от квадрата при всяка негова " \
      "големина — намери първо тази част." ]
  end
end

Authoring.family "geo.square_marks_side", topic: "Площ", area: "interactive_kangaroo",
                 variants: 8, rungs: SQUARE_AREA_LADDER do |c|
  pool, outside = c.by_level([ [ [ Rational(1, 2) ], false ],
                               [ [ Rational(1, 2), Rational(1, 3) ], false ],
                               [ SquareArea::FRACTIONS, false ],
                               [ SquareArea::FRACTIONS, false ],
                               [ SquareArea::FRACTIONS, true ],
                               [ SquareArea::FRACTIONS, true ] ])
  apex = c.pick(%w[A B C D])
  sides = SquareArea::FAR_SIDES[apex]
  marks = sides.map { |side| [ side, c.pick(pool) ] }
  letters = %w[E F]
  points = [ SquareArea::CORNERS[apex] ] + marks.map { |side, fraction| SquareArea.on(side, fraction) }
  share = SquareArea.part(points)
  # The side has to be a whole number of centimetres and the given area a whole
  # number too, or the question is not the one the sheet asks.
  side = c.int(c.by_level([ 2..8, 2..10, 3..12, 4..16, 4..14, 6..20 ]))
  area = share * side * side
  raise Authoring::Duplicate unless area.denominator == 1 && area >= 3
  raise Authoring::Duplicate if outside && ((1 - share) * side * side).denominator != 1

  triangle = "#{apex}#{letters.join}"
  answer = outside ? (1 - share) * side * side : side

  c.q(
    text: "#{SquareArea.setup_words(apex, marks, letters)} Лицето на триъгълника #{triangle} е " \
          "#{area.to_i} cm². " +
          (outside ?
            "Колко квадратни сантиметра е лицето на останалата част от квадрата (квадратът без триъгълника)?" :
            "Колко сантиметра е страната на квадрата?"),
    answer: Num.ans(answer),
    figure: SquareArea.figure_of(apex, marks, letters),
    hints: SquareArea.hint_ladder(apex, letters),
    explanation: Explain.build(
      idea: "Лицето на триъгълника е една и съща част от квадрата, каквато и да е страната му. Затова първо " \
            "се намира тази част, а после от нея — страната.",
      steps: [
        "Ако страната е a, точките са на #{marks.map { |side, fraction| "#{fraction.numerator}/#{fraction.denominator} от #{SquareArea.side_name(side)}" }.join(' и ')}, " \
        "а лицето на #{triangle} излиза #{share.numerator}/#{share.denominator} от a².",
        "От условието #{share.numerator}/#{share.denominator} · a² = #{area.to_i}, значи " \
        "a² = #{(area / share).to_i} и a = #{side}.",
        outside ?
          "Останалата част е квадратът без триъгълника: #{side * side} − #{area.to_i} = #{answer.to_i} cm²." :
          "Страната на квадрата е #{side} cm."
      ],
      answer: outside ? "#{answer.to_i} cm²" : "#{side} cm",
      check: "Квадратът е #{side} · #{side} = #{side * side} cm², а " \
             "#{share.numerator}/#{share.denominator} от #{side * side} е #{area.to_i} cm² — точно даденото " \
             "лице.",
      watch: "Частта не зависи от големината на квадрата: #{share.numerator}/#{share.denominator} важи и за " \
             "малък, и за голям квадрат. И не бъркай лицето на триъгълника с лицето на квадрата."
    )
  )
end

# The same figure with the numbers taken away: what fraction of the square is the
# triangle? The answer is the fraction itself, which ExactValue compares as a
# number, so 3/8 and 0,375 both pass.
Authoring.family "geo.square_marks_part", topic: "Площ", area: "interactive_kangaroo",
                 variants: 8, rungs: SQUARE_PART_LADDER do |c|
  pool, outside = c.by_level([ [ [ Rational(1, 2), Rational(1, 3) ], false ],
                               [ SquareArea::FRACTIONS, false ],
                               [ SquareArea::FRACTIONS, false ],
                               [ SquareArea::FRACTIONS, true ] ])
  apex = c.pick(%w[A B C D])
  sides = SquareArea::FAR_SIDES[apex]
  marks = sides.map { |side| [ side, c.pick(pool) ] }
  letters = %w[E F]
  points = [ SquareArea::CORNERS[apex] ] + marks.map { |side, fraction| SquareArea.on(side, fraction) }
  share = SquareArea.part(points)
  raise Authoring::Duplicate if share <= 0 || share >= 1

  wanted = outside ? 1 - share : share
  triangle = "#{apex}#{letters.join}"

  c.q(
    text: "#{SquareArea.setup_words(apex, marks, letters)} " +
          (outside ?
            "Каква част от квадрата е останала извън триъгълника #{triangle}? Отговори с дроб." :
            "Каква част от квадрата е триъгълникът #{triangle}? Отговори с дроб."),
    answer: "#{wanted.numerator}/#{wanted.denominator}",
    figure: SquareArea.figure_of(apex, marks, letters),
    hints: SquareArea.hint_ladder(apex, letters),
    explanation: Explain.build(
      idea: "Частта не зависи от страната, затова може да се смята при страна 1: тогава лицето на квадрата е " \
            "1, а лицето на триъгълника е точно търсената част.",
      steps: [
        "При страна 1 върховете са #{apex} и точките на " \
        "#{marks.map { |side, fraction| "#{fraction.numerator}/#{fraction.denominator} от #{SquareArea.side_name(side)}" }.join(' и ')}.",
        "Лицето на триъгълника #{triangle} излиза #{share.numerator}/#{share.denominator} от квадрата.",
        outside ?
          "Извън триъгълника остава 1 − #{share.numerator}/#{share.denominator} = " \
          "#{wanted.numerator}/#{wanted.denominator}." :
          "Значи търсената част е #{share.numerator}/#{share.denominator}."
      ],
      answer: "#{wanted.numerator}/#{wanted.denominator}",
      check: "При страна 4 cm лицето на квадрата е 16 cm², а на триъгълника — " \
             "#{(share * 16).to_f.round(2).to_s.tr('.', ',')} cm²: отношението е същото.",
      watch: "Търси се част от квадрата, а не лице в квадратни сантиметри — отговорът е дроб между 0 и 1."
    )
  )
end
