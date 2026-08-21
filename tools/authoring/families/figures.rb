# Задачи с чертеж.
#
# Two rules hold across this file:
#
#   * The figure is drawn by tools/authoring/lib/figures.rb, written out as SVG
#     and rasterized to PNG (the app serves question images as Active Storage
#     attachments, and Active Storage will not serve SVG inline).
#   * Every number in the figure is also in the question text. The views render
#     question images with an empty alt attribute, so a student using a screen
#     reader would otherwise get an unanswerable question; and the importer
#     keys questions by their text, so identical stems would collide anyway.

FIG_PI = Rational(314, 100)

# ------------------------------------------------------------------ Ъгли ---

Authoring.family "fig.triangle_angles", topic: "Ъгли", area: "figures", variants: 4,
                 rungs: [ 900, 990, 1080, 1170, 1260 ] do |c|
  first = c.int(c.by_level([ 30..70, 25..80, 20..90, 15..110, 10..130 ]))
  second = c.int(20..(170 - first))
  third = 180 - first - second
  raise Authoring::Duplicate if third < 10

  c.q(
    text: "На чертежа два от ъглите на триъгълника ABC са #{first}° и #{second}°. Колко градуса е ъгълът при C?",
    answer: Num.ans(third),
    # Sides proportional to the sines of the opposite angles, so the drawing
    # shows the angles the question is talking about.
    figure: Figures.triangle(sides: [ Math.sin(first * Math::PI / 180), Math.sin(second * Math::PI / 180), Math.sin(third * Math::PI / 180) ],
                             angle_labels: { "A" => "#{first}°", "B" => "#{second}°", "C" => "?" }),
    explanation: Explain.build(
      idea: "Сборът на вътрешните ъгли в триъгълник е 180°.",
      steps: [
        "#{first}° + #{second}° = #{first + second}°.",
        "180° − #{first + second}° = #{third}°."
      ],
      answer: "#{third}°",
      check: "#{first} + #{second} + #{third} = 180.",
      watch: "Чертежът не е по мащаб — работи се с дадените числа, не с вида на ъглите."
    )
  )
end

Authoring.family "fig.isosceles_base_angles", topic: "Ъгли", area: "figures", variants: 4,
                 rungs: [ 1050, 1140, 1230, 1320, 1410 ] do |c|
  apex = c.int(c.by_level([ 20..100, 20..120, 16..140, 12..150, 10..160 ]))
  apex += 1 if apex.odd?
  base_angle = (180 - apex) / 2
  raise Authoring::Duplicate if base_angle < 10

  c.q(
    text: "Триъгълникът на чертежа е равнобедрен (AC = BC) и ъгълът при върха C е #{apex}°. " \
          "Колко градуса е ъгълът при A?",
    answer: Num.ans(base_angle),
    figure: Figures.triangle(sides: [ Math.sin(base_angle * Math::PI / 180), Math.sin(base_angle * Math::PI / 180), Math.sin(apex * Math::PI / 180) ],
                             ticks: { "CA" => 1, "BC" => 1 },
                             angle_labels: { "C" => "#{apex}°", "A" => "?" }),
    explanation: Explain.build(
      idea: "В равнобедрен триъгълник ъглите при основата са равни.",
      steps: [
        "За двата ъгъла при основата остават 180° − #{apex}° = #{180 - apex}°.",
        "#{180 - apex}° : 2 = #{base_angle}°."
      ],
      answer: "#{base_angle}°",
      check: "#{apex} + #{base_angle} + #{base_angle} = 180.",
      watch: "Равните чертички по страните показват кои страни са равни — оттам и равните ъгли."
    )
  )
end

Authoring.family "fig.vertical_angles", topic: "Ъгли", area: "figures", variants: 4,
                 rungs: [ 950, 1040, 1130, 1220, 1310 ] do |c|
  known = c.int(c.by_level([ 20..70, 15..80, 25..155, 18..162, 12..168 ]))
  raise Authoring::Duplicate if known == 90

  ask_vertical = c.coin
  answer = ask_vertical ? known : 180 - known

  c.q(
    text: "Две прави се пресичат, както е показано, и един от ъглите е #{known}°. " \
          "Колко градуса е #{ask_vertical ? 'противоположният му' : 'съседният му'} ъгъл (означен с ?)?",
    answer: Num.ans(answer),
    figure: Figures.angle_pair(kind: ask_vertical ? :vertical : :supplementary, known: known),
    explanation: Explain.build(
      idea: "Противоположните при върха ъгли са равни, а съседните се допълват до 180°.",
      steps: [
        ask_vertical ? "Означеният ъгъл е противоположен на #{known}°, значи е равен на него." :
                       "Означеният ъгъл заедно с #{known}° лежи на права: 180° − #{known}° = #{answer}°."
      ],
      answer: "#{answer}°",
      check: "Четирите ъгъла около пресечната точка са #{known}°, #{180 - known}°, #{known}°, #{180 - known}° — общо 360°.",
      watch: "Равни са противоположните ъгли, не съседните."
    )
  )
end

Authoring.family "fig.angles_around_point", topic: "Ъгли", area: "figures", variants: 4,
                 rungs: [ 1100, 1190, 1280, 1370, 1460 ] do |c|
  first = c.int(c.by_level([ 60..120, 50..140, 40..150, 30..160, 20..170 ]))
  second = c.int(40..(340 - first))
  third = 360 - first - second
  raise Authoring::Duplicate if third < 20 || second < 20

  c.q(
    text: "Три ъгъла с общ връх изпълват цялата равнина около точката. Два от тях са #{first}° и #{second}°. " \
          "Колко градуса е третият?",
    answer: Num.ans(third),
    figure: Figures.angle_pair(kind: :around_point, known: [ [ "#{first}°", first ], [ "#{second}°", second ], [ "?", third ] ]),
    explanation: Explain.build(
      idea: "Ъглите около една точка дават заедно 360°.",
      steps: [
        "#{first}° + #{second}° = #{first + second}°.",
        "360° − #{first + second}° = #{third}°."
      ],
      answer: "#{third}°",
      check: "#{first} + #{second} + #{third} = 360.",
      watch: "Тук пълният ъгъл е 360°, а не 180° — точката е обиколена изцяло."
    )
  )
end

Authoring.family "fig.parallel_transversal", topic: "Ъгли", area: "figures", variants: 4,
                 rungs: [ 1180, 1270, 1360, 1450, 1540 ] do |c|
  known = c.int(c.by_level([ 30..70, 25..80, 20..85, 25..155, 15..165 ]))
  raise Authoring::Duplicate if known == 90

  c.q(
    text: "Правите a и b са успоредни и са пресечени от трета права. Единият ъгъл е #{known}°. " \
          "Колко градуса е съответният му ъгъл при другата права (означен с ?)?",
    answer: Num.ans(known),
    figure: Figures.angle_pair(kind: :transversal, known: known),
    explanation: Explain.build(
      idea: "При успоредни прави съответните ъгли са равни.",
      steps: [
        "Двата ъгъла са от една и съща страна на трансверзалата и в еднакво положение спрямо успоредните прави.",
        "Значи означеният ъгъл също е #{known}°."
      ],
      answer: "#{known}°",
      check: "Ако беше съседен на съответния, щеше да е 180° − #{known}° = #{180 - known}°.",
      watch: "Равенството важи само защото правите a и b са успоредни."
    )
  )
end

Authoring.family "fig.angle_classify", topic: "Ъгли", area: "figures", variants: 4,
                 rungs: [ 860, 950, 1040, 1130, 1220 ] do |c|
  degrees = c.int(c.by_level([ 10..170, 10..170, 5..175, 5..175, 5..179 ]))
  raise Authoring::Duplicate if (degrees - 90).abs < 3

  kind = degrees < 90 ? "остър" : (degrees > 90 ? "тъп" : "прав")

  c.q(
    text: "Ъгълът на чертежа е #{degrees}°. Какъв е той?",
    options: c.options(kind, "остър", "тъп", "прав"),
    answer: kind,
    figure: Figures.angle_figure(degrees: degrees, label: "#{degrees}°"),
    explanation: Explain.build(
      idea: "Ъглите се именуват по големина: под 90° — остър, точно 90° — прав, между 90° и 180° — тъп.",
      steps: [
        "#{degrees}° #{degrees < 90 ? 'е по-малко от' : 'е по-голямо от'} 90°.",
        "Значи ъгълът е #{kind}."
      ],
      answer: kind,
      check: "Правият ъгъл (90°) е границата между острите и тъпите.",
      watch: "Видът се определя от градусите, не от дължината на раменете на чертежа."
    )
  )
end

# ---------------------------------------------------------- Периметър и площ ---

Authoring.family "fig.rectangle_perimeter", topic: "Периметър", area: "figures", variants: 4,
                 rungs: [ 800, 890, 980, 1070, 1160 ] do |c|
  a = c.int(c.by_level([ 2..9, 3..15, 5..30, 8..60, 12..150 ]))
  b = c.int(c.by_level([ 2..9, 3..15, 5..30, 8..60, 12..150 ]))
  raise Authoring::Duplicate if a == b

  perimeter = 2 * (a + b)

  c.q(
    text: "Правоъгълникът на чертежа има страни #{a} см и #{b} см. Колко сантиметра е периметърът му?",
    answer: Num.ans(perimeter),
    figure: Figures.rectangle(w_label: "#{a} см", h_label: "#{b} см", proportion: [ a.to_f / b, 0.4 ].max.clamp(0.4, 2.5)),
    explanation: Explain.build(
      idea: "Периметърът е обиколката: срещуположните страни на правоъгълника са равни.",
      steps: [
        "P = 2 · (#{a} + #{b}) = 2 · #{a + b}.",
        "P = #{perimeter} см."
      ],
      answer: "#{perimeter} см",
      check: "#{a} + #{b} + #{a} + #{b} = #{perimeter} см.",
      watch: "Лицето на същия правоъгълник е #{a * b} см² — друга величина."
    )
  )
end

Authoring.family "fig.rectangle_area", topic: "Площ", area: "figures", variants: 4,
                 rungs: [ 860, 950, 1040, 1130, 1220 ] do |c|
  a = c.int(c.by_level([ 2..9, 3..15, 4..25, 6..50, 10..120 ]))
  b = c.int(c.by_level([ 2..9, 3..15, 4..25, 6..50, 10..120 ]))
  area = a * b

  c.q(
    text: "Правоъгълникът на чертежа е #{a} см на #{b} см. Колко квадратни сантиметра е лицето му?",
    answer: Num.ans(area),
    figure: Figures.rectangle(w_label: "#{a} см", h_label: "#{b} см", proportion: [ a.to_f / b, 0.4 ].max.clamp(0.4, 2.5)),
    explanation: Explain.build(
      idea: "Лицето на правоъгълник е произведението на двете съседни страни.",
      steps: [ "S = #{a} · #{b} = #{area} см²." ],
      answer: "#{area} см²",
      check: "Фигурата се покрива с #{a} реда по #{b} квадратчета.",
      watch: "Периметърът е #{2 * (a + b)} см — не се бърка с лицето."
    )
  )
end

Authoring.family "fig.lshape_area", topic: "Площ", area: "figures", variants: 4,
                 rungs: [ 1150, 1240, 1330, 1420, 1510 ] do |c|
  full_width = c.int(c.by_level([ 6..12, 8..20, 10..30, 12..60, 16..120 ]))
  full_height = c.int(c.by_level([ 6..12, 8..20, 10..30, 12..60, 16..120 ]))
  # The notch takes between a third and two thirds of each side, so the drawing
  # stays a recognisable L and matches the numbers.
  cut_width = (full_width * c.int(35..65) / 100.0).round
  cut_height = (full_height * c.int(35..65) / 100.0).round
  raise Authoring::Duplicate if cut_width < 1 || cut_height < 1 || cut_width >= full_width || cut_height >= full_height

  area = (full_width * full_height) - (cut_width * cut_height)

  c.q(
    text: "Фигурата на чертежа е получена от правоъгълник #{full_width} м на #{full_height} м, " \
          "от който е изрязан правоъгълник #{cut_width} м на #{cut_height} м. " \
          "Колко квадратни метра е лицето на фигурата?",
    answer: Num.ans(area),
    figure: Figures.lshape(labels: { bottom: "#{full_width} м", right: "#{full_height - cut_height} м",
                                     inner_top: "#{cut_width} м", inner_side: "#{cut_height} м",
                                     top: "#{full_width - cut_width} м", left: "#{full_height} м" },
                           cut_x: ((full_width - cut_width).to_f / full_width),
                           cut_y: (cut_height.to_f / full_height)),
    explanation: Explain.build(
      idea: "Съставната фигура е цялото минус изрязаното.",
      steps: [
        "Цял правоъгълник: #{full_width} · #{full_height} = #{full_width * full_height} м².",
        "Изрязано: #{cut_width} · #{cut_height} = #{cut_width * cut_height} м².",
        "#{full_width * full_height} − #{cut_width * cut_height} = #{area} м²."
      ],
      answer: "#{area} м²",
      check: "Фигурата може да се раздели и на два правоъгълника — сборът на лицата им е пак #{area} м².",
      watch: "Изваждането е на лица, не на страни."
    )
  )
end

Authoring.family "fig.triangle_area", topic: "Площ", area: "figures", variants: 4,
                 rungs: [ 1020, 1110, 1200, 1290, 1380 ] do |c|
  base = c.int(c.by_level([ 2..10, 3..16, 5..30, 8..60, 12..140 ])) * 2
  height = c.int(c.by_level([ 2..10, 3..16, 5..30, 8..60, 12..140 ]))
  area = base * height / 2

  c.q(
    text: "Триъгълникът на чертежа има основа AB = #{base} см и височина към нея #{height} см. " \
          "Колко квадратни сантиметра е лицето му?",
    answer: Num.ans(area),
    # An isosceles triangle with exactly this base and height.
    figure: Figures.triangle(sides: [ Math.sqrt(((base / 2.0)**2) + (height**2)), Math.sqrt(((base / 2.0)**2) + (height**2)), base ],
                             side_labels: { "AB" => "#{base} см" }, height_to: "#{height} см"),
    explanation: Explain.build(
      idea: "Лицето на триъгълник е половината от произведението на основа и височина.",
      steps: [
        "#{base} · #{height} = #{base * height}.",
        "#{base * height} : 2 = #{area} см²."
      ],
      answer: "#{area} см²",
      check: "Два еднакви триъгълника образуват успоредник с лице #{base * height} см².",
      watch: "Височината е перпендикулярната отсечка от върха до основата, показана с пунктир."
    )
  )
end

Authoring.family "fig.parallelogram_area", topic: "Площ", area: "figures", variants: 4,
                 rungs: [ 1100, 1190, 1280, 1370, 1460 ] do |c|
  base = c.int(c.by_level([ 3..10, 4..16, 6..30, 8..60, 12..140 ]))
  height = c.int(c.by_level([ 2..9, 3..14, 4..25, 6..50, 10..120 ]))
  side = height + c.int(1..5)
  # A parallelogram flatter than this is unreadable once it is drawn to scale.
  raise Authoring::Duplicate if base > 3 * height

  area = base * height

  c.q(
    text: "Успоредникът на чертежа има основа AB = #{base} см, височина #{height} см и страна BC = #{side} см. " \
          "Колко квадратни сантиметра е лицето му?",
    answer: Num.ans(area),
    figure: Figures.quad(points: (Math.sqrt((side**2) - (height**2))).then do |offset|
                           [ [ 0, 0 ], [ base, 0 ], [ base + offset, height ], [ offset, height ] ]
                         end,
                         side_labels: { "AB" => "#{base} см", "BC" => "#{side} см" },
                         height_to: "#{height} см"),
    explanation: Explain.build(
      idea: "Лицето на успоредник е основа по височина към нея; наклонената страна не участва.",
      steps: [ "S = #{base} · #{height} = #{area} см²." ],
      answer: "#{area} см²",
      check: "Отрязваме триъгълника отляво и го долепяме отдясно — получава се правоъгълник #{base} на #{height}.",
      watch: "#{base} · #{side} = #{base * side} см² е клопката в задачата."
    )
  )
end

Authoring.family "fig.trapezoid_area", topic: "Площ", area: "figures", variants: 4,
                 rungs: [ 1200, 1290, 1380, 1470, 1560 ] do |c|
  a = c.int(c.by_level([ 4..12, 5..20, 6..35, 8..70, 12..160 ]))
  b = c.int(2...a)
  height = c.int(c.by_level([ 2..10, 3..16, 4..30, 6..60, 10..140 ])) * 2
  area = (a + b) * height / 2

  c.q(
    text: "Трапецът на чертежа има основи AB = #{a} см и CD = #{b} см и височина #{height} см. " \
          "Колко квадратни сантиметра е лицето му?",
    answer: Num.ans(area),
    figure: Figures.quad(points: [ [ 0, 0 ], [ a, 0 ], [ (a + b) / 2.0, height ], [ (a - b) / 2.0, height ] ],
                         side_labels: { "AB" => "#{a} см", "CD" => "#{b} см" }, height_to: "#{height} см"),
    explanation: Explain.build(
      idea: "Лицето на трапец е полусборът на основите по височината.",
      steps: [
        "(#{a} + #{b}) : 2 = #{Num.dec(Rational(a + b, 2), 1)}.",
        "#{Num.dec(Rational(a + b, 2), 1)} · #{height} = #{area} см²."
      ],
      answer: "#{area} см²",
      check: "Лицето е между #{b * height} см² и #{a * height} см² — площите на двата правоъгълника с основи #{b} и #{a}.",
      watch: "Основите се събират и се делят на 2, преди умножението по височината."
    )
  )
end

Authoring.family "fig.grid_area", topic: "Площ", area: "figures", variants: 4,
                 rungs: [ 780, 870, 960, 1050, 1140 ] do |c|
  cols = c.int(c.by_level([ 3..6, 4..8, 5..10, 6..12, 8..14 ]))
  rows = c.int(c.by_level([ 2..5, 3..7, 4..8, 5..10, 6..12 ]))
  shaded = c.int(2..(cols * rows - 1))

  c.q(
    text: "Мрежата на чертежа е #{cols} на #{rows} квадратчета, като #{shaded} от тях са оцветени. " \
          "Колко квадратчета НЕ са оцветени?",
    answer: Num.ans((cols * rows) - shaded),
    figure: Figures.grid(cols: cols, rows: rows, shaded: shaded),
    explanation: Explain.build(
      idea: "Първо колко квадратчета има всичко (правоъгълна мрежа — умножение), после изваждаме оцветените.",
      steps: [
        "Всички: #{cols} · #{rows} = #{cols * rows}.",
        "Неоцветени: #{cols * rows} − #{shaded} = #{(cols * rows) - shaded}."
      ],
      answer: "#{(cols * rows) - shaded} квадратчета",
      check: "#{shaded} + #{(cols * rows) - shaded} = #{cols * rows}.",
      watch: "Броят на всички квадратчета е произведение, не сбор на страните."
    )
  )
end

Authoring.family "fig.circle_circumference", topic: "Окръжност", area: "figures", variants: 4,
                 rungs: [ 1230, 1320, 1410, 1500, 1590 ] do |c|
  radius = c.int(c.by_level([ 1..6, 2..10, 3..18, 4..30, 6..60 ]))
  circumference = 2 * FIG_PI * radius

  c.q(
    text: "Окръжността на чертежа има радиус #{radius} см. Колко сантиметра е дължината ѝ? (Приеми π ≈ 3,14.)",
    answer: Num.dec2(circumference),
    tolerance: "0.05",
    figure: Figures.circle_figure(label: "r = #{radius} см"),
    explanation: Explain.build(
      idea: "Дължината на окръжност е C = 2πr.",
      steps: [
        "2 · 3,14 = 6,28.",
        "C = 6,28 · #{radius} = #{Num.dec2(circumference)} см."
      ],
      answer: "#{Num.dec2(circumference)} см",
      check: "Диаметърът е #{2 * radius} см, а дължината е малко над три диаметъра.",
      watch: "Лицето на същия кръг е #{Num.dec2(FIG_PI * radius * radius)} см² — различна формула."
    )
  )
end

Authoring.family "fig.circle_sector", topic: "Окръжност", area: "figures", variants: 4,
                 rungs: [ 1400, 1490, 1580, 1670, 1760 ] do |c|
  radius = c.int(c.by_level([ 2..6, 2..10, 3..14, 4..24, 5..40 ]))
  angle = c.pick(c.by_level([ [ 90, 180 ], [ 90, 180, 270 ], [ 45, 90, 120 ], [ 60, 120, 240 ], [ 30, 150, 210 ] ]))
  area = FIG_PI * radius * radius * Rational(angle, 360)

  c.q(
    text: "Оцветеният сектор на чертежа има радиус #{radius} см и централен ъгъл #{angle}°. " \
          "Колко квадратни сантиметра е лицето му? (Приеми π ≈ 3,14.)",
    answer: Num.dec2(area),
    tolerance: "0.05",
    figure: Figures.circle_figure(label: "r = #{radius} см", sector: angle),
    explanation: Explain.build(
      idea: "Секторът е #{angle}/360 част от кръга.",
      steps: [
        "Цял кръг: 3,14 · #{radius}² = #{Num.dec2(FIG_PI * radius * radius)} см².",
        "#{angle} : 360 = #{Num.frac(Rational(angle, 360))}.",
        "S = #{Num.dec2(FIG_PI * radius * radius)} · #{Num.frac(Rational(angle, 360))} = #{Num.dec2(area)} см²."
      ],
      answer: "#{Num.dec2(area)} см²",
      check: "При 360° би се получил целият кръг.",
      watch: "Частта се смята спрямо 360°, не спрямо 180°."
    )
  )
end

Authoring.family "fig.pythagoras", topic: "Питагорова теорема", area: "figures", variants: 4,
                 rungs: [ 1290, 1380, 1470, 1560, 1650 ] do |c|
  a, b, hyp = pythagorean_triple(c)
  find_leg = c.level >= 2 && c.coin

  if find_leg
    c.q(
      text: "В правоъгълния триъгълник на чертежа хипотенузата AB е #{hyp} см, а катетът BC е #{b} см. " \
            "Колко сантиметра е катетът CA?",
      answer: Num.ans(a),
      figure: Figures.triangle(sides: [ b, a, hyp ], right_at: "C",
                               side_labels: { "AB" => "#{hyp} см", "BC" => "#{b} см", "CA" => "?" }),
      explanation: Explain.build(
        idea: "Питагоровата теорема, решена за катет: a² = c² − b².",
        steps: [
          "#{hyp}² = #{hyp * hyp}, #{b}² = #{b * b}.",
          "#{hyp * hyp} − #{b * b} = #{a * a}.",
          "CA = √#{a * a} = #{a} см."
        ],
        answer: "#{a} см",
        check: "#{a}² + #{b}² = #{a * a} + #{b * b} = #{hyp * hyp}.",
        watch: "Изваждат се квадратите, не дължините (#{hyp} − #{b} = #{hyp - b} е грешен отговор)."
      )
    )
  else
    c.q(
      text: "В правоъгълния триъгълник на чертежа катетите са #{a} см и #{b} см. " \
            "Колко сантиметра е хипотенузата AB?",
      answer: Num.ans(hyp),
      figure: Figures.triangle(sides: [ b, a, hyp ], right_at: "C",
                               side_labels: { "CA" => "#{a} см", "BC" => "#{b} см", "AB" => "?" }),
      explanation: Explain.build(
        idea: "Питагоровата теорема: c² = a² + b².",
        steps: [
          "#{a}² + #{b}² = #{a * a} + #{b * b} = #{hyp * hyp}.",
          "AB = √#{hyp * hyp} = #{hyp} см."
        ],
        answer: "#{hyp} см",
        check: "Хипотенузата е най-дългата страна: #{hyp} > #{[ a, b ].max}.",
        watch: "Правият ъгъл е при C — срещу него лежи хипотенузата."
      )
    )
  end
end

Authoring.family "fig.similar_triangles", topic: "Подобни фигури", area: "figures", variants: 4,
                 rungs: [ 1350, 1440, 1530, 1620, 1710 ] do |c|
  scale = c.int(c.by_level([ 2..3, 2..4, 2..5, 3..6, 3..8 ]))
  small_base = c.int(c.by_level([ 2..8, 3..12, 4..16, 5..25, 6..40 ]))
  small_side = c.int(c.by_level([ 2..8, 3..12, 4..16, 5..25, 6..40 ]))
  big_base = small_base * scale
  big_side = small_side * scale

  c.q(
    text: "Триъгълниците на чертежа са подобни. Малкият има основа #{small_base} см и страна #{small_side} см, " \
          "а големият — основа #{big_base} см. Колко сантиметра е съответната страна на големия триъгълник?",
    answer: Num.ans(big_side),
    figure: (80.0 * small_side / small_base).clamp(40, 150.0 / [ scale, 2 ].min).then do |small_height|
              Figures.similar_triangles(small: [ 80, small_height ],
                                        large: [ 80 * [ scale, 2 ].min, small_height * [ scale, 2 ].min ],
                                        labels: { small: { base: "#{small_base} см", side: "#{small_side} см", name: "ABC" },
                                                  large: { base: "#{big_base} см", side: "?", name: "MNP" } })
            end,
    explanation: Explain.build(
      idea: "При подобни фигури всички съответни страни са в едно и също отношение.",
      steps: [
        "k = #{big_base} : #{small_base} = #{scale}.",
        "#{small_side} · #{scale} = #{big_side} см."
      ],
      answer: "#{big_side} см",
      check: "#{big_side} : #{small_side} = #{scale} — същият коефициент.",
      watch: "Коефициентът умножава страните; лицата растат #{scale * scale} пъти."
    )
  )
end

Authoring.family "fig.segments", topic: "Събиране и изваждане", area: "figures", variants: 4,
                 rungs: [ 820, 910, 1000, 1090, 1180 ] do |c|
  ab = c.int(c.by_level([ 2..10, 3..20, 5..40, 8..90, 12..250 ]))
  bc = c.int(c.by_level([ 2..10, 3..20, 5..40, 8..90, 12..250 ]))
  cd = c.int(c.by_level([ 2..10, 3..20, 5..40, 8..90, 12..250 ]))
  total = ab + bc + cd

  c.q(
    text: "На чертежа точките A, B, C и D лежат на една права, като AB = #{ab} см, BC = #{bc} см и CD = #{cd} см. " \
          "Колко сантиметра е отсечката AD?",
    answer: Num.ans(total),
    figure: Figures.segments(points: [ { from: "A", to: "B", size: ab, label: "#{ab} см" },
                                       { to: "C", size: bc, label: "#{bc} см" },
                                       { to: "D", size: cd, label: "#{cd} см" } ]),
    explanation: Explain.build(
      idea: "Когато точките лежат в този ред, дължините на съседните отсечки се събират.",
      steps: [
        "AD = AB + BC + CD.",
        "#{ab} + #{bc} + #{cd} = #{total} см."
      ],
      answer: "#{total} см",
      check: "AC = #{ab + bc} см и BD = #{bc + cd} см — и двете са по-къси от AD.",
      watch: "Редът на точките е важен — само тогава дължините се събират."
    )
  )
end

Authoring.family "fig.number_line_read", topic: "Числа и редици", area: "figures", variants: 4,
                 rungs: [ 700, 790, 880, 970, 1060 ] do |c|
  step = c.by_level([ 1, 2, 5, 10, 25 ])
  max = step * c.pick([ 10, 20, 40 ])
  value = c.int(1..((max / step) - 1)) * step

  c.q(
    text: "Числовата ос на чертежа е разграфена през #{step}. Кое число е отбелязано с точката?",
    answer: Num.ans(value),
    figure: Figures.number_line(min: 0, max: max, step: step, label_every: max / step > 10 ? 5 : 2, question_at: value),
    explanation: Explain.build(
      idea: "Броим деленията от нулата, като всяко е #{step}.",
      steps: [
        "Точката е на #{value / step}-то деление след 0.",
        "#{value / step} · #{step} = #{value}."
      ],
      answer: Num.ans(value),
      check: "Съседните означени числа са #{value - step} и #{value + step}.",
      watch: "Не всяко деление е с надпис — стойността се получава от стъпката."
    )
  )
end

Authoring.family "fig.fraction_strip_read", topic: "Дроби", area: "figures", variants: 4,
                 rungs: [ 800, 890, 980, 1070, 1160 ] do |c|
  segments = c.pick(c.by_level([ [ 2, 4 ], [ 3, 4, 5 ], [ 5, 6, 8 ], [ 6, 8, 10 ], [ 8, 10, 12 ] ]))
  shaded = c.int(1...segments)
  value = Rational(shaded, segments)

  c.q(
    text: "Лентата на чертежа е разделена на #{segments} равни части и #{shaded} от тях са оцветени. " \
          "Каква част от лентата е оцветена? Запиши като несъкратима дроб.",
    answer: Num.frac(value),
    figure: Figures.fraction_strip(segments: segments, shaded: shaded),
    explanation: Explain.build(
      idea: "Числителят е броят оцветени части, знаменателят — броят на всички части.",
      steps: [
        "#{shaded} оцветени от #{segments} части: #{shaded}/#{segments}.",
        Num.gcd(shaded, segments) > 1 ? "Съкращаваме с #{Num.gcd(shaded, segments)}: #{Num.frac(value)}." : "Дробта е несъкратима."
      ],
      answer: Num.frac(value),
      check: "Неоцветената част е #{Num.frac(1 - value)}, а двете дават 1.",
      watch: "Знаменателят брои всички части, включително оцветените."
    )
  )
end

Authoring.family "fig.grid_fraction", topic: "Дроби", area: "figures", variants: 4,
                 rungs: [ 950, 1040, 1130, 1220, 1310 ] do |c|
  cols = c.pick(c.by_level([ [ 4, 5 ], [ 4, 5, 6 ], [ 5, 6, 8 ], [ 6, 8, 10 ], [ 8, 10 ] ]))
  rows = c.pick([ 2, 3, 4, 5 ])
  total = cols * rows
  shaded = c.int(1...total)
  value = Rational(shaded, total)

  c.q(
    text: "Правоъгълникът на чертежа е разделен на #{total} еднакви квадратчета (#{cols} на #{rows}), " \
          "като #{shaded} са оцветени. Каква част е оцветена? Запиши като несъкратима дроб.",
    answer: Num.frac(value),
    figure: Figures.grid(cols: cols, rows: rows, shaded: shaded),
    explanation: Explain.build(
      idea: "Частта е брой оцветени квадратчета към общия им брой.",
      steps: [
        "Всички: #{cols} · #{rows} = #{total}.",
        "Оцветени: #{shaded}, значи #{shaded}/#{total} = #{Num.frac(value)}."
      ],
      answer: Num.frac(value),
      check: "В десетичен вид: #{Num.dec(value, 3)}.",
      watch: "Броят на всички квадратчета е произведението на страните."
    )
  )
end

Authoring.family "fig.pie_percent", topic: "Проценти", area: "figures", variants: 4,
                 rungs: [ 1080, 1170, 1260, 1350, 1440 ] do |c|
  first = c.pick(c.by_level([ [ 50, 25 ], [ 25, 40, 60 ], [ 15, 35, 45 ], [ 12, 28, 64 ], [ 18, 37, 56 ] ]))
  second = c.pick([ 20, 25, 30, 15 ])
  third = 100 - first - second
  raise Authoring::Duplicate if third < 5

  people = c.int(c.by_level([ 2..8, 3..12, 4..20, 5..40, 8..90 ])) * 100 / Num.gcd(first, 100)
  raise Authoring::Duplicate if people > 4000

  count = people * first / 100

  c.q(
    text: "Кръговата диаграма показва как #{people} ученици избират спорт: футбол #{first}%, баскетбол #{second}%, " \
          "тенис #{third}%. Колко ученици са избрали футбол?",
    answer: Num.ans(count),
    figure: Figures.pie_chart(parts: [ { value: first, label: "футбол #{first}%", inner: "#{first}%" },
                                       { value: second, label: "баскетбол #{second}%", inner: "#{second}%" },
                                       { value: third, label: "тенис #{third}%", inner: "#{third}%" } ]),
    explanation: Explain.build(
      idea: "Процентът от диаграмата се превръща в брой чрез умножение по общия брой.",
      steps: [
        "1% от #{people} е #{Num.dec(Rational(people, 100), 2)} ученици.",
        "#{first}% са #{people} · #{first} : 100 = #{count}."
      ],
      answer: "#{count} ученици",
      check: "Трите дяла дават #{first} + #{second} + #{third} = 100%.",
      watch: "Процентите на диаграмата се отнасят към целия клас, не един към друг."
    )
  )
end

Authoring.family "fig.bar_read", topic: "Статистика", area: "figures", variants: 4,
                 rungs: [ 900, 990, 1080, 1170, 1260 ] do |c|
  days = %w[Пон Вт Ср Чет Пет]
  count = c.by_level([ 4, 5, 5, 5, 5 ])
  labels = days.first(count)
  values = Array.new(count) { c.int(c.by_level([ 2..12, 3..20, 5..40, 8..90, 10..200 ])) }
  raise Authoring::Duplicate if values.uniq.size < count

  c.q(
    text: "Стълбовата диаграма показва броя прочетени страници по дни: " \
          "#{labels.zip(values).map { |day, value| "#{day} — #{value}" }.join(', ')}. " \
          "С колко страници най-многото надвишава най-малкото?",
    answer: Num.ans(values.max - values.min),
    figure: Figures.bar_chart(labels: labels, values: values, unit: "страници"),
    explanation: Explain.build(
      idea: "Разликата между най-високия и най-ниския стълб е разлика на двете стойности.",
      steps: [
        "Най-много: #{values.max} (#{labels[values.index(values.max)]}).",
        "Най-малко: #{values.min} (#{labels[values.index(values.min)]}).",
        "#{values.max} − #{values.min} = #{values.max - values.min}."
      ],
      answer: "#{values.max - values.min} страници",
      check: "Общо за седмицата: #{values.sum} страници.",
      watch: "Търси се разликата, не сборът."
    )
  )
end

Authoring.family "fig.bar_mean", topic: "Статистика", area: "figures", variants: 4,
                 rungs: [ 1150, 1240, 1330, 1420, 1510 ] do |c|
  labels = %w[A Б В Г Д].first(c.by_level([ 3, 4, 4, 5, 5 ]))
  mean = c.int(c.by_level([ 4..12, 5..20, 6..40, 8..80, 10..200 ]))
  values = Array.new(labels.size - 1) { mean + c.int(-mean / 2..mean / 2) }
  values << (mean * labels.size) - values.sum
  raise Authoring::Duplicate if values.last <= 0

  values = values.shuffle(random: c.rng)

  c.q(
    text: "Диаграмата показва по колко точки са събрали отборите: " \
          "#{labels.zip(values).map { |label, value| "#{label} — #{value}" }.join(', ')}. " \
          "Колко е средният брой точки на отбор?",
    answer: Num.ans(mean),
    figure: Figures.bar_chart(labels: labels, values: values, unit: "точки"),
    explanation: Explain.build(
      idea: "Средното аритметично е сборът на стълбовете, разделен на броя им.",
      steps: [
        "Сбор: #{values.join(' + ')} = #{values.sum}.",
        "#{values.sum} : #{labels.size} = #{mean}."
      ],
      answer: "#{mean} точки",
      check: "Средното е между най-малкия (#{values.min}) и най-големия (#{values.max}) стълб.",
      watch: "Дели се на броя отбори, не на най-големия резултат."
    )
  )
end

Authoring.family "fig.table_read", topic: "Статистика", area: "figures", variants: 4,
                 rungs: [ 1000, 1090, 1180, 1270, 1360 ] do |c|
  names = c.sample(Props::NAMES, c.by_level([ 3, 3, 4, 4, 5 ]))
  values = names.map { c.int(c.by_level([ 2..15, 3..25, 5..50, 8..120, 10..300 ])) }
  raise Authoring::Duplicate if values.uniq.size < names.size

  total = values.sum

  c.q(
    text: "Таблицата показва събраните точки: #{names.zip(values).map { |name, value| "#{name} — #{value}" }.join(', ')}. " \
          "Колко точки са събрани общо?",
    answer: Num.ans(total),
    figure: Figures.table(headers: [ "Ученик", "Точки" ], rows: names.zip(values).map { |name, value| [ name, value.to_s ] }),
    explanation: Explain.build(
      idea: "Общият брой е сборът на всички редове в колоната „Точки“.",
      steps: [
        "#{values.join(' + ')} = #{total}."
      ],
      answer: "#{total} точки",
      check: "Средно по #{Num.dec(Rational(total, names.size), 2)} точки на ученик.",
      watch: "Сборът се прави по колоната със стойности, а не по броя на редовете."
    )
  )
end

Authoring.family "fig.spinner_probability", topic: "Вероятност", area: "figures", variants: 4,
                 rungs: [ 1120, 1210, 1300, 1390, 1480 ] do |c|
  colors = [ "red", "blue", "green", "yellow" ]
  sectors_count = c.pick(c.by_level([ [ 4 ], [ 4, 6 ], [ 6, 8 ], [ 6, 8 ], [ 8, 10 ] ]))
  palette = Array.new(sectors_count) { c.pick(colors) }
  target = c.pick(palette.uniq)
  favourable = palette.count(target)
  raise Authoring::Duplicate if favourable == sectors_count

  probability = Rational(favourable, sectors_count)
  bg = { "red" => "червен", "blue" => "син", "green" => "зелен", "yellow" => "жълт" }

  c.q(
    text: "Въртележката на чертежа е разделена на #{sectors_count} еднакви сектора, " \
          "от които #{favourable == 1 ? "един е #{bg[target]}" : "#{favourable} са #{bg[target]}и"}. " \
          "Колко е вероятността стрелката да спре на #{bg[target]} сектор? Запиши като несъкратима дроб.",
    answer: Num.ans(probability),
    figure: Figures.spinner(sectors: palette.each_with_index.map { |color, index| { color: color, label: (index + 1).to_s } }),
    explanation: Explain.build(
      idea: "Секторите са еднакви, значи всички изходи са равновъзможни.",
      steps: [
        "Благоприятни: #{favourable} сектора.",
        "Всички: #{sectors_count}.",
        "P = #{favourable}/#{sectors_count} = #{Num.frac(probability)}."
      ],
      answer: Num.frac(probability),
      check: "Вероятността да НЕ спре на #{bg[target]} е #{Num.frac(1 - probability)}, а двете дават 1.",
      watch: "Равновъзможността идва от това, че секторите са с еднакъв ъгъл."
    )
  )
end

Authoring.family "fig.venn_counts", topic: "Логически задачи", area: "figures", variants: 4,
                 rungs: [ 1230, 1320, 1410, 1500, 1590 ] do |c|
  only_first = c.int(c.by_level([ 2..10, 3..18, 4..30, 6..60, 10..150 ]))
  both = c.int(c.by_level([ 1..8, 2..14, 3..25, 4..50, 8..120 ]))
  only_second = c.int(c.by_level([ 2..10, 3..18, 4..30, 6..60, 10..150 ]))
  outside = c.int(0..c.by_level([ 5, 10, 20, 40, 90 ]))
  total = only_first + both + only_second + outside

  c.q(
    text: "Диаграмата показва: само футбол — #{only_first} ученици, само плуване — #{only_second}, " \
          "и двата спорта — #{both}, никакъв спорт — #{outside}. Колко ученици има в класа?",
    answer: Num.ans(total),
    figure: Figures.venn(left: only_first.to_s, both: both.to_s, right: only_second.to_s,
                         labels: [ "Футбол", "Плуване" ], outside: "извън: #{outside}"),
    explanation: Explain.build(
      idea: "Четирите области на диаграмата не се застъпват, затова броевете им просто се събират.",
      steps: [
        "#{only_first} + #{both} + #{only_second} + #{outside} = #{total}."
      ],
      answer: "#{total} ученици",
      check: "Футбол играят #{only_first + both}, плуват #{only_second + both} — сборът им (#{only_first + only_second + (2 * both)}) брои двойно тези в средата.",
      watch: "Средната област се брои веднъж, макар да принадлежи и на двата кръга."
    )
  )
end

Authoring.family "fig.pattern_next", topic: "Числа и редици", area: "figures", variants: 4,
                 rungs: [ 850, 940, 1030, 1120, 1210 ] do |c|
  kind = c.by_level([ :bars, :bars, :squares, :bars, :squares ])
  if kind == :squares
    start = c.int(1..c.by_level([ 1, 2, 2, 3, 4 ]))
    terms = (0..2).map { |i| (start + i)**2 }
    nxt = (start + 3)**2
    idea = "Фигурите са квадрати: броят на квадратчетата е квадрат на страната."
    steps = [ "Страни: #{start}, #{start + 1}, #{start + 2} → квадратчета #{terms.join(', ')}.",
              "Следващата страна е #{start + 3}: #{start + 3}² = #{nxt}." ]
  else
    first = c.int(1..c.by_level([ 3, 5, 7, 9, 12 ]))
    step = c.int(1..c.by_level([ 2, 3, 3, 4, 5 ]))
    terms = (0..2).map { |i| first + (i * step) }
    nxt = first + (3 * step)
    idea = "Стълбчетата растат с постоянен брой квадратчета."
    steps = [ "Разлики: #{terms[1] - terms[0]} и #{terms[2] - terms[1]} — постоянна стъпка #{step}.",
              "#{terms[2]} + #{step} = #{nxt}." ]
  end

  c.q(
    text: "Чертежът показва първите три фигури от редица с #{terms.join(', ')} квадратчета. " \
          "Колко квадратчета има четвъртата фигура?",
    answer: Num.ans(nxt),
    figure: Figures.pattern(terms: terms, kind: kind),
    explanation: Explain.build(
      idea: idea,
      steps: steps,
      answer: "#{nxt} квадратчета",
      check: "Правилото трябва да пасва на всички дадени фигури, не само на последната.",
      watch: "Броим квадратчетата, не фигурите."
    )
  )
end

Authoring.family "fig.dot_array", topic: "Умножение и деление", area: "figures", variants: 4,
                 rungs: [ 700, 790, 880, 970, 1060 ] do |c|
  rows = c.int(c.by_level([ 2..4, 2..5, 3..6, 3..7, 4..8 ]))
  cols = c.int(c.by_level([ 2..5, 3..6, 3..8, 4..9, 5..10 ]))
  total = rows * cols

  c.q(
    text: "На чертежа кръгчетата са наредени в #{rows} реда по #{cols} в ред. Колко кръгчета има всичко?",
    answer: Num.ans(total),
    figure: Figures.dot_array(rows: rows, cols: cols),
    explanation: Explain.build(
      idea: "Правоъгълна подредба се брои с умножение.",
      steps: [ "#{rows} · #{cols} = #{total}." ],
      answer: "#{total} кръгчета",
      check: "#{total} : #{rows} = #{cols} — толкова са в един ред.",
      watch: "Броенето едно по едно също дава #{total}, но умножението е по-бързо."
    )
  )
end

Authoring.family "fig.clock_duration", topic: "Събиране и изваждане", area: "figures", variants: 4,
                 rungs: [ 880, 970, 1060, 1150, 1240 ] do |c|
  hour = c.int(1..12)
  minute = c.pick(c.by_level([ [ 0, 30 ], [ 0, 15, 30, 45 ], [ 0, 10, 20, 40, 50 ], [ 5, 25, 35, 55 ], [ 5, 10, 20, 25, 35, 40, 50, 55 ] ]))
  length = c.int(c.by_level([ 10..30, 15..45, 20..60, 25..90, 30..150 ]))
  total = (hour * 60) + minute + length
  end_hour = (total / 60) % 12
  end_hour = 12 if end_hour.zero?
  end_minute = total % 60

  answer = "#{end_hour}:#{format('%02d', end_minute)}"

  c.q(
    text: "Часовникът на чертежа показва #{hour}:#{format('%02d', minute)}. " \
          "Колко ще е часът след #{length} минути?",
    options: c.options(answer,
                       minute + length < 100 ? format("%d:%02d", hour, minute + length) : format("%d:%02d", end_hour, (end_minute + 20) % 60),
                       format("%d:%02d", (end_hour % 12) + 1, end_minute),
                       format("%d:%02d", end_hour, minute)),
    answer: answer,
    figure: Figures.clock(hours: hour, minutes: minute),
    explanation: Explain.build(
      idea: "Добавяме минутите; всеки пълен час е 60 минути.",
      steps: [
        "#{minute} + #{length} = #{minute + length} минути.",
        (minute + length) >= 60 ? "#{minute + length} минути = #{(minute + length) / 60} ч и #{(minute + length) % 60} мин." : "Минутите не стигат до нов час.",
        "Часът става #{end_hour}:#{format('%02d', end_minute)}."
      ],
      answer: "#{end_hour}:#{format('%02d', end_minute)}",
      check: "Обратно: от #{end_hour}:#{format('%02d', end_minute)} назад #{length} минути се връщаме на #{hour}:#{format('%02d', minute)}.",
      watch: "Часът има 60 минути — 1:70 не е валиден запис."
    )
  )
end

# ------------------------------------------------------------------ Тела ---

Authoring.family "fig.cuboid_volume", topic: "Обем", area: "figures", variants: 4,
                 rungs: [ 1050, 1140, 1230, 1320, 1410 ] do |c|
  a = c.int(c.by_level([ 2..6, 2..9, 3..12, 4..20, 6..40 ]))
  b = c.int(c.by_level([ 2..6, 2..9, 3..12, 4..20, 6..40 ]))
  h = c.int(c.by_level([ 2..6, 2..9, 3..12, 4..20, 6..40 ]))
  volume = a * b * h

  c.q(
    text: "Правоъгълният паралелепипед на чертежа има измерения #{a} см, #{b} см и #{h} см. " \
          "Колко кубични сантиметра е обемът му?",
    answer: Num.ans(volume),
    figure: Figures.cuboid(labels: { a: "#{a} см", b: "#{b} см", c: "#{h} см" }),
    explanation: Explain.build(
      idea: "Обемът е произведение на трите измерения.",
      steps: [
        "#{a} · #{b} = #{a * b} (лице на основата).",
        "#{a * b} · #{h} = #{volume} см³."
      ],
      answer: "#{volume} см³",
      check: "Повърхнината му е #{2 * ((a * b) + (b * h) + (a * h))} см² — друга величина.",
      watch: "Кубичните сантиметри мерят обем; квадратните — лице."
    )
  )
end

Authoring.family "fig.cube_surface", topic: "Обем", area: "figures", variants: 4,
                 rungs: [ 1120, 1210, 1300, 1390, 1480 ] do |c|
  edge = c.int(c.by_level([ 2..7, 3..10, 4..15, 5..25, 8..50 ]))
  surface = 6 * edge * edge
  volume = edge**3
  ask_volume = c.coin

  c.q(
    text: "Кубът на чертежа има ръб #{edge} см. Колко е #{ask_volume ? 'обемът му в кубични сантиметри' : 'повърхнината му в квадратни сантиметри'}?",
    answer: Num.ans(ask_volume ? volume : surface),
    figure: Figures.cuboid(labels: { a: "#{edge} см" }, cube: true),
    explanation: Explain.build(
      idea: ask_volume ? "Обемът на куб е a³." : "Повърхнината на куб е 6a² — шест еднакви квадратни стени.",
      steps: ask_volume ?
        [ "#{edge} · #{edge} · #{edge} = #{volume} см³." ] :
        [ "Една стена: #{edge}² = #{edge * edge} см².", "6 · #{edge * edge} = #{surface} см²." ],
      answer: ask_volume ? "#{volume} см³" : "#{surface} см²",
      check: "За този куб обемът е #{volume} см³, а повърхнината #{surface} см².",
      watch: "Обем и повърхнина се мерят в различни единици — внимавайте кое се пита."
    )
  )
end

Authoring.family "fig.cylinder_volume", topic: "Ротационни тела", area: "figures", variants: 4,
                 rungs: [ 1480, 1570, 1660, 1750, 1840 ] do |c|
  radius = c.int(c.by_level([ 1..4, 2..6, 2..9, 3..14, 4..25 ]))
  h = c.int(c.by_level([ 2..8, 3..12, 4..18, 5..30, 8..60 ]))
  volume = FIG_PI * radius * radius * h

  c.q(
    text: "Цилиндърът на чертежа има радиус #{radius} см и височина #{h} см. " \
          "Колко кубични сантиметра е обемът му? (Приеми π ≈ 3,14.)",
    answer: Num.dec2(volume),
    tolerance: "0.05",
    figure: Figures.cylinder(labels: { r: "#{radius} см", h: "#{h} см" }),
    explanation: Explain.build(
      idea: "V = πr²h — лице на кръглата основа по височина.",
      steps: [
        "Основа: 3,14 · #{radius}² = #{Num.dec2(FIG_PI * radius * radius)} см².",
        "V = #{Num.dec2(FIG_PI * radius * radius)} · #{h} = #{Num.dec2(volume)} см³."
      ],
      answer: "#{Num.dec2(volume)} см³",
      check: "Ако височината се удвои, обемът също се удвоява.",
      watch: "Само радиусът се повдига на квадрат."
    )
  )
end

Authoring.family "fig.cone_volume", topic: "Ротационни тела", area: "figures", variants: 4,
                 rungs: [ 1540, 1630, 1720, 1810, 1900 ] do |c|
  radius = c.int(c.by_level([ 1..4, 2..6, 2..9, 3..14, 4..25 ]))
  h = c.int(c.by_level([ 3..9, 3..12, 6..18, 6..30, 9..60 ]))
  raise Authoring::Duplicate unless (h % 3).zero?

  volume = FIG_PI * radius * radius * h / 3

  c.q(
    text: "Конусът на чертежа има радиус на основата #{radius} см и височина #{h} см. " \
          "Колко кубични сантиметра е обемът му? (Приеми π ≈ 3,14.)",
    answer: Num.dec2(volume),
    tolerance: "0.05",
    figure: Figures.cone(labels: { r: "#{radius} см", h: "#{h} см" }),
    explanation: Explain.build(
      idea: "Конусът е една трета от цилиндър със същата основа и височина.",
      steps: [
        "Цилиндър: 3,14 · #{radius}² · #{h} = #{Num.dec2(FIG_PI * radius * radius * h)} см³.",
        "Конус: #{Num.dec2(FIG_PI * radius * radius * h)} : 3 = #{Num.dec2(volume)} см³."
      ],
      answer: "#{Num.dec2(volume)} см³",
      check: "Три конуса пълнят цилиндъра.",
      watch: "Височината е перпендикулярна на основата, не е образуващата."
    )
  )
end

Authoring.family "fig.pyramid_volume", topic: "Призма и пирамида", area: "figures", variants: 4,
                 rungs: [ 1450, 1540, 1630, 1720, 1810 ] do |c|
  side = c.int(c.by_level([ 2..6, 3..9, 3..12, 4..20, 6..40 ]))
  h = c.int(c.by_level([ 3..9, 3..12, 6..18, 6..30, 9..60 ]))
  raise Authoring::Duplicate unless ((side * side * h) % 3).zero?

  volume = side * side * h / 3

  c.q(
    text: "Правилната четириъгълна пирамида на чертежа има основен ръб #{side} см и височина #{h} см. " \
          "Колко кубични сантиметра е обемът ѝ?",
    answer: Num.ans(volume),
    figure: Figures.solid(kind: :pyramid, labels: { a: "#{side} см", h: "#{h} см" }),
    explanation: Explain.build(
      idea: "V = S·h : 3, където S е лицето на основата.",
      steps: [
        "Основа: #{side} · #{side} = #{side * side} см².",
        "V = #{side * side} · #{h} : 3 = #{volume} см³."
      ],
      answer: "#{volume} см³",
      check: "Призма със същата основа и височина има #{side * side * h} см³ — три пъти повече.",
      watch: "Височината на пирамидата е от върха до центъра на основата, не апотемата."
    )
  )
end

Authoring.family "fig.prism_volume", topic: "Призма и пирамида", area: "figures", variants: 4,
                 rungs: [ 1400, 1490, 1580, 1670, 1760 ] do |c|
  base = c.int(c.by_level([ 2..8, 3..12, 4..18, 5..30, 8..60 ])) * 2
  triangle_height = c.int(c.by_level([ 2..8, 3..12, 4..18, 5..30, 8..60 ]))
  length = c.int(c.by_level([ 2..8, 3..12, 4..18, 5..30, 8..60 ]))
  base_area = base * triangle_height / 2
  volume = base_area * length

  c.q(
    text: "Правата призма на чертежа има за основа триъгълник с основа #{base} см и височина #{triangle_height} см, " \
          "а височината на призмата е #{length} см. Колко кубични сантиметра е обемът ѝ?",
    answer: Num.ans(volume),
    figure: Figures.solid(kind: :prism, labels: { a: "#{base} см", h: "#{length} см" }),
    explanation: Explain.build(
      idea: "V = S·h — лице на основата по височина на призмата.",
      steps: [
        "Основа: #{base} · #{triangle_height} : 2 = #{base_area} см².",
        "V = #{base_area} · #{length} = #{volume} см³."
      ],
      answer: "#{volume} см³",
      check: "Двойно по-висока призма би имала #{2 * volume} см³.",
      watch: "Височината на триъгълника (#{triangle_height} см) и височината на призмата (#{length} см) са различни числа."
    )
  )
end

Authoring.family "fig.net_surface", topic: "Призма и пирамида", area: "figures", variants: 4,
                 rungs: [ 1330, 1420, 1510, 1600, 1690 ] do |c|
  a = c.int(c.by_level([ 2..6, 2..9, 3..12, 4..20, 6..40 ]))
  b = c.int(c.by_level([ 2..6, 2..9, 3..12, 4..20, 6..40 ]))
  h = c.int(c.by_level([ 2..6, 2..9, 3..12, 4..20, 6..40 ]))
  surface = 2 * ((a * b) + (b * h) + (a * h))

  c.q(
    text: "Чертежът показва разгъвката на кутия с измерения #{a} см, #{b} см и #{h} см. " \
          "Колко квадратни сантиметра картон е нужен за нея?",
    answer: Num.ans(surface),
    figure: Figures.cuboid_net(labels: { a: "#{a} см", b: "#{b} см", h: "#{h} см", face: "дъно" }),
    explanation: Explain.build(
      idea: "Разгъвката показва всичките шест стени — повърхнината е сборът на лицата им.",
      steps: [
        "Две стени #{a} · #{b} = #{a * b}: заедно #{2 * a * b} см².",
        "Две стени #{b} · #{h} = #{b * h}: заедно #{2 * b * h} см².",
        "Две стени #{a} · #{h} = #{a * h}: заедно #{2 * a * h} см².",
        "S = #{2 * a * b} + #{2 * b * h} + #{2 * a * h} = #{surface} см²."
      ],
      answer: "#{surface} см²",
      check: "Обемът на кутията е #{a * b * h} см³ — не се бърка с картона.",
      watch: "Стените са шест и се повтарят по двойки."
    )
  )
end

# ------------------------------------------------------- Координатна система ---

Authoring.family "fig.plane_point", topic: "Линейна функция", area: "figures", variants: 4,
                 rungs: [ 1150, 1240, 1330, 1420, 1510 ] do |c|
  x = c.int(-5..5)
  y = c.int(-5..5)
  raise Authoring::Duplicate if x.zero? && y.zero?

  ask_sum = c.level >= 2 && c.coin

  c.q(
    text: "В координатната система на чертежа е отбелязана точка A. " \
          "Абсцисата ѝ е #{Num.bg(x)}, а ординатата — #{Num.bg(y)}. " \
          "Колко е #{ask_sum ? 'сборът на координатите ѝ' : 'произведението на координатите ѝ'}?",
    answer: Num.ans(ask_sum ? x + y : x * y),
    figure: Figures.plane(points: [ [ x, y, "A" ] ]),
    explanation: Explain.build(
      idea: "Абсцисата е първата координата (по оста x), ординатата — втората (по оста y).",
      steps: [
        "A(#{Num.bg(x)}; #{Num.bg(y)}).",
        ask_sum ? "#{Num.bg(x)} + #{Num.bg(y)} = #{Num.bg(x + y)}." : "#{Num.bg(x)} · #{Num.bg(y)} = #{Num.bg(x * y)}."
      ],
      answer: Num.bg(ask_sum ? x + y : x * y),
      check: "Точката е в #{x.positive? && y.positive? ? 'първи' : (x.negative? && y.positive? ? 'втори' : (x.negative? && y.negative? ? 'трети' : 'четвърти'))} квадрант.",
      watch: "Редът на координатите е (x; y) — първо надясно, после нагоре."
    )
  )
end

Authoring.family "fig.plane_slope", topic: "Линейна функция", area: "figures", variants: 4,
                 rungs: [ 1380, 1470, 1560, 1650, 1740 ] do |c|
  a = c.pick(c.by_level([ [ 1, 2 ], [ 1, 2, -1 ], [ 1, 2, 3, -2 ], [ 1, 2, 3, -3 ], [ 1, 2, 3, 4, -4 ] ]))
  b = c.int(-4..4)
  ask_zero = c.level >= 3 && c.coin && !a.zero? && ((-b) % a).zero?

  c.q(
    text: "Правата на чертежа има уравнение y = #{Num.linear(a, b)}. " \
          "#{ask_zero ? 'В коя точка пресича оста x (запиши абсцисата)?' : 'Колко е ординатата ѝ при x = ' + Num.bg(2) + '?'}",
    answer: Num.ans(ask_zero ? -b / a : (2 * a) + b),
    figure: Figures.plane(line: { a: a, b: b }),
    explanation: Explain.build(
      idea: ask_zero ? "Пресечната точка с оста x е там, където y = 0." : "Заместваме x в уравнението на правата.",
      steps: ask_zero ?
        [ "#{Num.linear(a, b)} = 0.", "#{Num.lead(a)} = #{Num.bg(-b)}, значи x = #{Num.bg(-b / a)}." ] :
        [ "y = #{Num.bg(a)} · 2 #{b.negative? ? Num::MINUS : '+'} #{b.abs} = #{Num.bg((2 * a) + b)}." ],
      answer: Num.bg(ask_zero ? -b / a : (2 * a) + b),
      check: "Правата пресича оста y в точката (0; #{Num.bg(b)}) — това е свободният член.",
      watch: "Ъгловият коефициент #{Num.bg(a)} показва с колко се качва y при стъпка 1 надясно."
    )
  )
end

Authoring.family "fig.parabola_vertex", topic: "Квадратна функция", area: "figures", variants: 4,
                 rungs: [ 1520, 1610, 1700, 1790, 1880 ] do |c|
  a = c.pick([ 1, 1, 2 ])
  vertex_x = c.int(-3..3)
  b = -2 * a * vertex_x
  cc = c.int(-3..4)
  vertex_y = (a * vertex_x * vertex_x) + (b * vertex_x) + cc
  raise Authoring::Duplicate if vertex_y.abs > 6

  ask_y = c.coin

  c.q(
    text: "Параболата на чертежа е графика на y = #{Num.quadratic(a, b, cc)}. " \
          "Колко е #{ask_y ? 'ординатата' : 'абсцисата'} на върха ѝ?",
    answer: Num.ans(ask_y ? vertex_y : vertex_x),
    figure: Figures.plane(x_range: (-5..5), y_range: (-6..8), parabola: { a: a, b: b, c: cc }),
    explanation: Explain.build(
      idea: "Абсцисата на върха е x₀ = −b : (2a), а ординатата се получава чрез заместване.",
      steps: [
        "x₀ = #{Num.bg(-b)} : #{2 * a} = #{Num.bg(vertex_x)}.",
        ask_y ? "y₀ = #{Num.bg(a)} · #{vertex_x * vertex_x} #{Num.term(b * vertex_x, '')} #{Num.term(cc, '')} = #{Num.bg(vertex_y)}." : nil
      ].compact,
      answer: Num.bg(ask_y ? vertex_y : vertex_x),
      check: "Графиката е симетрична спрямо вертикалната права x = #{Num.bg(vertex_x)}.",
      watch: "Клоните сочат нагоре (a = #{a} > 0), затова върхът е най-ниската точка."
    )
  )
end

Authoring.family "fig.tape_word", topic: "Текстови задачи", area: "figures", variants: 4,
                 rungs: [ 950, 1040, 1130, 1220, 1310 ] do |c|
  parts_first = c.int(c.by_level([ 1..2, 1..3, 2..4, 2..5, 3..6 ]))
  parts_second = c.int(c.by_level([ 1..2, 1..3, 2..4, 2..5, 3..6 ]))
  raise Authoring::Duplicate if parts_first == parts_second

  unit = c.int(c.by_level([ 2..8, 3..15, 4..30, 6..60, 10..150 ]))
  first = parts_first * unit
  second = parts_second * unit
  total = first + second

  c.q(
    text: "Лентовата схема показва, че две числа се отнасят като #{parts_first} : #{parts_second}, " \
          "а сборът им е #{total}. Колко е по-голямото число?",
    answer: Num.ans([ first, second ].max),
    figure: Figures.tape(parts: [ { size: parts_first, label: "#{parts_first} части" },
                                  { size: parts_second, label: "#{parts_second} части", fill: "#c7d2fe" } ],
                         total_label: "общо #{total}"),
    explanation: Explain.build(
      idea: "Схемата дели цялото на #{parts_first + parts_second} равни части.",
      steps: [
        "Една част: #{total} : #{parts_first + parts_second} = #{unit}.",
        "По-голямото число има #{[ parts_first, parts_second ].max} части: #{[ parts_first, parts_second ].max} · #{unit} = #{[ first, second ].max}."
      ],
      answer: Num.ans([ first, second ].max),
      check: "#{first} + #{second} = #{total} и #{first} : #{second} = #{Num.frac(parts_first, parts_second)}.",
      watch: "Частите са #{parts_first + parts_second}, не 2 — затова не се дели наполовина."
    )
  )
end
