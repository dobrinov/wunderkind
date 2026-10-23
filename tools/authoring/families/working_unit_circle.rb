# Единична окръжност: ъгли, отбелязани като точки по окръжността.
#
# The widget shows the point, its radius and the two projections — the sine is
# the height, the cosine the abscissa — with the special values 1/2, √2/2, √3/2
# ticked on the axes. A question that names the angle ("отбележи 210°", "7π/6")
# turns the degree readout off: otherwise it is answered by tapping until the
# readout agrees. So these families ask for the *places*: an angle in
# degrees or radians, every angle with a given sine or cosine, the one angle
# that also satisfies a sign condition. The answer is a set of angles from
# 0° to 359°, graded as a set.

module UnitCircle
  module_function

  # The special values, as the text writes them, with their size as a number.
  VALUES = {
    "0" => 0.0, "1/2" => 0.5, "√2/2" => Math.sqrt(2) / 2, "√3/2" => Math.sqrt(3) / 2, "1" => 1.0,
    "−1/2" => -0.5, "−√2/2" => -Math.sqrt(2) / 2, "−√3/2" => -Math.sqrt(3) / 2, "−1" => -1.0
  }.freeze

  TANGENTS = {
    "1" => 1.0, "−1" => -1.0, "√3" => Math.sqrt(3), "−√3" => -Math.sqrt(3),
    "√3/3" => Math.sqrt(3) / 3, "−√3/3" => -Math.sqrt(3) / 3
  }.freeze

  def sin(degrees) = Math.sin(degrees * Math::PI / 180)
  def cos(degrees) = Math.cos(degrees * Math::PI / 180)

  # Every angle on the 15° grid whose sine (or cosine) is the value — read off
  # the circle rather than written down, so the stored answer cannot miss the
  # second solution the way a hand-written table can.
  def solutions(function, value)
    (0...360).step(15).select { |angle| (public_send(function, angle) - value).abs < 1e-9 }
  end

  def quadrant(angle)
    return nil if (angle % 90).zero?

    angle / 90 + 1
  end

  def reference(angle)
    case quadrant(angle)
    when 1 then angle
    when 2 then 180 - angle
    when 3 then angle - 180
    when 4 then 360 - angle
    end
  end

  QUADRANT_NAMES = { 1 => "първи", 2 => "втори", 3 => "трети", 4 => "четвърти" }.freeze

  # Where a point on an axis sits — 0°, 90°, 180°, 270° are in no quadrant.
  AXIS_PLACES = { 0 => "вдясно, на оста x", 90 => "горе, на оста y", 180 => "вляво, на оста x", 270 => "долу, на оста y" }.freeze

  def where(angle)
    return "на оста — #{AXIS_PLACES.fetch(angle % 360)}" if quadrant(angle).nil?

    # „във втори“: в before a в or ф becomes във.
    "#{quadrant(angle) == 2 ? 'във' : 'в'} #{QUADRANT_NAMES[quadrant(angle)]} квадрант"
  end

  # A sign as a word, with zero as zero: floating point puts sin 180° a hair
  # above nought, which used to come out as "положителен".
  def sign_word(value, positive, negative)
    return "нула" if value.abs < 1e-9

    value.positive? ? positive : negative
  end

  # "7π/6", "π/2", "π", "−π/3" — from a multiple k of π/n.
  def radians(k, n)
    g = Num.gcd(k.abs, n)
    k, n = k / g, n / g
    top = case k.abs
    when 0 then "0"
    when 1 then "π"
    else "#{k.abs}π"
    end
    text = n == 1 ? top : "#{top}/#{n}"
    k.negative? ? "−#{text}" : text
  end

  def signed_degrees(value) = value.negative? ? "−#{value.abs}°" : "#{value}°"

  def decimal(value) = Num.dec(value, 3).sub("-", "−")
end

# ------------------------------------------------------------- Ъгъл в градуси ---

Authoring.family "working.circle.degrees", topic: "Тригонометрични функции", area: "interactive_working", variants: 8,
                 rungs: [ 1640, 1700, 1760, 1820, 1880, 1940 ] do |c|
  pool, step = c.by_level([
    [ (30..330).step(30).reject { |a| (a % 90).zero? }, 30 ],
    [ [ 45, 135, 225, 315, 15, 75 ], 15 ],
    [ [ 105, 165, 195, 255, 285, 345 ], 15 ],
    [ (-345..-15).step(15).to_a, 15 ],
    [ (375..705).step(15).reject { |a| (a % 90).zero? }, 15 ],
    [ (-705..-375).step(15).reject { |a| (a % 90).zero? }, 15 ]
  ])
  given = c.pick(pool)
  angle = given % 360
  turns = (given - angle) / 360

  steps = []
  if given != angle
    steps << if given.negative?
      "Отрицателен ъгъл се отмерва по часовниковата стрелка. Добавяме #{turns.abs} пълн#{turns.abs == 1 ? 'а обиколка' : 'и обиколки'}: #{UnitCircle.signed_degrees(given)} + #{360 * turns.abs}° = #{angle}° — същата точка."
    else
      "Пълна обиколка (360°) връща точката на същото място. Махаме #{turns} обиколк#{turns == 1 ? 'а' : 'и'}: #{given}° − #{360 * turns}° = #{angle}°."
    end
  end
  if UnitCircle.quadrant(angle)
    steps << "#{angle}° е #{UnitCircle.where(angle)}: между #{angle / 90 * 90}° и #{angle / 90 * 90 + 90}°."
    steps << "До оста x остават #{UnitCircle.reference(angle)}° — по това се намира точката в квадранта."
  else
    steps << "#{angle}° е кратно на 90°, затова точката е #{UnitCircle.where(angle)}."
  end

  c.q(
    text: "Отбележи на единичната окръжност ъгъла α = #{UnitCircle.signed_degrees(given)}.",
    widget: WidgetKit.unit_circle(angles: [ angle ], step: step, degrees: false),
    hints: [
      "Ъглите се отмерват от положителната посока на оста x обратно на часовниковата стрелка; 90° е горе, 180° — вляво, 270° — долу.",
      given == angle ? "Определи първо в кой квадрант е ъгълът — между кои две оси попада." : "Ъгли, които се различават с цяла обиколка от 360°, сочат една и съща точка."
    ],
    explanation: Explain.build(
      idea: "Ъгълът се отмерва от положителната посока на оста x обратно на часовниковата стрелка, а пълна обиколка е 360°.",
      steps: steps,
      answer: "точката на #{angle}°",
      check: "При #{angle}° синусът е #{UnitCircle.sign_word(UnitCircle.sin(angle), 'положителен (точката е над оста x)', 'отрицателен (точката е под оста x)')}, а косинусът — #{UnitCircle.sign_word(UnitCircle.cos(angle), 'положителен (вдясно от оста y)', 'отрицателен (вляво от оста y)')}.",
      watch: given.negative? ? "Минусът значи „по часовниковата стрелка“, а не огледален образ спрямо оста y." : "Ъгли над 180° са под оста x — не ги търси в горната половина."
    )
  )
end

# ------------------------------------------------------------- Ъгъл в радиани ---

Authoring.family "working.circle.radians", topic: "Тригонометрични функции", area: "interactive_working", variants: 7,
                 rungs: [ 1760, 1820, 1880, 1940, 2000, 2060 ] do |c|
  k, n, step = c.pick(c.by_level([
    [ [ 1, 2, 30 ], [ 1, 1, 30 ], [ 3, 2, 30 ], [ 1, 3, 30 ], [ 2, 3, 30 ], [ 1, 6, 30 ], [ 5, 6, 30 ] ],
    [ [ 7, 6, 30 ], [ 11, 6, 30 ], [ 4, 3, 30 ], [ 5, 3, 30 ], [ 2, 1, 30 ] ],
    [ [ 1, 4, 15 ], [ 3, 4, 15 ], [ 5, 4, 15 ], [ 7, 4, 15 ] ],
    [ 1, 5, 7, 11, 13, 17, 19, 23 ].map { |kk| [ kk, 12, 15 ] },
    [ [ -1, 3, 15 ], [ -2, 3, 15 ], [ -1, 4, 15 ], [ -3, 4, 15 ], [ -1, 6, 15 ], [ -5, 6, 15 ], [ -1, 2, 15 ] ],
    [ [ 13, 6, 15 ], [ 17, 6, 15 ], [ 19, 6, 15 ], [ 9, 4, 15 ], [ 11, 4, 15 ], [ 7, 3, 15 ], [ 8, 3, 15 ], [ 23, 6, 15 ] ]
  ]))
  degrees_given = k * 180 / n
  angle = degrees_given % 360
  shown = UnitCircle.radians(k, n)

  multiple = k.abs == 1 ? "180°" : "#{k.abs} · 180°"
  multiple = "#{multiple} : #{n}" unless n == 1
  steps = if k.abs == 1 && n == 1
    [ "π радиана са 180°#{k.negative? ? ', затова −π = −180°' : ''}." ]
  else
    [ "π радиана са 180°, затова #{shown} = #{k.negative? ? '−(' : ''}#{multiple}#{k.negative? ? ')' : ''} = #{UnitCircle.signed_degrees(degrees_given)}." ]
  end
  if degrees_given != angle
    steps << (degrees_given.negative? ? "Отрицателният ъгъл е по часовниковата стрелка: #{UnitCircle.signed_degrees(degrees_given)} + #{angle - degrees_given}° = #{angle}°." : "Махаме пълните обиколки: #{degrees_given}° − #{degrees_given - angle}° = #{angle}°.")
  end
  steps << "#{angle}° е #{UnitCircle.where(angle)}."

  c.q(
    text: "Отбележи на единичната окръжност ъгъла α = #{shown}.",
    widget: WidgetKit.unit_circle(angles: [ angle ], step: step, degrees: false),
    hints: [
      "Преведи ъгъла в градуси, преди да го търсиш: колко градуса са 2π радиана?",
      "Пълна обиколка е 2π — ъгъл, по-голям от 2π или отрицателен, сочи същата точка като някой между 0 и 2π."
    ],
    explanation: Explain.build(
      idea: "π радиана са половин обиколка, т.е. 180°. Превеждаме в градуси и отмерваме от положителната посока на оста x.",
      steps: steps,
      answer: "точката на #{angle}°",
      check: if Rational(k, n).abs == 1
        "π е точно половин обиколка#{degrees_given.negative? ? ', отмерена по часовниковата стрелка' : ''} — точката е вляво, на оста x."
             else
        size = if degrees_given.abs > 360 then "повече от цяла обиколка (2π)"
        elsif degrees_given.abs > 180 then "повече от половин обиколка"
        else "не повече от половин обиколка"
        end
        "#{shown} е #{UnitCircle.decimal(Rational(k, n))} пъти по π — #{size}#{degrees_given.negative? ? ', отмерено по часовниковата стрелка' : ''}."
             end,
      watch: "π не е 3,14°, а 180°: π/6 е 30°, а не нещо близо до половин градус."
    )
  )
end

# ------------------------------------------- Всички ъгли с даден sin или cos ---

Authoring.family "working.circle.equation", topic: "Тригонометрични функции", area: "interactive_working", variants: 5,
                 rungs: [ 1880, 1940, 2000, 2060, 2120, 2180 ] do |c|
  plain = ->(function, value_text) { [ :plain, function, value_text ] }
  item = c.pick(c.by_level([
    [ plain.("sin", "1"), plain.("sin", "0"), plain.("sin", "1/2"), plain.("sin", "−1") ],
    [ plain.("cos", "1/2"), plain.("cos", "0"), plain.("cos", "−1"), plain.("cos", "1") ],
    [ plain.("sin", "−1/2"), plain.("cos", "−1/2"), plain.("sin", "√3/2"), plain.("cos", "√3/2") ],
    [ plain.("sin", "−√3/2"), plain.("cos", "−√3/2"), plain.("sin", "√2/2"), plain.("cos", "√2/2") ],
    [ plain.("sin", "−√2/2"), plain.("cos", "−√2/2"), [ :abs, "sin", "1/2" ], [ :abs, "cos", "√3/2" ] ],
    [ [ :diagonal, "=" ], [ :diagonal, "−" ], [ :square, "sin", "3/4" ], [ :square, "cos", "1/2" ], [ :abs, "sin", "√2/2" ] ]
  ]))

  sin_of, cos_of = UnitCircle.method(:sin), UnitCircle.method(:cos)
  value_of = ->(function, a) { function == "sin" ? sin_of.(a) : cos_of.(a) }
  grid = (0...360).step(15).to_a
  name = ->(function) { function == "sin" ? "синусът" : "косинусът" }
  measure = ->(function) { function == "sin" ? "височината на точката (координатата y)" : "абсцисата на точката (координатата x)" }

  case item.first
  when :plain
    _, function, value_text = item
    value = UnitCircle::VALUES.fetch(value_text)
    condition = "#{function} α = #{value_text}"
    angles = grid.select { |a| (value_of.(function, a) - value).abs < 1e-9 }
    line = function == "sin" ? "хоризонталната права y = #{value_text}" : "вертикалната права x = #{value_text}"
    idea = "На единичната окръжност #{name.(function)} е #{measure.(function)}, така че търсим точките на окръжността върху #{line}."
    steps = [ angles.size == 1 ? "Правата само допира окръжността — има една точка." : "Правата пресича окръжността в две точки — има два ъгъла." ]
    unless angles.any? { |a| (a % 90).zero? }
      ref = UnitCircle.reference(angles.first)
      quadrants = function == "sin" ? (value.positive? ? "в първи и втори" : "в трети и четвърти") : (value.positive? ? "в първи и четвърти" : "във втори и трети")
      steps << "Основният ъгъл е #{ref}°, защото #{function} #{ref}° = #{value_text.delete('−')}."
      steps << "#{name.(function).capitalize} е #{value.positive? ? 'положителен' : 'отрицателен'} #{quadrants} квадрант."
    end
    hint = "Представи си #{line}. В колко точки пресича окръжността?"
  when :abs
    _, function, value_text = item
    value = UnitCircle::VALUES.fetch(value_text)
    condition = "|#{function} α| = #{value_text}"
    angles = grid.select { |a| (value_of.(function, a).abs - value).abs < 1e-9 }
    idea = "Модул #{value_text} значи #{function} α = #{value_text} или #{function} α = −#{value_text}: две прави, всяка с по две точки."
    steps = [ "#{function} α = #{value_text} при #{angles.select { |a| value_of.(function, a).positive? }.map { |a| "#{a}°" }.join(' и ')}.",
              "#{function} α = −#{value_text} при #{angles.select { |a| value_of.(function, a).negative? }.map { |a| "#{a}°" }.join(' и ')}." ]
    hint = "Модулът изпуска знака: стойността може да е и #{value_text}, и −#{value_text}."
  when :square
    _, function, value_text = item
    root = value_text == "3/4" ? "√3/2" : "√2/2"
    condition = "#{function}²α = #{value_text}"
    angles = grid.select { |a| (value_of.(function, a)**2 - Rational(*value_text.split("/").map(&:to_i)).to_f).abs < 1e-9 }
    idea = "Квадратът е #{value_text}, значи #{function} α = #{root} или #{function} α = −#{root}."
    steps = [ "#{value_text} = (#{root})², защото (#{root})² = #{value_text}.",
              "#{function} α = ±#{root} при #{angles.map { |a| "#{a}°" }.join(', ')}." ]
    hint = "Ако квадратът на едно число е #{value_text}, какво може да е самото число? Не забравяй отрицателното."
  when :diagonal
    sign = item[1]
    condition = sign == "=" ? "sin α = cos α" : "sin α = −cos α"
    angles = grid.select { |a| (sin_of.(a) - (sign == "=" ? 1 : -1) * cos_of.(a)).abs < 1e-9 }
    idea = "Синусът е височината на точката, косинусът — абсцисата ѝ. Търсим точките, в които #{sign == '=' ? 'двете са равни' : 'са равни по големина, но с противоположни знаци'}."
    steps = [ "Това са точките на окръжността върху правата #{sign == '=' ? 'y = x' : 'y = −x'} — ъглополовящата на #{sign == '=' ? 'първи и трети' : 'втори и четвърти'} квадрант.",
              "Правата минава през центъра, затова пресича окръжността в две срещуположни точки." ]
    hint = "Къде по окръжността височината на точката е #{sign == '=' ? 'равна на' : 'обратна на'} абсцисата ѝ? Помисли за права през центъра."
  end
  raise Authoring::Duplicate if angles.empty?

  step = angles.all? { |a| (a % 30).zero? } ? 30 : 15
  steps << (angles.size == 1 ? "Ъгълът е #{angles.first}°." : "Ъглите са #{angles.map { |a| "#{a}°" }.join(', ')}.")

  c.q(
    text: "Отбележи всички ъгли α, за които 0° ≤ α < 360° и #{condition}.",
    widget: WidgetKit.unit_circle(angles: angles, step: step),
    hints: [ "Синусът е височината на точката по окръжността, а косинусът — абсцисата ѝ.", hint ],
    explanation: Explain.build(
      idea: idea,
      steps: steps,
      answer: angles.map { |a| "#{a}°" }.join(", "),
      check: angles.map { |a| "sin #{a}° = #{UnitCircle.decimal(sin_of.(a))}, cos #{a}° = #{UnitCircle.decimal(cos_of.(a))}" }.join("; ") + ".",
      watch: "Повечето стойности се срещат по два пъти в една обиколка — спирането на първия ъгъл е половин отговор."
    )
  )
end

# ----------------------------------------- Един ъгъл с допълнително условие ---

Authoring.family "working.circle.quadrant", topic: "Тригонометрични функции", area: "interactive_working", variants: 8,
                 rungs: [ 1980, 2040, 2100, 2160, 2220, 2280 ] do |c|
  pool, step, kind = c.by_level([
    [ [ 30, 60, 120, 150, 210, 240, 300, 330 ], 30, "sin" ],
    [ [ 30, 60, 120, 150, 210, 240, 300, 330 ], 30, "cos" ],
    [ [ 45, 135, 225, 315 ], 15, "sin" ],
    [ [ 45, 135, 225, 315 ], 15, "cos" ],
    [ [ 30, 60, 120, 150, 210, 240, 300, 330, 45, 135, 225, 315 ], 15, "tg" ],
    [ [ 30, 60, 120, 150, 210, 240, 300, 330, 45, 135, 225, 315 ], 15, "cotg" ]
  ])
  angle = c.pick(pool)
  sin_v, cos_v = UnitCircle.sin(angle), UnitCircle.cos(angle)

  # The given value, as the text writes it, and a test for it at any angle.
  value_test = lambda do |function, a|
    s, co = UnitCircle.sin(a), UnitCircle.cos(a)
    case function
    when "sin" then s
    when "cos" then co
    when "tg" then co.abs < 1e-9 ? nil : s / co
    when "cotg" then s.abs < 1e-9 ? nil : co / s
    end
  end
  table = %w[sin cos].include?(kind) ? UnitCircle::VALUES : UnitCircle::TANGENTS
  given_value = value_test.(kind, angle)
  given_text = table.key(table.values.find { |v| (v - given_value).abs < 1e-9 })
  raise Authoring::Duplicate if given_text.nil?

  given_function = kind
  other_function = case kind
  when "sin" then "cos"
  when "cos" then "sin"
  else c.pick(%w[sin cos])
  end
  other_value = other_function == "sin" ? sin_v : cos_v
  sign = other_value.positive? ? ">" : "<"

  # The answer is computed from the conditions as written, not taken from the
  # angle we started from — a condition that leaves two angles is refused.
  candidates = (0...360).step(15).select do |a|
    v = value_test.(given_function, a)
    v && (v - table[given_text]).abs < 1e-9
  end
  matches = candidates.select do |a|
    second = other_function == "sin" ? UnitCircle.sin(a) : UnitCircle.cos(a)
    sign == ">" ? second > 1e-9 : second < -1e-9
  end
  raise Authoring::Duplicate unless matches == [ angle ]

  other_name = other_function == "sin" ? "синусът" : "косинусът"
  half = other_function == "sin" ? (sign == ">" ? "над оста x" : "под оста x") : (sign == ">" ? "вдясно от оста y" : "вляво от оста y")

  c.q(
    text: "Отбележи ъгъла α, за който 0° ≤ α < 360°, #{given_function} α = #{given_text} и #{other_function} α #{sign} 0.",
    widget: WidgetKit.unit_circle(angles: [ angle ], step: step),
    hints: [
      "Намери първо всички ъгли от 0° до 360° с #{given_function} α = #{given_text} — те са два.",
      "#{other_name.capitalize} #{sign == '>' ? 'положителен' : 'отрицателен'} значи, че точката е #{half}."
    ],
    explanation: Explain.build(
      idea: "Първото условие дава две точки по окръжността; знакът на #{other_function == 'sin' ? 'синуса' : 'косинуса'} избира едната от тях.",
      steps: [
        "#{given_function} α = #{given_text} при #{candidates.map { |a| "#{a}°" }.join(' и ')}.",
        "#{other_function} α #{sign} 0 означава, че точката е #{half}.",
        "От двата ъгъла това условие изпълнява само #{angle}° — той е #{UnitCircle.where(angle)}."
      ],
      answer: "#{angle}°",
      check: "#{other_function} #{angle}° = #{UnitCircle.decimal(other_value)} — #{sign == '>' ? 'положително' : 'отрицателно'}, а другият ъгъл, #{(candidates - [ angle ]).map { |a| "#{a}°" }.join}, не става.",
      watch: %w[tg cotg].include?(given_function) ? "#{given_function == "tg" ? "Тангенсът" : "Котангенсът"} е еднакъв в срещуположни квадранти — без второто условие ъглите са два." : "Не спирай на основния ъгъл от първи квадрант: знакът на #{other_function == 'sin' ? 'синуса' : 'косинуса'} решава къде е точката."
    )
  )
end
