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
