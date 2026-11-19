# Задачи за подготвителната група: броене, повече и по-малко, събиране и
# изваждане до 10 с картинки, съседни числа, наредба, редици и „кое не е от
# групата“.
#
# The bank used to start at 600 on purpose (see interactive_early.rb): that
# was the floor every new student started from, and nothing sat below the
# first grade. A five-year-old who could not yet do „Колко е 3 + 7?“ had
# nothing aimed at them at all. On 2026-11-18 a child rated 416 got one problem
# in twenty right for a whole evening, and the dispatcher's target for them
# (269) had not one problem within 180 points. These rungs run from 300 up to
# the old floor, so placement and the cold start now begin lower (both read the
# easiest problem there is), a decision the owner took knowing that.
#
# Every problem shows its objects as pictures, so a child who reads slowly (or
# has „Прочети ми“ read it) counts what is in front of them, and every answer
# is a number or one of the options shown. The topics are all ones the first
# grade already has, so the grade hold never sets them aside.

module Preschool
  module_function

  PRE = [ 300, 360, 420, 480, 540, 600 ].freeze

  # [emoji, one, many, the many]
  Thing = Struct.new(:emoji, :one, :many, :the_many) do
    def count(n) = "#{n} #{n == 1 ? one : many}"
    def row(n) = ([ emoji ] * n).join(" ")
  end

  THINGS = [
    Thing.new("🍎", "ябълка", "ябълки", "ябълките"),
    Thing.new("🍐", "круша", "круши", "крушите"),
    Thing.new("🍌", "банан", "банана", "бананите"),
    Thing.new("🍓", "ягода", "ягоди", "ягодите"),
    Thing.new("🐟", "рибка", "рибки", "рибките"),
    Thing.new("🐥", "пиленце", "пиленца", "пиленцата"),
    Thing.new("⭐", "звезда", "звезди", "звездите"),
    Thing.new("🎈", "балон", "балона", "балоните"),
    Thing.new("⚽", "топка", "топки", "топките"),
    Thing.new("🚗", "кола", "коли", "колите"),
    Thing.new("🌸", "цвете", "цветя", "цветята"),
    Thing.new("🍪", "бисквита", "бисквити", "бисквитите")
  ].freeze

  # Neuter nouns, so „Кое животно е трето?“ agrees with every one of them.
  Animal = Struct.new(:emoji, :name, :the)
  ANIMALS = [
    Animal.new("🐶", "кученце", "кученцето"), Animal.new("🐱", "коте", "котето"),
    Animal.new("🐰", "зайче", "зайчето"), Animal.new("🐻", "мече", "мечето"),
    Animal.new("🐸", "жабче", "жабчето"), Animal.new("🐥", "пиленце", "пиленцето"),
    Animal.new("🐷", "прасенце", "прасенцето"), Animal.new("🐭", "мишле", "мишлето")
  ].freeze

  ORDINALS = %w[първо второ трето четвърто пето шесто].freeze

  # Sets of four pictures a repeating pattern is drawn from.
  PATTERN_SETS = [
    %w[🔴 🔵 🟡 🟢], %w[🍎 🍌 🍇 🍓], %w[🐶 🐱 🐰 🐸], %w[⚽ 🎈 🚗 🌸], %w[⭐ 🍪 🐟 🌸]
  ].freeze

  # The category, a member of it in the singular, and its members with their
  # names as the explanation says them. Only singular names: „черешите не е
  # плод“ does not agree.
  Group = Struct.new(:many, :one, :members)
  GROUPS = {
    fruit: Group.new("плодове", "плод", [ %w[🍎 ябълката], %w[🍐 крушата], %w[🍌 бананът], %w[🍓 ягодата], %w[🍇 гроздето], %w[🍊 портокалът] ]),
    animal: Group.new("животни", "животно", [ %w[🐶 кученцето], %w[🐱 котето], %w[🐰 зайчето], %w[🐻 мечето], %w[🐷 прасенцето], %w[🐭 мишлето] ]),
    vehicle: Group.new("превозни средства", "превозно средство", [ %w[🚗 колата], %w[🚌 автобусът], %w[🚲 колелото], %w[🚂 влакът], %w[🚜 тракторът] ]),
    clothes: Group.new("дрехи", "дреха", [ %w[👕 тениската], %w[👖 панталонът], %w[🧢 шапката], %w[👗 роклята] ]),
    vegetable: Group.new("зеленчуци", "зеленчук", [ %w[🥕 морковът], %w[🥒 краставицата], %w[🌽 царевицата], %w[🥔 картофът] ])
  }.freeze

  def counting(from, to) = (from..to).to_a.join(", ")

  def names(list)
    return list.first if list.size == 1

    "#{list[0..-2].join(', ')} и #{list.last}"
  end
end

# ------------------------------------------------------------------ Броене ---

Authoring.family "pre.count_pictures", topic: "Числа и редици", area: "preschool", variants: 8,
                 rungs: Preschool::PRE do |c|
  thing = c.pick(Preschool::THINGS)
  count = c.int(c.by_level([ 1..3, 2..5, 4..7, 5..10, 3..7, 5..10 ]))
  mixed = c.level >= 4

  if mixed
    other = c.pick(Preschool::THINGS - [ thing ])
    extra = c.int(2..4)
    pictures = c.sample(([ thing.emoji ] * count) + ([ other.emoji ] * extra), count + extra)
    raise Authoring::Duplicate if pictures.first(count).uniq.size == 1 && pictures.last(extra).uniq.size == 1

    text = "Колко са #{thing.the_many}? #{pictures.join(' ')}"
  else
    text = "Колко #{thing.many} има? #{thing.row(count)}"
  end

  c.q(
    text: text,
    answer: Num.ans(count),
    explanation: Explain.build(
      idea: "Броим всяка #{mixed ? "от #{thing.the_many}" : 'картинка'} точно по веднъж, като я посочваме с пръст.",
      steps: [
        "Тръгваме отляво надясно и казваме: #{Preschool.counting(1, count)}.",
        "Последното число, което казахме, е #{count}. Толкова са."
      ],
      answer: thing.count(count),
      check: "Броим още веднъж отдясно наляво. Пак излиза #{count}.",
      watch: mixed ? "Броим само #{thing.the_many}. Другите картинки не се броят." : "Не пропускаме картинка и не броим една и съща два пъти."
    ),
    hints: [ "Посочвай всяка картинка с пръст, докато броиш." ]
  )
end

Authoring.family "pre.which_more", topic: "Числа и редици", area: "preschool", variants: 8,
                 rungs: Preschool::PRE do |c|
  thing = c.pick(Preschool::THINGS)
  # [smallest, largest, the gap between the rows]
  low, high, gaps = c.by_level([ [ 1, 6, 3..5 ], [ 1, 6, 2..3 ], [ 2, 7, 1..2 ], [ 2, 8, 0..2 ], [ 3, 10, 0..1 ], [ 4, 10, 1..1 ] ])
  gap = c.int(gaps)
  small = c.int(low..(high - gap))
  big = small + gap
  first, second = c.coin ? [ small, big ] : [ big, small ]
  ask_fewer = c.level >= 3 && c.coin
  word = ask_fewer ? "по-малко" : "повече"

  answer =
    if first == second then "еднакво"
    elsif (first > second) != ask_fewer then "на първия ред"
    else "на втория ред"
    end

  c.q(
    text: "Къде има #{word} #{thing.many}: на първия ред или на втория?\n" \
          "Първи ред: #{thing.row(first)}\nВтори ред: #{thing.row(second)}",
    options: [ "на първия ред", "на втория ред", "еднакво" ],
    answer: answer,
    explanation: Explain.build(
      idea: "Броим картинките на всеки ред и сравняваме двете числа.",
      steps: [
        "На първия ред има #{thing.count(first)}.",
        "На втория ред има #{thing.count(second)}.",
        first == second ? "#{first} и #{second} са равни, значи на двата реда има еднакво #{thing.many}." : "#{[ first, second ].max} е повече от #{[ first, second ].min}."
      ],
      answer: answer,
      check: "Свързваме с пръст по една картинка от двата реда. #{first == second ? 'Никоя не остава сама.' : "На реда с повече остават #{thing.count((first - second).abs)} без двойка."}",
      watch: ask_fewer ? "Търсим реда с по-малко, а не с повече." : "Гледаме колко са картинките, а не колко дълъг изглежда редът."
    ),
    hints: [ "Преброй картинките във всеки ред поотделно и сравни двете числа." ]
  )
end

# ---------------------------------------------------------- Събиране, изваждане ---

Authoring.family "pre.add_pictures", topic: "Събиране и изваждане", area: "preschool", variants: 8,
                 rungs: Preschool::PRE do |c|
  thing = c.pick(Preschool::THINGS)
  total_max = c.by_level([ 3, 5, 6, 8, 10, 10 ])
  a = c.int(1..(total_max - 1))
  b = c.int(1..(total_max - a))
  total = a + b
  # The top rung writes the second group as a number: the step from pictures
  # to „и още 3“.
  added = c.top? ? thing.count(b) : thing.row(b)

  c.q(
    text: "Тук има #{thing.row(a)}. Добавяме още #{added}. Колко #{thing.many} стават?",
    answer: Num.ans(total),
    explanation: Explain.build(
      idea: "Събираме: към първите #{a} прибавяме още #{b} и броим всички заедно.",
      steps: [
        "Започваме от #{a} и броим нататък още #{b}: #{Preschool.counting(a + 1, total)}.",
        "#{a} + #{b} = #{total}."
      ],
      answer: thing.count(total),
      check: "Броим всички картинки една по една от начало. Пак са #{total}.",
      watch: "Не започваме броенето пак от 1 за новите. Продължаваме от #{a}."
    ),
    hints: [ "Колко са първите? Продължи да броиш нататък с новите." ]
  )
end

Authoring.family "pre.take_away", topic: "Събиране и изваждане", area: "preschool", variants: 8,
                 rungs: Preschool::PRE do |c|
  thing = c.pick(Preschool::THINGS)
  have = c.int(c.by_level([ 2..3, 3..5, 3..6, 4..8, 5..10, 6..10 ]))
  # Taking everything leaves nothing, which is worth meeting, but not on the first rung.
  take = c.int(1..(c.level >= 2 ? have : have - 1))
  left = have - take

  c.q(
    text: "Тук има #{thing.row(have)}. Взимаме #{thing.count(take)}. Колко #{thing.many} остават?",
    answer: Num.ans(left),
    explanation: Explain.build(
      idea: "Изваждаме: от всички #{have} махаме #{take} и броим колко са останали.",
      steps: [
        "Закриваме с пръст #{take} от картинките.",
        left.zero? ? "Взехме всички, затова не остава нито една. #{have} − #{take} = 0." : "Броим незакритите: #{Preschool.counting(1, left)}. #{have} − #{take} = #{left}."
      ],
      answer: thing.count(left),
      check: "Останалите и взетите заедно са #{left} + #{take} = #{have}, колкото бяха в началото.",
      watch: "Отговорът е колко остават, а не колко взехме."
    ),
    hints: [ "Закрий с пръсти толкова картинки, колкото взимаме. Колко се виждат още?" ]
  )
end

# ---------------------------------------------------------------- Числата ---

Authoring.family "pre.number_neighbours", topic: "Числа и редици", area: "preschool", variants: 8,
                 rungs: Preschool::PRE do |c|
  case c.level
  when 0
    if c.coin
      n = c.int(1..5)
      text = "Кое число идва веднага след #{n}?"
    else
      n = c.int(2..4)
      text = "Броим: #{Preschool.counting(1, n)}. Кое число казваме после?"
    end
    answer = n + 1
    steps = [ "Броим от 1: #{Preschool.counting(1, n + 1)}.", "След #{n} идва #{n + 1}." ]
    watch = "Числото след #{n} е с 1 по-голямо от #{n}."
  when 1
    n = c.int(2..6)
    before = c.coin
    text = before ? "Кое число е точно преди #{n}?" : "Кое число идва веднага след #{n}?"
    answer = before ? n - 1 : n + 1
    steps = [ "Броим от 1: #{Preschool.counting(1, [ n + 1, 3 ].max)}.", before ? "Точно преди #{n} казваме #{n - 1}." : "След #{n} казваме #{n + 1}." ]
    watch = before ? "„Преди“ значи по-малкото число, с 1 по-малко." : "„След“ значи по-голямото число, с 1 повече."
  when 2, 3
    start = c.int(c.level == 2 ? 1..2 : 1..6)
    row = (start..(start + 4)).to_a
    hole = c.int(1..3)
    answer = row[hole]
    shown = row.each_with_index.map { |value, index| index == hole ? "□" : value }
    text = "Кое число трябва да е в □? #{shown.join(', ')}"
    steps = [ "Числата растат с по 1: #{row[hole - 1]}, после идва #{answer}.", "Проверяваме със следващото: след #{answer} идва #{row[hole + 1]}." ]
    watch = "Числото в □ е с 1 повече от числото преди него."
  when 4
    n = c.int(2..9)
    text = "Кое число е между #{n - 1} и #{n + 1}?"
    answer = n
    steps = [ "Броим: #{n - 1}, #{n}, #{n + 1}.", "Между #{n - 1} и #{n + 1} стои #{n}." ]
    watch = "Числото по средата е с 1 повече от #{n - 1} и с 1 по-малко от #{n + 1}."
  else
    start = c.int(6..10)
    row = start.downto(start - 4).to_a
    hole = c.int(1..3)
    answer = row[hole]
    shown = row.each_with_index.map { |value, index| index == hole ? "□" : value }
    text = "Броим назад: #{shown.join(', ')}. Кое число е в □?"
    steps = [ "Като броим назад, всяко следващо число е с 1 по-малко.", "След #{row[hole - 1]} идва #{answer}." ]
    watch = "Броим назад, затова числата намаляват, а не растат."
  end

  c.q(
    text: text,
    answer: Num.ans(answer),
    explanation: Explain.build(
      idea: "Числата се редят едно след друго, всяко с 1 повече от предишното.",
      steps: steps,
      answer: answer.to_s,
      check: "Казваме редицата на глас и слушаме дали #{answer} е на мястото си.",
      watch: watch
    )
  )
end

# ---------------------------------------------------------------- Наредба ---

Authoring.family "pre.queue_place", topic: "Логически задачи", area: "preschool", variants: 8,
                 rungs: Preschool::PRE do |c|
  size = c.by_level([ 3, 3, 4, 5, 5, 6 ])
  queue = c.sample(Preschool::ANIMALS, size)
  line = queue.map(&:emoji).join(" ")
  intro = "Животните чакат на опашка. Първото е най-отляво: #{line}."

  case c.level
  when 0..3
    place = c.level.zero? ? c.int(0..1) : c.int(0..(size - 1))
    target = queue[place]
    text = "#{intro} Кое животно е #{Preschool::ORDINALS[place]}?"
    options = c.options(target.name, (queue - [ target ]).map(&:name))
    answer = target.name
    steps = [ "Броим отляво: #{queue.first(place + 1).each_with_index.map { |a, i| "#{Preschool::ORDINALS[i]} е #{a.emoji}" }.join(', ')}.",
              "#{Preschool::ORDINALS[place].capitalize} е #{target.the}." ]
  when 4
    place = c.int(1..(size - 1))
    target = queue[place]
    text = "#{intro} На кое място е #{target.the}?"
    answer = place + 1
    steps = [ "Броим отляво: #{Preschool.counting(1, place + 1)}.", "#{target.the.capitalize} е #{Preschool::ORDINALS[place]}, на #{Preschool::ORDINALS[place]} място." ]
  else
    place = c.int(1..(size - 2))
    before = c.coin
    anchor = queue[place]
    target = before ? queue[place - 1] : queue[place + 1]
    text = "#{intro} Кое животно е точно #{before ? 'преди' : 'след'} #{anchor.the}?"
    options = c.options(target.name, (queue - [ target, anchor ]).map(&:name))
    answer = target.name
    steps = [ "Намираме #{anchor.the}: то е #{Preschool::ORDINALS[place]}.",
              "#{before ? 'Точно преди него, наляво' : 'Точно след него, надясно'}, е #{target.the}." ]
  end

  c.q(
    text: text,
    options: options,
    answer: answer.to_s,
    explanation: Explain.build(
      idea: "Броим местата отляво надясно, защото първото животно е най-отляво.",
      steps: steps,
      answer: answer.is_a?(Integer) ? "на #{Preschool::ORDINALS[answer - 1]} място (#{answer})" : target.name,
      check: "Посочваме животните едно по едно и казваме: първо, второ, трето...",
      watch: "Започваме да броим отляво, от първото животно на опашката."
    )
  )
end

Authoring.family "pre.picture_pattern", topic: "Логически задачи", area: "preschool", variants: 8,
                 rungs: Preschool::PRE do |c|
  set = c.pick(Preschool::PATTERN_SETS)
  shape = c.by_level([ [ 0, 1 ], [ 0, 1 ], [ 0, 1, 2 ], [ 0, 0, 1 ], [ 0, 1, 1 ], [ 0, 1, 2 ] ])
  pictures = c.sample(set, shape.max + 1)
  unit = shape.map { |index| pictures[index] }
  length = c.by_level([ 4, 5, 6, 6, 6, 7 ]) + (c.level >= 1 ? c.int(0..1) : 0)
  row = Array.new(length) { |i| unit[i % unit.size] }
  extra = c.pick(set - pictures)

  if c.top?
    hole = c.int(2..(length - 2))
    answer = row[hole]
    shown = row.each_with_index.map { |p, i| i == hole ? "□" : p }
    text = "Коя картинка трябва да е в □? #{shown.join(' ')}"
  else
    answer = unit[length % unit.size]
    text = "Коя картинка идва след тях? #{row.join(' ')}"
  end

  c.q(
    text: text,
    options: c.options(answer, pictures - [ answer ], extra),
    answer: answer,
    explanation: Explain.build(
      idea: "Търсим групата картинки, която се повтаря отново и отново.",
      steps: [
        "Повтаря се групата #{unit.join(' ')}.",
        c.top? ? "На мястото на □ групата продължава с #{answer}." : "Редът свършва с #{row.last}, а групата продължава с #{answer}."
      ],
      answer: answer,
      check: "Казваме редицата на глас по групи: #{Array.new(3) { unit.join(' ') }.join(', ')}.",
      watch: unit.size == 2 ? "Картинките се редуват по две." : "Групата е от #{unit.size} картинки, а не от 2."
    ),
    hints: [ "Огради с пръст групата, която се повтаря." ]
  )
end

Authoring.family "pre.odd_one_out", topic: "Логически задачи", area: "preschool", variants: 8,
                 rungs: Preschool::PRE do |c|
  size = c.by_level([ 3, 4, 4, 5, 4, 5 ])
  # The top two rungs set fruit against vegetables, which takes a closer look
  # than fruit against a car.
  if c.level >= 4
    kind, odd_kind = c.coin ? %i[fruit vegetable] : %i[vegetable fruit]
  else
    kind = c.pick(%i[fruit animal vehicle clothes])
    odd_kind = c.pick(%i[fruit animal vehicle clothes] - [ kind ])
  end
  group = Preschool::GROUPS.fetch(kind)
  odd_group = Preschool::GROUPS.fetch(odd_kind)
  raise Authoring::Duplicate if group.members.size < size

  members = c.sample(group.members, size)
  odd = c.pick(odd_group.members)
  shown = c.sample(members + [ odd ], size + 1)

  c.q(
    text: "Коя картинка не е от групата? #{shown.map(&:first).join(' ')}",
    options: c.options(odd.first, members.map(&:first)),
    answer: odd.first,
    explanation: Explain.build(
      idea: "Търсим какво е общото на повечето картинки и коя картинка го няма.",
      steps: [
        "#{Preschool.names(members.map { |m| "#{m.last} #{m.first}" }).capitalize} са #{group.many}.",
        "#{odd.last.capitalize} #{odd.first} не е #{group.one}, а е #{odd_group.one}."
      ],
      answer: odd.first,
      check: "Без #{odd.first} всички останали са #{group.many}.",
      watch: "Гледаме какво е нещото, а не какъв цвят е."
    ),
    hints: [ "Какво са повечето картинки? Коя от тях е друго нещо?" ]
  )
end
