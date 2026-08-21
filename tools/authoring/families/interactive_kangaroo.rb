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
