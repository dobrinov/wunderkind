# Интерактивни задачи: вероятности, статистика, броене, логика.

# ------------------------------------------------------------- Вероятности ---

Authoring.family "blank.probability_fraction", topic: "Вероятност", area: "interactive_data", variants: 11,
                 rungs: [ 1120, 1210, 1300, 1390, 1480, 1570 ] do |c|
  red = c.int(c.by_level([ 1..5, 2..8, 2..12, 3..20, 4..40, 5..90 ]))
  blue = c.int(c.by_level([ 1..5, 2..8, 2..12, 3..20, 4..40, 5..90 ]))
  total = red + blue

  c.q(
    text: "В кутия има #{red} червени и #{blue} сини топки. Изтегляме една наслуки. " \
          "Попълни броя на благоприятните изходи и броя на всички изходи за събитието „топката е червена“.",
    widget: WidgetKit.blanks([ [ "good", "благоприятни", red ], [ "all", "всички", total ] ]),
    explanation: Explain.build(
      idea: "Вероятността е отношение: благоприятни изходи към всички равновъзможни изходи.",
      steps: [
        "Благоприятни са #{red}-те червени топки.",
        "Всички изходи са #{red} + #{blue} = #{total} топки.",
        "P = #{red}/#{total} = #{Num.frac(red, total)}."
      ],
      answer: "#{red} от #{total}",
      check: "Вероятността за синя е #{Num.frac(blue, total)}, а двете дават 1.",
      watch: "Знаменателят е броят на всички топки, не на другия цвят."
    )
  )
end

Authoring.family "pick.dice_outcomes", topic: "Вероятност", area: "interactive_data", variants: 11,
                 rungs: [ 1250, 1340, 1430, 1520, 1610, 1700 ] do |c|
  target = c.int(4..10)
  pairs = (1..6).to_a.product((1..6).to_a)
  good = pairs.select { |a, b| a + b == target }
  raise Authoring::Duplicate if good.size < 3

  chosen_good = c.sample(good, 2)
  chosen_bad = c.sample(pairs - good, 3)
  options = (chosen_good + chosen_bad).map { |a, b| [ "(#{a}; #{b})", chosen_good.include?([ a, b ]) ] }

  c.q(
    text: "Хвърлят се два зара. Кои от двойките #{options.map(&:first).join(', ')} дават сбор #{target}? Избери всички верни.",
    widget: WidgetKit.multi_select(options),
    explanation: Explain.build(
      idea: "Проверяваме сбора на всяка двойка поотделно.",
      steps: [
        chosen_good.map { |a, b| "#{a} + #{b} = #{target} ✓" }.join(", ") + ".",
        chosen_bad.first(2).map { |a, b| "#{a} + #{b} = #{a + b}" }.join(", ") + " — не дават #{target}."
      ],
      answer: chosen_good.map { |a, b| "(#{a}; #{b})" }.join(", "),
      check: "Общо сбор #{target} се получава по #{good.size} начина от 36 възможни, значи P = #{Num.frac(good.size, 36)}.",
      watch: "(#{good.first[0]}; #{good.first[1]}) и (#{good.first[1]}; #{good.first[0]}) са различни изхода, макар сборът да е същият."
    )
  )
end

Authoring.family "sortbins.event_chance", topic: "Вероятност", area: "interactive_data", variants: 11,
                 rungs: [ 1050, 1140, 1230, 1320, 1410, 1500 ] do |c|
  faces = c.pick([ 6, 6, 8, 10, 12 ])
  certain = [ "числото е по-малко от #{faces + 1}", "числото е поне 1" ]
  impossible = [ "числото е #{faces + c.int(1..4)}", "числото е 0", "числото е отрицателно" ]
  possible = [ "числото е четно", "числото е просто", "числото е по-голямо от #{c.int(2..(faces - 1))}", "числото е кратно на 3" ]
  items = [ [ c.pick(certain), "cer" ], [ c.pick(impossible), "imp" ] ] + c.sample(possible, 2).map { |label| [ label, "pos" ] }
  raise Authoring::Duplicate if items.map(&:first).uniq.size < 4

  c.q(
    text: "Хвърля се зар с #{faces} стени. Разпредели събитията (#{items.map(&:first).join('), (')}) " \
          "на сигурни, възможни и невъзможни.",
    widget: WidgetKit.categorize(
      bins: [ [ "cer", "сигурно" ], [ "pos", "възможно" ], [ "imp", "невъзможно" ] ],
      items: items.each_with_index.map { |(label, bin), i| [ "e#{i}", label, bin ] }
    ),
    explanation: Explain.build(
      idea: "Сигурно събитие има вероятност 1, невъзможно — 0, а възможното е между тях.",
      steps: [
        "Зарът показва число от 1 до #{faces}.",
        "Събитие, което важи за всички стени, е сигурно; което не важи за нито една — невъзможно."
      ],
      answer: items.map { |label, bin| "#{label}: #{{ 'cer' => 'сигурно', 'pos' => 'възможно', 'imp' => 'невъзможно' }[bin]}" }.join("; "),
      check: "Вероятностите на трите вида са 1, между 0 и 1, и 0.",
      watch: "„Възможно“ не значи „вероятно“ — достатъчна е една подходяща стена."
    )
  )
end

Authoring.family "match.event_probability", topic: "Вероятност", area: "interactive_data", variants: 11,
                 rungs: [ 1300, 1390, 1480, 1570, 1660, 1750 ] do |c|
  pool = [
    [ "зар показва 6", "1/6" ], [ "зар показва четно число", "1/2" ], [ "зар показва число под 3", "1/3" ],
    [ "зар показва число, кратно на 3", "1/3" ], [ "монета показва ези", "1/2" ],
    [ "две монети показват две ези", "1/4" ], [ "зар показва число над 4", "1/3" ],
    [ "зар показва просто число", "1/2" ], [ "две монети показват поне едно ези", "3/4" ]
  ]
  pairs = c.sample(pool, 3)
  raise Authoring::Duplicate if pairs.map(&:last).uniq.size < 3

  c.q(
    text: "Свържи всяко от събитията #{pairs.map(&:first).join('; ')} с вероятността му.",
    widget: WidgetKit.matcher(pairs),
    explanation: Explain.build(
      idea: "Броим благоприятните изходи и делим на всички равновъзможни.",
      steps: pairs.map { |event, probability| "#{event} → #{probability}" },
      answer: pairs.map { |event, probability| "#{event}: #{probability}" }.join("; "),
      check: "Всяка вероятност е между 0 и 1.",
      watch: "При две монети изходите са 4 (ЕЕ, ЕТ, ТЕ, ТТ), не 3."
    )
  )
end

Authoring.family "shade.probability_area", topic: "Вероятност", area: "interactive_data", variants: 11,
                 rungs: [ 1200, 1290, 1380, 1470, 1560, 1650 ] do |c|
  rows = c.pick([ 2, 4, 5 ])
  cols = c.pick([ 4, 5, 8, 10 ])
  total = rows * cols
  denominator = c.pick(Num.divisors(total).select { |d| d.between?(2, 10) })
  numerator = c.int(1...denominator)
  shaded = total * numerator / denominator

  c.q(
    text: "Мишена е разделена на #{total} еднакви полета (#{rows} на #{cols}). " \
          "Оцвети толкова полета, че вероятността да улучим оцветено поле да е #{Num.frac(numerator, denominator)}.",
    widget: WidgetKit.grid_shade(rows: rows, cols: cols, count: shaded),
    explanation: Explain.build(
      idea: "При равни полета вероятността е отношението на оцветените полета към всички.",
      steps: [
        "Всички полета: #{total}.",
        "#{Num.frac(numerator, denominator)} от #{total} = #{shaded} полета."
      ],
      answer: "#{shaded} полета",
      check: "#{shaded}/#{total} = #{Num.frac(numerator, denominator)}.",
      watch: "Полетата са равни по големина — иначе броенето не работи."
    )
  )
end

# --------------------------------------------------------------- Статистика ---

Authoring.family "blank.mean_median", topic: "Статистика", area: "interactive_data", variants: 11,
                 rungs: [ 1180, 1270, 1360, 1450, 1540, 1630 ] do |c|
  count = c.by_level([ 5, 5, 5, 7, 7, 9 ])
  mean = c.int(c.by_level([ 4..12, 5..20, 6..40, 8..80, 10..200, 12..500 ]))
  values = Array.new(count - 1) { mean + c.int(-mean / 2..mean / 2) }
  values << (mean * count) - values.sum
  raise Authoring::Duplicate if values.last.negative?

  sorted = values.sort
  median = sorted[count / 2]

  c.q(
    text: "Дадени са числата #{values.join(', ')}. Попълни средното аритметично и медианата.",
    widget: WidgetKit.blanks([ [ "mean", "средно", mean ], [ "median", "медиана", median ] ]),
    explanation: Explain.build(
      idea: "Средното е сборът делен на броя; медианата е средното по големина число след подреждане.",
      steps: [
        "Сбор: #{values.sum}, брой: #{count}, средно: #{values.sum} : #{count} = #{mean}.",
        "Подредени: #{sorted.join(', ')} — по средата стои #{median}."
      ],
      answer: "средно #{mean}, медиана #{median}",
      check: "Медианата дели данните на две равни по брой половини.",
      watch: "Средното и медианата съвпадат само при симетрични данни — тук #{mean == median ? 'случайно съвпадат' : "са различни (#{mean} и #{median})"}."
    )
  )
end

Authoring.family "table.frequency", topic: "Статистика", area: "interactive_data", variants: 11,
                 rungs: [ 1150, 1240, 1330, 1420, 1510, 1600 ] do |c|
  categories = c.sample(%w[Пон Вт Ср Чет Пет Съб Нед], c.by_level([ 3, 4, 4, 5, 5, 6 ]))
  counts = categories.map { c.int(c.by_level([ 2..10, 3..20, 4..40, 5..80, 8..150, 10..400 ])) }
  total = counts.sum
  hidden = c.int(0...categories.size)
  rows = [ counts.each_with_index.map { |value, i| i == hidden ? nil : value } + [ total ] ]

  c.q(
    text: "Таблицата показва броя прочетени страници по дни, а последната клетка е сборът (#{total}). " \
          "Попълни липсващата стойност за #{categories[hidden]}.",
    widget: WidgetKit.grid_fill(rows: rows, answers: [ counts + [ total ] ],
                                column_headers: categories + [ "общо" ]),
    explanation: Explain.build(
      idea: "Сборът на всички стойности е известен, затова липсващата се получава с изваждане.",
      steps: [
        "Известните дават #{counts.each_with_index.reject { |_, i| i == hidden }.map(&:first).join(' + ')} = #{total - counts[hidden]}.",
        "#{total} − #{total - counts[hidden]} = #{counts[hidden]}."
      ],
      answer: counts[hidden].to_s,
      check: "#{counts.join(' + ')} = #{total}.",
      watch: "Общата клетка не е част от данните — тя ги сумира."
    )
  )
end

Authoring.family "table.two_way", topic: "Статистика", area: "interactive_data", variants: 11,
                 rungs: [ 1400, 1490, 1580, 1670, 1760, 1850 ] do |c|
  a = c.int(c.by_level([ 2..8, 3..15, 4..25, 5..50, 8..120, 10..300 ]))
  b = c.int(c.by_level([ 2..8, 3..15, 4..25, 5..50, 8..120, 10..300 ]))
  d = c.int(c.by_level([ 2..8, 3..15, 4..25, 5..50, 8..120, 10..300 ]))
  e = c.int(c.by_level([ 2..8, 3..15, 4..25, 5..50, 8..120, 10..300 ]))
  answers = [ [ a, b, a + b ], [ d, e, d + e ], [ a + d, b + e, a + b + d + e ] ]
  blanks = c.sample([ [ 0, 1 ], [ 1, 0 ], [ 0, 2 ], [ 2, 1 ], [ 1, 2 ], [ 2, 0 ] ], c.by_level([ 2, 2, 3, 3, 4, 4 ]))
  rows = answers.each_with_index.map { |row, r| row.each_with_index.map { |value, cc| blanks.include?([ r, cc ]) ? nil : value } }

  c.q(
    text: "Попълни липсващите числа в таблицата, така че редовете и колоните да излизат " \
          "(общо анкетирани: #{a + b + d + e}).",
    widget: WidgetKit.grid_fill(rows: rows, answers: answers,
                                column_headers: [ "момичета", "момчета", "общо" ],
                                row_headers: [ "спортуват", "не спортуват", "общо" ]),
    explanation: Explain.build(
      idea: "Всеки ред и всяка колона трябва да се събират до крайната си клетка.",
      steps: [
        "Първи ред: #{a} + #{b} = #{a + b}.",
        "Първа колона: #{a} + #{d} = #{a + d}.",
        "Общо: #{a + b} + #{d + e} = #{a + b + d + e}, което съвпада с #{a + d} + #{b + e}."
      ],
      answer: blanks.map { |r, cc| "#{answers[r][cc]}" }.join(", "),
      check: "Сборът по редове и сборът по колони дават едно и също число: #{a + b + d + e}.",
      watch: "Долният десен ъгъл се брои веднъж — той е общата сума, не сбор на другите тотали."
    )
  )
end

Authoring.family "pick.mean_sets", topic: "Статистика", area: "interactive_data", variants: 11,
                 rungs: [ 1350, 1440, 1530, 1620, 1710, 1800 ] do |c|
  mean = c.int(c.by_level([ 3..8, 4..12, 5..20, 6..40, 8..90, 10..200 ]))
  make_set = lambda do |target|
    size = c.int(3..4)
    values = Array.new(size - 1) { target + c.int(-2..2) }
    values << (target * size) - values.sum
    values.all?(&:positive?) ? values : nil
  end
  good = []
  6.times { set = make_set.call(mean); good << set if set && !good.include?(set) }
  good = good.first(2)
  bad = []
  8.times do
    set = make_set.call(mean + c.pick([ -2, -1, 1, 2 ]))
    bad << set if set && !bad.include?(set) && (set.sum % set.size != 0 || set.sum / set.size != mean)
  end
  bad = bad.first(3)
  raise Authoring::Duplicate if good.size < 2 || bad.size < 3

  options = (good + bad).map { |set| [ set.join(", "), good.include?(set) ] }.uniq { |label, _| label }

  c.q(
    text: "Кои от групите числа имат средно аритметично точно #{mean}? Избери всички.",
    widget: WidgetKit.multi_select(options),
    explanation: Explain.build(
      idea: "Средното е сборът делен на броя — проверяваме всяка група поотделно.",
      steps: good.map { |set| "#{set.join(', ')}: сбор #{set.sum}, брой #{set.size}, средно #{set.sum / set.size}." } +
             bad.first(2).map { |set| "#{set.join(', ')}: средно #{Num.dec(Rational(set.sum, set.size), 2)}." },
      answer: good.map { |set| set.join(", ") }.join(" | "),
      check: "Сборът на всяка вярна група е #{mean} по броя на числата в нея.",
      watch: "Групи с различен брой числа могат да имат едно и също средно."
    )
  )
end

Authoring.family "plot.data_point", topic: "Статистика", area: "interactive_data", variants: 11,
                 rungs: [ 1250, 1340, 1430, 1520, 1610, 1700 ] do |c|
  x = c.int(1..5)
  y = c.int(1..5)
  extra_x = c.int(1..5)
  extra_y = c.int(1..5)
  raise Authoring::Duplicate if [ x, y ] == [ extra_x, extra_y ]

  c.q(
    text: "На диаграмата на разсейване вече е нанесена точката (#{extra_x}; #{extra_y}). " \
          "Нанеси наблюдението: #{count_noun(x, 'час', 'часа')} учене и #{count_noun(y, 'точка', 'точки')} на теста.",
    widget: WidgetKit.plot(points: [ [ x, y ] ], x_range: (0..6), y_range: (0..6),
                           fixed: [ [ extra_x, extra_y, "" ] ]),
    explanation: Explain.build(
      idea: "Първата стойност се отчита по хоризонталната ос, втората — по вертикалната.",
      steps: [
        "#{count_noun(x, 'час', 'часа')} → #{count_noun(x, 'деление', 'деления')} надясно.",
        "#{count_noun(y, 'точка', 'точки')} → #{count_noun(y, 'деление', 'деления')} нагоре."
      ],
      answer: "(#{x}; #{y})",
      check: "Точката трябва да е точно над #{x} по хоризонталната ос.",
      watch: "Осите не са взаимозаменяеми — часовете са по едната, точките по другата."
    )
  )
end

# ------------------------------------------------- Броене и комбинаторика ---

Authoring.family "blank.count_two_ways", topic: "Броене и комбинаторика", area: "interactive_data", variants: 11,
                 rungs: [ 1300, 1390, 1480, 1570, 1660, 1750 ] do |c|
  n = c.int(c.by_level([ 3..5, 4..6, 4..7, 5..8, 6..9, 7..10 ]))
  k = c.int(2..[ n - 1, c.by_level([ 2, 2, 3, 3, 4, 4 ]) ].min)
  ordered = (0...k).reduce(1) { |acc, i| acc * (n - i) }
  unordered = ordered / (1..k).reduce(1, :*)

  c.q(
    text: "От #{n} ученици се избират #{k}. Попълни броя на подредбите (когато редът е важен) " \
          "и броя на групите (когато редът не е важен).",
    widget: WidgetKit.blanks([ [ "ordered", "с ред", ordered ], [ "unordered", "без ред", unordered ] ]),
    explanation: Explain.build(
      idea: "С ред броим позиция по позиция; без ред делим на броя подредби на избраните.",
      steps: [
        "С ред: #{(0...k).map { |i| n - i }.join(' · ')} = #{ordered}.",
        "Всяка група от #{k} души се брои #{k}! = #{(1..k).reduce(1, :*)} пъти.",
        "Без ред: #{ordered} : #{(1..k).reduce(1, :*)} = #{unordered}."
      ],
      answer: "#{ordered} и #{unordered}",
      check: "Броят без ред винаги е по-малък: #{unordered} < #{ordered}.",
      watch: "„Отбор“ обикновено значи без ред, „класиране“ — с ред."
    )
  )
end

Authoring.family "table.outcome_grid", topic: "Броене и комбинаторика", area: "interactive_data", variants: 11,
                 rungs: [ 1200, 1290, 1380, 1470, 1560, 1650 ] do |c|
  first = c.int(c.by_level([ 2..4, 2..5, 3..6, 3..7, 4..8, 4..9 ]))
  second = c.int(c.by_level([ 2..4, 2..5, 3..6, 3..7, 4..8, 4..9 ]))
  answers = (1..first).map { |a| (1..second).map { |b| a * b } }
  blanks = c.sample((0...(first * second)).to_a, c.by_level([ 2, 3, 3, 4, 4, 5 ]))
  rows = answers.each_with_index.map { |row, r| row.each_with_index.map { |value, cc| blanks.include?((r * second) + cc) ? nil : value } }

  c.q(
    text: "Таблицата показва произведенията при хвърляне на два зара с #{first} и #{second} стени. " \
          "Попълни липсващите клетки.",
    widget: WidgetKit.grid_fill(rows: rows, answers: answers,
                                column_headers: (1..second).map(&:to_s), row_headers: (1..first).map(&:to_s)),
    explanation: Explain.build(
      idea: "Всяка клетка е произведението на числото от реда и числото от колоната; клетките са всички възможни изходи.",
      steps: [
        "Изходите са #{first} · #{second} = #{first * second} на брой.",
        blanks.first(3).map { |index| "Ред #{(index / second) + 1}, колона #{(index % second) + 1}: #{(index / second) + 1} · #{(index % second) + 1} = #{answers[index / second][index % second]}." }.join(" ")
      ],
      answer: blanks.sort.map { |index| answers[index / second][index % second] }.join(", "),
      check: "Най-голямото произведение е #{first} · #{second} = #{first * second}.",
      watch: "Различни клетки могат да имат еднаква стойност — това не ги прави един изход."
    )
  )
end

Authoring.family "pick.counting_statements", topic: "Броене и комбинаторика", area: "interactive_data", variants: 11,
                 rungs: [ 1400, 1490, 1580, 1670, 1760, 1850 ] do |c|
  shirts = c.int(2..c.by_level([ 4, 5, 6, 8, 10, 12 ]))
  trousers = c.int(2..c.by_level([ 4, 5, 6, 8, 10, 12 ]))
  correct = [ "#{shirts} · #{trousers} = #{shirts * trousers} различни облекла" ]
  wrong = [ "#{shirts} + #{trousers} = #{shirts + trousers} различни облекла",
            "#{shirts * trousers * 2} различни облекла",
            "#{shirts} различни облекла",
            "#{[ shirts, trousers ].max} различни облекла" ]
  extra_correct = [ "ако тениските станат #{shirts + 1}, облеклата стават #{(shirts + 1) * trousers}" ]
  options = (correct + extra_correct + c.sample(wrong, 3)).map { |label| [ label, (correct + extra_correct).include?(label) ] }.uniq { |label, _| label }
  raise Authoring::Duplicate if options.size < 5

  c.q(
    text: "Ученик има #{shirts} тениски и #{trousers} панталона. Кои твърдения са верни? Избери всички.",
    widget: WidgetKit.multi_select(options),
    explanation: Explain.build(
      idea: "Независими избори се умножават — за всяка тениска има #{trousers} възможни панталона.",
      steps: [
        "#{shirts} · #{trousers} = #{shirts * trousers} комбинации.",
        "Една тениска повече добавя още #{trousers} комбинации: #{(shirts + 1) * trousers}."
      ],
      answer: (correct + extra_correct).join("; "),
      check: "Броят расте на скокове по #{trousers} — точно колкото са панталоните.",
      watch: "Събирането брои дрехите, не облеклата."
    )
  )
end

# --------------------------------------------------------- Логически задачи ---

Authoring.family "match.riddle_answer", topic: "Логически задачи", area: "interactive_data", variants: 11,
                 rungs: [ 1250, 1340, 1430, 1520, 1610, 1700 ] do |c|
  spec = c.by_level([ 2..10, 3..20, 4..40, 6..80, 10..200, 15..500 ])
  pairs = 3.times.map do
    a = c.int(spec)
    b = c.int(1..a)
    kind = c.pick([ :sum_diff, :half, :times ])
    case kind
    when :sum_diff then [ "сборът е #{a + b}, разликата е #{a - b} — по-голямото число", a ]
    when :half then [ "половината от числото е #{a} — самото число", 2 * a ]
    else [ "числото е #{b} пъти по-малко от #{a * b} — самото число", a ]
    end
  end
  raise Authoring::Duplicate if pairs.map(&:last).uniq.size < 3

  c.q(
    text: "Свържи всяко от условията (#{pairs.map(&:first).join('), (')}) с числото, което му отговаря.",
    widget: WidgetKit.matcher(pairs.map { |clue, value| [ clue, value.to_s ] }),
    explanation: Explain.build(
      idea: "Всяко условие се превежда в действие: сбор и разлика → полусбор; половина → удвояване.",
      steps: pairs.map { |clue, value| "#{clue} → #{value}" },
      answer: pairs.map { |clue, value| "#{clue}: #{value}" }.join("; "),
      check: "Заместването във всяко условие връща дадените числа.",
      watch: "„По-малко от“ значи деление, не изваждане."
    )
  )
end

Authoring.family "pick.logic_consequences", topic: "Логически задачи", area: "interactive_data", variants: 11,
                 rungs: [ 1450, 1540, 1630, 1720, 1810, 1900 ] do |c|
  total = c.int(c.by_level([ 10..25, 15..40, 20..60, 25..100, 40..200, 60..500 ]))
  both = c.int(2..(total / 4))
  only_first = c.int(2..(total / 3))
  only_second = total - both - only_first
  raise Authoring::Duplicate if only_second < 2

  correct = [ "футбол играят #{only_first + both} ученици", "плуват #{only_second + both} ученици" ]
  wrong = [ "футбол играят #{only_first} ученици", "и двата спорта правят #{only_first + only_second} ученици",
            "никой не прави и двата спорта", "плуват #{only_second} ученици" ]
  options = (correct + c.sample(wrong, 3)).map { |label| [ label, correct.include?(label) ] }.uniq { |label, _| label }
  raise Authoring::Duplicate if options.size < 5

  c.q(
    text: "В клас от #{total} ученици #{only_first} правят само футбол, #{only_second} само плуване, " \
          "а #{both} правят и двете. Кои твърдения следват? Избери всички верни.",
    widget: WidgetKit.multi_select(options),
    explanation: Explain.build(
      idea: "Който прави и двата спорта, се брои и към футболистите, и към плувците.",
      steps: [
        "Футбол: #{only_first} + #{both} = #{only_first + both}.",
        "Плуване: #{only_second} + #{both} = #{only_second + both}.",
        "Проверка: #{only_first} + #{only_second} + #{both} = #{total}."
      ],
      answer: correct.join("; "),
      check: "Сборът на двете групи (#{(only_first + both) + (only_second + both)}) надхвърля класа точно с #{both} — двойно броените.",
      watch: "„Само футбол“ и „футбол“ са различни числа."
    )
  )
end

Authoring.family "sortbins.statements_true", topic: "Логически задачи", area: "interactive_data", variants: 11,
                 rungs: [ 1150, 1240, 1330, 1420, 1510, 1600 ] do |c|
  a = c.int(c.by_level([ 10..40, 20..80, 30..150, 50..300, 80..800, 100..2000 ]))
  b = c.int(c.by_level([ 10..40, 20..80, 30..150, 50..300, 80..800, 100..2000 ]))
  raise Authoring::Duplicate if a == b

  statements = [
    [ "#{a} + #{b} = #{a + b}", true ],
    [ "#{a} #{Num::MINUS} #{b} = #{Num.bg(a - b)}", true ],
    [ "#{a} > #{b}", a > b ],
    [ "#{a} + #{b} = #{a + b + c.int(1..9)}", false ],
    [ "#{[ a, b ].max} #{Num::MINUS} #{[ a, b ].min} = #{[ a, b ].max - [ a, b ].min + c.int(1..5)}", false ]
  ]
  items = statements.each_with_index.map { |(label, truth), i| [ "s#{i}", label, truth ? "t" : "f" ] }
  raise Authoring::Duplicate if items.map(&:last).uniq.size < 2

  c.q(
    text: "Разпредели твърденията #{statements.map(&:first).join('; ')} на верни и неверни.",
    widget: WidgetKit.categorize(bins: [ [ "t", "вярно" ], [ "f", "невярно" ] ], items: items),
    explanation: Explain.build(
      idea: "Всяко твърдение се проверява с пресмятане, не на око.",
      steps: [
        "#{a} + #{b} = #{a + b}.",
        "#{a} − #{b} = #{Num.bg(a - b)}.",
        "#{a} #{a > b ? '>' : '<'} #{b}."
      ],
      answer: statements.select(&:last).map(&:first).join("; "),
      check: "Верните твърдения издържат заместване, неверните — не.",
      watch: "Едно вярно действие не прави цялото твърдение вярно — проверява се точно както е записано."
    )
  )
end

Authoring.family "blank.age_puzzle_pair", topic: "Логически задачи", area: "interactive_data", variants: 11,
                 rungs: [ 1300, 1390, 1480, 1570, 1660, 1750 ] do |c|
  times = c.int(2..c.by_level([ 3, 4, 4, 5, 6, 8 ]))
  child = c.int(c.by_level([ 3..10, 4..14, 5..20, 6..30, 8..50, 10..90 ]))
  parent = times * child
  difference = parent - child

  c.q(
    text: "Единият е #{times} пъти по-възрастен от другия, а разликата им е #{difference} години. " \
          "Попълни възрастта на по-младия и на по-възрастния.",
    widget: WidgetKit.blanks([ [ "young", "по-млад", child ], [ "old", "по-възрастен", parent ] ]),
    explanation: Explain.build(
      idea: "По-младият е една част, по-възрастният — #{times} части, значи разликата е #{times - 1} части.",
      steps: [
        "#{times - 1} части = #{difference} години.",
        "Една част: #{difference} : #{times - 1} = #{child} години.",
        "По-възрастният: #{times} · #{child} = #{parent}."
      ],
      answer: "#{child} и #{parent} години",
      check: "#{parent} : #{child} = #{times} и #{parent} − #{child} = #{difference}.",
      watch: "Разликата се дели на #{times - 1}, не на #{times}."
    )
  )
end
