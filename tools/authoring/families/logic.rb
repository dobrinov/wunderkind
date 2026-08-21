# Логика: броене и комбинаторика, логически задачи.

def factorial(n) = (1..n).reduce(1, :*)

def combinations(n, k) = factorial(n) / (factorial(k) * factorial(n - k))

# ------------------------------------------------- Броене и комбинаторика ---

Authoring.family "count.outfits", topic: "Броене и комбинаторика", area: "logic",
                 rungs: [ 900, 990, 1080, 1170, 1260, 1360 ] do |c|
  spec = c.by_level([ [ 2..4, 2..4, nil ], [ 2..5, 3..6, nil ], [ 3..7, 3..7, nil ],
                      [ 3..8, 4..9, 2..4 ], [ 4..10, 5..12, 2..6 ], [ 5..15, 6..15, 3..8 ] ])
  shirts = c.int(spec[0])
  trousers = c.int(spec[1])
  shoes = spec[2] ? c.int(spec[2]) : nil
  total = shirts * trousers * (shoes || 1)

  c.q(
    text: shoes ? "Един ученик има #{shirts} тениски, #{trousers} панталона и #{shoes} чифта обувки. По колко различни начина може да се облече?" :
                  "Един ученик има #{shirts} тениски и #{trousers} панталона. По колко различни начина може да се облече?",
    answer: Num.ans(total),
    explanation: Explain.build(
      idea: "Когато изборите са независими един от друг, броят на комбинациите е произведението на възможностите.",
      steps: [
        "За всяка от #{shirts} тениски има #{trousers} възможни панталона: #{shirts} · #{trousers} = #{shirts * trousers}.",
        shoes ? "За всяка от тези #{shirts * trousers} комбинации има #{shoes} чифта обувки: #{shirts * trousers} · #{shoes} = #{total}." : nil
      ].compact,
      answer: "#{total} начина",
      check: "Ако тениските бяха с една повече, начините щяха да станат #{total + (trousers * (shoes || 1))} — растат на скокове по #{trousers * (shoes || 1)}.",
      watch: "Изборите се умножават, не се събират: #{shirts} + #{trousers}#{shoes ? " + #{shoes}" : ''} = #{shirts + trousers + (shoes || 0)} е грешният отговор."
    )
  )
end

Authoring.family "count.permutations", topic: "Броене и комбинаторика", area: "logic",
                 rungs: [ 1080, 1170, 1260, 1350, 1440, 1540 ] do |c|
  n = c.int(c.by_level([ 3..4, 3..5, 4..6, 5..7, 6..8, 7..10 ]))
  total = factorial(n)
  thing = c.pick([ "книги на рафт", "ученици в редица", "картички в албум", "флагчета на въже", "кутии една до друга" ])

  c.q(
    text: "По колко различни начина могат да се подредят #{n} #{thing}?",
    answer: Num.ans(total),
    explanation: Explain.build(
      idea: "Подреждането на n различни предмета е n! — за първото място има n избора, за второто n − 1 и така нататък.",
      steps: [
        "Първо място: #{n} възможности; второ: #{n - 1}; ... последно: 1.",
        "#{(1..n).to_a.reverse.join(' · ')} = #{total}."
      ],
      answer: "#{total} начина",
      check: "#{n}! = #{n} · #{n - 1}! = #{n} · #{factorial(n - 1)} = #{total}.",
      watch: "Броят расте много бързо: с един предмет повече става #{factorial(n + 1)}."
    )
  )
end

Authoring.family "count.handshakes", topic: "Броене и комбинаторика", area: "logic",
                 rungs: [ 1120, 1210, 1300, 1390, 1480, 1580 ] do |c|
  n = c.int(c.by_level([ 4..8, 5..12, 6..16, 8..24, 10..40, 12..80 ]))
  total = n * (n - 1) / 2

  c.q(
    text: "В стая има #{n} души и всеки се ръкува с всеки останал точно веднъж. Колко ръкувания стават?",
    answer: Num.ans(total),
    explanation: Explain.build(
      idea: "Всеки се ръкува с останалите #{n - 1}, но всяко ръкуване се брои от двама души — затова се дели на 2.",
      steps: [
        "#{n} · #{n - 1} = #{n * (n - 1)} — така всяко ръкуване е броено два пъти.",
        "#{n * (n - 1)} : 2 = #{total}."
      ],
      answer: "#{total} ръкувания",
      check: "За 2 души формулата дава 1 ръкуване, за 3 — 3. Расте като триъгълните числа.",
      watch: "Без делението на 2 отговорът излиза #{n * (n - 1)} — всяко ръкуване броено по два пъти."
    )
  )
end

Authoring.family "count.choose", topic: "Броене и комбинаторика", area: "logic",
                 rungs: [ 1250, 1340, 1430, 1520, 1610, 1710 ] do |c|
  n = c.int(c.by_level([ 4..6, 5..7, 5..8, 6..10, 7..12, 8..15 ]))
  k = c.int(2..[ n - 1, c.by_level([ 2, 2, 3, 3, 4, 5 ]) ].min)
  total = combinations(n, k)

  c.q(
    text: "От #{n} ученици трябва да се изберат #{k} за отбор. По колко различни начина може да стане това? " \
          "(Редът на избиране няма значение.)",
    answer: Num.ans(total),
    explanation: Explain.build(
      idea: "Брой комбинации без значение на реда: C(n, k) = n! : (k! · (n − k)!).",
      steps: [
        "Подредени избори: #{((n - k + 1)..n).to_a.reverse.join(' · ')} = #{factorial(n) / factorial(n - k)}.",
        "Всеки отбор е броен #{k}! = #{factorial(k)} пъти, защото редът не е важен.",
        "#{factorial(n) / factorial(n - k)} : #{factorial(k)} = #{total}."
      ],
      answer: "#{total} начина",
      check: "C(#{n}, #{k}) = C(#{n}, #{n - k}) = #{combinations(n, n - k)} — двете допълващи се задачи имат еднакъв отговор.",
      watch: "Ако редът имаше значение, отговорът щеше да е #{factorial(n) / factorial(n - k)}."
    )
  )
end

Authoring.family "count.numbers_from_digits", topic: "Броене и комбинаторика", area: "logic",
                 rungs: [ 1200, 1290, 1380, 1470, 1560, 1660 ] do |c|
  digits = c.int(c.by_level([ 3..4, 3..5, 4..6, 4..7, 5..8, 6..9 ]))
  length = c.by_level([ 2, 2, 3, 3, 3, 4 ])
  raise Authoring::Duplicate if length > digits

  distinct = (0...length).reduce(1) { |acc, i| acc * (digits - i) }

  c.q(
    text: "От цифрите 1 до #{digits} се съставят #{length}-цифрени числа, в които цифрите не се повтарят. Колко са те?",
    answer: Num.ans(distinct),
    explanation: Explain.build(
      idea: "Избираме цифра за всяка позиция поред; всяка използвана цифра отпада за следващите позиции.",
      steps: [
        (0...length).map { |i| "#{i + 1}-ва позиция: #{digits - i} възможности" }.join("; ") + ".",
        "#{(0...length).map { |i| digits - i }.join(' · ')} = #{distinct}."
      ],
      answer: "#{distinct} числа",
      check: "Ако цифрите можеха да се повтарят, числата щяха да са #{digits**length}.",
      watch: "Цифрата 0 не участва тук — иначе първата позиция би имала по-малко възможности."
    )
  )
end

Authoring.family "count.subsets", topic: "Броене и комбинаторика", area: "logic",
                 rungs: [ 1300, 1390, 1480, 1570, 1660, 1760 ] do |c|
  n = c.int(c.by_level([ 3..5, 4..6, 4..7, 5..8, 6..10, 7..12 ]))
  total = 2**n

  c.q(
    text: "Едно меню предлага #{n} различни добавки към пица. Клиентът може да избере колкото добавки пожелае " \
          "(включително нито една). Колко различни поръчки са възможни?",
    answer: Num.ans(total),
    explanation: Explain.build(
      idea: "За всяка добавка има независим избор: да или не. Значи 2 · 2 · ... · 2 = 2 на степен броя на добавките.",
      steps: [
        "#{n} независими избора по 2 възможности: 2#{Num.sup(n)}.",
        "2#{Num.sup(n)} = #{total}."
      ],
      answer: "#{total} поръчки",
      check: "Пица без добавки също се брои — тя е 1 от #{total}-те възможности.",
      watch: "Отговорът не е #{2 * n}: изборите се умножават, а не се събират."
    )
  )
end

Authoring.family "count.together_pair", topic: "Броене и комбинаторика", area: "logic",
                 rungs: [ 1400, 1490, 1580, 1670, 1760, 1860 ] do |c|
  n = c.int(c.by_level([ 3..4, 4..5, 4..6, 5..7, 6..8, 7..9 ]))
  total = factorial(n - 1) * 2

  c.q(
    text: "#{n} деца се нареждат в редица, но двама от тях са близнаци и искат да стоят един до друг. " \
          "По колко начина може да се подреди редицата?",
    answer: Num.ans(total),
    explanation: Explain.build(
      idea: "Слепваме близнаците в един „блок“: остават #{n - 1} обекта за подреждане, а вътре в блока има 2 подредби.",
      steps: [
        "Подреждания на #{n - 1} обекта: #{n - 1}! = #{factorial(n - 1)}.",
        "Близнаците вътре в блока: 2 начина.",
        "#{factorial(n - 1)} · 2 = #{total}."
      ],
      answer: "#{total} начина",
      check: "Без условието подрежданията са #{factorial(n)}; с условието са по-малко — #{total} < #{factorial(n)}.",
      watch: "Умножението по 2 е задължително: „АБ“ и „БА“ вътре в блока са различни редици."
    )
  )
end

Authoring.family "count.grid_paths", topic: "Броене и комбинаторика", area: "logic",
                 rungs: [ 1450, 1540, 1630, 1720, 1810, 1910 ] do |c|
  right = c.int(c.by_level([ 2..3, 2..4, 3..5, 3..6, 4..7, 5..9 ]))
  up = c.int(c.by_level([ 2..3, 2..4, 2..5, 3..6, 4..7, 4..9 ]))
  total = combinations(right + up, up)

  c.q(
    text: "По улиците на квартал се върви само надясно и нагоре. От единия ъгъл до другия трябва да се минат " \
          "#{right} пресечки надясно и #{up} нагоре. Колко различни маршрута има?",
    answer: Num.ans(total),
    explanation: Explain.build(
      idea: "Всеки маршрут е редица от #{right + up} хода, в която трябва да изберем кои #{up} са нагоре.",
      steps: [
        "Общо ходове: #{right} + #{up} = #{right + up}.",
        "Избираме местата на ходовете нагоре: C(#{right + up}, #{up}) = #{factorial(right + up)} : (#{factorial(up)} · #{factorial(right)}).",
        "Резултатът е #{total}."
      ],
      answer: "#{total} маршрута",
      check: "C(#{right + up}, #{up}) = C(#{right + up}, #{right}) = #{combinations(right + up, right)} — избирането на ходовете надясно дава същото.",
      watch: "Броят на пресечките се събира, но маршрутите се броят с комбинации, не с умножение."
    )
  )
end

# --------------------------------------------------------- Логически задачи ---

Authoring.family "logic.sum_and_difference", topic: "Логически задачи", area: "logic",
                 rungs: [ 950, 1040, 1130, 1220, 1310, 1410 ] do |c|
  spec = c.by_level([ 2..12, 5..30, 10..60, 20..150, 40..400, 80..1200 ])
  smaller = c.int(spec)
  difference = c.int(1..spec.max) * 2
  bigger = smaller + difference
  sum = smaller + bigger

  c.q(
    text: "Сборът на две числа е #{sum}, а разликата им е #{difference}. Кое е по-голямото число?",
    answer: Num.ans(bigger),
    explanation: Explain.build(
      idea: "Ако към сбора се прибави разликата, се получава удвоеното по-голямо число.",
      steps: [
        "#{sum} + #{difference} = #{sum + difference} — това е двойното по-голямо число.",
        "#{sum + difference} : 2 = #{bigger}.",
        "По-малкото е #{sum} − #{bigger} = #{smaller}."
      ],
      answer: Num.ans(bigger),
      check: "#{bigger} + #{smaller} = #{sum} и #{bigger} − #{smaller} = #{difference}.",
      watch: "Половината от сбора (#{sum / 2}) би била отговорът само ако числата бяха равни."
    )
  )
end

Authoring.family "logic.chickens_rabbits", topic: "Логически задачи", area: "logic",
                 rungs: [ 1150, 1240, 1330, 1420, 1510, 1610 ] do |c|
  spec = c.by_level([ 2..6, 3..10, 4..15, 6..25, 10..50, 15..120 ])
  chickens = c.int(spec)
  rabbits = c.int(spec)
  heads = chickens + rabbits
  legs = (2 * chickens) + (4 * rabbits)

  c.q(
    text: "В двора има кокошки и зайци — общо #{heads} глави и #{legs} крака. Колко са зайците?",
    answer: Num.ans(rabbits),
    explanation: Explain.build(
      idea: "Предполагаме, че всички са кокошки, и гледаме колко крака липсват — всеки заек добавя по два.",
      steps: [
        "Ако всички #{heads} бяха кокошки, краката щяха да са #{2 * heads}.",
        "Липсват #{legs} − #{2 * heads} = #{legs - (2 * heads)} крака.",
        "Всеки заек добавя 2 крака: #{legs - (2 * heads)} : 2 = #{rabbits} зайци."
      ],
      answer: "#{rabbits} зайци",
      check: "#{rabbits} зайци и #{chickens} кокошки: #{4 * rabbits} + #{2 * chickens} = #{legs} крака и #{heads} глави.",
      watch: "Броят на главите е броят на животните — не се дели на 2."
    )
  )
end

Authoring.family "logic.age_puzzle", topic: "Логически задачи", area: "logic",
                 rungs: [ 1250, 1340, 1430, 1520, 1610, 1710 ] do |c|
  times = c.int(c.by_level([ 2..3, 2..4, 2..4, 3..5, 3..6, 4..8 ]))
  years = c.int(c.by_level([ 2..6, 3..10, 4..14, 5..20, 6..30, 8..40 ]))
  child = years / (times - 1)
  raise Authoring::Duplicate unless (years % (times - 1)).zero? && child >= 1

  parent = times * child
  first, second = c.people(2)

  c.q(
    text: "Сега #{first} е #{times} пъти по-възрастен от #{second}. Разликата във възрастта им е #{count_noun(years, 'година', 'години')}. " \
          "На колко години е #{second}?",
    answer: Num.ans(child),
    explanation: Explain.build(
      idea: "Приемаме възрастта на по-младия за една част; тогава по-възрастният е #{times} части, а разликата е #{times - 1} части.",
      steps: [
        "#{times} части − 1 част = #{times - 1} части = #{count_noun(years, 'година', 'години')}.",
        "Една част: #{years} : #{times - 1} = #{count_noun(child, 'година', 'години')}.",
        "По-възрастният е #{times} · #{child} = #{count_noun(parent, 'година', 'години')}."
      ],
      answer: count_noun(child, "година", "години"),
      check: "#{parent} : #{child} = #{times} и #{parent} − #{child} = #{years}.",
      watch: "Разликата се дели на #{times - 1}, не на #{times} — една част се съкращава."
    )
  )
end

Authoring.family "logic.coins_mix", topic: "Логически задачи", area: "logic",
                 rungs: [ 1200, 1290, 1380, 1470, 1560, 1660 ] do |c|
  small, big = c.pick([ [ 1, 2 ], [ 2, 5 ], [ 1, 5 ], [ 5, 10 ], [ 2, 10 ] ])
  spec = c.by_level([ 2..6, 3..10, 4..15, 5..25, 8..50, 12..100 ])
  small_count = c.int(spec)
  big_count = c.int(spec)
  total_coins = small_count + big_count
  total_value = (small * small_count) + (big * big_count)

  c.q(
    text: "В касичка има само монети от #{small} лв. и от #{big} лв. — общо #{total_coins} монети на стойност #{total_value} лв. " \
          "Колко са монетите от #{big} лв.?",
    answer: Num.ans(big_count),
    explanation: Explain.build(
      idea: "Пресмятаме колко би струвало, ако всички монети бяха от #{small} лв., и виждаме колко липсва.",
      steps: [
        "Ако всички #{total_coins} бяха по #{small} лв.: #{small * total_coins} лв.",
        "Липсват #{total_value} − #{small * total_coins} = #{total_value - (small * total_coins)} лв.",
        "Всяка монета от #{big} лв. добавя по #{big - small} лв.: #{total_value - (small * total_coins)} : #{big - small} = #{big_count}."
      ],
      answer: "#{big_count} монети от #{big} лв.",
      check: "#{big_count} · #{big} + #{small_count} · #{small} = #{total_value} лв., а монетите са #{total_coins}.",
      watch: "Двете неизвестни са свързани: щом монетите от #{big} лв. са #{big_count}, останалите #{small_count} са от #{small} лв."
    )
  )
end

Authoring.family "logic.pigeonhole", topic: "Логически задачи", area: "logic",
                 rungs: [ 1300, 1390, 1480, 1570, 1660, 1760 ] do |c|
  colors = c.int(c.by_level([ 2..3, 2..4, 3..5, 3..6, 4..8, 5..12 ]))
  want = c.by_level([ 2, 2, 2, 3, 3, 4 ])
  answer = (colors * (want - 1)) + 1

  c.q(
    text: "В чекмедже има чорапи в #{colors} цвята, разбъркани. На тъмно вадим чорапи един по един. " \
          "Колко най-малко трябва да извадим, за да сме сигурни, че имаме #{want} с еднакъв цвят?",
    answer: Num.ans(answer),
    explanation: Explain.build(
      idea: "Мислим за най-лошия случай: колко може да извадим, без да успеем, и добавяме още един.",
      steps: [
        "В най-лошия случай вадим по #{want - 1} от всеки цвят: #{colors} · #{want - 1} = #{colors * (want - 1)} чорапа без успех.",
        "Следващият чорап задължително допълва някой цвят до #{want}.",
        "#{colors * (want - 1)} + 1 = #{answer}."
      ],
      answer: "#{answer} чорапа",
      check: "С #{answer - 1} чорапа е възможно да имаме само по #{want - 1} от цвят — значи по-малко не стига.",
      watch: "Търси се гаранция, не късмет: #{want} чорапа могат да съвпаднат, но не е сигурно."
    )
  )
end

Authoring.family "logic.balance", topic: "Логически задачи", area: "logic",
                 rungs: [ 1180, 1270, 1360, 1450, 1540, 1640 ] do |c|
  small_per_big = c.int(c.by_level([ 2..3, 2..4, 2..5, 3..6, 3..8, 4..10 ]))
  bigs = c.int(c.by_level([ 2..4, 2..6, 3..8, 4..10, 5..15, 6..25 ]))
  answer = small_per_big * bigs

  c.q(
    text: "Една голяма тежест уравновесява #{small_per_big} малки. Колко малки тежести са нужни, " \
          "за да се уравновесят #{bigs} големи?",
    answer: Num.ans(answer),
    explanation: Explain.build(
      idea: "Заменяме всяка голяма тежест с равностойните ѝ малки.",
      steps: [
        "1 голяма = #{small_per_big} малки.",
        "#{bigs} големи = #{bigs} · #{small_per_big} = #{answer} малки."
      ],
      answer: "#{answer} малки тежести",
      check: "#{answer} : #{small_per_big} = #{bigs} големи — обратната замяна пасва.",
      watch: "Отношението е постоянно: удвояване на големите удвоява и малките."
    )
  )
end

Authoring.family "logic.venn_two_sets", topic: "Логически задачи", area: "logic",
                 rungs: [ 1280, 1370, 1460, 1550, 1640, 1740 ] do |c|
  spec = c.by_level([ 2..8, 3..12, 4..20, 6..40, 10..90, 15..200 ])
  both = c.int(spec)
  only_first = c.int(spec)
  only_second = c.int(spec)
  neither = c.int(0..spec.max)
  total = only_first + only_second + both + neither
  first_total = only_first + both
  second_total = only_second + both

  c.q(
    text: "В клас от #{total} ученици #{first_total} играят футбол, #{second_total} плуват, а #{neither} не спортуват. " \
          "Колко ученици правят и двете?",
    answer: Num.ans(both),
    explanation: Explain.build(
      idea: "Който спортува, е поне в едно от двете множества. Сборът на двете групи брои двойно тези, които са и в двете.",
      steps: [
        "Спортуват: #{total} − #{neither} = #{total - neither} ученици.",
        "Сборът на двете групи е #{first_total} + #{second_total} = #{first_total + second_total}.",
        "Разликата е двойно броените: #{first_total + second_total} − #{total - neither} = #{both}."
      ],
      answer: "#{both} ученици",
      check: "Само футбол: #{only_first}, само плуване: #{only_second}, и двете: #{both}, нищо: #{neither} — заедно #{total}.",
      watch: "Броят на футболистите включва и тези, които плуват — групите се застъпват."
    )
  )
end

Authoring.family "logic.odd_one_out", topic: "Логически задачи", area: "logic",
                 rungs: [ 1050, 1140, 1230, 1320, 1410, 1510 ] do |c|
  kind = c.by_level([ :even, :multiple, :square, :prime, :multiple, :square ])
  case kind
  when :even
    base = c.int(2..40)
    group = (0..3).map { |i| (base + i) * 2 }
    odd = group[c.int(0..3)] + 1
    rule = "всички са четни"
  when :multiple
    factor = c.int(c.level >= 4 ? 6..15 : 3..9)
    start = c.int(2..12)
    group = (0..3).map { |i| (start + i) * factor }
    odd = group[c.int(0..3)] + c.int(1...factor)
    rule = "всички се делят на #{factor}"
  when :square
    start = c.int(c.level >= 5 ? 5..12 : 2..8)
    group = (0..3).map { |i| (start + i)**2 }
    odd = group[c.int(0..3)] + c.int(1..3)
    rule = "всички са точни квадрати"
  else
    primes = Num.primes_upto(c.level >= 3 ? 200 : 60).select { |p| p > 5 }
    group = c.sample(primes, 4)
    odd = group.max + 1
    rule = "всички са прости числа"
  end
  raise Authoring::Duplicate if group.include?(odd)

  shown = (group[0..2] + [ odd ]).sort

  c.q(
    text: "Кое число не се вписва в редицата #{shown.join(', ')}?",
    options: c.options(odd, shown - [ odd ]),
    answer: Num.ans(odd),
    explanation: Explain.build(
      idea: "Търсим общото свойство на числата и проверяваме кое го нарушава.",
      steps: [
        "Общото правило е: #{rule}.",
        "#{(shown - [ odd ]).join(', ')} го изпълняват.",
        "#{odd} не го изпълнява — то е излишното."
      ],
      answer: Num.ans(odd),
      check: "Ако #{odd} се махне, останалите три следват едно и също правило.",
      watch: "Търси се общото свойство, не най-голямото или най-малкото число."
    )
  )
end
