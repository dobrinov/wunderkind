# Интерактивни задачи: числова ос, подреждане, дробни ленти.
#
# The widget's solution never reaches the client — the server grades the state
# the student submits (app/services/widgets.rb). Two constraints shape these
# families: the question text has to be unique (the importer keys on it, so the
# numbers go in the stem), and the number line snaps to its step, so the step
# and the answer must agree.

def number_line_widget(min:, max:, step:, value:, tolerance: 0)
  { "widget" => "number_line",
    "params" => { "min" => min, "max" => max, "step" => step },
    "solution" => { "value" => value, "tolerance" => tolerance } }
end

def ordering_widget(items)
  { "widget" => "ordering",
    "params" => { "items" => items.map { |id, label| { "id" => id.to_s, "label" => label.to_s } } },
    "solution" => { "order" => items.map { |id, _| id.to_s } } }
end

def fraction_bars_widget(segments:, shaded:)
  { "widget" => "fraction_bars",
    "params" => { "segments" => segments },
    "solution" => { "shaded" => shaded } }
end

# --------------------------------------------------------------- Числова ос ---

Authoring.family "line.place_integer", topic: "Числа и редици", area: "interactive",
                 rungs: [ 640, 700, 770, 840, 910, 990 ] do |c|
  max = c.by_level([ 10, 20, 50, 100, 200, 1000 ])
  step = c.by_level([ 1, 1, 5, 10, 20, 100 ])
  value = c.int(1..(max / step - 1)) * step

  c.q(
    text: "Постави точката върху числото #{value} на числовата ос.",
    widget: number_line_widget(min: 0, max: max, step: step, value: value),
    explanation: Explain.build(
      idea: "Числовата ос е разграфена на равни части — всяко деление е #{step}.",
      steps: [
        "От 0 до #{max} делението е през #{step}.",
        "#{value} : #{step} = #{value / step}, значи точката е на #{value / step}-то деление след нулата."
      ],
      answer: "точката върху #{value}",
      check: "Съседните деления са #{value - step} и #{value + step} — търсеното число е между тях.",
      watch: "Броят на деленията, не на разстоянията, лесно се обърква — броим от нулата."
    )
  )
end

Authoring.family "line.place_negative", topic: "Числа и редици", area: "interactive",
                 rungs: [ 950, 1030, 1110, 1190, 1280, 1370 ] do |c|
  bound = c.by_level([ 5, 10, 12, 20, 50, 100 ])
  step = c.by_level([ 1, 1, 2, 4, 5, 10 ])
  value = c.int(-bound / step..(bound / step)) * step
  raise Authoring::Duplicate if value >= 0

  c.q(
    text: "Постави точката върху числото #{Num.bg(value)} на числовата ос.",
    widget: number_line_widget(min: -bound, max: bound, step: step, value: value),
    explanation: Explain.build(
      idea: "Отрицателните числа стоят вляво от нулата, а колкото по-голяма е абсолютната стойност, толкова по-наляво.",
      steps: [
        "Тръгваме от 0 и вървим наляво.",
        "#{value.abs} : #{step} = #{count_noun(value.abs / step, 'деление', 'деления')} наляво."
      ],
      answer: "точката върху #{Num.bg(value)}",
      check: "Отсрещното число #{value.abs} е на същото разстояние вдясно от нулата.",
      watch: "#{Num.bg(value)} е по-малко от #{Num.bg(value + step)} — наляво числата намаляват."
    )
  )
end

Authoring.family "line.place_decimal", topic: "Десетични числа", area: "interactive",
                 rungs: [ 980, 1060, 1150, 1240, 1330, 1420 ] do |c|
  # (max - min) / step stays under 40: the widget stops drawing ticks past that
  # and the labels would no longer line up with the step it snaps to.
  spec = c.by_level([ [ 1, 10 ], [ 2, 10 ], [ 2, 10 ], [ 3, 10 ], [ 4, 10 ], [ 8, 5 ] ])
  max, per_unit = spec
  step = Rational(1, per_unit)
  ticks = (max * per_unit)
  value = Rational(c.int(1...ticks), per_unit)
  raise Authoring::Duplicate if value.denominator == 1

  c.q(
    text: "Постави точката върху числото #{Num.dec(value, 2)} на числовата ос.",
    widget: number_line_widget(min: 0, max: max, step: step.to_f, value: value.to_f, tolerance: 0.001),
    explanation: Explain.build(
      idea: "Между две цели числа отсечката е разделена на #{per_unit} равни части — всяка е #{Num.dec(step, 2)}.",
      steps: [
        "Цялата част на #{Num.dec(value, 2)} е #{value.truncate}, значи точката е след #{value.truncate}.",
        "Остават #{Num.dec(value - value.truncate, 2)}, тоест #{((value - value.truncate) * per_unit).to_i} малки деления."
      ],
      answer: "точката върху #{Num.dec(value, 2)}",
      check: "Точката стои между #{value.truncate} и #{value.truncate + 1}, по-близо до #{value - value.truncate >= Rational(1, 2) ? value.truncate + 1 : value.truncate}.",
      watch: "Всяко малко деление е #{Num.dec(step, 2)}, а не 1."
    )
  )
end

Authoring.family "line.place_fraction", topic: "Дроби", area: "interactive",
                 rungs: [ 900, 980, 1070, 1160, 1250, 1340 ] do |c|
  denominator = c.pick(c.by_level([ [ 2, 4 ], [ 3, 4 ], [ 5, 6 ], [ 6, 8 ], [ 8, 10 ], [ 10, 12 ] ]))
  numerator = c.int(1...(denominator * 2))
  raise Authoring::Duplicate if (numerator % denominator).zero?

  value = Rational(numerator, denominator)

  c.q(
    text: "Постави точката върху дробта #{Num.frac(numerator, denominator)} на числовата ос.",
    widget: number_line_widget(min: 0, max: 2, step: (1.0 / denominator).round(4), value: value.to_f, tolerance: 0.01),
    explanation: Explain.build(
      idea: "Знаменателят казва на колко части е разделена всяка единица, числителят — колко от тях се броят.",
      steps: [
        "Отсечката от 0 до 1 е разделена на #{denominator} равни части.",
        "Броим #{numerator} такива части: попадаме на #{Num.mixed(value)}."
      ],
      answer: "точката върху #{Num.frac(value)}",
      check: "#{Num.frac(value)} = #{Num.dec(value, 3)} в десетичен вид.",
      watch: value > 1 ? "Дробта е по-голяма от 1, затова точката е след единицата." : "Дробта е под 1, затова точката е преди единицата."
    )
  )
end

Authoring.family "line.place_sum", topic: "Събиране и изваждане", area: "interactive",
                 rungs: [ 700, 780, 860, 940, 1020, 1110 ] do |c|
  max = c.by_level([ 10, 20, 20, 50, 100, 200 ])
  step = c.by_level([ 1, 1, 2, 5, 10, 20 ])
  result = c.int(2..(max / step - 1)) * step
  first = c.int(1...(result / step)) * step
  second = result - first

  c.q(
    text: "Пресметни #{first} + #{second} и постави точката върху отговора.",
    widget: number_line_widget(min: 0, max: max, step: step, value: result),
    explanation: Explain.build(
      idea: "Събирането по числовата ос е местене надясно: тръгваме от първото число и правим толкова стъпки, колкото е второто.",
      steps: [
        "Започваме на #{first}.",
        "Вървим #{second} надясно: #{first} + #{second} = #{result}."
      ],
      answer: "точката върху #{result}",
      check: "#{result} − #{second} = #{first} — връщаме се обратно.",
      watch: "Точката се поставя върху сбора, а не върху някое от събираемите."
    )
  )
end

Authoring.family "line.place_difference", topic: "Събиране и изваждане", area: "interactive",
                 rungs: [ 760, 840, 920, 1000, 1090, 1180 ] do |c|
  max = c.by_level([ 10, 20, 20, 50, 100, 200 ])
  step = c.by_level([ 1, 1, 2, 5, 10, 20 ])
  minuend = c.int(2..(max / step)) * step
  subtrahend = c.int(1...(minuend / step)) * step
  result = minuend - subtrahend

  c.q(
    text: "Пресметни #{minuend} − #{subtrahend} и постави точката върху отговора.",
    widget: number_line_widget(min: 0, max: max, step: step, value: result),
    explanation: Explain.build(
      idea: "Изваждането по числовата ос е местене наляво.",
      steps: [
        "Започваме на #{minuend}.",
        "Вървим #{subtrahend} наляво: #{minuend} − #{subtrahend} = #{result}."
      ],
      answer: "точката върху #{result}",
      check: "#{result} + #{subtrahend} = #{minuend}.",
      watch: "Посоката е наляво — резултатът е по-малък от #{minuend}."
    )
  )
end

Authoring.family "line.place_midpoint", topic: "Числа и редици", area: "interactive",
                 rungs: [ 880, 960, 1050, 1140, 1230, 1320 ] do |c|
  max = c.by_level([ 20, 20, 50, 100, 200, 1000 ])
  step = c.by_level([ 1, 2, 5, 10, 20, 100 ])
  a = c.int(0..(max / step - 2)) * step
  b = c.int((a / step + 2)..(max / step)) * step
  raise Authoring::Duplicate unless ((a + b) % (2 * step)).zero?

  middle = (a + b) / 2

  c.q(
    text: "Постави точката точно по средата между #{a} и #{b}.",
    widget: number_line_widget(min: 0, max: max, step: step, value: middle),
    explanation: Explain.build(
      idea: "Средата на две числа е средното им аритметично.",
      steps: [
        "#{a} + #{b} = #{a + b}.",
        "#{a + b} : 2 = #{middle}."
      ],
      answer: "точката върху #{middle}",
      check: "#{middle} − #{a} = #{middle - a} и #{b} − #{middle} = #{b - middle} — равни разстояния.",
      watch: "Средата не е половината от по-голямото число."
    )
  )
end

Authoring.family "line.place_percent", topic: "Проценти", area: "interactive",
                 rungs: [ 1030, 1120, 1210, 1300, 1390, 1480 ] do |c|
  # The line snaps to steps of 5, so every asked percentage has to be a
  # multiple of 5 — otherwise the student cannot place the point at all.
  pct = c.pick(c.by_level([ [ 50, 100 ], [ 25, 50, 75 ], [ 10, 20, 30, 40 ],
                            [ 15, 35, 60, 85 ], [ 5, 45, 65, 95 ], [ 55, 65, 80, 90 ] ]))
  base = 100
  value = base * pct / 100

  c.q(
    text: "Постави точката върху #{pct}% от #{base} на числовата ос.",
    widget: number_line_widget(min: 0, max: base, step: 5, value: value, tolerance: 0.001),
    explanation: Explain.build(
      idea: "Процентът е стотна част: #{pct}% значи #{pct} от всеки 100.",
      steps: [
        "1% от #{base} е #{Num.dec(Rational(base, 100), 2)}.",
        "#{pct}% са #{pct} · #{Num.dec(Rational(base, 100), 2)} = #{value}."
      ],
      answer: "точката върху #{value}",
      check: "#{value} : #{base} = #{Num.dec(Rational(value, base), 2)} = #{pct}%.",
      watch: "Върху ос до 100 процентите съвпадат с числата — това не важи за друга крайна стойност."
    )
  )
end

Authoring.family "line.place_rounded", topic: "Числа и редици", area: "interactive",
                 rungs: [ 1000, 1090, 1180, 1270, 1360, 1450 ] do |c|
  unit = c.by_level([ 10, 10, 10, 100, 100, 100 ])
  max = unit * 10
  number = c.int((max / 10)..(max - (max / 10)))
  raise Authoring::Duplicate if (number % unit).zero?

  rest = number % unit
  rounded = rest >= unit / 2 ? number - rest + unit : number - rest

  c.q(
    text: "Закръгли #{number} до най-близките #{unit == 10 ? 'десетици' : 'стотици'} и постави точката върху резултата.",
    widget: number_line_widget(min: 0, max: max, step: unit, value: rounded),
    explanation: Explain.build(
      idea: "Закръгляването избира по-близкото от двете съседни кръгли числа.",
      steps: [
        "#{number} е между #{number - rest} и #{number - rest + unit}.",
        "Разстоянията са #{rest} и #{unit - rest}, значи по-близо е #{rounded}."
      ],
      answer: "точката върху #{rounded}",
      check: "|#{number} − #{rounded}| = #{(number - rounded).abs} ≤ #{unit / 2}.",
      watch: "При точно #{unit / 2} се закръгля нагоре — това е уговорката."
    )
  )
end

Authoring.family "line.place_product", topic: "Умножение и деление", area: "interactive",
                 rungs: [ 800, 880, 960, 1050, 1140, 1230 ] do |c|
  spec = c.by_level([ [ 2..5, 2..4 ], [ 2..9, 2..5 ], [ 3..9, 3..7 ], [ 4..12, 4..8 ], [ 5..20, 5..10 ], [ 8..25, 6..12 ] ])
  a = c.int(spec[0])
  b = c.int(spec[1])
  product = a * b
  step = product > 100 ? 10 : (product > 30 ? 5 : 1)
  raise Authoring::Duplicate unless (product % step).zero?

  max = ((product / step) + c.int(1..4)) * step
  # The widget draws at most 40 ticks; past that its labels stop matching the
  # step it snaps to.
  raise Authoring::Duplicate if max / step > 40

  c.q(
    text: "Пресметни #{a} · #{b} и постави точката върху отговора.",
    widget: number_line_widget(min: 0, max: max, step: step, value: product),
    explanation: Explain.build(
      idea: "Умножението е повторено събиране — по оста това са #{a} равни скока по #{b}.",
      steps: [
        "#{a} · #{b} = #{product}.",
        "По оста: #{a} скока по #{b} стигат до #{product}."
      ],
      answer: "точката върху #{product}",
      check: "#{product} : #{b} = #{a} — обратното действие връща множителя.",
      watch: "Всяко деление по тази ос е #{step}."
    )
  )
end

# -------------------------------------------------------------- Подреждане ---

Authoring.family "sort.integers", topic: "Числа и редици", area: "interactive",
                 rungs: [ 680, 760, 840, 920, 1010, 1100 ] do |c|
  count = c.by_level([ 3, 3, 4, 4, 5, 5 ])
  spec = c.by_level([ 1..20, 5..60, 10..200, 50..900, 100..5000, 1000..99_999 ])
  values = []
  values << c.int(spec) while values.uniq.size < count
  values = values.uniq.first(count)
  descending = c.level >= 2 && c.coin
  sorted = descending ? values.sort.reverse : values.sort

  c.q(
    text: "Подреди числата #{values.join(', ')} от #{descending ? 'най-голямото към най-малкото' : 'най-малкото към най-голямото'}.",
    widget: ordering_widget(sorted.map { |value| [ value, value ] }),
    explanation: Explain.build(
      idea: "Числата с еднакъв брой цифри се сравняват отляво надясно; по-дългото число е по-голямо.",
      steps: [
        "Подредени: #{values.sort.join(' < ')}.",
        "Исканият ред е #{sorted.join(' → ')}."
      ],
      answer: sorted.join(" → "),
      check: "Разликата между крайните е #{values.max - values.min}.",
      watch: descending ? "Редът е низходящ — започва се от най-голямото." : "Редът е възходящ — започва се от най-малкото."
    )
  )
end

Authoring.family "sort.negatives", topic: "Числа и редици", area: "interactive",
                 rungs: [ 1050, 1140, 1230, 1320, 1410, 1500 ] do |c|
  count = c.by_level([ 3, 4, 4, 5, 5, 6 ])
  bound = c.by_level([ 9, 15, 30, 60, 150, 500 ])
  values = []
  values << c.int(-bound..bound) while values.uniq.size < count
  values = values.uniq.first(count)
  raise Authoring::Duplicate if values.none?(&:negative?)

  sorted = values.sort

  c.q(
    text: "Подреди числата #{values.map { |v| Num.bg(v) }.join(', ')} от най-малкото към най-голямото.",
    widget: ordering_widget(sorted.map { |value| [ value, Num.bg(value) ] }),
    explanation: Explain.build(
      idea: "По числовата ос по-малкото стои по-вляво: всички отрицателни са преди нулата, а между тях по-голяма абсолютна стойност значи по-малко число.",
      steps: [
        "Отрицателни: #{values.select(&:negative?).sort.map { |v| Num.bg(v) }.join(', ')}.",
        "Неотрицателни: #{values.reject(&:negative?).sort.join(', ')}.",
        "Общият ред е #{sorted.map { |v| Num.bg(v) }.join(' < ')}."
      ],
      answer: sorted.map { |v| Num.bg(v) }.join(" → "),
      check: "Най-малкото е #{Num.bg(values.min)}, най-голямото — #{Num.bg(values.max)}.",
      watch: "#{Num.bg(-9)} е по-малко от #{Num.bg(-2)}, макар 9 да е повече от 2."
    )
  )
end

Authoring.family "sort.decimals", topic: "Десетични числа", area: "interactive",
                 rungs: [ 960, 1050, 1140, 1230, 1320, 1410 ] do |c|
  count = c.by_level([ 3, 3, 4, 4, 5, 5 ])
  whole = c.int(0..c.by_level([ 2, 5, 9, 20, 50, 200 ]))
  values = []
  count.times do
    places = c.int(1..c.by_level([ 1, 2, 2, 3, 3, 3 ]))
    values << Rational((whole * (10**places)) + c.int(0...(10**places)), 10**places)
  end
  values = values.uniq
  raise Authoring::Duplicate if values.size < count

  sorted = values.sort
  labels = values.to_h { |value| [ value, Num.dec(value, 3) ] }

  c.q(
    text: "Подреди числата #{values.map { |v| labels[v] }.join(', ')} от най-малкото към най-голямото.",
    widget: ordering_widget(sorted.map { |value| [ labels[value], labels[value] ] }),
    explanation: Explain.build(
      idea: "Изравняваме броя знаци след запетаята с нули и сравняваме разред по разред.",
      steps: [
        "С еднакъв брой знаци: #{values.map { |v| Num.dec(v, 3) }.join(', ')}.",
        "Подредени: #{sorted.map { |v| labels[v] }.join(' < ')}."
      ],
      answer: sorted.map { |v| labels[v] }.join(" → "),
      check: "Разликата между най-голямото и най-малкото е #{Num.dec(sorted.last - sorted.first, 3)}.",
      watch: "Повече цифри след запетаята не значи по-голямо число."
    )
  )
end

Authoring.family "sort.fractions", topic: "Дроби", area: "interactive",
                 rungs: [ 1080, 1170, 1260, 1350, 1440, 1530 ] do |c|
  count = c.by_level([ 3, 3, 4, 4, 5, 5 ])
  values = []
  count.times do
    denominator = c.int(c.by_level([ 2..5, 2..6, 2..8, 3..10, 3..12, 4..16 ]))
    values << Rational(c.int(1...denominator), denominator)
  end
  values = values.uniq
  raise Authoring::Duplicate if values.size < count

  sorted = values.sort
  labels = values.to_h { |value| [ value, Num.frac(value) ] }
  common = values.map(&:denominator).reduce { |a, b| Num.lcm(a, b) }

  c.q(
    text: "Подреди дробите #{values.map { |v| labels[v] }.join(', ')} от най-малката към най-голямата.",
    widget: ordering_widget(sorted.map { |value| [ labels[value], labels[value] ] }),
    explanation: Explain.build(
      idea: "Свеждаме дробите до общ знаменател — тогава сравняваме само числителите.",
      steps: [
        "Общ знаменател: #{common}.",
        values.map { |v| "#{labels[v]} = #{(v * common).to_i}/#{common}" }.join(", ") + ".",
        "Подредени: #{sorted.map { |v| labels[v] }.join(' < ')}."
      ],
      answer: sorted.map { |v| labels[v] }.join(" → "),
      check: "В десетичен вид: #{sorted.map { |v| Num.dec(v, 3) }.join(' < ')}.",
      watch: "По-голям знаменател значи по-малки части — не по-голяма дроб."
    )
  )
end

Authoring.family "sort.mixed_forms", topic: "Проценти", area: "interactive",
                 rungs: [ 1250, 1340, 1430, 1520, 1610, 1700 ] do |c|
  pool = [ [ Rational(1, 2), "1/2" ], [ Rational(1, 4), "1/4" ], [ Rational(3, 4), "3/4" ],
           [ Rational(2, 5), "2/5" ], [ Rational(3, 5), "3/5" ], [ Rational(1, 5), "1/5" ],
           [ Rational(35, 100), "0,35" ], [ Rational(6, 10), "0,6" ], [ Rational(12, 100), "0,12" ],
           [ Rational(85, 100), "0,85" ], [ Rational(45, 100), "45%" ], [ Rational(70, 100), "70%" ],
           [ Rational(25, 100), "25%" ], [ Rational(9, 100), "9%" ], [ Rational(8, 10), "0,8" ] ]
  count = c.by_level([ 3, 3, 4, 4, 5, 5 ])
  picked = c.sample(pool, count)
  raise Authoring::Duplicate if picked.map(&:first).uniq.size < count

  sorted = picked.sort_by(&:first)

  c.q(
    text: "Подреди стойностите #{picked.map(&:last).join(', ')} от най-малката към най-голямата.",
    widget: ordering_widget(sorted.map { |_, label| [ label, label ] }),
    explanation: Explain.build(
      idea: "Дроби, десетични числа и проценти се сравняват, след като се сведат до един и същ вид — най-лесно десетичен.",
      steps: [
        picked.map { |value, label| "#{label} = #{Num.dec(value, 3)}" }.join(", ") + ".",
        "Подредени: #{sorted.map(&:last).join(' < ')}."
      ],
      answer: sorted.map(&:last).join(" → "),
      check: "Най-малката е #{sorted.first.last}, а най-голямата — #{sorted.last.last}.",
      watch: "Записът лъже окото: 9% е по-малко от 0,12, макар 9 да изглежда голямо число."
    )
  )
end

Authoring.family "sort.powers", topic: "Степени и корени", area: "interactive",
                 rungs: [ 1330, 1420, 1510, 1600, 1690, 1780 ] do |c|
  pool = [ [ 2, 3 ], [ 3, 2 ], [ 2, 5 ], [ 5, 2 ], [ 2, 4 ], [ 4, 2 ], [ 3, 3 ], [ 2, 6 ],
           [ 6, 2 ], [ 3, 4 ], [ 10, 2 ], [ 2, 7 ], [ 4, 3 ], [ 5, 3 ], [ 7, 2 ] ]
  count = c.by_level([ 3, 3, 4, 4, 5, 5 ])
  picked = c.sample(pool, count)
  values = picked.map { |base, exponent| [ base**exponent, Num.power(base, exponent) ] }
  raise Authoring::Duplicate if values.map(&:first).uniq.size < count

  sorted = values.sort_by(&:first)

  c.q(
    text: "Подреди степените #{values.map(&:last).join(', ')} от най-малката към най-голямата.",
    widget: ordering_widget(sorted.map { |_, label| [ label, label ] }),
    explanation: Explain.build(
      idea: "Степените се сравняват по стойност — пресмятаме всяка и подреждаме.",
      steps: [
        values.map { |value, label| "#{label} = #{value}" }.join(", ") + ".",
        "Подредени: #{sorted.map(&:last).join(' < ')}."
      ],
      answer: sorted.map(&:last).join(" → "),
      check: "Най-малката е #{sorted.first.last} = #{sorted.first.first}, най-голямата — #{sorted.last.last} = #{sorted.last.first}.",
      watch: "Голямата основа не значи голяма степен: сравнете #{values.first.last} и #{values.last.last}."
    )
  )
end

Authoring.family "sort.measures", topic: "Десетични числа", area: "interactive",
                 rungs: [ 1120, 1210, 1300, 1390, 1480, 1570 ] do |c|
  kind = c.by_level([ :length, :length, :mass, :length, :mass, :volume ])
  units = { length: [ [ "мм", 1 ], [ "см", 10 ], [ "дм", 100 ], [ "м", 1000 ] ],
            mass: [ [ "г", 1 ], [ "кг", 1000 ] ],
            volume: [ [ "мл", 1 ], [ "л", 1000 ] ] }.fetch(kind)
  count = c.by_level([ 3, 3, 4, 4, 4, 5 ])
  picked = []
  count.times do
    unit, factor = c.pick(units)
    amount = c.int(1..99)
    picked << [ amount * factor, "#{amount} #{unit}" ]
  end
  raise Authoring::Duplicate if picked.map(&:first).uniq.size < count

  sorted = picked.sort_by(&:first)
  base_unit = units.first.first

  c.q(
    text: "Подреди мерките #{picked.map(&:last).join(', ')} от най-малката към най-голямата.",
    widget: ordering_widget(sorted.map { |_, label| [ label, label ] }),
    explanation: Explain.build(
      idea: "Сравняват се само еднакви мерни единици — превръщаме всичко в #{base_unit}.",
      steps: [
        picked.map { |value, label| "#{label} = #{value} #{base_unit}" }.join(", ") + ".",
        "Подредени: #{sorted.map(&:last).join(' < ')}."
      ],
      answer: sorted.map(&:last).join(" → "),
      check: "Най-малката е #{sorted.first.last}, най-голямата — #{sorted.last.last}.",
      watch: "Числото пред мерната единица не решава: #{picked.max_by(&:last).last} не е задължително най-голямото."
    )
  )
end

Authoring.family "sort.probabilities", topic: "Вероятност", area: "interactive",
                 rungs: [ 1280, 1370, 1460, 1550, 1640, 1730 ] do |c|
  pool = [ [ Rational(1, 6), "1/6" ], [ Rational(1, 2), "1/2" ], [ Rational(1, 3), "1/3" ],
           [ Rational(2, 3), "2/3" ], [ Rational(1, 4), "1/4" ], [ Rational(5, 6), "5/6" ],
           [ Rational(3, 4), "3/4" ], [ Rational(1, 12), "1/12" ], [ Rational(7, 12), "7/12" ],
           [ Rational(11, 12), "11/12" ], [ Rational(2, 5), "2/5" ], [ Rational(3, 8), "3/8" ],
           [ Rational(5, 8), "5/8" ], [ Rational(7, 10), "7/10" ], [ Rational(9, 10), "9/10" ] ]
  count = c.by_level([ 3, 3, 4, 4, 5, 5 ])
  picked = c.sample(pool, count)
  raise Authoring::Duplicate if picked.map(&:first).uniq.size < count

  sorted = picked.sort_by(&:first)

  c.q(
    text: "Подреди вероятностите #{picked.map(&:last).join('; ')} от най-малката към най-голямата.",
    widget: ordering_widget(sorted.map { |_, label| [ label, label ] }),
    explanation: Explain.build(
      idea: "Вероятностите са числа между 0 и 1 — сравняват се като дроби, през общ знаменател или десетичен вид.",
      steps: [
        picked.map { |value, label| "#{label} ≈ #{Num.dec(value, 3)}" }.join(", ") + ".",
        "Подредени: #{sorted.map(&:last).join(' < ')}."
      ],
      answer: sorted.map(&:last).join(" → "),
      check: "Всички стойности са между 0 (невъзможно) и 1 (сигурно).",
      watch: "По-голям знаменател при равен числител значи по-малка вероятност."
    )
  )
end

Authoring.family "sort.solution_steps", topic: "Логически задачи", area: "interactive",
                 rungs: [ 1150, 1240, 1330, 1420, 1510, 1600 ] do |c|
  a = c.int(c.by_level([ 2..5, 2..8, 3..12, 4..20, 5..40, 6..90 ]))
  x = c.int(c.by_level([ 2..8, 2..12, 3..20, 4..40, 5..90, 6..200 ]))
  b = c.int(c.by_level([ 1..10, 2..20, 3..40, 5..80, 8..200, 10..500 ]))
  right = (a * x) + b
  steps = [
    [ "1", "#{a}x + #{b} = #{right}" ],
    [ "2", "#{a}x = #{right} − #{b}" ],
    [ "3", "#{a}x = #{a * x}" ],
    [ "4", "x = #{x}" ]
  ]

  c.q(
    text: "Подреди стъпките от решението на уравнението #{a}x + #{b} = #{right} в правилния ред.",
    widget: ordering_widget(steps),
    explanation: Explain.build(
      idea: "Решаването върви от уравнението към стойността на x: първо се маха свободният член, после се дели на коефициента.",
      steps: [
        "Записваме уравнението: #{a}x + #{b} = #{right}.",
        "Изваждаме #{b} от двете страни: #{a}x = #{right} − #{b} = #{a * x}.",
        "Делим на #{a}: x = #{x}."
      ],
      answer: steps.map(&:last).join(" → "),
      check: "#{a} · #{x} + #{b} = #{right}.",
      watch: "Делението е последно — докато има събираемо отстрани, коефициентът не се маха."
    )
  )
end

# ------------------------------------------------------------ Дробни ленти ---

Authoring.family "bars.shade_fraction", topic: "Дроби", area: "interactive",
                 rungs: [ 780, 860, 940, 1030, 1120, 1210 ] do |c|
  segments = c.pick(c.by_level([ [ 2, 4 ], [ 3, 4 ], [ 5, 6 ], [ 6, 8 ], [ 8, 10 ], [ 9, 12 ] ]))
  shaded = c.int(1...segments)

  c.q(
    text: "Оцвети #{Num.frac(shaded, segments)} от лентата, разделена на #{segments} равни части.",
    widget: fraction_bars_widget(segments: segments, shaded: shaded),
    explanation: Explain.build(
      idea: "Знаменателят е на колко части е разделено цялото, числителят — колко части се оцветяват.",
      steps: [
        "Лентата има #{segments} части.",
        "Оцветяваме #{shaded} от тях."
      ],
      answer: "#{shaded} от #{segments} части",
      check: "Неоцветени остават #{segments - shaded} части, тоест #{Num.frac(segments - shaded, segments)}.",
      watch: "Числителят брои оцветените части, не празните."
    )
  )
end

# Four variants a rung: with at most twelve segments there are only so many
# equivalent fractions to show.
Authoring.family "bars.equivalent", topic: "Дроби", area: "interactive", variants: 4,
                 rungs: [ 1000, 1090, 1180, 1270, 1360, 1450 ] do |c|
  simple_denominator = c.pick(c.by_level([ [ 2 ], [ 2, 3 ], [ 3, 4 ], [ 4, 5 ], [ 3, 5, 6 ], [ 4, 5, 6 ] ]))
  factor = c.int(2..c.by_level([ 2, 3, 3, 2, 2, 2 ]))
  segments = simple_denominator * factor
  raise Authoring::Duplicate if segments > 12

  simple_numerator = c.int(1...simple_denominator)
  shaded = simple_numerator * factor

  c.q(
    text: "Оцвети толкова части от лентата с #{segments} части, колкото прави #{Num.frac(simple_numerator, simple_denominator)}.",
    widget: fraction_bars_widget(segments: segments, shaded: shaded),
    explanation: Explain.build(
      idea: "Равни дроби показват едно и също количество: разширяваме дробта до знаменател #{segments}.",
      steps: [
        "#{segments} : #{simple_denominator} = #{factor}, значи всяка част от #{Num.frac(1, simple_denominator)} се разделя на #{factor}.",
        "#{simple_numerator} · #{factor} = #{shaded} части."
      ],
      answer: "#{shaded} от #{segments} части",
      check: "#{Num.frac(shaded, segments)} = #{Num.frac(simple_numerator, simple_denominator)} след съкращаване.",
      watch: "Числителят и знаменателят се умножават по едно и също число."
    )
  )
end

Authoring.family "bars.shade_percent", topic: "Проценти", area: "interactive",
                 rungs: [ 1040, 1130, 1220, 1310, 1400, 1490 ] do |c|
  segments = c.pick(c.by_level([ [ 10 ], [ 10 ], [ 10, 5 ], [ 4, 5, 10 ], [ 4, 8, 10 ], [ 5, 10, 12 ] ]))
  pct = c.pick((1...segments).map { |i| i * 100 / segments }.select { |value| (value % 1).zero? })
  shaded = segments * pct / 100
  raise Authoring::Duplicate unless (segments * pct % 100).zero?

  c.q(
    text: "Оцвети #{pct}% от лентата, разделена на #{segments} равни части.",
    widget: fraction_bars_widget(segments: segments, shaded: shaded),
    explanation: Explain.build(
      idea: "Процентът се превръща в части: колко от #{segments}-те части правят #{pct}%.",
      steps: [
        "Една част е #{100 / segments}% от лентата.",
        "#{pct} : #{100 / segments} = #{shaded} части."
      ],
      answer: "#{shaded} от #{segments} части",
      check: "#{shaded} : #{segments} = #{Num.dec(Rational(shaded, segments), 2)} = #{pct}%.",
      watch: "100% е цялата лента — #{segments} части, не #{segments} процента."
    )
  )
end

# Fewer variants per rung than most: a bar has at most twelve parts, so the
# family runs out of distinct decimals quickly.
Authoring.family "bars.shade_decimal", topic: "Десетични числа", area: "interactive", variants: 4,
                 rungs: [ 1010, 1100, 1190, 1280, 1370, 1460 ] do |c|
  segments = c.pick(c.by_level([ [ 10 ], [ 5, 10 ], [ 4, 10 ], [ 4, 8 ], [ 8, 10 ], [ 4, 8, 10 ] ]))
  shaded = c.int(1...segments)
  value = Rational(shaded, segments)
  raise Authoring::Duplicate unless Num.terminating?(value, 3)

  c.q(
    text: "Оцвети #{Num.dec(value, 3)} от лентата, разделена на #{segments} равни части.",
    widget: fraction_bars_widget(segments: segments, shaded: shaded),
    explanation: Explain.build(
      idea: "Десетичното число показва каква част от цялото се оцветява.",
      steps: [
        "Една част е #{Num.dec(Rational(1, segments), 3)} от лентата.",
        "#{Num.dec(value, 3)} : #{Num.dec(Rational(1, segments), 3)} = #{shaded} части."
      ],
      answer: "#{shaded} от #{segments} части",
      check: "#{shaded}/#{segments} = #{Num.dec(value, 3)}.",
      watch: "0,5 е половината лента, независимо на колко части е разделена."
    )
  )
end

Authoring.family "bars.remaining", topic: "Дроби", area: "interactive",
                 rungs: [ 1090, 1180, 1270, 1360, 1450, 1540 ] do |c|
  segments = c.pick(c.by_level([ [ 4 ], [ 4, 5 ], [ 5, 6 ], [ 6, 8 ], [ 8, 10 ], [ 10, 12 ] ]))
  eaten = c.int(1...segments)
  left = segments - eaten

  c.q(
    text: "От шоколад с #{segments} парчета са изядени #{Num.frac(eaten, segments)}. " \
          "Оцвети частта, която остава.",
    widget: fraction_bars_widget(segments: segments, shaded: left),
    explanation: Explain.build(
      idea: "Цялото е 1; остатъкът е 1 минус изядената част.",
      steps: [
        "Изядени: #{eaten} от #{segments} части.",
        "Остават #{segments} − #{eaten} = #{left} части, тоест #{Num.frac(left, segments)}."
      ],
      answer: "#{left} от #{segments} части",
      check: "#{Num.frac(eaten, segments)} + #{Num.frac(left, segments)} = 1.",
      watch: "Оцветява се остатъкът, не изядената част."
    )
  )
end

Authoring.family "bars.sum_of_fractions", topic: "Дроби", area: "interactive",
                 rungs: [ 1130, 1220, 1310, 1400, 1490, 1580 ] do |c|
  segments = c.pick(c.by_level([ [ 4 ], [ 4, 6 ], [ 6, 8 ], [ 8, 9 ], [ 9, 10 ], [ 10, 12 ] ]))
  first = c.int(1...segments)
  second = c.int(1...(segments - first + 1))
  total = first + second
  raise Authoring::Duplicate if total > segments

  c.q(
    text: "Пресметни #{Num.frac(first, segments)} + #{Num.frac(second, segments)} и оцвети резултата " \
          "върху лентата с #{segments} части.",
    widget: fraction_bars_widget(segments: segments, shaded: total),
    explanation: Explain.build(
      idea: "При равни знаменатели се събират само числителите — частите са еднакви по големина.",
      steps: [
        "#{first} части + #{second} части = #{total} части.",
        "#{Num.frac(first, segments)} + #{Num.frac(second, segments)} = #{Num.frac(total, segments)}#{Rational(total, segments) == Rational(total, segments).round ? '' : " = #{Num.frac(Rational(total, segments))} след съкращаване"}."
      ],
      answer: "#{total} от #{segments} части",
      check: "Остават #{segments - total} части до цялото.",
      watch: "Знаменателят остава #{segments} — той не се събира."
    )
  )
end

Authoring.family "bars.of_amount", topic: "Дроби", area: "interactive",
                 rungs: [ 1160, 1250, 1340, 1430, 1520, 1610 ] do |c|
  segments = c.pick(c.by_level([ [ 4 ], [ 4, 5 ], [ 5, 6 ], [ 6, 8 ], [ 8, 10 ], [ 10, 12 ] ]))
  shaded = c.int(1...segments)
  unit = c.int(c.by_level([ 2..6, 2..10, 3..15, 4..25, 5..50, 6..100 ]))
  total = segments * unit
  part = shaded * unit

  c.q(
    text: "Лентата представя #{total} лв. Оцвети частта, която струва #{part} лв.",
    widget: fraction_bars_widget(segments: segments, shaded: shaded),
    explanation: Explain.build(
      idea: "Всяка част от лентата струва еднакво — намираме колко и броим нужните части.",
      steps: [
        "Една част: #{total} : #{segments} = #{unit} лв.",
        "#{part} : #{unit} = #{shaded} части."
      ],
      answer: "#{shaded} от #{segments} части",
      check: "#{shaded} · #{unit} = #{part} лв., а цялата лента е #{total} лв.",
      watch: "Първо се намира стойността на една част — иначе броенето е наслуки."
    )
  )
end
