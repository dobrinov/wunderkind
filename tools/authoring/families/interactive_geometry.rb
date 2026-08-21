# Интерактивни задачи по геометрия: ъгломер, координатна система, мрежа,
# двойни отговори (периметър и лице), избор и групиране.

ANGLE_STEP = 5

# ----------------------------------------------------------------- Ъгломер ---

Authoring.family "dial.set_angle", topic: "Ъгли", area: "interactive_geometry", variants: 5,
                 rungs: [ 820, 900, 990, 1080, 1170, 1260 ] do |c|
  degrees = c.int(c.by_level([ 6..12, 2..6, 13..18, 19..24, 25..30, 31..35 ])) * ANGLE_STEP
  raise Authoring::Duplicate if degrees > 175 || degrees < 10

  kind = degrees < 90 ? "остър" : degrees == 90 ? "прав" : "тъп"

  c.q(
    text: "Завърти лъча така, че ъгълът да стане #{degrees}°.",
    widget: WidgetKit.angle_dial(degrees: degrees, tolerance: 0, step: ANGLE_STEP),
    explanation: Explain.build(
      idea: "Ъгломерът е разграфен през #{ANGLE_STEP}°, а по-дългите чертички са през 30°.",
      steps: [
        "#{degrees} : 30 = #{degrees / 30} цели тридесетградусови стъпки и още #{degrees % 30}°.",
        "Значи лъчът минава #{degrees / 30} дълги чертички и още #{(degrees % 30) / ANGLE_STEP} малки."
      ],
      answer: "#{degrees}°",
      check: "#{degrees}° е #{kind} ъгъл — сравнете с правия ъгъл от 90°.",
      watch: "Ъгълът се брои от неподвижния лъч надясно, не от вертикалата."
    )
  )
end

Authoring.family "dial.complement", topic: "Ъгли", area: "interactive_geometry", variants: 6,
                 rungs: [ 1000, 1090, 1180, 1270, 1360, 1450 ] do |c|
  supplement = c.level >= 2 && c.coin
  total = supplement ? 180 : 90
  known = c.int(1..((total / ANGLE_STEP) - 1)) * ANGLE_STEP
  answer = total - known
  raise Authoring::Duplicate if answer < 10 || answer > 175

  c.q(
    text: "Един ъгъл е #{known}°. Завърти лъча до ъгъла, който го допълва до #{supplement ? '180° (изпънат ъгъл)' : '90° (прав ъгъл)'}.",
    widget: WidgetKit.angle_dial(degrees: answer, tolerance: 0, step: ANGLE_STEP),
    explanation: Explain.build(
      idea: supplement ? "Съседните ъгли по една права дават заедно 180°." : "Двата ъгъла заедно правят прав ъгъл, тоест 90°.",
      steps: [ "#{total} − #{known} = #{answer}°." ],
      answer: "#{answer}°",
      check: "#{known} + #{answer} = #{total}°.",
      watch: supplement ? "Изпънатият ъгъл е 180°, а не 360°." : "Правият ъгъл е 90° — допълването до 180° е друга задача."
    )
  )
end

Authoring.family "dial.triangle_third", topic: "Ъгли", area: "interactive_geometry", variants: 11,
                 rungs: [ 1080, 1170, 1260, 1350, 1440, 1530 ] do |c|
  first = c.int(3..30) * ANGLE_STEP
  second = c.int(3..30) * ANGLE_STEP
  third = 180 - first - second
  raise Authoring::Duplicate if third < 15 || third > 170 || (third % ANGLE_STEP) != 0

  c.q(
    text: "В триъгълник два от ъглите са #{first}° и #{second}°. Завърти лъча до третия ъгъл.",
    widget: WidgetKit.angle_dial(degrees: third, tolerance: 0, step: ANGLE_STEP),
    explanation: Explain.build(
      idea: "Сборът на ъглите в триъгълник е 180°.",
      steps: [
        "#{first} + #{second} = #{first + second}°.",
        "180 − #{first + second} = #{third}°."
      ],
      answer: "#{third}°",
      check: "#{first} + #{second} + #{third} = 180°.",
      watch: "Ако сборът на двата дадени ъгъла надхвърли 180°, триъгълник не съществува."
    )
  )
end

Authoring.family "dial.clock_angle", topic: "Ъгли", area: "interactive_geometry", variants: 3,
                 rungs: [ 1250, 1340, 1430, 1520, 1610, 1700 ] do |c|
  hour = c.int(1..12)
  minute = c.pick([ 0, 30 ])
  hour_angle = ((hour % 12) * 30) + (minute * 0.5)
  minute_angle = minute * 6
  diff = (hour_angle - minute_angle).abs
  diff = 360 - diff if diff > 180
  raise Authoring::Duplicate if (diff % ANGLE_STEP) != 0 || diff < 10 || diff > 175

  c.q(
    text: "Часовникът показва #{hour}:#{format('%02d', minute)}. Завърти лъча до по-малкия ъгъл между стрелките.",
    widget: WidgetKit.angle_dial(degrees: diff.to_i, tolerance: 0, step: ANGLE_STEP),
    explanation: Explain.build(
      idea: "Часовата стрелка изминава 30° на час (и 0,5° на минута), минутната — 6° на минута.",
      steps: [
        "Часова стрелка: #{Num.dec(Rational((hour_angle * 2).to_i, 2), 1)}° от 12 часа.",
        "Минутна стрелка: #{minute_angle}°.",
        "Разлика: #{diff.to_i}° (по-малкият от двата ъгъла)."
      ],
      answer: "#{diff.to_i}°",
      check: "Другият ъгъл между стрелките е #{360 - diff.to_i}°, а двата дават 360°.",
      watch: "В #{hour}:30 часовата стрелка стои по средата между две цифри, не на самата цифра."
    )
  )
end

Authoring.family "dial.exterior_angle", topic: "Ъгли", area: "interactive_geometry", variants: 11,
                 rungs: [ 1300, 1390, 1480, 1570, 1660, 1750 ] do |c|
  first = c.int(3..24) * ANGLE_STEP
  second = c.int(3..24) * ANGLE_STEP
  exterior = first + second
  raise Authoring::Duplicate if exterior > 175 || exterior < 20

  c.q(
    text: "Два от вътрешните ъгли на триъгълник са #{first}° и #{second}°. " \
          "Завърти лъча до външния ъгъл при третия връх.",
    widget: WidgetKit.angle_dial(degrees: exterior, tolerance: 0, step: ANGLE_STEP),
    explanation: Explain.build(
      idea: "Външният ъгъл е равен на сбора на двата несъседни вътрешни ъгъла.",
      steps: [
        "#{first} + #{second} = #{exterior}°.",
        "Проверка: вътрешният ъгъл при същия връх е 180 − #{exterior} = #{180 - exterior}°."
      ],
      answer: "#{exterior}°",
      check: "#{first} + #{second} + #{180 - exterior} = 180°.",
      watch: "Външният ъгъл е извън триъгълника — той допълва вътрешния до 180°."
    )
  )
end

Authoring.family "dial.polygon_interior", topic: "Ъгли", area: "interactive_geometry", variants: 11,
                 rungs: [ 1350, 1440, 1530, 1620, 1710, 1800 ] do |c|
  sides = c.pick(c.by_level([ [ 3, 4, 5 ], [ 5, 6, 8 ], [ 9, 10, 12 ], [ 15, 18, 20 ], [ 24, 30, 36 ], [ 40, 45, 60, 72 ] ]))
  interior = (sides - 2) * 180 / sides
  raise Authoring::Duplicate if ((sides - 2) * 180) % sides != 0 || interior > 178

  c.q(
    text: "Завърти лъча до големината на един вътрешен ъгъл на правилен #{sides}-ъгълник.",
    widget: WidgetKit.angle_dial(degrees: interior, tolerance: 2, step: 1),
    explanation: Explain.build(
      idea: "Сборът на вътрешните ъгли е (n − 2) · 180°, а при правилен многоъгълник всички са равни. Ъгломерът тук е през 1°.",
      steps: [
        "Сбор: (#{sides} − 2) · 180 = #{(sides - 2) * 180}°.",
        "Един ъгъл: #{(sides - 2) * 180} : #{sides} = #{interior}°."
      ],
      answer: "#{interior}°",
      check: "Външният ъгъл е 360 : #{sides} = #{360 / sides}°, а #{interior} + #{360 / sides} = 180°.",
      watch: "Колкото повече страни, толкова по-голям вътрешен ъгъл — но никога 180°."
    )
  )
end

Authoring.family "dial.turn_direction", topic: "Ъгли", area: "interactive_geometry", variants: 11,
                 rungs: [ 1150, 1240, 1330, 1420, 1510, 1600 ] do |c|
  turns = c.int(2..4)
  angles = Array.new(turns) { c.int(2..14) * ANGLE_STEP }
  total = angles.sum
  raise Authoring::Duplicate if total > 175 || total < 20

  c.q(
    text: "Робот се завърта последователно на #{angles.join('°, ')}° в една и съща посока. " \
          "Завърти лъча до общия ъгъл на завъртане.",
    widget: WidgetKit.angle_dial(degrees: total, tolerance: 0, step: ANGLE_STEP),
    explanation: Explain.build(
      idea: "Завъртания в една и съща посока се събират.",
      steps: [ "#{angles.join(' + ')} = #{total}°." ],
      answer: "#{total}°",
      check: "До пълен обрат (360°) остават още #{360 - total}°.",
      watch: "Ако едно от завъртанията беше в обратна посока, то щеше да се извади, а не да се събере."
    )
  )
end

# ------------------------------------------------- Координатна система ---

Authoring.family "plot.point_pair", topic: "Линейна функция", area: "interactive_geometry", variants: 11,
                 rungs: [ 950, 1040, 1130, 1220, 1310, 1400 ] do |c|
  points = c.sample((-5..5).to_a.product((-5..5).to_a), 2)
  raise Authoring::Duplicate if points.any? { |x, y| x.zero? && y.zero? }

  c.q(
    text: "Постави точките A(#{Num.bg(points[0][0])}; #{Num.bg(points[0][1])}) и " \
          "B(#{Num.bg(points[1][0])}; #{Num.bg(points[1][1])}) в координатната система.",
    widget: WidgetKit.plot(points: points),
    explanation: Explain.build(
      idea: "Първата координата се брои по хоризонталната ос, втората — по вертикалната.",
      steps: points.map do |x, y|
        "(#{Num.bg(x)}; #{Num.bg(y)}): #{x.abs} наляво-надясно (#{x.negative? ? 'наляво' : 'надясно'}), после #{y.abs} #{y.negative? ? 'надолу' : 'нагоре'}."
      end,
      answer: points.map { |x, y| "(#{Num.bg(x)}; #{Num.bg(y)})" }.join(" и "),
      check: "Точка с отрицателна абсциса стои вляво от оста y.",
      watch: "(#{Num.bg(points[0][0])}; #{Num.bg(points[0][1])}) и (#{Num.bg(points[0][1])}; #{Num.bg(points[0][0])}) са различни точки, освен ако координатите не съвпадат."
    )
  )
end

Authoring.family "plot.reflect_point", topic: "Подобни фигури", area: "interactive_geometry", variants: 11,
                 rungs: [ 1200, 1290, 1380, 1470, 1560, 1650 ] do |c|
  x = c.int(-5..5)
  y = c.int(-5..5)
  raise Authoring::Duplicate if x.zero? || y.zero?

  axis = c.by_level([ :x, :x, :y, :y, :origin, :origin ])
  image = case axis
  when :x then [ x, -y ]
  when :y then [ -x, y ]
  else [ -x, -y ]
  end
  name = { x: "абсцисната ос (оста x)", y: "ординатната ос (оста y)", origin: "началото на координатната система" }[axis]

  c.q(
    text: "Точката A(#{Num.bg(x)}; #{Num.bg(y)}) се симетрира спрямо #{name}. Постави образа ѝ.",
    widget: WidgetKit.plot(points: [ image ], fixed: [ [ x, y, "A" ] ]),
    explanation: Explain.build(
      idea: axis == :origin ? "Симетрия спрямо началото сменя знака и на двете координати." :
            "Симетрия спрямо ос сменя знака само на координатата, перпендикулярна на оста.",
      steps: [
        axis == :x ? "Абсцисата остава #{Num.bg(x)}, ординатата сменя знака: #{Num.bg(y)} → #{Num.bg(-y)}." :
        axis == :y ? "Ординатата остава #{Num.bg(y)}, абсцисата сменя знака: #{Num.bg(x)} → #{Num.bg(-x)}." :
                     "И двете сменят знака: (#{Num.bg(x)}; #{Num.bg(y)}) → (#{Num.bg(-x)}; #{Num.bg(-y)}).",
        "Образът е (#{Num.bg(image[0])}; #{Num.bg(image[1])})."
      ],
      answer: "(#{Num.bg(image[0])}; #{Num.bg(image[1])})",
      check: "Оригиналът и образът са на еднакво разстояние от оста на симетрия.",
      watch: "Симетрия спрямо оста x не променя абсцисата — сменя се това, което е „нагоре-надолу“."
    )
  )
end

Authoring.family "plot.translate_point", topic: "Подобни фигури", area: "interactive_geometry", variants: 11,
                 rungs: [ 1150, 1240, 1330, 1420, 1510, 1600 ] do |c|
  x = c.int(-4..4)
  y = c.int(-4..4)
  dx = c.int(-4..4)
  dy = c.int(-4..4)
  raise Authoring::Duplicate if dx.zero? && dy.zero?
  raise Authoring::Duplicate unless (x + dx).between?(-5, 5) && (y + dy).between?(-5, 5)

  c.q(
    text: "Точката A(#{Num.bg(x)}; #{Num.bg(y)}) се премества с #{Num.bg(dx)} по хоризонтала и #{Num.bg(dy)} по вертикала. " \
          "Постави новото ѝ място.",
    widget: WidgetKit.plot(points: [ [ x + dx, y + dy ] ], fixed: [ [ x, y, "A" ] ]),
    explanation: Explain.build(
      idea: "Транслацията добавя преместването към всяка координата поотделно.",
      steps: [
        "Абсциса: #{Num.bg(x)} + #{Num.bg(dx)} = #{Num.bg(x + dx)}.",
        "Ордината: #{Num.bg(y)} + #{Num.bg(dy)} = #{Num.bg(y + dy)}."
      ],
      answer: "(#{Num.bg(x + dx)}; #{Num.bg(y + dy)})",
      check: "Разстоянието и посоката са същите за всяка точка при транслация.",
      watch: "Отрицателното преместване е наляво или надолу."
    )
  )
end

Authoring.family "plot.rectangle_vertex", topic: "Площ", area: "interactive_geometry", variants: 11,
                 rungs: [ 1250, 1340, 1430, 1520, 1610, 1700 ] do |c|
  x1 = c.int(-4..2)
  y1 = c.int(-4..2)
  width = c.int(2..5)
  height = c.int(2..5)
  raise Authoring::Duplicate unless (x1 + width).between?(-5, 5) && (y1 + height).between?(-5, 5)

  c.q(
    text: "Три от върховете на правоъгълник са (#{Num.bg(x1)}; #{Num.bg(y1)}), (#{Num.bg(x1 + width)}; #{Num.bg(y1)}) " \
          "и (#{Num.bg(x1)}; #{Num.bg(y1 + height)}). Постави четвъртия връх.",
    widget: WidgetKit.plot(points: [ [ x1 + width, y1 + height ] ],
                           fixed: [ [ x1, y1, "A" ], [ x1 + width, y1, "B" ], [ x1, y1 + height, "D" ] ]),
    explanation: Explain.build(
      idea: "Срещуположните страни на правоъгълника са равни и успоредни, затова четвъртият връх се получава чрез същите премествания.",
      steps: [
        "От A до B се минава #{width} надясно; същото важи от D до търсения връх.",
        "От A до D се минава #{height} нагоре; същото важи от B нататък.",
        "Върхът е (#{Num.bg(x1 + width)}; #{Num.bg(y1 + height)})."
      ],
      answer: "(#{Num.bg(x1 + width)}; #{Num.bg(y1 + height)})",
      check: "Страните излизат #{width} и #{height}, а лицето е #{width * height} квадратни единици.",
      watch: "Четвъртият връх е срещу първия, не до него."
    )
  )
end

Authoring.family "plot.midpoint", topic: "Подобни фигури", area: "interactive_geometry", variants: 11,
                 rungs: [ 1300, 1390, 1480, 1570, 1660, 1750 ] do |c|
  x1 = c.int(-5..5)
  y1 = c.int(-5..5)
  dx = c.int(1..5) * 2 * c.pick([ 1, -1 ])
  dy = c.int(1..5) * 2 * c.pick([ 1, -1 ])
  x2 = x1 + dx
  y2 = y1 + dy
  raise Authoring::Duplicate unless x2.between?(-5, 5) && y2.between?(-5, 5)

  c.q(
    text: "Постави средата на отсечката с краища A(#{Num.bg(x1)}; #{Num.bg(y1)}) и B(#{Num.bg(x2)}; #{Num.bg(y2)}).",
    widget: WidgetKit.plot(points: [ [ (x1 + x2) / 2, (y1 + y2) / 2 ] ],
                           fixed: [ [ x1, y1, "A" ], [ x2, y2, "B" ] ]),
    explanation: Explain.build(
      idea: "Координатите на средата са средните аритметични на съответните координати.",
      steps: [
        "x = (#{Num.bg(x1)} + #{Num.bg(x2)}) : 2 = #{Num.bg((x1 + x2) / 2)}.",
        "y = (#{Num.bg(y1)} + #{Num.bg(y2)}) : 2 = #{Num.bg((y1 + y2) / 2)}."
      ],
      answer: "(#{Num.bg((x1 + x2) / 2)}; #{Num.bg((y1 + y2) / 2)})",
      check: "Средата е на еднакво разстояние от A и от B.",
      watch: "Средата се смята за всяка координата поотделно, не само за едната."
    )
  )
end

# ------------------------------------------------------------------ Мрежа ---

Authoring.family "shade.rectangle_area", topic: "Площ", area: "interactive_geometry", variants: 11,
                 rungs: [ 880, 970, 1060, 1150, 1240, 1330 ] do |c|
  rows = c.int(c.by_level([ 3..5, 3..6, 4..7, 4..8, 5..9, 6..10 ]))
  cols = c.int(c.by_level([ 4..6, 4..8, 5..9, 6..10, 7..11, 8..12 ]))
  area = c.int(2..(rows * cols - 1))
  raise Authoring::Duplicate if area > (rows * cols) / 2 + 4

  c.q(
    text: "Мрежата е #{rows} на #{cols} квадратчета. Оцвети фигура с лице точно #{area} квадратчета.",
    widget: WidgetKit.grid_shade(rows: rows, cols: cols, count: area),
    explanation: Explain.build(
      idea: "Лицето върху мрежа се брои в квадратчета — формата няма значение, броят има.",
      steps: [
        "Цялата мрежа е #{rows} · #{cols} = #{rows * cols} квадратчета.",
        "Оцветяваме #{area} от тях — например правоъгълник #{Num.divisors(area).find { |d| d <= rows } || 1} на #{area / (Num.divisors(area).find { |d| d <= rows } || 1)}."
      ],
      answer: "#{area} квадратчета",
      check: "Неоцветени остават #{(rows * cols) - area} квадратчета.",
      watch: "Едно и също лице може да има различна форма — и различен периметър."
    )
  )
end

Authoring.family "shade.symmetry", topic: "Подобни фигури", area: "interactive_geometry", variants: 11,
                 rungs: [ 1050, 1140, 1230, 1320, 1410, 1500 ] do |c|
  rows = c.int(c.by_level([ 3..4, 3..5, 4..5, 4..6, 5..6, 5..7 ]))
  half = c.int(c.by_level([ 2..3, 2..3, 3..4, 3..4, 4..5, 4..5 ]))
  cols = half * 2
  given = []
  cells = []
  rows.times do |r|
    half.times do |cc|
      next unless c.coin

      given << "#{r},#{cc}"
      cells << "#{r},#{cols - 1 - cc}"
    end
  end
  raise Authoring::Duplicate if given.size < 3 || given.size > (rows * half) - 1

  c.q(
    text: "Лявата половина на фигурата е оцветена. Довърши я така, че мрежата #{rows} на #{cols} " \
          "да е симетрична спрямо вертикалната си среда (#{given.size} квадратчета).",
    widget: WidgetKit.grid_shade(rows: rows, cols: cols, given: given, cells: cells),
    explanation: Explain.build(
      idea: "При огледална симетрия всяко оцветено квадратче има чифт на същия ред, на същото разстояние от средата.",
      steps: [
        "Средата минава между колони #{half} и #{half + 1}.",
        "Квадратче в колона k отляво се пресъздава в колона #{cols + 1} − k отдясно.",
        "Оцветени са #{given.size} квадратчета отляво, значи и отдясно трябва да са #{given.size}."
      ],
      answer: "#{cells.size} квадратчета вдясно",
      check: "Сгъната по средата, фигурата трябва да съвпадне сама със себе си.",
      watch: "Редът не се променя при огледалото — мести се само колоната."
    )
  )
end

Authoring.family "shade.perimeter_shape", topic: "Периметър", area: "interactive_geometry", variants: 11,
                 rungs: [ 1150, 1240, 1330, 1420, 1510, 1600 ] do |c|
  rows = c.int(c.by_level([ 4..5, 4..6, 5..7, 5..8, 6..9, 6..10 ]))
  cols = c.int(c.by_level([ 4..6, 5..7, 5..8, 6..9, 7..10, 8..12 ]))
  width = c.int(2..[ cols - 1, 5 ].min)
  height = c.int(2..[ rows - 1, 5 ].min)
  raise Authoring::Duplicate if width == height

  perimeter = 2 * (width + height)

  c.q(
    text: "Оцвети правоъгълник със страни #{width} и #{height} квадратчета (периметър #{perimeter} единици) " \
          "в мрежата #{rows} на #{cols}.",
    widget: WidgetKit.grid_shade(rows: rows, cols: cols, count: width * height),
    explanation: Explain.build(
      idea: "Правоъгълник #{width} на #{height} съдържа #{width} · #{height} квадратчета, а обиколката му е 2 · (#{width} + #{height}).",
      steps: [
        "Лице: #{width} · #{height} = #{width * height} квадратчета.",
        "Периметър: 2 · (#{width} + #{height}) = #{perimeter} единици."
      ],
      answer: "#{width * height} квадратчета",
      check: "Правоъгълник #{height} на #{width} има същото лице и същия периметър.",
      watch: "Периметърът се мери по страните, а лицето — по вътрешността; те не растат заедно."
    )
  )
end

Authoring.family "shade.fraction_of_shape", topic: "Дроби", area: "interactive_geometry", variants: 11,
                 rungs: [ 1000, 1090, 1180, 1270, 1360, 1450 ] do |c|
  rows = c.pick([ 2, 3, 4 ])
  cols = c.pick(c.by_level([ [ 4, 6 ], [ 4, 6, 8 ], [ 6, 8 ], [ 6, 8, 9 ], [ 8, 9, 10 ], [ 8, 10, 12 ] ]))
  total = rows * cols
  given_count = c.int(1..(total / 4))
  given = c.sample((0...total).to_a, given_count).map { |index| "#{index / cols},#{index % cols}" }
  denominator = c.pick(Num.divisors(total).select { |d| d.between?(2, 8) })
  numerator = c.int(1...denominator)
  target = total * numerator / denominator
  raise Authoring::Duplicate if target <= given_count || (target - given_count) > (total - given_count)

  c.q(
    text: "В мрежата #{rows} на #{cols} вече са оцветени #{given_count} квадратчета. " \
          "Оцвети още толкова, че общо да станат #{Num.frac(numerator, denominator)} от мрежата.",
    widget: WidgetKit.grid_shade(rows: rows, cols: cols, given: given, count: target - given_count),
    explanation: Explain.build(
      idea: "Първо колко квадратчета прави исканата дроб, после колко липсват до тях.",
      steps: [
        "Всички: #{rows} · #{cols} = #{total}.",
        "#{Num.frac(numerator, denominator)} от #{total} = #{target} квадратчета.",
        "Вече има #{given_count}, значи трябват още #{target - given_count}."
      ],
      answer: "още #{target - given_count} квадратчета",
      check: "#{given_count} + #{target - given_count} = #{target}, а #{target}/#{total} = #{Num.frac(numerator, denominator)}.",
      watch: "Даденото се брои — не се оцветява цялата дроб отначало."
    )
  )
end

# ------------------------------------------------------------- Два отговора ---

Authoring.family "blank.rect_perimeter_area", topic: "Площ", area: "interactive_geometry", variants: 11,
                 rungs: [ 900, 990, 1080, 1170, 1260, 1350 ] do |c|
  a = c.int(c.by_level([ 2..9, 3..15, 4..25, 6..50, 10..120, 15..300 ]))
  b = c.int(c.by_level([ 2..9, 3..15, 4..25, 6..50, 10..120, 15..300 ]))

  c.q(
    text: "Правоъгълник има страни #{a} см и #{b} см. Попълни периметъра и лицето му.",
    widget: WidgetKit.blanks([ [ "p", "периметър", 2 * (a + b), "см" ], [ "s", "лице", a * b, "см²" ] ]),
    explanation: Explain.build(
      idea: "Периметърът е обиколката, лицето — колко квадратчета покриват фигурата.",
      steps: [
        "P = 2 · (#{a} + #{b}) = #{2 * (a + b)} см.",
        "S = #{a} · #{b} = #{a * b} см²."
      ],
      answer: "P = #{2 * (a + b)} см, S = #{a * b} см²",
      check: "Мерните единици са различни: сантиметри за обиколката, квадратни сантиметри за площта.",
      watch: "Двете величини не се променят еднакво — правоъгълник #{a + 1} на #{b - 1} има друг периметър и друго лице."
    )
  )
end

Authoring.family "blank.triangle_angles_three", topic: "Ъгли", area: "interactive_geometry", variants: 11,
                 rungs: [ 1200, 1290, 1380, 1470, 1560, 1650 ] do |c|
  ratio = c.sample((1..12).to_a, 3).sort
  raise Authoring::Duplicate unless (180 % ratio.sum).zero?

  unit = 180 / ratio.sum
  raise Authoring::Duplicate if unit < 2

  angles = ratio.map { |part| part * unit }

  c.q(
    text: "Ъглите на триъгълник се отнасят като #{ratio.join(' : ')}. Попълни трите ъгъла от най-малкия към най-големия.",
    widget: WidgetKit.blanks(angles.each_with_index.map { |angle, i| [ "a#{i}", "ъгъл #{i + 1}", angle, "°" ] }),
    explanation: Explain.build(
      idea: "Отношението дели 180° на #{ratio.sum} равни части.",
      steps: [
        "Части общо: #{ratio.join(' + ')} = #{ratio.sum}.",
        "Една част: 180 : #{ratio.sum} = #{unit}°.",
        "Ъглите са #{ratio.map { |part| "#{part} · #{unit} = #{part * unit}°" }.join(', ')}."
      ],
      answer: angles.map { |angle| "#{angle}°" }.join(", "),
      check: "#{angles.join(' + ')} = 180°.",
      watch: "Отношението не дава градусите направо — първо се намира стойността на една част."
    )
  )
end

Authoring.family "blank.cuboid_pair", topic: "Обем", area: "interactive_geometry", variants: 11,
                 rungs: [ 1250, 1340, 1430, 1520, 1610, 1700 ] do |c|
  a = c.int(c.by_level([ 2..5, 2..8, 3..12, 4..20, 6..40, 8..70 ]))
  b = c.int(c.by_level([ 2..5, 2..8, 3..12, 4..20, 6..40, 8..70 ]))
  h = c.int(c.by_level([ 2..5, 2..8, 3..12, 4..20, 6..40, 8..70 ]))

  c.q(
    text: "Правоъгълен паралелепипед е #{a} см на #{b} см на #{h} см. Попълни обема и повърхнината му.",
    widget: WidgetKit.blanks([ [ "v", "обем", a * b * h, "см³" ],
                               [ "s", "повърхнина", 2 * ((a * b) + (b * h) + (a * h)), "см²" ] ]),
    explanation: Explain.build(
      idea: "Обемът е произведението на трите измерения; повърхнината е сборът на шестте стени.",
      steps: [
        "V = #{a} · #{b} · #{h} = #{a * b * h} см³.",
        "S = 2 · (#{a * b} + #{b * h} + #{a * h}) = #{2 * ((a * b) + (b * h) + (a * h))} см²."
      ],
      answer: "V = #{a * b * h} см³, S = #{2 * ((a * b) + (b * h) + (a * h))} см²",
      check: "Стените са равни по двойки, затова в повърхнината има множител 2.",
      watch: "Кубични сантиметри мерят обем, квадратни — повърхнина."
    )
  )
end

Authoring.family "blank.pythagoras_pair", topic: "Питагорова теорема", area: "interactive_geometry", variants: 11,
                 rungs: [ 1400, 1490, 1580, 1670, 1760, 1850 ] do |c|
  a, b, hyp = pythagorean_triple(c)

  c.q(
    text: "Правоъгълен триъгълник има катети #{a} см и #{b} см. Попълни хипотенузата и лицето.",
    widget: WidgetKit.blanks([ [ "c", "хипотенуза", hyp, "см" ], [ "s", "лице", Num.ans(Rational(a * b, 2)), "см²" ] ]),
    explanation: Explain.build(
      idea: "Хипотенузата идва от Питагоровата теорема, а лицето — от двата катета, които са основа и височина.",
      steps: [
        "c² = #{a}² + #{b}² = #{(a * a) + (b * b)}, значи c = #{hyp} см.",
        "S = #{a} · #{b} : 2 = #{Num.ans(Rational(a * b, 2))} см²."
      ],
      answer: "c = #{hyp} см, S = #{Num.ans(Rational(a * b, 2))} см²",
      check: "#{a}² + #{b}² = #{hyp}².",
      watch: "В лицето влизат катетите, не хипотенузата."
    )
  )
end

# --------------------------------------------------- Избор и групиране ---

Authoring.family "pick.right_triangles", topic: "Питагорова теорема", area: "interactive_geometry", variants: 11,
                 rungs: [ 1350, 1440, 1530, 1620, 1710, 1800 ] do |c|
  good = 2.times.map { pythagorean_triple(c) }
  bad = 3.times.map do
    a, b, hyp = pythagorean_triple(c)
    [ a, b, hyp + c.pick([ -2, -1, 1, 2 ]) ]
  end
  options = (good + bad).map { |sides| [ sides.join(", "), (sides[0]**2) + (sides[1]**2) == sides[2]**2 ] }.uniq { |label, _| label }
  raise Authoring::Duplicate if options.count { |_, ok| ok } < 2 || options.size < 5

  c.q(
    text: "Кои от тройките (#{options.map(&:first).join('), (')}) са страни на правоъгълен триъгълник? Избери всички.",
    widget: WidgetKit.multi_select(options),
    explanation: Explain.build(
      idea: "Обратната Питагорова теорема: триъгълникът е правоъгълен точно когато a² + b² = c² за най-дългата страна c.",
      steps: good.map { |a, b, hyp| "#{a}² + #{b}² = #{(a * a) + (b * b)} = #{hyp}² ✓" } +
             [ bad.first(2).map { |a, b, hyp| "#{a}² + #{b}² = #{(a * a) + (b * b)} ≠ #{hyp}² = #{hyp * hyp}" }.join("; ") ],
      answer: good.map { |sides| sides.join(", ") }.join(" | "),
      check: "Сравнението е между квадратите, не между самите дължини.",
      watch: "Тройка, близка до правоъгълна, пак не е правоъгълна — разликата в квадратите е решаваща."
    )
  )
end

Authoring.family "pick.area_units", topic: "Площ", area: "interactive_geometry", variants: 11,
                 rungs: [ 1050, 1140, 1230, 1320, 1410, 1500 ] do |c|
  base = c.int(c.by_level([ 2..6, 2..10, 3..20, 4..40, 6..90, 8..200 ]))
  correct = [ "#{base * 100} дм²", "#{base * 10_000} см²" ]
  wrong = [ "#{base * 10} дм²", "#{base * 100} см²", "#{base * 1000} см²", "#{base * 10} м²" ]
  options = (correct + c.sample(wrong, 3)).map { |label| [ label, correct.include?(label) ] }.uniq { |label, _| label }
  raise Authoring::Duplicate if options.count { |_, ok| ok } < 2 || options.size < 5

  c.q(
    text: "Кои записи са равни на #{base} м²? Избери всички верни.",
    widget: WidgetKit.multi_select(options),
    explanation: Explain.build(
      idea: "При квадратните мерки множителят се повдига на квадрат: 1 м = 10 дм, значи 1 м² = 100 дм².",
      steps: [
        "1 м² = 100 дм², затова #{base} м² = #{base * 100} дм².",
        "1 м² = 10 000 см², затова #{base} м² = #{base * 10_000} см²."
      ],
      answer: correct.join(", "),
      check: "Проверката е през дължините: 1 м = 100 см, а 100 · 100 = 10 000.",
      watch: "Множителят при площите не е 10 или 100, а квадратът им."
    )
  )
end

Authoring.family "sortbins.angle_kind", topic: "Ъгли", area: "interactive_geometry", variants: 11,
                 rungs: [ 860, 950, 1040, 1130, 1220, 1310 ] do |c|
  angles = c.sample((5..175).step(5).to_a, 5)
  raise Authoring::Duplicate if angles.count { |a| a < 90 } < 2 || angles.count { |a| a > 90 } < 2

  items = angles.sort.each_with_index.map { |angle, i| [ "a#{i}", "#{angle}°", angle < 90 ? "acute" : "obtuse" ] }

  c.q(
    text: "Разпредели ъглите #{angles.sort.map { |a| "#{a}°" }.join(', ')} на остри и тъпи.",
    widget: WidgetKit.categorize(bins: [ [ "acute", "остри" ], [ "obtuse", "тъпи" ] ], items: items),
    explanation: Explain.build(
      idea: "Правият ъгъл (90°) е границата: под него ъглите са остри, над него — тъпи.",
      steps: [
        "Остри: #{angles.select { |a| a < 90 }.sort.map { |a| "#{a}°" }.join(', ')}.",
        "Тъпи: #{angles.select { |a| a > 90 }.sort.map { |a| "#{a}°" }.join(', ')}."
      ],
      answer: "остри: #{angles.select { |a| a < 90 }.sort.join(', ')}",
      check: "Всеки тъп ъгъл е по-голям от 90° и по-малък от 180°.",
      watch: "90° не е нито остър, нито тъп — той е прав."
    )
  )
end

Authoring.family "sortbins.triangle_by_sides", topic: "Периметър", area: "interactive_geometry", variants: 11,
                 rungs: [ 1100, 1190, 1280, 1370, 1460, 1550 ] do |c|
  items = []
  equilateral = c.int(2..c.by_level([ 8, 12, 20, 40, 90, 200 ]))
  items << [ "#{equilateral}, #{equilateral}, #{equilateral}", "eq" ]
  2.times do
    base = c.int(2..c.by_level([ 8, 12, 20, 40, 90, 200 ]))
    leg = base + c.int(1..5)
    items << [ "#{leg}, #{leg}, #{base}", "iso" ]
  end
  2.times do
    a = c.int(3..c.by_level([ 9, 14, 25, 50, 100, 250 ]))
    b = a + c.int(1..4)
    d = b + c.int(1..3)
    items << [ "#{a}, #{b}, #{d}", "sca" ] if a + b > d
  end
  chosen = items.uniq(&:first).first(5)
  raise Authoring::Duplicate if chosen.size < 4 || chosen.map(&:last).uniq.size < 3

  c.q(
    text: "Разпредели триъгълниците по страните им: #{chosen.map(&:first).join('; ')}.",
    widget: WidgetKit.categorize(
      bins: [ [ "eq", "равностранен" ], [ "iso", "равнобедрен" ], [ "sca", "разностранен" ] ],
      items: chosen.each_with_index.map { |(label, bin), i| [ "t#{i}", label, bin ] }
    ),
    explanation: Explain.build(
      idea: "Равностранен има три равни страни, равнобедрен — точно две, разностранен — нито две равни.",
      steps: chosen.map { |label, bin| "#{label} → #{{ 'eq' => 'равностранен', 'iso' => 'равнобедрен', 'sca' => 'разностранен' }[bin]}." },
      answer: chosen.map { |label, bin| "#{label}: #{{ 'eq' => 'равностранен', 'iso' => 'равнобедрен', 'sca' => 'разностранен' }[bin]}" }.join("; "),
      check: "Във всеки от тях сборът на две страни надвишава третата — иначе триъгълник няма.",
      watch: "Равностранният е и равнобедрен по определение, но тук се търси най-точното име."
    )
  )
end

Authoring.family "match.shape_formula", topic: "Площ", area: "interactive_geometry", variants: 11,
                 rungs: [ 1150, 1240, 1330, 1420, 1510, 1600 ] do |c|
  pool = [
    [ "правоъгълник", "a · b" ], [ "триъгълник", "a · h : 2" ], [ "квадрат", "a²" ],
    [ "успоредник", "a · h" ], [ "трапец", "(a + b) : 2 · h" ], [ "кръг", "πr²" ],
    [ "куб (обем)", "a³" ], [ "паралелепипед (обем)", "a · b · c" ], [ "цилиндър (обем)", "πr²h" ],
    [ "пирамида (обем)", "S · h : 3" ], [ "конус (обем)", "πr²h : 3" ], [ "окръжност (дължина)", "2πr" ]
  ]
  window = c.by_level([ pool[0..3], pool[0..5], pool[2..7], pool[4..9], pool[5..11], pool ])
  pairs = c.sample(window, 3)
  raise Authoring::Duplicate if pairs.size < 3

  c.q(
    text: "Свържи всяка фигура с формулата ѝ: #{pairs.map(&:first).join(', ')}.",
    widget: WidgetKit.matcher(pairs),
    explanation: Explain.build(
      idea: "Формулите се помнят по смисъла им: лицето брои квадратчета, обемът — кубчета.",
      steps: pairs.map { |shape, formula| "#{shape} → #{formula}" },
      answer: pairs.map { |shape, formula| "#{shape}: #{formula}" }.join("; "),
      check: "Във формула за обем участват три измерения, в лице — две.",
      watch: "Делението на 2 е при триъгълника и трапеца, делението на 3 — при пирамидата и конуса."
    )
  )
end

Authoring.family "match.solid_faces", topic: "Призма и пирамида", area: "interactive_geometry", variants: 11,
                 rungs: [ 1200, 1290, 1380, 1470, 1560, 1650 ] do |c|
  pool = [
    [ "куб", "6 стени, 12 ръба" ], [ "правоъгълен паралелепипед", "6 стени, 8 върха" ],
    [ "триъгълна призма", "5 стени, 9 ръба" ], [ "четириъгълна пирамида", "5 стени, 5 върха" ],
    [ "триъгълна пирамида", "4 стени, 6 ръба" ], [ "цилиндър", "2 равни кръга и една извита повърхнина" ],
    [ "конус", "1 кръг и един връх" ], [ "кълбо", "нито една равнинна стена" ]
  ]
  pairs = c.sample(pool, 3)
  raise Authoring::Duplicate if pairs.size < 3

  c.q(
    text: "Свържи всяко тяло с описанието му: #{pairs.map(&:first).join(', ')}.",
    widget: WidgetKit.matcher(pairs),
    explanation: Explain.build(
      idea: "Броим стените, ръбовете и върховете по модела: всяка равнинна част е стена.",
      steps: pairs.map { |solid, description| "#{solid}: #{description}." },
      answer: pairs.map { |solid, description| "#{solid} → #{description}" }.join("; "),
      check: "За многостен важи В − Р + С = 2 (формулата на Ойлер).",
      watch: "Цилиндърът и конусът имат извити повърхнини — те не се броят като стени на многостен."
    )
  )
end
