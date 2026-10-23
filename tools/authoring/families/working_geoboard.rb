# Геоборд: начертай фигура по правило.
#
# The geoboard grades by rule, not by position — any rectangle with area 12 and
# perimeter 14 is right wherever it is drawn — so these families state a rule
# and keep one example polygon for the checks. The board size is in the text:
# it is part of what the student has to work within (a 6 × 6 board has no room
# for a side of 6), and it keeps the stems of one rung apart.

GEOBOARD_SIZES = [ 6, 7, 8, 9 ].freeze

# A board the shape fits on: span is the most pegs it needs in one direction.
def geoboard_size(c, span)
  c.pick(GEOBOARD_SIZES.select { |size| size - 1 >= span })
end

# Areas are written as the text writes them: 4,5 and 12, never 12,0.
def geoboard_area(twice) = twice.even? ? twice / 2 : twice / 2.0

def geoboard_area_text(area) = area.is_a?(Integer) ? area.to_s : area.to_s.tr(".", ",")

# „1 отсечка“, „3 отсечки“.
def geoboard_segments(count) = count == 1 ? "1 отсечка" : "#{count} отсечки"

# ------------------------------------------------- Правоъгълник по лице и обиколка ---

Authoring.family "working.geoboard.rectangle", topic: "Периметър", area: "interactive_working", variants: 9,
                 rungs: [ 950, 1030, 1110, 1190, 1270, 1360 ] do |c|
  band = c.by_level([ 2..6, 7..12, 13..18, 20..24, 28..32, 35..56 ])
  a, b = c.pick((1..8).to_a.combination(2).select { |d, e| band.cover?(d * e) })
  size = geoboard_size(c, b)
  area = a * b
  perimeter = 2 * (a + b)
  others = (1..area).select { |d| (area % d).zero? && d <= area / d && d != a }.map { |d| [ d, area / d ] }
  other = others.min_by { |d, e| (d - a).abs + (e - b).abs }

  c.q(
    text: c.level >= 3 && c.coin ? "На дъска от #{size} × #{size} точки начертай правоъгълник с обиколка #{perimeter} и лице #{area}." :
                                   "На дъска от #{size} × #{size} точки начертай правоъгълник с лице #{area} и обиколка #{perimeter}.",
    widget: WidgetKit.geoboard(shape: :rectangle, area: area, perimeter: perimeter, size: size,
                               example: [ [ 0, 0 ], [ b, 0 ], [ b, a ], [ 0, a ] ]),
    explanation: Explain.build(
      idea: "Лицето на правоъгълник е произведението на страните му, обиколката — два пъти сборът им. Търсим две страни, които дават и двете числа.",
      steps: [
        "Двойки страни с произведение #{area}: #{(others + [ [ a, b ] ]).sort.map { |d, e| "#{d} и #{e}" }.join(', ')}.",
        "Сборът на страните трябва да е #{perimeter} : 2 = #{a + b}. Това са #{a} и #{b}.",
        "Начертай правоъгълник #{a} на #{b} — броим отсечките между съседни точки, а не самите точки."
      ],
      answer: "правоъгълник със страни #{a} и #{b}",
      check: "#{a} · #{b} = #{area} и 2 · (#{a} + #{b}) = #{perimeter}.",
      watch: other ? "Правоъгълник #{other[0]} на #{other[1]} има същото лице #{area}, но обиколка #{2 * other.sum} — еднакво лице не значи еднаква обиколка." :
                     "Страната се брои в отсечки: между 1-вата и 4-тата точка в ред има 3 единици, не 4."
    ),
    hints: [
      "Запиши двойките числа, чието произведение е #{area}.",
      "За всяка двойка пресметни 2 · (първото + второто) и сравни с #{perimeter}."
    ]
  )
end

# --------------------------------------------------------- Триъгълник по лице ---

# Legs whose half-product is the area — the example is a right triangle on the
# grid lines, the easiest to check, though any triangle of that area is right.
def geoboard_triangle_legs(c, twice, span)
  legs = (1..span).to_a.repeated_permutation(2).select { |b, h| b * h == twice }
  c.pick(legs)
end

Authoring.family "working.geoboard.triangle", topic: "Площ", area: "interactive_working", variants: 9,
                 rungs: [ 1050, 1130, 1210, 1290, 1370, 1450 ] do |c|
  twice = c.pick(c.by_level([ [ 2, 4, 6, 8 ], [ 1, 3, 5, 9 ], [ 10, 12, 14, 16 ], [ 7, 15, 21, 25 ],
                              [ 18, 20, 24, 28 ], [ 30, 35, 36, 40, 42, 48 ] ]))
  area = geoboard_area(twice)
  b, h = geoboard_triangle_legs(c, twice, 8)
  raise Authoring::Duplicate unless b
  size = geoboard_size(c, [ b, h ].max)
  text_area = geoboard_area_text(area)

  c.q(
    text: "На дъска от #{size} × #{size} точки начертай триъгълник с лице #{text_area}.",
    widget: WidgetKit.geoboard(shape: :triangle, area: area, size: size, example: [ [ 0, 0 ], [ b, 0 ], [ 0, h ] ]),
    explanation: Explain.build(
      idea: "Лицето на триъгълник е половината от основата по височината. Затова основа · височина трябва да даде #{twice}.",
      steps: [
        "#{text_area} · 2 = #{twice}: търсим основа и височина с произведение #{twice}.",
        "Например основа #{b} и височина #{h}: #{b} · #{h} = #{twice}.",
        "Постави основата по линия от точки, а върха — #{h} реда над нея. Върхът може да е над която и да е точка от реда."
      ],
      answer: "триъгълник с основа #{b} и височина #{h} (или друг с лице #{text_area})",
      check: "#{b} · #{h} : 2 = #{text_area}.",
      watch: twice.odd? ? "Лицето #{text_area} не е цяло число — триъгълникът е половината от правоъгълник с лице #{twice}." :
                          "Не забравяй делението на 2: триъгълник с основа #{b} и височина #{h} е половината от правоъгълник #{b} на #{h}."
    ),
    hints: [
      "Триъгълникът е половината от правоъгълник. Какво лице трябва да има правоъгълникът?",
      "Избери основа по линия от точки и пресметни нужната височина."
    ]
  )
end

# ---------------------------------------------------- Правоъгълен триъгълник ---

Authoring.family "working.geoboard.right_triangle", topic: "Площ", area: "interactive_working", variants: 9,
                 rungs: [ 1150, 1230, 1310, 1390, 1470, 1550 ] do |c|
  twice = c.pick(c.by_level([ [ 2, 4, 6, 8, 12 ], [ 3, 5, 10, 15 ], [ 16, 18, 20, 24 ], [ 7, 9, 21, 35 ],
                              [ 28, 30, 32, 36 ], [ 35, 40, 42, 48, 49, 56 ] ]))
  area = geoboard_area(twice)
  b, h = geoboard_triangle_legs(c, twice, 8)
  raise Authoring::Duplicate unless b
  size = geoboard_size(c, [ b, h ].max)
  text_area = geoboard_area_text(area)

  c.q(
    text: "На дъска от #{size} × #{size} точки начертай правоъгълен триъгълник с лице #{text_area}.",
    widget: WidgetKit.geoboard(shape: :right_triangle, area: area, size: size, example: [ [ 0, 0 ], [ b, 0 ], [ 0, h ] ]),
    explanation: Explain.build(
      idea: "В правоъгълен триъгълник двата катета са основа и височина едновременно, така че лицето е половината от произведението им.",
      steps: [
        "Катетите трябва да дават произведение #{text_area} · 2 = #{twice}.",
        "Например #{b} и #{h}: #{b} · #{h} = #{twice}.",
        "Начертай ъгъл от #{geoboard_segments(b)} по ред и #{geoboard_segments(h)} по колона от един и същ връх и затвори фигурата."
      ],
      answer: "правоъгълен триъгълник с катети #{b} и #{h}",
      check: "#{b} · #{h} : 2 = #{text_area}, а ъгълът между двата катета е прав.",
      watch: "Правият ъгъл трябва да е между двете страни, чието произведение пресмяташ — не между основа и наклонена страна."
    ),
    hints: [
      "Удобно е катетите да лежат по линиите на дъската.",
      "Произведението на катетите е два пъти лицето."
    ]
  )
end

# ---------------------------------------------------------- Квадрат по лице ---

# A square on a lattice has a side that runs p across and q up, so its area is
# p² + q². The top rungs are the squares that only exist tilted: area 2, 5, 10,
# 13 — there is no 2 × 2 grid-aligned square of area 5.
Authoring.family "working.geoboard.square", topic: "Площ", area: "interactive_working", variants: 9,
                 rungs: [ 1250, 1330, 1410, 1490, 1570, 1650 ] do |c|
  p, q = c.pick(c.by_level([ [ [ 2, 0 ], [ 3, 0 ] ], [ [ 4, 0 ], [ 5, 0 ], [ 6, 0 ] ],
                             [ [ 1, 1 ], [ 2, 2 ], [ 3, 3 ] ], [ [ 1, 2 ], [ 1, 3 ] ],
                             [ [ 2, 3 ], [ 1, 4 ], [ 2, 4 ] ], [ [ 1, 5 ], [ 2, 5 ], [ 4, 4 ], [ 1, 6 ], [ 3, 5 ], [ 2, 6 ] ] ]))
  area = p * p + q * q
  span = p + q
  size = geoboard_size(c, span)
  example = [ [ q, 0 ], [ q + p, q ], [ p, q + p ], [ 0, p ] ]
  tilted = q.positive?

  steps = if tilted
    [
      "Лице #{area} не е квадрат на цяло число, затова квадратът е наклонен.",
      "Нека страната върви #{p} надясно и #{q} надолу. Квадратът се вписва в изправен квадрат #{span} на #{span} с лице #{span * span}.",
      "От него отпадат четири правоъгълни триъгълника с катети #{p} и #{q}: 4 · #{p} · #{q} : 2 = #{2 * p * q}.",
      "#{span * span} − #{2 * p * q} = #{area}."
    ]
  else
    [ "#{area} = #{p} · #{p}, значи страната е #{p}.", "Начертай изправен квадрат със страна #{geoboard_segments(p)}." ]
  end

  c.q(
    text: "На дъска от #{size} × #{size} точки начертай квадрат с лице #{area}.",
    widget: WidgetKit.geoboard(shape: :square, area: area, size: size, example: example),
    explanation: Explain.build(
      idea: tilted ? "Квадрат на дъската може да е и наклонен: ако страната му върви #{p} в едната посока и #{q} в другата, лицето му е #{p}² + #{q}²." :
                     "Лицето на квадрат е страната по себе си.",
      steps: steps,
      answer: tilted ? "наклонен квадрат, чиято страна върви #{p} надясно и #{q} надолу" : "квадрат със страна #{p}",
      check: tilted ? "#{p}² + #{q}² = #{p * p} + #{q * q} = #{area}." : "#{p} · #{p} = #{area}.",
      watch: tilted ? "Изправен квадрат има лице 1, 4, 9, 16… — за всяко друго лице квадратът трябва да се завърти." :
                      "Страната се брои в отсечки между точките, не в точки."
    ),
    hints: tilted ? [ "Квадратът не е задължително изправен.", "Ако наклонена страна върви a в едната посока и b в другата, квадратът на дължината ѝ е a² + b²." ] :
                    [ "Кое число, умножено по себе си, дава лицето?" ]
  )
end
