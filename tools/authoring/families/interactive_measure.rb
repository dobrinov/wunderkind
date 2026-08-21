# Интерактивни задачи: мерки, пари, време, отношения, скорост и работа.

# ------------------------------------------------------------------ Мерки ---

Authoring.family "blank.unit_chain", topic: "Десетични числа", area: "interactive_measure", variants: 11,
                 rungs: [ 1000, 1090, 1180, 1270, 1360, 1450 ] do |c|
  chain = c.by_level([
    [ "м", "дм", "см", 10, 10 ], [ "м", "дм", "см", 10, 10 ], [ "км", "м", "дм", 1000, 10 ],
    [ "кг", "г", "мг", 1000, 1000 ], [ "л", "дл", "мл", 10, 100 ], [ "т", "кг", "г", 1000, 1000 ]
  ])
  big, middle, small, first_factor, second_factor = chain
  value = c.int(c.by_level([ 2..9, 2..15, 3..25, 4..40, 6..90, 8..200 ]))

  c.q(
    text: "Попълни колко #{middle} и колко #{small} са #{value} #{big}.",
    widget: WidgetKit.blanks([ [ "mid", middle, value * first_factor ],
                               [ "small", small, value * first_factor * second_factor ] ]),
    explanation: Explain.build(
      idea: "Всяка стъпка към по-малка мерна единица е умножение — числото расте.",
      steps: [
        "1 #{big} = #{first_factor} #{middle}, значи #{value} #{big} = #{value * first_factor} #{middle}.",
        "1 #{middle} = #{second_factor} #{small}, значи #{value * first_factor} #{middle} = #{value * first_factor * second_factor} #{small}."
      ],
      answer: "#{value * first_factor} #{middle} и #{value * first_factor * second_factor} #{small}",
      check: "Обратно: #{value * first_factor * second_factor} : #{second_factor} : #{first_factor} = #{value}.",
      watch: "Двете стъпки се умножават една след друга — не се събират."
    )
  )
end

Authoring.family "pick.equal_measures", topic: "Десетични числа", area: "interactive_measure", variants: 11,
                 rungs: [ 1080, 1170, 1260, 1350, 1440, 1530 ] do |c|
  base = c.int(c.by_level([ 2..9, 2..15, 3..25, 4..40, 6..90, 8..200 ]))
  pair = c.by_level([ [ "м", "см", 100 ], [ "м", "см", 100 ], [ "кг", "г", 1000 ],
                      [ "км", "м", 1000 ], [ "л", "мл", 1000 ], [ "т", "кг", 1000 ] ])
  big, small, factor = pair
  correct = [ "#{base * factor} #{small}", "#{Num.dec(Rational(base, 2), 1)} #{big} и още #{Num.dec(Rational(base, 2), 1)} #{big}" ]
  wrong = [ "#{base * factor / 10} #{small}", "#{base * 10} #{small}", "#{base} #{small}", "#{base * factor * 10} #{small}" ]
  options = (correct + c.sample(wrong, 3)).map { |label| [ label, correct.include?(label) ] }.uniq { |label, _| label }
  raise Authoring::Duplicate if options.size < 5

  c.q(
    text: "Кои записи означават същото като #{base} #{big}? Избери всички верни.",
    widget: WidgetKit.multi_select(options),
    explanation: Explain.build(
      idea: "Превръщаме всичко в #{small} и сравняваме числата.",
      steps: [
        "#{base} #{big} = #{base} · #{factor} = #{base * factor} #{small}.",
        "Половина и половина също дават цялото."
      ],
      answer: correct.join("; "),
      check: "Обратното превръщане връща #{base} #{big}.",
      watch: "Един разред разлика (#{base * factor / 10} вместо #{base * factor}) е най-честата грешка."
    )
  )
end

Authoring.family "sortbins.unit_kind", topic: "Десетични числа", area: "interactive_measure", variants: 11,
                 rungs: [ 820, 910, 1000, 1090, 1180, 1270 ] do |c|
  length = [ "мм", "см", "дм", "м", "км" ]
  mass = [ "мг", "г", "кг", "т" ]
  volume = [ "мл", "дл", "л", "хл" ]
  items = c.sample(length, 2).map { |unit| [ unit, "len" ] } +
          c.sample(mass, 2).map { |unit| [ unit, "mass" ] } +
          c.sample(volume, 1).map { |unit| [ unit, "vol" ] }
  raise Authoring::Duplicate if items.map(&:first).uniq.size < 5

  c.q(
    text: "Разпредели мерните единици #{items.map(&:first).join(', ')} по величината, която мерят.",
    widget: WidgetKit.categorize(
      bins: [ [ "len", "дължина" ], [ "mass", "маса" ], [ "vol", "обем" ] ],
      items: items.each_with_index.map { |(label, bin), i| [ "u#{i}", label, bin ] }
    ),
    explanation: Explain.build(
      idea: "Мерните единици се различават по величината: дължина се мери в метри и производните им, масата — в грамове, обемът — в литри.",
      steps: [
        "Дължина: #{items.select { |_, bin| bin == 'len' }.map(&:first).join(', ')}.",
        "Маса: #{items.select { |_, bin| bin == 'mass' }.map(&:first).join(', ')}.",
        "Обем: #{items.select { |_, bin| bin == 'vol' }.map(&:first).join(', ')}."
      ],
      answer: items.map { |label, bin| "#{label} → #{{ 'len' => 'дължина', 'mass' => 'маса', 'vol' => 'обем' }[bin]}" }.join(", "),
      check: "Представките (мили-, санти-, кило-) са едни и същи при всички величини.",
      watch: "„кг“ и „км“ се различават с една буква, но мерят различни неща."
    )
  )
end

Authoring.family "match.unit_equal", topic: "Десетични числа", area: "interactive_measure", variants: 11,
                 rungs: [ 1050, 1140, 1230, 1320, 1410, 1500 ] do |c|
  base = c.int(2..9)
  pool = [
    [ "#{base} м", "#{base * 100} см" ], [ "#{base} кг", "#{base * 1000} г" ],
    [ "#{base} км", "#{base * 1000} м" ], [ "#{base} л", "#{base * 1000} мл" ],
    [ "#{base} ч", "#{base * 60} мин" ], [ "#{base} дм", "#{base * 10} см" ],
    [ "#{base} т", "#{base * 1000} кг" ], [ "#{base} мин", "#{base * 60} с" ]
  ]
  pairs = c.sample(pool, 3)
  raise Authoring::Duplicate if pairs.map(&:last).uniq.size < 3

  c.q(
    text: "Свържи всяка мярка (#{pairs.map(&:first).join(', ')}) с равната ѝ стойност.",
    widget: WidgetKit.matcher(pairs),
    explanation: Explain.build(
      idea: "Всяка двойка се проверява с множителя между двете единици.",
      steps: pairs.map { |left, right| "#{left} = #{right}" },
      answer: pairs.map { |left, right| "#{left} = #{right}" }.join(", "),
      check: "По-малката единица дава по-голямо число.",
      watch: "Часът има 60 минути, а метърът 100 сантиметра — множителите не са еднакви."
    )
  )
end

Authoring.family "table.conversion", topic: "Десетични числа", area: "interactive_measure", variants: 6,
                 rungs: [ 1100, 1190, 1280, 1370, 1460, 1550 ] do |c|
  factor = c.by_level([ 10, 100, 100, 1000, 1000, 1000 ])
  names = { 10 => %w[дм см], 100 => %w[м см], 1000 => %w[км м] }.fetch(factor)
  values = c.sample((2..30).to_a, 4).sort
  converted = values.map { |value| value * factor }
  hidden = c.sample((0..3).to_a, c.by_level([ 2, 2, 3, 3, 3, 4 ]))
  rows = [ values, converted.each_with_index.map { |value, i| hidden.include?(i) ? nil : value } ]

  c.q(
    text: "Попълни таблицата за превръщане на #{values.join(', ')} #{names[0]} в #{names[1]} " \
          "(1 #{names[0]} = #{factor} #{names[1]}).",
    widget: WidgetKit.grid_fill(rows: rows, answers: [ values, converted ], row_headers: names),
    explanation: Explain.build(
      idea: "Всяка стойност се умножава по един и същ множител.",
      steps: hidden.sort.map { |i| "#{values[i]} · #{factor} = #{converted[i]}" },
      answer: hidden.sort.map { |i| converted[i] }.join(", "),
      check: "Обратно делене на #{factor} връща първия ред.",
      watch: "Множителят е един и същ за целия ред — не се променя от стойност към стойност."
    )
  )
end

# --------------------------------------------------------------------- Пари ---

Authoring.family "blank.money_change", topic: "Текстови задачи", area: "interactive_measure", variants: 11,
                 rungs: [ 900, 990, 1080, 1170, 1260, 1350 ] do |c|
  item, band = c.goods
  count = c.int(c.by_level([ 2..3, 2..5, 3..7, 4..10, 5..15, 6..25 ]))
  price = c.int(band)
  total = price * count
  paid = total + c.int(1..40)

  c.q(
    text: "#{c.person} купува #{item.count(count)} по #{price} лв. и плаща с #{paid} лв. " \
          "Попълни стойността на покупката и рестото.",
    widget: WidgetKit.blanks([ [ "total", "покупка", total, "лв." ], [ "change", "ресто", paid - total, "лв." ] ]),
    explanation: Explain.build(
      idea: "Първо стойността на покупката (цена по брой), после рестото (платено минус покупка).",
      steps: [
        "#{count} · #{price} = #{total} лв.",
        "#{paid} − #{total} = #{paid - total} лв."
      ],
      answer: "#{total} лв. и #{paid - total} лв.",
      check: "#{total} + #{paid - total} = #{paid} лв.",
      watch: "Рестото се смята от платената сума, не от цената на един брой."
    )
  )
end

Authoring.family "blank.discount_pair", topic: "Проценти", area: "interactive_measure", variants: 11,
                 rungs: [ 1150, 1240, 1330, 1420, 1510, 1600 ] do |c|
  pct = c.pick(c.by_level([ [ 10, 50 ], [ 10, 20, 25 ], [ 15, 20, 40 ], [ 12, 30, 45 ], [ 8, 35, 65 ], [ 6, 24, 72 ] ]))
  price = c.int(c.by_level([ 2..12, 2..25, 4..50, 5..120, 10..400, 20..900 ])) * (100 / Num.gcd(pct, 100))
  raise Authoring::Duplicate if price > 6000

  discount = price * pct / 100

  c.q(
    text: "Стока за #{price} лв. поевтинява с #{pct}%. Попълни намалението в лева и новата цена.",
    widget: WidgetKit.blanks([ [ "off", "намаление", discount, "лв." ], [ "new", "нова цена", price - discount, "лв." ] ]),
    explanation: Explain.build(
      idea: "Намалението е процент от старата цена; новата цена е останалото.",
      steps: [
        "#{price} · #{pct} : 100 = #{discount} лв.",
        "#{price} − #{discount} = #{price - discount} лв. (тоест #{100 - pct}% от старата цена)."
      ],
      answer: "#{discount} лв. и #{price - discount} лв.",
      check: "#{discount} + #{price - discount} = #{price} лв.",
      watch: "Процентът се смята от старата цена, не от новата."
    )
  )
end

Authoring.family "blank.interest_pair", topic: "Проценти", area: "interactive_measure", variants: 11,
                 rungs: [ 1300, 1390, 1480, 1570, 1660, 1750 ] do |c|
  rate = c.pick([ 2, 3, 4, 5, 6, 8, 10 ])
  years = c.by_level([ 1, 2, 2, 3, 4, 5 ])
  principal = c.int(c.by_level([ 2..10, 3..20, 4..40, 5..80, 8..200, 10..500 ])) * 100
  yearly = principal * rate / 100

  c.q(
    text: "Влог от #{principal} лв. носи проста лихва #{rate}% годишно. " \
          "Попълни лихвата за една година и общата лихва за #{years} #{years == 1 ? 'година' : 'години'}.",
    widget: WidgetKit.blanks([ [ "year", "за 1 година", yearly, "лв." ], [ "total", "за #{years} г.", yearly * years, "лв." ] ]),
    explanation: Explain.build(
      idea: "Простата лихва се начислява всяка година върху една и съща начална сума.",
      steps: [
        "#{principal} · #{rate} : 100 = #{yearly} лв. за година.",
        "#{yearly} · #{years} = #{yearly * years} лв. общо."
      ],
      answer: "#{yearly} лв. и #{yearly * years} лв.",
      check: "Влогът става #{principal + (yearly * years)} лв.",
      watch: "При проста лихва основата не расте — иначе сумата щеше да е по-голяма."
    )
  )
end

Authoring.family "match.percent_change", topic: "Проценти", area: "interactive_measure", variants: 11,
                 rungs: [ 1250, 1340, 1430, 1520, 1610, 1700 ] do |c|
  base = c.int(c.by_level([ 2..8, 2..14, 3..25, 4..50, 6..120, 8..300 ])) * 100
  pairs = c.sample([ 10, 20, 25, 50, 5, 40 ], 3).map { |pct| [ "поевтиняване с #{pct}%", "#{base - (base * pct / 100)} лв." ] }
  raise Authoring::Duplicate if pairs.map(&:last).uniq.size < 3

  c.q(
    text: "Цена от #{base} лв. се променя. Свържи всяко намаление с новата цена.",
    widget: WidgetKit.matcher(pairs),
    explanation: Explain.build(
      idea: "Намаление с p% оставя (100 − p)% от цената.",
      steps: pairs.map do |label, price|
        pct = label[/\d+/].to_i
        "#{label}: остават #{100 - pct}% → #{base} · #{100 - pct} : 100 = #{price}"
      end,
      answer: pairs.map { |label, price| "#{label} → #{price}" }.join(", "),
      check: "По-голямото намаление дава по-ниска цена.",
      watch: "Новата цена не е процентът, а това, което остава след него."
    )
  )
end

# -------------------------------------------------------------------- Време ---

Authoring.family "blank.duration_pair", topic: "Събиране и изваждане", area: "interactive_measure", variants: 11,
                 rungs: [ 950, 1040, 1130, 1220, 1310, 1400 ] do |c|
  minutes = c.int(c.by_level([ 70..200, 100..400, 150..800, 200..1500, 300..3000, 500..8000 ]))

  c.q(
    text: "Пътуване продължава #{minutes} минути. Попълни на колко цели часа и колко минути отговаря това.",
    widget: WidgetKit.blanks([ [ "h", "часа", minutes / 60 ], [ "m", "минути", minutes % 60 ] ]),
    explanation: Explain.build(
      idea: "Часът е 60 минути, затова делим с остатък.",
      steps: [
        "#{minutes} : 60 = #{minutes / 60} и остатък #{minutes % 60}.",
        "Значи #{minutes / 60} ч и #{minutes % 60} мин."
      ],
      answer: "#{minutes / 60} ч и #{minutes % 60} мин",
      check: "#{minutes / 60} · 60 + #{minutes % 60} = #{minutes}.",
      watch: "Остатъкът е под 60 — иначе часовете са взети твърде малко."
    )
  )
end

Authoring.family "clock.start_time", topic: "Събиране и изваждане", area: "interactive_measure", variants: 11,
                 rungs: [ 1000, 1090, 1180, 1270, 1360, 1450 ] do |c|
  end_hour = c.int(1..12)
  end_minute = c.pick([ 0, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55 ])
  length = c.int(c.by_level([ 2..12, 3..24, 4..36, 6..48, 8..72, 10..140 ])) * 5
  total = (end_hour * 60) + end_minute - length
  total += 720 while total <= 0
  start_hour = ((total / 60 - 1) % 12) + 1
  start_minute = total % 60

  c.q(
    text: "Филмът свършва в #{end_hour}:#{format('%02d', end_minute)} и е продължил #{length} минути. " \
          "Нагласи часовника на времето, когато е започнал.",
    widget: WidgetKit.clock(hours: start_hour, minutes: start_minute),
    explanation: Explain.build(
      idea: "Връщаме се назад по часовника: изваждаме продължителността от края.",
      steps: [
        "#{length} минути са #{length / 60} ч и #{length % 60} мин.",
        "От #{end_hour}:#{format('%02d', end_minute)} назад: #{start_hour}:#{format('%02d', start_minute)}."
      ],
      answer: "#{start_hour}:#{format('%02d', start_minute)}",
      check: "Напред от #{start_hour}:#{format('%02d', start_minute)} с #{length} минути се стига до #{end_hour}:#{format('%02d', end_minute)}.",
      watch: "При изваждане на минути често се налага заемане на цял час (60 минути)."
    )
  )
end

Authoring.family "blank.calendar_pair", topic: "Остатъци", area: "interactive_measure", variants: 11,
                 rungs: [ 1100, 1190, 1280, 1370, 1460, 1550 ] do |c|
  days = c.int(c.by_level([ 10..40, 20..90, 40..200, 80..400, 150..1000, 300..3000 ]))

  c.q(
    text: "До събитието остават #{days} дни. Попълни колко пълни седмици са това и колко дни остават над тях.",
    widget: WidgetKit.blanks([ [ "w", "седмици", days / 7 ], [ "d", "дни", days % 7 ] ]),
    explanation: Explain.build(
      idea: "Седмицата има 7 дни, затова делим с остатък.",
      steps: [ "#{days} : 7 = #{days / 7} и остатък #{days % 7}." ],
      answer: "#{days / 7} седмици и #{days % 7} дни",
      check: "7 · #{days / 7} + #{days % 7} = #{days}.",
      watch: "Само остатъкът мести деня от седмицата — пълните седмици не го променят."
    )
  )
end

# ------------------------------------------------------- Отношения и мащаб ---

Authoring.family "blank.ratio_shares", topic: "Текстови задачи", area: "interactive_measure", variants: 11,
                 rungs: [ 1150, 1240, 1330, 1420, 1510, 1600 ] do |c|
  a = c.int(1..c.by_level([ 3, 4, 5, 7, 9, 12 ]))
  b = c.int(1..c.by_level([ 3, 4, 5, 7, 9, 12 ]))
  raise Authoring::Duplicate if a == b || Num.gcd(a, b) != 1

  unit = c.int(c.by_level([ 2..10, 3..20, 4..40, 6..80, 10..200, 15..500 ]))
  total = (a + b) * unit

  c.q(
    text: "Сума от #{total} лв. се разделя в отношение #{a} : #{b}. Попълни двете части.",
    widget: WidgetKit.blanks([ [ "first", "първа част", a * unit, "лв." ], [ "second", "втора част", b * unit, "лв." ] ]),
    explanation: Explain.build(
      idea: "Отношението дели сумата на #{a + b} равни части.",
      steps: [
        "Една част: #{total} : #{a + b} = #{unit} лв.",
        "Частите са #{a} · #{unit} = #{a * unit} лв. и #{b} · #{unit} = #{b * unit} лв."
      ],
      answer: "#{a * unit} лв. и #{b * unit} лв.",
      check: "#{a * unit} + #{b * unit} = #{total} лв., а отношението им е #{a} : #{b}.",
      watch: "Сумата не се дели наполовина, освен ако отношението не е 1 : 1."
    )
  )
end

Authoring.family "pick.equal_ratios", topic: "Текстови задачи", area: "interactive_measure", variants: 11,
                 rungs: [ 1200, 1290, 1380, 1470, 1560, 1650 ] do |c|
  a = c.int(1..c.by_level([ 4, 5, 6, 8, 10, 14 ]))
  b = c.int(1..c.by_level([ 4, 5, 6, 8, 10, 14 ]))
  raise Authoring::Duplicate if a == b || Num.gcd(a, b) != 1

  equal = c.sample((2..7).to_a, 2).map { |k| "#{a * k} : #{b * k}" }
  wrong = c.sample((1..6).to_a, 3).map { |k| "#{(a * k) + c.pick([ 1, 2 ])} : #{b * k}" }
  options = (equal + wrong).map { |label| [ label, equal.include?(label) ] }.uniq { |label, _| label }
  raise Authoring::Duplicate if options.count { |_, ok| ok } < 2 || options.size < 5

  c.q(
    text: "Кои от отношенията #{options.map(&:first).join(', ')} са равни на #{a} : #{b}? Избери всички.",
    widget: WidgetKit.multi_select(options),
    explanation: Explain.build(
      idea: "Отношението не се променя, когато двата му члена се умножат по едно и също число.",
      steps: [
        equal.map { |label| "#{label} се съкращава до #{a} : #{b}" }.join("; ") + ".",
        "Останалите дават друго частно."
      ],
      answer: equal.join(", "),
      check: "#{a} : #{b} = #{Num.dec(Rational(a, b), 3)}; всички верни отношения дават същото число.",
      watch: "Прибавянето на едно и също число към двата члена променя отношението."
    )
  )
end

Authoring.family "match.map_scale", topic: "Подобни фигури", area: "interactive_measure", variants: 11,
                 rungs: [ 1300, 1390, 1480, 1570, 1660, 1750 ] do |c|
  scale = c.pick(c.by_level([ [ 1000, 10_000 ], [ 10_000, 25_000 ], [ 25_000, 50_000 ],
                              [ 50_000, 100_000 ], [ 100_000, 200_000 ], [ 200_000, 500_000 ] ]))
  pairs = c.sample((2..12).to_a, 3).map do |cm|
    metres = cm * scale / 100
    [ "#{cm} см на картата", metres >= 1000 ? "#{Num.dec(Rational(metres, 1000), 2)} км" : "#{metres} м" ]
  end
  raise Authoring::Duplicate if pairs.map(&:last).uniq.size < 3

  c.q(
    text: "Картата е в мащаб 1 : #{scale}. Свържи всяко разстояние на картата с действителното.",
    widget: WidgetKit.matcher(pairs),
    explanation: Explain.build(
      idea: "1 см на картата е #{scale} см в действителност, тоест #{scale / 100} м.",
      steps: pairs.map { |left, right| "#{left} → #{left[/\d+/]} · #{scale / 100} м = #{right}" },
      answer: pairs.map { |left, right| "#{left} = #{right}" }.join(", "),
      check: "Двойно по-голямо разстояние на картата дава двойно по-голямо в действителност.",
      watch: "Мащабът е в сантиметри — превръщането в метри и километри е втора стъпка."
    )
  )
end

Authoring.family "blank.recipe_pair", topic: "Текстови задачи", area: "interactive_measure", variants: 11,
                 rungs: [ 1100, 1190, 1280, 1370, 1460, 1550 ] do |c|
  people = c.int(c.by_level([ 2..4, 2..6, 3..8, 4..10, 5..15, 6..25 ]))
  flour = c.int(c.by_level([ 2..10, 3..20, 4..40, 6..80, 10..200, 15..500 ])) * 10
  sugar = c.int(c.by_level([ 1..5, 2..10, 3..20, 4..40, 6..100, 10..250 ])) * 10
  wanted = people * c.int(2..4)

  c.q(
    text: "Рецепта за #{people} души иска #{flour} г брашно и #{sugar} г захар. " \
          "Попълни количествата за #{wanted} души.",
    widget: WidgetKit.blanks([ [ "flour", "брашно", flour * wanted / people, "г" ],
                               [ "sugar", "захар", sugar * wanted / people, "г" ] ]),
    explanation: Explain.build(
      idea: "И двете количества растат в едно и също отношение — колкото пъти повече хора, толкова пъти повече продукти.",
      steps: [
        "#{wanted} : #{people} = #{wanted / people} пъти повече.",
        "Брашно: #{flour} · #{wanted / people} = #{flour * wanted / people} г.",
        "Захар: #{sugar} · #{wanted / people} = #{sugar * wanted / people} г."
      ],
      answer: "#{flour * wanted / people} г и #{sugar * wanted / people} г",
      check: "Отношението брашно : захар остава #{Num.frac(flour, sugar)}.",
      watch: "Умножава се всяка съставка, не само първата."
    )
  )
end

# ------------------------------------------------------- Движение и работа ---

Authoring.family "blank.speed_pair", topic: "Движение", area: "interactive_measure", variants: 11,
                 rungs: [ 1100, 1190, 1280, 1370, 1460, 1550 ] do |c|
  speed = c.int(c.by_level([ 4..12, 5..25, 10..45, 20..75, 30..120, 45..160 ]))
  time = c.int(c.by_level([ 2..4, 2..6, 3..8, 4..9, 5..10, 6..12 ]))
  distance = speed * time

  c.q(
    text: "Автомобил изминава #{distance} км за #{time} часа. Попълни средната скорост и разстоянието за 1 час.",
    widget: WidgetKit.blanks([ [ "v", "скорост", speed, "км/ч" ], [ "d", "за 1 час", speed, "км" ] ]),
    explanation: Explain.build(
      idea: "Средната скорост е пътят делен на времето, а тя показва точно колко се изминава за час.",
      steps: [
        "#{distance} : #{time} = #{speed} км/ч.",
        "За един час се изминават същите #{speed} км."
      ],
      answer: "#{speed} км/ч",
      check: "#{speed} · #{time} = #{distance} км.",
      watch: "Скоростта и разстоянието за час съвпадат по число, но се мерят в различни единици."
    )
  )
end

Authoring.family "blank.meeting_pair", topic: "Движение", area: "interactive_measure", variants: 11,
                 rungs: [ 1350, 1440, 1530, 1620, 1710, 1800 ] do |c|
  first = c.int(c.by_level([ 4..15, 5..25, 10..40, 15..60, 25..90, 40..130 ]))
  second = c.int(c.by_level([ 4..15, 5..25, 10..40, 15..60, 25..90, 40..130 ]))
  raise Authoring::Duplicate if first == second

  time = c.int(2..c.by_level([ 3, 4, 5, 6, 8, 10 ]))
  distance = (first + second) * time

  c.q(
    text: "Два автомобила тръгват едновременно един срещу друг от градове на #{distance} км. " \
          "Скоростите им са #{first} км/ч и #{second} км/ч. Попълни скоростта на сближаване и времето до срещата.",
    widget: WidgetKit.blanks([ [ "v", "сближаване", first + second, "км/ч" ], [ "t", "време", time, "ч" ] ]),
    explanation: Explain.build(
      idea: "При движение един срещу друг разстоянието намалява със сбора на скоростите.",
      steps: [
        "#{first} + #{second} = #{first + second} км/ч.",
        "#{distance} : #{first + second} = #{time} часа."
      ],
      answer: "#{first + second} км/ч и #{time} часа",
      check: "Първият изминава #{first * time} км, вторият #{second * time} км — заедно #{distance} км.",
      watch: "При движение в една посока скоростите се изваждат, не се събират."
    )
  )
end

Authoring.family "blank.work_pair", topic: "Работа", area: "interactive_measure", variants: 11,
                 rungs: [ 1250, 1340, 1430, 1520, 1610, 1700 ] do |c|
  per_hour = c.int(c.by_level([ 2..8, 3..15, 5..25, 8..40, 12..80, 20..150 ]))
  hours = c.int(c.by_level([ 2..5, 3..8, 4..12, 5..20, 6..30, 8..50 ]))
  total = per_hour * hours
  extra = c.int(2..6)

  c.q(
    text: "Работник прави по #{per_hour} детайла на час. Попълни колко детайла прави за #{hours} часа " \
          "и за колко часа ще направи #{per_hour * (hours + extra)} детайла.",
    widget: WidgetKit.blanks([ [ "made", "детайла", total ], [ "hours", "часа", hours + extra ] ]),
    explanation: Explain.build(
      idea: "Производителността свързва броя и времето: брой = производителност · време.",
      steps: [
        "#{per_hour} · #{hours} = #{total} детайла.",
        "#{per_hour * (hours + extra)} : #{per_hour} = #{hours + extra} часа."
      ],
      answer: "#{total} детайла и #{hours + extra} часа",
      check: "#{per_hour} · #{hours + extra} = #{per_hour * (hours + extra)}.",
      watch: "Двете задачи са обратни една на друга — в едната се умножава, в другата се дели."
    )
  )
end

Authoring.family "table.speed_table", topic: "Движение", area: "interactive_measure", variants: 11,
                 rungs: [ 1200, 1290, 1380, 1470, 1560, 1650 ] do |c|
  speed = c.int(c.by_level([ 5..20, 10..40, 15..60, 20..80, 30..110, 40..150 ]))
  times = c.sample((1..9).to_a, 4).sort
  distances = times.map { |t| speed * t }
  hidden = c.sample((0..3).to_a, c.by_level([ 2, 2, 3, 3, 3, 4 ]))
  rows = [ times, distances.each_with_index.map { |value, i| hidden.include?(i) ? nil : value } ]

  c.q(
    text: "Автомобил се движи с постоянна скорост #{speed} км/ч. Попълни изминатия път за всяко време.",
    widget: WidgetKit.grid_fill(rows: rows, answers: [ times, distances ], row_headers: [ "часа", "км" ]),
    explanation: Explain.build(
      idea: "При постоянна скорост пътят е право пропорционален на времето.",
      steps: hidden.sort.map { |i| "#{times[i]} ч · #{speed} км/ч = #{distances[i]} км" },
      answer: hidden.sort.map { |i| distances[i] }.join(", "),
      check: "Всяко следващо число в реда расте с #{speed} на час.",
      watch: "Пътят расте пропорционално — двойно време, двоен път."
    )
  )
end

# ---------------------------------------------------- Отрицателни величини ---

Authoring.family "line.temperature", topic: "Числа и редици", area: "interactive_measure", variants: 11,
                 rungs: [ 980, 1070, 1160, 1250, 1340, 1430 ] do |c|
  bound = c.by_level([ 10, 15, 20, 25, 30, 40 ])
  step = c.by_level([ 1, 1, 2, 5, 5, 10 ])
  start = c.int((-bound / step)..(bound / step)) * step
  drop = c.int(1..(bound / step)) * step
  result = start - drop
  raise Authoring::Duplicate if result < -bound || result >= start

  c.q(
    text: "Температурата е #{Num.bg(start)}°C и пада с #{drop} градуса. " \
          "Постави точката върху новата температура.",
    widget: WidgetKit.number_line(min: -bound, max: bound, step: step, value: result),
    explanation: Explain.build(
      idea: "Спадането на температурата е движение наляво по числовата ос.",
      steps: [
        "Тръгваме от #{Num.bg(start)} и вървим #{drop} наляво.",
        "#{Num.bg(start)} − #{drop} = #{Num.bg(result)}."
      ],
      answer: "#{Num.bg(result)}°C",
      check: "#{Num.bg(result)} + #{drop} = #{Num.bg(start)}.",
      watch: result.negative? ? "Под нулата по-голямото число по абсолютна стойност е по-студено." : "Резултатът още е над нулата."
    )
  )
end

Authoring.family "sortbins.temperature_compare", topic: "Числа и редици", area: "interactive_measure", variants: 11,
                 rungs: [ 1050, 1140, 1230, 1320, 1410, 1500 ] do |c|
  pivot = c.int(-10..10)
  values = []
  10.times do
    value = c.int(-25..25)
    values << value if value != pivot && !values.include?(value)
  end
  values = values.first(5)
  raise Authoring::Duplicate if values.count { |v| v < pivot } < 2 || values.count { |v| v > pivot } < 2

  items = values.each_with_index.map { |v, i| [ "t#{i}", "#{Num.bg(v)}°C", v < pivot ? "colder" : "warmer" ] }

  c.q(
    text: "Разпредели температурите #{values.map { |v| "#{Num.bg(v)}°C" }.join(', ')} " \
          "според това дали са по-студени или по-топли от #{Num.bg(pivot)}°C.",
    widget: WidgetKit.categorize(bins: [ [ "colder", "по-студено" ], [ "warmer", "по-топло" ] ], items: items),
    explanation: Explain.build(
      idea: "По числовата ос по-студеното е вляво: колкото по-наляво, толкова по-малко.",
      steps: [
        "По-студени от #{Num.bg(pivot)}: #{values.select { |v| v < pivot }.map { |v| Num.bg(v) }.join(', ')}.",
        "По-топли: #{values.select { |v| v > pivot }.map { |v| Num.bg(v) }.join(', ')}."
      ],
      answer: "по-студени: #{values.select { |v| v < pivot }.map { |v| Num.bg(v) }.join(', ')}",
      check: "Разликата между най-топлото и най-студеното е #{values.max - values.min} градуса.",
      watch: "#{Num.bg(-15)}°C е по-студено от #{Num.bg(-5)}°C, макар 15 да е по-голямо от 5."
    )
  )
end
