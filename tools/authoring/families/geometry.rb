# Геометрия: периметър, площ, ъгли, обем, Питагорова теорема, подобие, окръжност.
#
# Answers stay numeric: π is given as 3,14 and the result asked in the stated
# unit, because the student types the answer into a MathLive field that the
# server parses as a number.

PI = Rational(314, 100)


# ------------------------------------------------------------- Периметър ---

Authoring.family "perim.rectangle", topic: "Периметър", area: "geometry",
                 rungs: [ 780, 860, 950, 1040, 1130, 1230 ] do |c|
  spec = c.by_level([ 2..9, 3..15, 5..30, 8..60, 12..150, 20..400 ])
  a = c.int(spec)
  b = c.int(spec)
  raise Authoring::Duplicate if a == b

  perimeter = 2 * (a + b)

  c.q(
    text: "Правоъгълник има страни #{a} см и #{b} см. Колко сантиметра е периметърът му?",
    answer: Num.ans(perimeter),
    explanation: Explain.build(
      idea: "Периметърът е обиколката: сборът на всички страни. При правоъгълника срещуположните страни са равни.",
      steps: [
        "P = 2 · (a + b) = 2 · (#{a} + #{b}).",
        "#{a} + #{b} = #{a + b}, значи P = 2 · #{a + b} = #{perimeter} см."
      ],
      answer: "#{perimeter} см",
      check: "Обиколка по страни: #{a} + #{b} + #{a} + #{b} = #{perimeter} см.",
      watch: "Периметърът се мери в см, а площта (#{a * b} см²) — в квадратни сантиметри. Тук се търси обиколката."
    )
  )
end

Authoring.family "perim.square_reverse", topic: "Периметър", area: "geometry",
                 rungs: [ 820, 900, 990, 1080, 1170, 1270 ] do |c|
  side = c.int(c.by_level([ 2..9, 3..15, 5..30, 8..60, 12..150, 25..400 ]))
  perimeter = 4 * side

  c.q(
    text: "Периметърът на квадрат е #{perimeter} см. Колко сантиметра е страната му?",
    answer: Num.ans(side),
    explanation: Explain.build(
      idea: "Квадратът има четири равни страни, затова периметърът е 4 пъти страната.",
      steps: [
        "P = 4 · a, значи a = P : 4.",
        "#{perimeter} : 4 = #{side} см."
      ],
      answer: "#{side} см",
      check: "4 · #{side} = #{perimeter} см.",
      watch: "Дели се на 4, не на 2 — квадратът има четири страни."
    )
  )
end

Authoring.family "perim.triangle", topic: "Периметър", area: "geometry",
                 rungs: [ 800, 890, 980, 1070, 1160, 1260 ] do |c|
  spec = c.by_level([ 2..9, 3..14, 4..25, 6..50, 10..120, 15..300 ])
  a = c.int(spec)
  b = c.int(spec)
  d = c.int([ (a - b).abs + 1, spec.min ].max..(a + b - 1))
  raise Authoring::Duplicate if a + b <= d

  perimeter = a + b + d
  ask_side = c.level >= 3 && c.coin

  if ask_side
    c.q(
      text: "Периметърът на триъгълник е #{perimeter} см, а две от страните му са #{a} см и #{b} см. " \
            "Колко сантиметра е третата страна?",
      answer: Num.ans(d),
      explanation: Explain.build(
        idea: "Периметърът е сборът на трите страни, затова третата се намира с изваждане.",
        steps: [
          "#{a} + #{b} = #{a + b}.",
          "#{perimeter} − #{a + b} = #{d} см."
        ],
        answer: "#{d} см",
        check: "#{a} + #{b} + #{d} = #{perimeter} см.",
        watch: "Всяка страна е по-малка от сбора на другите две — #{d} < #{a + b}, значи триъгълникът съществува."
      )
    )
  else
    c.q(
      text: "Триъгълник има страни #{a} см, #{b} см и #{d} см. Колко сантиметра е периметърът му?",
      answer: Num.ans(perimeter),
      explanation: Explain.build(
        idea: "Периметърът на триъгълник е сборът на трите му страни.",
        steps: [ "P = #{a} + #{b} + #{d} = #{perimeter} см." ],
        answer: "#{perimeter} см",
        check: "Всяка страна е под половината от периметъра — иначе триъгълник не се получава.",
        watch: "Не се умножава по 3 — страните са различни."
      )
    )
  end
end

Authoring.family "perim.fence_story", topic: "Периметър", area: "geometry",
                 rungs: [ 900, 990, 1080, 1170, 1260, 1360 ] do |c|
  spec = c.by_level([ 3..10, 5..20, 8..40, 12..80, 20..150, 30..300 ])
  a = c.int(spec)
  b = c.int(spec)
  price = c.int(c.by_level([ 2..6, 3..9, 4..12, 5..20, 8..40, 10..80 ]))
  perimeter = 2 * (a + b)
  total = perimeter * price

  c.q(
    text: "Правоъгълен двор е #{a} м на #{b} м и се огражда с мрежа. Един метър мрежа струва #{price} лв. " \
          "Колко лева струва мрежата за целия двор?",
    answer: Num.ans(total),
    explanation: Explain.build(
      idea: "Оградата върви по обиколката, значи първо периметър, после цена.",
      steps: [
        "P = 2 · (#{a} + #{b}) = #{perimeter} м.",
        "#{perimeter} · #{price} = #{total} лв."
      ],
      answer: "#{total} лв.",
      check: "#{total} : #{price} = #{perimeter} м мрежа.",
      watch: "Оградата се мери по периметъра, не по площта (#{a * b} м²)."
    )
  )
end

Authoring.family "perim.regular_polygon", topic: "Периметър", area: "geometry",
                 rungs: [ 860, 950, 1040, 1130, 1220, 1320 ] do |c|
  sides = c.pick(c.by_level([ [ 3, 4 ], [ 3, 4, 5 ], [ 5, 6 ], [ 6, 8 ], [ 8, 10 ], [ 9, 12 ] ]))
  side = c.int(c.by_level([ 2..9, 3..15, 4..25, 6..50, 10..120, 15..250 ]))
  perimeter = sides * side
  names = { 3 => "триъгълник", 4 => "четириъгълник", 5 => "петоъгълник", 6 => "шестоъгълник",
            8 => "осмоъгълник", 9 => "деветоъгълник", 10 => "десетоъгълник", 12 => "дванадесетоъгълник" }

  c.q(
    text: "Правилен #{names[sides]} има страна #{side} см. Колко сантиметра е периметърът му?",
    answer: Num.ans(perimeter),
    explanation: Explain.build(
      idea: "„Правилен“ значи всички страни са равни, затова периметърът е брой страни по дължина на страната.",
      steps: [ "P = #{sides} · #{side} = #{perimeter} см." ],
      answer: "#{perimeter} см",
      check: "#{perimeter} : #{sides} = #{side} см — връщаме се към страната.",
      watch: "Броят на страните е #{sides}, колкото са и върховете."
    )
  )
end

# ------------------------------------------------------------------ Площ ---

Authoring.family "area.rectangle", topic: "Площ", area: "geometry",
                 rungs: [ 850, 940, 1030, 1120, 1210, 1310 ] do |c|
  spec = c.by_level([ 2..9, 3..15, 4..25, 6..50, 10..120, 15..300 ])
  a = c.int(spec)
  b = c.int(spec)
  area = a * b

  c.q(
    text: "Правоъгълник има страни #{a} см и #{b} см. Колко квадратни сантиметра е лицето му?",
    answer: Num.ans(area),
    explanation: Explain.build(
      idea: "Лицето на правоъгълник е произведението на двете му съседни страни.",
      steps: [ "S = a · b = #{a} · #{b} = #{area} см²." ],
      answer: "#{area} см²",
      check: "Правоъгълникът се покрива с #{a} реда по #{b} квадратчета — #{area} на брой.",
      watch: "Периметърът тук е #{2 * (a + b)} см — не се бърка с лицето."
    )
  )
end

Authoring.family "area.rectangle_reverse", topic: "Площ", area: "geometry",
                 rungs: [ 950, 1040, 1130, 1220, 1310, 1410 ] do |c|
  spec = c.by_level([ 2..9, 3..12, 4..20, 5..40, 8..90, 12..200 ])
  a = c.int(spec)
  b = c.int(spec)
  area = a * b

  c.q(
    text: "Лицето на правоъгълник е #{area} см², а едната му страна е #{a} см. Колко сантиметра е другата страна?",
    answer: Num.ans(b),
    explanation: Explain.build(
      idea: "От S = a · b следва, че липсващата страна е лицето, разделено на известната страна.",
      steps: [ "b = S : a = #{area} : #{a} = #{b} см." ],
      answer: "#{b} см",
      check: "#{a} · #{b} = #{area} см².",
      watch: "Дели се лицето на страната; изваждането няма смисъл тук."
    )
  )
end

Authoring.family "area.triangle", topic: "Площ", area: "geometry",
                 rungs: [ 1000, 1090, 1180, 1270, 1360, 1460 ] do |c|
  spec = c.by_level([ 2..10, 4..16, 6..30, 8..60, 12..140, 20..300 ])
  base = c.int(spec) * 2
  height = c.int(spec)
  area = base * height / 2

  c.q(
    text: "Триъгълник има основа #{base} см и височина към нея #{height} см. Колко квадратни сантиметра е лицето му?",
    answer: Num.ans(area),
    explanation: Explain.build(
      idea: "Триъгълникът е половината от правоъгълник със същата основа и височина.",
      steps: [
        "S = a · h : 2 = #{base} · #{height} : 2.",
        "#{base} · #{height} = #{base * height}, а половината е #{area} см²."
      ],
      answer: "#{area} см²",
      check: "Двоен триъгълник дава правоъгълник с лице #{base * height} см².",
      watch: "Височината е перпендикулярна на основата — не е коя да е страна."
    )
  )
end

Authoring.family "area.parallelogram", topic: "Площ", area: "geometry",
                 rungs: [ 1050, 1140, 1230, 1320, 1410, 1510 ] do |c|
  spec = c.by_level([ 3..10, 4..16, 6..30, 8..60, 12..140, 20..300 ])
  base = c.int(spec)
  height = c.int(spec)
  side = height + c.int(1..5)
  area = base * height

  c.q(
    text: "Успоредник има основа #{base} см, височина към нея #{height} см и втора страна #{side} см. " \
          "Колко квадратни сантиметра е лицето му?",
    answer: Num.ans(area),
    explanation: Explain.build(
      idea: "Лицето на успоредник е основа по височина — страната отстрани не участва.",
      steps: [
        "S = a · h = #{base} · #{height} = #{area} см².",
        "Втората страна (#{side} см) е дадена нарочно, за да се провери дали ще бъде използвана погрешно."
      ],
      answer: "#{area} см²",
      check: "Успоредникът се преподрежда в правоъгълник #{base} см на #{height} см.",
      watch: "#{base} · #{side} = #{base * side} см² е типичната грешка — това не е лицето."
    )
  )
end

Authoring.family "area.trapezoid", topic: "Площ", area: "geometry",
                 rungs: [ 1150, 1240, 1330, 1420, 1510, 1610 ] do |c|
  spec = c.by_level([ 2..10, 3..16, 4..30, 6..60, 10..140, 15..300 ])
  a = c.int(spec)
  b = c.int(spec)
  raise Authoring::Duplicate if a == b

  height = c.int(spec) * 2
  area = (a + b) * height / 2

  c.q(
    text: "Трапец има основи #{a} см и #{b} см и височина #{height} см. Колко квадратни сантиметра е лицето му?",
    answer: Num.ans(area),
    explanation: Explain.build(
      idea: "Лицето на трапец е средното аритметично на основите, умножено по височината.",
      steps: [
        "S = (a + b) : 2 · h = (#{a} + #{b}) : 2 · #{height}.",
        "#{a} + #{b} = #{a + b}, а #{a + b} : 2 = #{Num.dec(Rational(a + b, 2), 1)}.",
        "#{Num.dec(Rational(a + b, 2), 1)} · #{height} = #{area} см²."
      ],
      answer: "#{area} см²",
      check: "Лицето е между това на правоъгълниците #{a} · #{height} = #{a * height} и #{b} · #{height} = #{b * height}.",
      watch: "Основите се събират, преди да се дели на 2 — не се умножават."
    )
  )
end

Authoring.family "area.composite", topic: "Площ", area: "geometry",
                 rungs: [ 1200, 1290, 1380, 1470, 1560, 1660 ] do |c|
  spec = c.by_level([ 2..8, 3..12, 4..20, 6..40, 10..90, 14..200 ])
  big_a = c.int(spec) + 4
  big_b = c.int(spec) + 4
  cut_a = c.int(1...big_a)
  cut_b = c.int(1...big_b)
  area = (big_a * big_b) - (cut_a * cut_b)

  c.q(
    text: "От правоъгълник #{big_a} м на #{big_b} м е изрязано правоъгълно парче #{cut_a} м на #{cut_b} м. " \
          "Колко квадратни метра е лицето на останалата фигура?",
    answer: Num.ans(area),
    explanation: Explain.build(
      idea: "Съставна фигура се смята чрез изваждане: цялото минус изрязаното.",
      steps: [
        "Голям правоъгълник: #{big_a} · #{big_b} = #{big_a * big_b} м².",
        "Изрязано парче: #{cut_a} · #{cut_b} = #{cut_a * cut_b} м².",
        "Остава: #{big_a * big_b} − #{cut_a * cut_b} = #{area} м²."
      ],
      answer: "#{area} м²",
      check: "#{area} + #{cut_a * cut_b} = #{big_a * big_b} м² — сглобяваме обратно.",
      watch: "Периметърът на останалата фигура не се променя толкова просто — тук се пита за лице."
    )
  )
end

Authoring.family "area.units", topic: "Площ", area: "geometry",
                 rungs: [ 1120, 1210, 1300, 1390, 1480, 1580 ] do |c|
  pair = c.by_level([
    [ "дм²", "см²", 100 ], [ "м²", "дм²", 100 ], [ "м²", "см²", 10_000 ],
    [ "дка", "м²", 1000 ], [ "хектара", "м²", 10_000 ], [ "км²", "м²", 1_000_000 ]
  ])
  big, small, factor = pair
  value = c.int(c.by_level([ 2..9, 3..15, 2..12, 3..25, 2..18, 2..9 ]))
  converted = value * factor

  c.q(
    text: "Колко #{small} са #{value} #{big}?",
    answer: Num.ans(converted),
    explanation: Explain.build(
      idea: "При квадратните мерки множителят се повдига на квадрат: ако дължините се различават #{Integer.sqrt(factor)} пъти, лицата се различават #{factor} пъти.",
      steps: [
        "1 #{big} = #{factor} #{small}.",
        "#{value} · #{factor} = #{converted} #{small}."
      ],
      answer: "#{converted} #{small}",
      check: "#{converted} : #{factor} = #{value} #{big}.",
      watch: "Множителят при площите не е #{Integer.sqrt(factor)}, а #{factor} — това е най-честата грешка."
    )
  )
end

Authoring.family "area.path_frame", topic: "Площ", area: "geometry",
                 rungs: [ 1300, 1390, 1480, 1570, 1660, 1760 ] do |c|
  spec = c.by_level([ 4..10, 5..16, 6..25, 8..40, 12..80, 16..150 ])
  a = c.int(spec)
  b = c.int(spec)
  width = c.int(1..c.by_level([ 1, 2, 2, 3, 4, 5 ]))
  inner = (a - (2 * width)) * (b - (2 * width))
  raise Authoring::Duplicate if a - (2 * width) < 1 || b - (2 * width) < 1

  frame = (a * b) - inner

  c.q(
    text: "Правоъгълна градина е #{a} м на #{b} м. Около нея, отвътре, минава алея с ширина #{width} м. " \
          "Колко квадратни метра е лицето на алеята?",
    answer: Num.ans(frame),
    explanation: Explain.build(
      idea: "Алеята е рамка: лицето на цялата градина минус лицето на вътрешния правоъгълник.",
      steps: [
        "Цялата градина: #{a} · #{b} = #{a * b} м².",
        "Вътрешният правоъгълник е с #{2 * width} м по-къс във всяка посока: #{a - (2 * width)} · #{b - (2 * width)} = #{inner} м².",
        "Алеята: #{a * b} − #{inner} = #{frame} м²."
      ],
      answer: "#{frame} м²",
      check: "#{inner} + #{frame} = #{a * b} м².",
      watch: "Ширината се маха два пъти от всяка страна — по веднъж от всеки край."
    )
  )
end

# ------------------------------------------------------------------ Ъгли ---

Authoring.family "angle.triangle_sum", topic: "Ъгли", area: "geometry",
                 rungs: [ 920, 1010, 1100, 1190, 1280, 1380 ] do |c|
  first = c.int(c.by_level([ 20..80, 20..90, 15..100, 12..120, 11..130, 10..140 ]))
  second = c.int(20..(175 - first))
  third = 180 - first - second
  raise Authoring::Duplicate if third < 5

  c.q(
    text: "В триъгълник два от ъглите са #{first}° и #{second}°. Колко градуса е третият ъгъл?",
    answer: Num.ans(third),
    explanation: Explain.build(
      idea: "Сборът на ъглите във всеки триъгълник е 180°.",
      steps: [
        "#{first} + #{second} = #{first + second}.",
        "180 − #{first + second} = #{third}°."
      ],
      answer: "#{third}°",
      check: "#{first} + #{second} + #{third} = 180°.",
      watch: third > 90 ? "Ъгъл над 90° е тъп — триъгълникът е тъпоъгълен, което е напълно възможно." : "Всички ъгли излизат положителни, значи триъгълникът съществува."
    )
  )
end

Authoring.family "angle.isosceles", topic: "Ъгли", area: "geometry",
                 rungs: [ 1050, 1140, 1230, 1320, 1410, 1510 ] do |c|
  apex_known = c.coin
  if apex_known
    apex = c.int(c.by_level([ 20..100, 20..120, 16..140, 12..150, 10..160, 8..170 ]))
    apex += 1 if apex.odd?
    base_angle = (180 - apex) / 2
    raise Authoring::Duplicate if base_angle < 5

    text = "В равнобедрен триъгълник ъгълът при върха е #{apex}°. Колко градуса е всеки от ъглите при основата?"
    answer = base_angle
    steps = [
      "Двата ъгъла при основата са равни.",
      "180 − #{apex} = #{180 - apex} градуса остават за тях.",
      "#{180 - apex} : 2 = #{base_angle}°."
    ]
  else
    base_angle = c.int(c.by_level([ 30..70, 25..80, 20..85, 15..87, 11..88, 6..89 ]))
    apex = 180 - (2 * base_angle)
    text = "В равнобедрен триъгълник ъгълът при основата е #{base_angle}°. Колко градуса е ъгълът при върха?"
    answer = apex
    steps = [
      "Ъглите при основата са два и всеки е #{base_angle}°: заедно #{2 * base_angle}°.",
      "180 − #{2 * base_angle} = #{apex}°."
    ]
  end

  c.q(
    text: text,
    answer: Num.ans(answer),
    explanation: Explain.build(
      idea: "В равнобедрен триъгълник ъглите при основата са равни, а сборът на трите е 180°.",
      steps: steps,
      answer: "#{answer}°",
      check: "#{apex} + #{base_angle} + #{base_angle} = 180°.",
      watch: "Ъгълът при върха и ъглите при основата играят различни роли — важно е кой е даден."
    )
  )
end

Authoring.family "angle.exterior", topic: "Ъгли", area: "geometry",
                 rungs: [ 1180, 1270, 1360, 1450, 1540, 1640 ] do |c|
  first = c.int(c.by_level([ 30..70, 25..80, 20..90, 15..100, 12..120, 10..140 ]))
  second = c.int(20..(170 - first))
  exterior = first + second
  raise Authoring::Duplicate if exterior >= 180 || 180 - exterior < 5

  c.q(
    text: "Външният ъгъл при един връх на триъгълник е #{exterior}°, а единият от несъседните вътрешни ъгли е #{first}°. " \
          "Колко градуса е другият несъседен вътрешен ъгъл?",
    answer: Num.ans(second),
    explanation: Explain.build(
      idea: "Външният ъгъл е равен на сбора на двата несъседни вътрешни ъгъла.",
      steps: [
        "#{exterior} = #{first} + x.",
        "x = #{exterior} − #{first} = #{second}°."
      ],
      answer: "#{second}°",
      check: "Вътрешният ъгъл при същия връх е 180 − #{exterior} = #{180 - exterior}°, а #{first} + #{second} + #{180 - exterior} = 180°.",
      watch: "Външният ъгъл не е равен на вътрешния при същия връх — те се допълват до 180°."
    )
  )
end

Authoring.family "angle.complement_supplement", topic: "Ъгли", area: "geometry",
                 rungs: [ 900, 990, 1080, 1170, 1260, 1360 ] do |c|
  supplement = c.level >= 2 ? c.coin : false
  total = supplement ? 180 : 90
  known = c.int(c.by_level([ 10..80, 10..85, 15..165, 12..170, 8..172, 5..175 ]))
  known = c.int(10..80) unless supplement || known < 90
  other = total - known
  raise Authoring::Duplicate if other <= 0

  c.q(
    text: supplement ? "Два ъгъла се допълват до 180°. Единият е #{known}°. Колко градуса е другият?" :
                       "Два ъгъла се допълват до прав ъгъл. Единият е #{known}°. Колко градуса е другият?",
    answer: Num.ans(other),
    explanation: Explain.build(
      idea: supplement ? "Съседните ъгли (прилежащи по права) дават заедно 180°." : "Двата ъгъла дават заедно 90°, защото допълват прав ъгъл.",
      steps: [ "#{total} − #{known} = #{other}°." ],
      answer: "#{other}°",
      check: "#{known} + #{other} = #{total}°.",
      watch: supplement ? "180° е изпънат ъгъл; 90° е правият." : "Правият ъгъл е 90°, не 180°."
    )
  )
end

Authoring.family "angle.vertical_pairs", topic: "Ъгли", area: "geometry",
                 rungs: [ 1000, 1090, 1180, 1270, 1360, 1460 ] do |c|
  known = c.int(c.by_level([ 20..70, 15..80, 12..85, 25..155, 18..162, 8..172 ]))
  raise Authoring::Duplicate if known == 90

  ask_vertical = c.coin
  answer = ask_vertical ? known : 180 - known

  c.q(
    text: "Две прави се пресичат. Един от получените ъгли е #{known}°. " \
          "Колко градуса е #{ask_vertical ? 'противоположният му' : 'съседният му'} ъгъл?",
    answer: Num.ans(answer),
    explanation: Explain.build(
      idea: "При пресичане на две прави противоположните ъгли са равни, а съседните се допълват до 180°.",
      steps: [
        ask_vertical ? "Противоположните (вертикалните) ъгли са равни: #{known}° и #{known}°." :
                       "Съседните ъгли лежат на една права: #{known} + x = 180."
      ],
      answer: "#{answer}°",
      check: "Четирите ъгъла са #{known}°, #{180 - known}°, #{known}° и #{180 - known}° — сборът им е 360°.",
      watch: "Равни са противоположните, не съседните ъгли."
    )
  )
end

Authoring.family "angle.parallel_lines", topic: "Ъгли", area: "geometry",
                 rungs: [ 1120, 1210, 1300, 1390, 1480, 1580 ] do |c|
  known = c.int(c.by_level([ 30..70, 25..80, 20..85, 25..155, 18..162, 12..168 ]))
  raise Authoring::Duplicate if known == 90

  kind = c.by_level([ :corresponding, :corresponding, :alternate, :cointerior, :alternate, :cointerior ])
  answer = kind == :cointerior ? 180 - known : known
  name = { corresponding: "съответните", alternate: "кръстните вътрешни", cointerior: "едностранните вътрешни" }[kind]

  c.q(
    text: "Две успоредни прави са пресечени от трета. Един от ъглите е #{known}°. " \
          "Колко градуса е #{name.sub(/те\z/, 'ият')} му ъгъл?",
    answer: Num.ans(answer),
    explanation: Explain.build(
      idea: "При успоредни прави и трансверзала съответните и кръстните ъгли са равни, а едностранните вътрешни се допълват до 180°.",
      steps: [
        kind == :cointerior ? "Едностранните вътрешни ъгли дават заедно 180°: 180 − #{known} = #{answer}°." :
                              "#{name.capitalize} ъгли са равни, значи ъгълът е #{answer}°."
      ],
      answer: "#{answer}°",
      check: "Около всяко пресичане ъглите са #{known}°, #{180 - known}°, #{known}°, #{180 - known}°.",
      watch: "Без успоредност нито едно от тези равенства не важи."
    )
  )
end

Authoring.family "angle.polygon_sum", topic: "Ъгли", area: "geometry",
                 rungs: [ 1250, 1340, 1430, 1520, 1610, 1710 ] do |c|
  sides = c.pick(c.by_level([ [ 4, 5, 6 ], [ 5, 6, 7, 8 ], [ 6, 7, 8, 9, 10 ], [ 9, 10, 11, 12, 14 ], [ 11, 12, 15, 16, 18 ], [ 13, 14, 18, 20, 24, 30 ] ]))
  total = (sides - 2) * 180
  ask_one = c.level >= 2 && c.coin
  single = total / sides
  raise Authoring::Duplicate if ask_one && (total % sides) != 0

  c.q(
    text: ask_one ? "Колко градуса е един вътрешен ъгъл на правилен #{sides}-ъгълник?" :
                    "Колко градуса е сборът на вътрешните ъгли на изпъкнал #{sides}-ъгълник?",
    answer: Num.ans(ask_one ? single : total),
    explanation: Explain.build(
      idea: "От един връх многоъгълникът се разрязва на #{sides - 2} триъгълника, а всеки дава по 180°.",
      steps: [
        "Сбор = (#{sides} − 2) · 180 = #{sides - 2} · 180 = #{total}°.",
        ask_one ? "При правилен многоъгълник всички ъгли са равни: #{total} : #{sides} = #{single}°." : nil
      ].compact,
      answer: "#{ask_one ? single : total}°",
      check: ask_one ? "#{sides} · #{single} = #{total}° — сборът излиза същият." : "За #{sides} = 3 формулата дава 180°, както трябва.",
      watch: "Формулата е (n − 2) · 180, не n · 180."
    )
  )
end

Authoring.family "angle.clock", topic: "Ъгли", area: "geometry",
                 rungs: [ 1200, 1290, 1380, 1470, 1560, 1660 ] do |c|
  hour = c.int(1..12)
  minute = c.pick(c.by_level([ [ 0, 30 ], [ 0, 15, 30, 45 ], [ 0, 10, 20, 40, 50 ], [ 5, 15, 25, 35, 45, 55 ], [ 8, 12, 16, 24, 36, 48 ], [ 7, 13, 17, 23, 29, 41, 53 ] ]))
  hour_angle = ((hour % 12) * 30) + (minute * 0.5)
  minute_angle = minute * 6
  diff = (hour_angle - minute_angle).abs
  diff = 360 - diff if diff > 180
  diff = Rational((diff * 2).round, 2)

  c.q(
    text: "Колко градуса е по-малкият ъгъл между стрелките на часовника в #{hour}:#{format('%02d', minute)} ч?",
    answer: Num.dec(diff, 1),
    explanation: Explain.build(
      idea: "Минутната стрелка изминава 6° за минута, часовата — 0,5° за минута (30° на час).",
      steps: [
        "Минутна стрелка: #{minute} · 6 = #{minute_angle}° от 12 часа.",
        "Часова стрелка: #{hour % 12} · 30 + #{minute} · 0,5 = #{Num.dec(Rational((hour_angle * 2).to_i, 2), 1)}°.",
        "Разлика: |#{Num.dec(Rational((hour_angle * 2).to_i, 2), 1)} − #{minute_angle}| = #{Num.dec(diff, 1)}°#{(hour_angle - minute_angle).abs > 180 ? ", а по-малкият ъгъл е 360 минус това" : ''}."
      ],
      answer: "#{Num.dec(diff, 1)}°",
      check: "Двата ъгъла между стрелките дават 360°: #{Num.dec(diff, 1)}° и #{Num.dec(360 - diff, 1)}°.",
      watch: "Часовата стрелка също се движи през часа — не стои точно на цифрата."
    )
  )
end

# ------------------------------------------------------------------ Обем ---

Authoring.family "vol.cuboid", topic: "Обем", area: "geometry",
                 rungs: [ 1030, 1120, 1210, 1300, 1390, 1490 ] do |c|
  spec = c.by_level([ 2..6, 2..9, 3..12, 4..20, 6..40, 8..90 ])
  a = c.int(spec)
  b = c.int(spec)
  h = c.int(spec)
  volume = a * b * h

  c.q(
    text: "Правоъгълен паралелепипед има измерения #{a} см, #{b} см и #{h} см. Колко кубични сантиметра е обемът му?",
    answer: Num.ans(volume),
    explanation: Explain.build(
      idea: "Обемът на паралелепипед е произведението на трите измерения.",
      steps: [
        "V = a · b · c = #{a} · #{b} · #{h}.",
        "#{a} · #{b} = #{a * b}, после #{a * b} · #{h} = #{volume} см³."
      ],
      answer: "#{volume} см³",
      check: "Един слой е #{a * b} см³ и слоевете са #{h}.",
      watch: "Обемът е в кубични единици; лицето на основата (#{a * b} см²) е друга величина."
    )
  )
end

Authoring.family "vol.cube", topic: "Обем", area: "geometry",
                 rungs: [ 1060, 1150, 1240, 1330, 1420, 1520 ] do |c|
  edge = c.int(c.by_level([ 2..7, 3..10, 4..14, 5..20, 8..30, 10..60 ]))
  volume = edge**3
  ask_edge = c.level >= 3 && c.coin

  c.q(
    text: ask_edge ? "Обемът на куб е #{volume} см³. Колко сантиметра е ръбът му?" :
                     "Куб има ръб #{edge} см. Колко кубични сантиметра е обемът му?",
    answer: Num.ans(ask_edge ? edge : volume),
    explanation: Explain.build(
      idea: "При куба и трите измерения са равни, затова V = a³.",
      steps: ask_edge ?
        [ "Търсим число, чийто куб е #{volume}.",
          "#{edge} · #{edge} · #{edge} = #{volume}, значи ръбът е #{edge} см." ] :
        [ "V = #{edge}³ = #{edge} · #{edge} · #{edge} = #{volume} см³." ],
      answer: ask_edge ? "#{edge} см" : "#{volume} см³",
      check: "#{edge}³ = #{volume} — двете посоки съвпадат.",
      watch: "a³ не е 3 · a: #{edge}³ = #{volume}, а 3 · #{edge} = #{3 * edge}."
    )
  )
end

Authoring.family "vol.units_litres", topic: "Обем", area: "geometry",
                 rungs: [ 1150, 1240, 1330, 1420, 1510, 1610 ] do |c|
  # An aquarium, not a swimming pool: each dimension has its own ceiling.
  size = c.by_level([ 3, 4, 6, 8, 10, 12 ])
  a = c.int(2..size) * 10
  b = c.int(2..[ size, 12 ].min) * 10
  h = c.int(2..[ size, 10 ].min) * 10
  volume_cm = a * b * h
  litres = Rational(volume_cm, 1000)

  c.q(
    text: "Аквариум има дъно #{a} см на #{b} см и височина #{h} см. Колко литра вода побира, ако се напълни догоре?",
    answer: Num.ans(litres),
    explanation: Explain.build(
      idea: "Първо обемът в кубични сантиметри, после превръщане: 1 литър = 1000 см³ (1 дм³).",
      steps: [
        "V = #{a} · #{b} · #{h} = #{volume_cm} см³.",
        "#{volume_cm} : 1000 = #{Num.ans(litres)} литра."
      ],
      answer: "#{Num.ans(litres)} л",
      check: "#{Num.ans(litres)} · 1000 = #{volume_cm} см³.",
      watch: "1 литър е 1000 см³, а не 100 см³ — грешката мести отговора 10 пъти."
    )
  )
end

Authoring.family "vol.surface_cuboid", topic: "Обем", area: "geometry",
                 rungs: [ 1250, 1340, 1430, 1520, 1610, 1710 ] do |c|
  spec = c.by_level([ 2..6, 2..9, 3..12, 4..20, 6..35, 8..60 ])
  a = c.int(spec)
  b = c.int(spec)
  h = c.int(spec)
  surface = 2 * ((a * b) + (b * h) + (a * h))

  c.q(
    text: "Затворена кутия с форма на правоъгълен паралелепипед е #{a} см на #{b} см на #{h} см. " \
          "Колко квадратни сантиметра картон са нужни за нея (без застъпване)?",
    answer: Num.ans(surface),
    explanation: Explain.build(
      idea: "Повърхнината е сборът от лицата на шестте стени, които са равни по двойки.",
      steps: [
        "Двойка 1: #{a} · #{b} = #{a * b}, две такива стени: #{2 * a * b}.",
        "Двойка 2: #{b} · #{h} = #{b * h}, две такива стени: #{2 * b * h}.",
        "Двойка 3: #{a} · #{h} = #{a * h}, две такива стени: #{2 * a * h}.",
        "S = #{2 * a * b} + #{2 * b * h} + #{2 * a * h} = #{surface} см²."
      ],
      answer: "#{surface} см²",
      check: "Обемът е #{a * b * h} см³ — различна величина, различна мерна единица.",
      watch: "Стените са шест, а не три — всяко лице участва два пъти."
    )
  )
end

Authoring.family "vol.prism", topic: "Обем", area: "geometry",
                 rungs: [ 1300, 1390, 1480, 1570, 1660, 1760 ] do |c|
  spec = c.by_level([ 2..8, 3..12, 4..18, 5..30, 8..60, 10..120 ])
  base = c.int(spec) * 2
  height_tri = c.int(spec)
  length = c.int(spec)
  base_area = base * height_tri / 2
  volume = base_area * length

  c.q(
    text: "Права призма има за основа триъгълник с основа #{base} см и височина #{height_tri} см. " \
          "Височината на призмата е #{length} см. Колко кубични сантиметра е обемът ѝ?",
    answer: Num.ans(volume),
    explanation: Explain.build(
      idea: "Обемът на призма е лице на основата по височина.",
      steps: [
        "Лице на основата: #{base} · #{height_tri} : 2 = #{base_area} см².",
        "V = #{base_area} · #{length} = #{volume} см³."
      ],
      answer: "#{volume} см³",
      check: "Ако височината се удвои, обемът става #{2 * volume} см³ — расте пропорционално.",
      watch: "Височината на триъгълника и височината на призмата са различни неща."
    )
  )
end

# ------------------------------------------------------- Питагорова теорема ---

Authoring.family "pyth.hypotenuse", topic: "Питагорова теорема", area: "geometry",
                 rungs: [ 1260, 1350, 1440, 1530, 1620, 1720 ] do |c|
  a, b, hyp = pythagorean_triple(c)
  a, b = b, a if c.coin

  c.q(
    text: "Правоъгълен триъгълник има катети #{a} см и #{b} см. Колко сантиметра е хипотенузата?",
    answer: Num.ans(hyp),
    explanation: Explain.build(
      idea: "Питагоровата теорема: сборът от квадратите на катетите е равен на квадрата на хипотенузата.",
      steps: [
        "#{a}² + #{b}² = #{a * a} + #{b * b} = #{(a * a) + (b * b)}.",
        "c² = #{(a * a) + (b * b)}, значи c = √#{(a * a) + (b * b)} = #{hyp} см."
      ],
      answer: "#{hyp} см",
      check: "#{hyp}² = #{hyp * hyp} = #{a * a} + #{b * b}.",
      watch: "Хипотенузата е по-дълга от всеки катет, но по-къса от сбора им: #{[ a, b ].max} < #{hyp} < #{a + b}."
    )
  )
end

Authoring.family "pyth.leg", topic: "Питагорова теорема", area: "geometry",
                 rungs: [ 1340, 1430, 1520, 1610, 1700, 1800 ] do |c|
  a, b, hyp = pythagorean_triple(c)
  a, b = b, a if c.coin
  known, unknown = c.coin ? [ a, b ] : [ b, a ]

  c.q(
    text: "В правоъгълен триъгълник хипотенузата е #{hyp} см, а единият катет — #{known} см. " \
          "Колко сантиметра е другият катет?",
    answer: Num.ans(unknown),
    explanation: Explain.build(
      idea: "От c² = a² + b² следва, че липсващият катет се намира с изваждане на квадратите.",
      steps: [
        "#{hyp}² = #{hyp * hyp} и #{known}² = #{known * known}.",
        "#{hyp * hyp} − #{known * known} = #{unknown * unknown}.",
        "√#{unknown * unknown} = #{unknown} см."
      ],
      answer: "#{unknown} см",
      check: "#{unknown}² + #{known}² = #{unknown * unknown} + #{known * known} = #{hyp * hyp} = #{hyp}².",
      watch: "Изважда се квадратът на катета от квадрата на хипотенузата, не самите дължини (#{hyp} − #{known} = #{hyp - known} е грешка)."
    )
  )
end

Authoring.family "pyth.rectangle_diagonal", topic: "Питагорова теорема", area: "geometry",
                 rungs: [ 1380, 1470, 1560, 1650, 1740, 1840 ] do |c|
  a, b, diagonal = pythagorean_triple(c)
  a, b = b, a if c.coin

  c.q(
    text: "Правоъгълник има страни #{a} см и #{b} см. Колко сантиметра е диагоналът му?",
    answer: Num.ans(diagonal),
    explanation: Explain.build(
      idea: "Диагоналът разделя правоъгълника на два правоъгълни триъгълника с катети страните.",
      steps: [
        "d² = #{a}² + #{b}² = #{a * a} + #{b * b} = #{diagonal * diagonal}.",
        "d = √#{diagonal * diagonal} = #{diagonal} см."
      ],
      answer: "#{diagonal} см",
      check: "#{diagonal}² = #{diagonal * diagonal} = #{a * a} + #{b * b}.",
      watch: "Диагоналът е по-дълъг от всяка страна, но по-къс от полупериметъра (#{a + b} см)."
    )
  )
end

Authoring.family "pyth.ladder", topic: "Питагорова теорема", area: "geometry",
                 rungs: [ 1420, 1510, 1600, 1690, 1780, 1880 ] do |c|
  a, b, hyp = pythagorean_triple(c)
  a, b = b, a if c.coin
  # The object has to match the length: a 60 m ladder is not a thing, a guy rope
  # or a cable car span is.
  thing, verb = if hyp <= 25
                  [ "Стълба", "е опряна на стена" ]
  elsif hyp <= 70
                  [ "Въже", "е опънато от върха на стълб до земята" ]
  else
                  [ "Кабел", "е опънат от върха на мачта до земята" ]
  end

  c.q(
    text: "#{thing} с дължина #{hyp} м #{verb}. Долният край е на #{a} м от основата. " \
          "На каква височина в метри стига горният край?",
    answer: Num.ans(b),
    explanation: Explain.build(
      idea: "Стълбата, стената и земята образуват правоъгълен триъгълник, в който стълбата е хипотенузата.",
      steps: [
        "#{hyp}² − #{a}² = #{hyp * hyp} − #{a * a} = #{b * b}.",
        "Височината е √#{b * b} = #{b} м."
      ],
      answer: "#{b} м",
      check: "#{a}² + #{b}² = #{a * a} + #{b * b} = #{hyp * hyp} = #{hyp}².",
      watch: "Наклонената страна винаги е най-дългата — височината (#{b} м) не може да надмине #{hyp} м."
    )
  )
end

Authoring.family "pyth.is_right", topic: "Питагорова теорема", area: "geometry",
                 rungs: [ 1300, 1390, 1480, 1570, 1660, 1760 ] do |c|
  a, b, hyp = pythagorean_triple(c)
  fake = hyp + c.pick([ -1, 1, 2 ])
  right = c.coin
  sides = right ? [ a, b, hyp ] : [ a, b, fake ]

  c.q(
    text: "Триъгълник има страни #{sides[0]} см, #{sides[1]} см и #{sides[2]} см. Правоъгълен ли е? " \
          "(Отговори с „да“ или „не“.)",
    options: c.options(right ? "да" : "не", right ? "не" : "да", "не може да се определи"),
    answer: right ? "да" : "не",
    explanation: Explain.build(
      idea: "Обратната Питагорова теорема: триъгълникът е правоъгълен точно когато квадратът на най-дългата страна е сборът от квадратите на другите две.",
      steps: [
        "Най-дългата страна е #{sides.max} см: #{sides.max}² = #{sides.max**2}.",
        "Другите две: #{sides.sort[0]}² + #{sides.sort[1]}² = #{sides.sort[0]**2} + #{sides.sort[1]**2} = #{(sides.sort[0]**2) + (sides.sort[1]**2)}.",
        right ? "Двете числа съвпадат, значи триъгълникът е правоъгълен." :
                "#{sides.max**2} ≠ #{(sides.sort[0]**2) + (sides.sort[1]**2)}, значи не е правоъгълен."
      ],
      answer: right ? "да" : "не",
      check: "Проверката е върху квадратите, а разликата тук е #{((sides.max**2) - ((sides.sort[0]**2) + (sides.sort[1]**2))).abs}.",
      watch: "Сравняват се квадратите, а не самите страни."
    )
  )
end

# ------------------------------------------------------------ Подобни фигури ---

Authoring.family "similar.missing_side", topic: "Подобни фигури", area: "geometry",
                 rungs: [ 1320, 1410, 1500, 1590, 1680, 1780 ] do |c|
  scale = c.int(c.by_level([ 2..3, 2..4, 2..5, 3..6, 3..8, 4..12 ]))
  a = c.int(c.by_level([ 2..8, 3..12, 4..16, 5..25, 8..40, 10..80 ]))
  b = c.int(c.by_level([ 2..8, 3..12, 4..16, 5..25, 8..40, 10..80 ]))
  big_a = a * scale
  big_b = b * scale

  c.q(
    text: "Два триъгълника са подобни. На страна #{a} см от малкия съответства страна #{big_a} см от големия. " \
          "Колко сантиметра е страната на големия, съответна на страна #{b} см от малкия?",
    answer: Num.ans(big_b),
    explanation: Explain.build(
      idea: "При подобни фигури всички съответни страни са в едно и също отношение — коефициента на подобие.",
      steps: [
        "k = #{big_a} : #{a} = #{scale}.",
        "#{b} · #{scale} = #{big_b} см."
      ],
      answer: "#{big_b} см",
      check: "#{big_b} : #{b} = #{scale} — същият коефициент като при първата двойка.",
      watch: "Коефициентът умножава, не прибавя: #{b} + #{big_a - a} = #{b + big_a - a} е грешен отговор."
    )
  )
end

Authoring.family "similar.area_ratio", topic: "Подобни фигури", area: "geometry",
                 rungs: [ 1420, 1510, 1600, 1690, 1780, 1880 ] do |c|
  scale = c.int(c.by_level([ 2..3, 2..4, 2..5, 3..6, 3..8, 4..10 ]))
  small_area = c.int(c.by_level([ 2..12, 3..20, 4..40, 6..80, 10..200, 15..500 ]))
  big_area = small_area * scale * scale

  c.q(
    text: "Две подобни фигури имат коефициент на подобие #{scale}. Лицето на по-малката е #{small_area} см². " \
          "Колко квадратни сантиметра е лицето на по-голямата?",
    answer: Num.ans(big_area),
    explanation: Explain.build(
      idea: "Дължините растат k пъти, а лицата — k² пъти.",
      steps: [
        "k = #{scale}, значи k² = #{scale * scale}.",
        "#{small_area} · #{scale * scale} = #{big_area} см²."
      ],
      answer: "#{big_area} см²",
      check: "#{big_area} : #{small_area} = #{scale * scale} = #{scale}².",
      watch: "Лицето не расте #{scale} пъти (#{small_area * scale} см²), а #{scale * scale} пъти."
    )
  )
end

Authoring.family "similar.map_scale", topic: "Подобни фигури", area: "geometry",
                 rungs: [ 1280, 1370, 1460, 1550, 1640, 1740 ] do |c|
  scale = c.pick(c.by_level([ [ 100, 1000 ], [ 1000, 10_000 ], [ 10_000, 25_000 ],
                              [ 25_000, 50_000 ], [ 50_000, 100_000 ], [ 200_000, 500_000 ] ]))
  map_cm = c.int(2..30)
  real_cm = map_cm * scale
  real_m = Rational(real_cm, 100)
  ask_km = real_m >= 1000

  c.q(
    text: "Картата е в мащаб 1 : #{scale}. Две места са на #{map_cm} см на картата. " \
          "Колко #{ask_km ? 'километра' : 'метра'} са в действителност?",
    answer: Num.ans(ask_km ? real_m / 1000 : real_m),
    explanation: Explain.build(
      idea: "Мащаб 1 : #{scale} значи, че 1 см на картата е #{scale} см в действителност.",
      steps: [
        "#{map_cm} · #{scale} = #{real_cm} см.",
        "#{real_cm} см = #{Num.ans(real_m)} м#{ask_km ? " = #{Num.ans(real_m / 1000)} км" : ''}."
      ],
      answer: "#{Num.ans(ask_km ? real_m / 1000 : real_m)} #{ask_km ? 'км' : 'м'}",
      check: "Обратно: #{Num.ans(real_m)} м = #{real_cm} см, а #{real_cm} : #{scale} = #{map_cm} см на картата.",
      watch: "1 м = 100 см и 1 км = 1000 м — превръщането е половината от задачата."
    )
  )
end

Authoring.family "similar.shadow", topic: "Подобни фигури", area: "geometry",
                 rungs: [ 1380, 1470, 1560, 1650, 1740, 1840 ] do |c|
  factor = c.int(c.by_level([ 2..4, 2..5, 2..6, 3..8, 3..10, 4..14 ]))
  pole = c.int(c.by_level([ 1..3, 1..4, 2..5, 2..6, 2..8, 3..10 ]))
  pole_shadow = c.int(1..4)
  tree_shadow = pole_shadow * factor
  tree = pole * factor
  raise Authoring::Duplicate if tree > 40

  c.q(
    text: "Стълб, висок #{pole} м, хвърля сянка #{pole_shadow} м. По същото време дърво хвърля сянка #{tree_shadow} м. " \
          "Колко метра е високо дървото?",
    answer: Num.ans(tree),
    explanation: Explain.build(
      idea: "Слънчевите лъчи падат под един и същ ъгъл, затова стълбът и дървото със сенките си образуват подобни триъгълници.",
      steps: [
        "Отношението на сенките: #{tree_shadow} : #{pole_shadow} = #{factor}.",
        "Височините са в същото отношение: #{pole} · #{factor} = #{tree} м."
      ],
      answer: "#{tree} м",
      check: "#{tree} : #{tree_shadow} = #{Num.dec(Rational(tree, tree_shadow), 2)} и #{pole} : #{pole_shadow} = #{Num.dec(Rational(pole, pole_shadow), 2)} — равни отношения.",
      watch: "Сравняват се отношенията, не разликите."
    )
  )
end

# ------------------------------------------------------------------ Окръжност ---

Authoring.family "circle.circumference", topic: "Окръжност", area: "geometry",
                 rungs: [ 1200, 1290, 1380, 1470, 1560, 1660 ] do |c|
  radius = c.int(c.by_level([ 1..5, 2..9, 3..15, 4..25, 6..50, 10..120 ]))
  circumference = 2 * PI * radius
  from_diameter = c.level >= 2 && c.coin

  c.q(
    text: from_diameter ? "Окръжност има диаметър #{2 * radius} см. Колко сантиметра е дължината ѝ? (Приеми π ≈ 3,14.)" :
                          "Окръжност има радиус #{radius} см. Колко сантиметра е дължината ѝ? (Приеми π ≈ 3,14.)",
    answer: Num.dec2(circumference),
    tolerance: "0.05",
    explanation: Explain.build(
      idea: "Дължината на окръжност е C = 2πr, а също C = πd — диаметърът е два радиуса.",
      steps: [
        from_diameter ? "d = #{2 * radius} см, значи C = 3,14 · #{2 * radius}." : "C = 2 · 3,14 · #{radius}.",
        "C = #{Num.dec2(circumference)} см."
      ],
      answer: "#{Num.dec2(circumference)} см",
      check: "Дължината е малко над 3 диаметъра: 3 · #{2 * radius} = #{6 * radius} см, а отговорът е #{Num.dec2(circumference)} см.",
      watch: "C = 2πr, но S = πr² — двете формули лесно се разменят."
    )
  )
end

Authoring.family "circle.area", topic: "Окръжност", area: "geometry",
                 rungs: [ 1280, 1370, 1460, 1550, 1640, 1740 ] do |c|
  radius = c.int(c.by_level([ 1..5, 2..8, 3..12, 4..20, 5..40, 8..90 ]))
  area = PI * radius * radius

  c.q(
    text: "Кръг има радиус #{radius} см. Колко квадратни сантиметра е лицето му? (Приеми π ≈ 3,14.)",
    answer: Num.dec2(area),
    tolerance: "0.05",
    explanation: Explain.build(
      idea: "Лицето на кръг е S = πr².",
      steps: [
        "r² = #{radius}² = #{radius * radius}.",
        "S = 3,14 · #{radius * radius} = #{Num.dec2(area)} см²."
      ],
      answer: "#{Num.dec2(area)} см²",
      check: "Кръгът се вписва в квадрат със страна #{2 * radius} см и лице #{4 * radius * radius} см² — лицето му е малко над три четвърти от това.",
      watch: "Първо се повдига радиусът на квадрат, после се умножава по π."
    )
  )
end

Authoring.family "circle.radius_from_circumference", topic: "Окръжност", area: "geometry",
                 rungs: [ 1350, 1440, 1530, 1620, 1710, 1810 ] do |c|
  radius = c.int(c.by_level([ 1..6, 2..10, 3..18, 4..30, 6..60, 10..150 ]))
  circumference = 2 * PI * radius

  c.q(
    text: "Дължината на окръжност е #{Num.dec2(circumference)} см. Колко сантиметра е радиусът ѝ? (Приеми π ≈ 3,14.)",
    answer: Num.ans(radius),
    explanation: Explain.build(
      idea: "От C = 2πr следва r = C : (2π).",
      steps: [
        "2π ≈ 2 · 3,14 = 6,28.",
        "#{Num.dec2(circumference)} : 6,28 = #{radius} см."
      ],
      answer: "#{radius} см",
      check: "2 · 3,14 · #{radius} = #{Num.dec2(circumference)} см.",
      watch: "Дели се на 6,28, не на 3,14 — иначе се получава диаметърът (#{2 * radius} см)."
    )
  )
end

Authoring.family "circle.sector", topic: "Окръжност", area: "geometry",
                 rungs: [ 1450, 1540, 1630, 1720, 1810, 1910 ] do |c|
  radius = c.int(c.by_level([ 2..6, 2..10, 3..14, 4..20, 5..35, 6..60 ]))
  angle = c.pick(c.by_level([ [ 90, 180 ], [ 90, 180, 270 ], [ 45, 90, 120 ], [ 60, 120, 240 ], [ 30, 150, 210 ], [ 36, 72, 216 ] ]))
  area = PI * radius * radius * Rational(angle, 360)

  c.q(
    text: "Кръгов сектор има радиус #{radius} см и централен ъгъл #{angle}°. " \
          "Колко квадратни сантиметра е лицето му? (Приеми π ≈ 3,14.)",
    answer: Num.dec2(area),
    tolerance: "0.05",
    explanation: Explain.build(
      idea: "Секторът е част от кръга, каквато част е ъгълът му от 360°.",
      steps: [
        "Цял кръг: S = 3,14 · #{radius}² = #{Num.dec2(PI * radius * radius)} см².",
        "Част: #{angle} : 360 = #{Num.frac(Rational(angle, 360))}.",
        "#{Num.dec2(PI * radius * radius)} · #{Num.frac(Rational(angle, 360))} = #{Num.dec2(area)} см²."
      ],
      answer: "#{Num.dec2(area)} см²",
      check: "При 360° би се получил целият кръг: #{Num.dec2(PI * radius * radius)} см².",
      watch: "Ъгълът се дели на 360, не на 180."
    )
  )
end

Authoring.family "circle.in_square", topic: "Окръжност", area: "geometry",
                 rungs: [ 1500, 1590, 1680, 1770, 1860, 1960 ] do |c|
  side = c.int(c.by_level([ 2..6, 2..10, 4..16, 6..24, 8..40, 10..80 ])) * 2
  radius = Rational(side, 2)
  area = (side * side) - (PI * radius * radius)

  c.q(
    text: "В квадрат със страна #{side} см е вписан кръг. Колко квадратни сантиметра е лицето извън кръга, но в квадрата? " \
          "(Приеми π ≈ 3,14.)",
    answer: Num.dec2(area),
    tolerance: "0.05",
    explanation: Explain.build(
      idea: "Търсената площ е разликата: квадрат минус вписания кръг. Диаметърът на кръга е равен на страната.",
      steps: [
        "Квадрат: #{side} · #{side} = #{side * side} см².",
        "Радиус: #{side} : 2 = #{Num.ans(radius)} см, значи кръгът е 3,14 · #{Num.ans(radius * radius)} = #{Num.dec2(PI * radius * radius)} см².",
        "#{side * side} − #{Num.dec2(PI * radius * radius)} = #{Num.dec2(area)} см²."
      ],
      answer: "#{Num.dec2(area)} см²",
      check: "Кръгът заема около 78,5% от квадрата, значи остатъкът е около 21,5% от #{side * side} ≈ #{Num.dec2(Rational(215, 1000) * side * side)} см².",
      watch: "Радиусът е половината от страната, не самата страна."
    )
  )
end
