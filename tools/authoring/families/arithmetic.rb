# Аритметика: събиране и изваждане, умножение и деление, ред на действията.
#
# The fact tables (db/seeds/arithmetic_facts.yml) already drill "Колко е a + b?"
# thousands of times, so nothing here is a bare fact: these are the contexts,
# the written algorithms and the multi-step problems that the facts are for.

# --------------------------------------------------- Събиране и изваждане ---

Authoring.family "add.change", topic: "Събиране и изваждане", area: "arithmetic",
                 rungs: [ 660, 730, 810, 890, 970, 1060 ] do |c|
  spec = c.by_level([
    { purse: 10..20, count: 1, cents: false },
    { purse: 20..50, count: 1, cents: false },
    { purse: 40..100, count: 2, cents: false },
    { purse: 20..60, count: 2, cents: true },
    { purse: 60..150, count: 3, cents: true },
    { purse: 100..300, count: 4, cents: true }
  ])
  who = c.person
  item, band = c.goods
  price = c.int(band)
  price = Rational((price * 100) + c.pick([ 20, 50, 80, 90, 40, 60 ]), 100) if spec[:cents]
  count = spec[:count]
  total = price * count
  purse = c.int(spec[:purse])
  raise Authoring::Duplicate if purse <= total

  left = purse - total

  c.q(
    text: (count == 1 ? "#{who} има #{Num.money(purse)} и купува #{item.one} за #{Num.money(price)}. " :
                        "#{who} има #{Num.money(purse)} и купува #{item.count(count)} по #{Num.money(price)}. ") +
          "Колко лева остават след покупката?",
    answer: Num.dec2(left),
    explanation: Explain.build(
      idea: "Първо намираме колко струва цялата покупка, после изваждаме от парите.",
      steps: [
        count == 1 ? "Покупката струва #{Num.money(price)}." : "Покупката струва #{count} · #{Num.money(price)} = #{Num.money(total)}.",
        "Остават #{Num.money(purse)} − #{Num.money(total)} = #{Num.money(left)}."
      ],
      answer: Num.money(left),
      check: "#{Num.money(total)} + #{Num.money(left)} = #{Num.money(purse)} — толкова, колкото са били парите.",
      watch: count > 1 ? "Цената е за един #{item.one}, не за всички — умножи, преди да извадиш." : nil
    )
  )
end

Authoring.family "add.column_carry", topic: "Събиране и изваждане", area: "arithmetic",
                 rungs: [ 690, 760, 830, 900, 980, 1070 ] do |c|
  spec = c.by_level([
    { range: 11..44, carry: false }, { range: 15..79, carry: true },
    { range: 120..449, carry: true }, { range: 250..899, carry: true },
    { range: 1200..4999, carry: true }, { range: 2500..8999, carry: true }
  ])
  a = c.int(spec[:range])
  b = c.int(spec[:range])
  raise Authoring::Duplicate if spec[:carry] && ((a % 10) + (b % 10) < 10)
  raise Authoring::Duplicate if !spec[:carry] && ((a % 10) + (b % 10) >= 10)

  sum = a + b
  units = (a % 10) + (b % 10)
  tens = ((a / 10) % 10) + ((b / 10) % 10) + (units >= 10 ? 1 : 0)

  c.q(
    text: "Пресметни: #{a} + #{b}.",
    answer: Num.ans(sum),
    explanation: Explain.build(
      idea: "Събираме отделно единиците, десетиците и по-нагоре, като пренасяме наум.",
      steps: [
        "Единици: #{a % 10} + #{b % 10} = #{units}#{units >= 10 ? " — пишем #{units % 10}, наум 1" : ''}.",
        "Десетици: #{(a / 10) % 10} + #{(b / 10) % 10}#{units >= 10 ? ' + 1 (наум)' : ''} = #{tens}#{tens >= 10 ? " — пишем #{tens % 10}, наум 1" : ''}.",
        a >= 100 ? "Продължаваме така до най-старшия разред: #{a} + #{b} = #{sum}." : "Сборът е #{sum}."
      ].compact,
      answer: Num.ans(sum),
      check: "#{sum} − #{b} = #{a} — връщаме се на първото събираемо.",
      watch: spec[:carry] ? "Пренесената единица се събира със следващия разред — лесно се забравя." : nil
    )
  )
end

Authoring.family "sub.column_borrow", topic: "Събиране и изваждане", area: "arithmetic",
                 rungs: [ 700, 780, 860, 930, 1010, 1090 ] do |c|
  spec = c.by_level([
    { range: 25..69, borrow: false }, { range: 22..95, borrow: true },
    { range: 130..480, borrow: true }, { range: 300..900, borrow: true },
    { range: 1300..4800, borrow: true }, { range: 3000..9000, borrow: true }
  ])
  a = c.int(spec[:range])
  b = c.int((spec[:range].min / 3)..(a - 10))
  raise Authoring::Duplicate if spec[:borrow] && (a % 10) >= (b % 10)
  raise Authoring::Duplicate if !spec[:borrow] && (a % 10) < (b % 10)

  difference = a - b

  c.q(
    text: "Пресметни: #{a} − #{b}.",
    answer: Num.ans(difference),
    explanation: Explain.build(
      idea: "Изваждаме разред по разред. Ако горната цифра е по-малка, заемаме една десетица.",
      steps: [
        spec[:borrow] ? "Единици: #{a % 10} е по-малко от #{b % 10}, затова заемаме: #{(a % 10) + 10} − #{b % 10} = #{((a % 10) + 10) - (b % 10)}." :
                        "Единици: #{a % 10} − #{b % 10} = #{(a % 10) - (b % 10)}.",
        "Продължаваме със следващите разреди и получаваме #{difference}."
      ],
      answer: Num.ans(difference),
      check: "#{difference} + #{b} = #{a} — сборът връща умалямото.",
      watch: spec[:borrow] ? "След заемане съседният разред намалява с 1." : nil
    )
  )
end

Authoring.family "add.missing_number", topic: "Събиране и изваждане", area: "arithmetic",
                 rungs: [ 700, 780, 860, 940, 1020, 1110 ] do |c|
  spec = c.by_level([ 5..20, 20..90, 80..400, 200..900, 1000..5000, 2000..9000 ])
  total = c.int(spec)
  part = c.int((total / 5)..(total - 2))
  missing = total - part
  reversed = c.coin

  c.q(
    text: reversed ? "Намери числото, което липсва: ☐ + #{part} = #{total}." :
                     "Намери числото, което липсва: #{part} + ☐ = #{total}.",
    answer: Num.ans(missing),
    explanation: Explain.build(
      idea: "Липсващото събираемо се намира с изваждане: цялото минус известната част.",
      steps: [
        "Цялото е #{total}, известната част е #{part}.",
        "#{total} − #{part} = #{missing}."
      ],
      answer: Num.ans(missing),
      check: "#{part} + #{missing} = #{total} — равенството е вярно.",
      watch: "Тук не се събира, а се изважда — знакът в записа лъже окото."
    )
  )
end

Authoring.family "add.two_step_story", topic: "Събиране и изваждане", area: "arithmetic",
                 rungs: [ 740, 820, 900, 980, 1060, 1150 ] do |c|
  spec = c.by_level([ 6..20, 15..60, 40..150, 100..400, 250..900, 600..2500 ])
  who = c.person
  item = c.thing
  start = c.int(spec)
  given = c.int(2..[ start - 1, 2 ].max)
  raise Authoring::Duplicate if given >= start
  found = c.int(2..(spec.max / 2))
  result = start - given + found

  c.q(
    text: "#{who} има #{item.count(start)}. Подарява #{item.count(given)}, а после получава още #{item.count(found)}. " \
          "Колко #{item.many} има накрая?",
    answer: Num.ans(result),
    explanation: Explain.build(
      idea: "Проследяваме промените една след друга: първо намаляване, после увеличаване.",
      steps: [
        "След подаръка: #{start} − #{given} = #{start - given}.",
        "След полученото: #{start - given} + #{found} = #{result}."
      ],
      answer: "#{item.count(result)}",
      check: "Обратно: #{result} − #{found} + #{given} = #{start} — връщаме се към началото.",
      watch: "Двете промени са в различни посоки — не бива да се събират наведнъж."
    )
  )
end

Authoring.family "add.compare_difference", topic: "Събиране и изваждане", area: "arithmetic",
                 rungs: [ 700, 770, 850, 930, 1010, 1100 ] do |c|
  spec = c.by_level([ 5..20, 12..60, 30..150, 90..400, 200..900, 500..3000 ])
  first, second = c.people(2)
  item = c.thing
  more = c.int(spec)
  less = c.int(1..(more - 1))
  difference = more - less

  c.q(
    text: "#{first} събира #{item.count(more)}, а #{second} — #{item.count(less)}. " \
          "С колко #{item.many} #{first} има повече от #{second}?",
    answer: Num.ans(difference),
    explanation: Explain.build(
      idea: "„С колко повече“ значи разлика, а разликата се намира с изваждане.",
      steps: [
        "По-голямото число е #{more}, по-малкото е #{less}.",
        "#{more} − #{less} = #{difference}."
      ],
      answer: "с #{item.count(difference)} повече",
      check: "#{less} + #{difference} = #{more} — точно толкова липсват на #{second}.",
      watch: "Въпросът е за разликата, не за общия брой — общият брой би бил #{more + less}."
    )
  )
end

Authoring.family "add.three_numbers", topic: "Събиране и изваждане", area: "arithmetic",
                 rungs: [ 720, 800, 880, 960, 1040, 1130 ] do |c|
  spec = c.by_level([ 2..9, 5..25, 15..60, 40..180, 120..600, 400..2000 ])
  a = c.int(spec)
  b = c.int(spec)
  d = c.int(spec)
  friendly = [ [ a, b ], [ a, d ], [ b, d ] ].find { |x, y| ((x + y) % 10).zero? }
  total = a + b + d

  c.q(
    text: "Пресметни по удобен начин: #{a} + #{b} + #{d}.",
    answer: Num.ans(total),
    explanation: Explain.build(
      idea: "Събирането е разместимо: подреждаме числата така, че първо да се получи кръгло число.",
      steps: [
        friendly ? "#{friendly[0]} + #{friendly[1]} = #{friendly.sum} — кръгло число, с него се работи лесно." :
                   "Събираме отляво надясно: #{a} + #{b} = #{a + b}.",
        friendly ? "Остава да добавим третото число: #{friendly.sum} + #{total - friendly.sum} = #{total}." :
                   "#{a + b} + #{d} = #{total}."
      ],
      answer: Num.ans(total),
      check: "Съберете в друг ред — сборът трябва да излезе същият: #{total}.",
      watch: "Разместването е позволено при събиране, но не при изваждане."
    )
  )
end

Authoring.family "add.estimate", topic: "Събиране и изваждане", area: "arithmetic",
                 rungs: [ 780, 860, 940, 1020, 1100, 1190 ] do |c|
  spec = c.by_level([
    { range: 12..88, unit: 10 }, { range: 105..890, unit: 10 },
    { range: 120..880, unit: 100 }, { range: 1100..8800, unit: 100 },
    { range: 1200..8800, unit: 1000 }, { range: 12_000..88_000, unit: 1000 }
  ])
  unit = spec[:unit]
  a = c.int(spec[:range])
  b = c.int(spec[:range])
  round = ->(n) { ((n + (unit / 2)) / unit) * unit }
  estimate = round.call(a) + round.call(b)
  exact = a + b

  c.q(
    text: "Пресметни приблизително #{a} + #{b}, като закръглиш до #{unit == 10 ? 'десетици' : unit == 100 ? 'стотици' : 'хиляди'}.",
    answer: Num.ans(estimate),
    explanation: Explain.build(
      idea: "Закръгляме всяко събираемо поотделно, после събираме закръглените числа.",
      steps: [
        "#{a} се закръгля до #{round.call(a)}, защото гледаме следващата по-малка цифра.",
        "#{b} се закръгля до #{round.call(b)}.",
        "#{round.call(a)} + #{round.call(b)} = #{estimate}."
      ],
      answer: Num.ans(estimate),
      check: "Точният сбор е #{exact} — приблизителният е близо до него, разликата е #{(exact - estimate).abs}.",
      watch: "Приблизителната стойност не е точният сбор; тук се иска именно закръгленият резултат."
    )
  )
end

Authoring.family "add.duration", topic: "Събиране и изваждане", area: "arithmetic",
                 rungs: [ 800, 880, 960, 1040, 1130, 1220 ] do |c|
  spec = c.by_level([
    { minutes: 10..40, cross: false }, { minutes: 20..55, cross: false },
    { minutes: 25..90, cross: true }, { minutes: 40..150, cross: true },
    { minutes: 70..180, cross: true }, { minutes: 95..240, cross: true }
  ])
  hour = c.int(7..19)
  minute = c.pick([ 0, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50 ])
  length = c.int(spec[:minutes])
  total = (hour * 60) + minute + length
  raise Authoring::Duplicate if total >= 24 * 60
  raise Authoring::Duplicate if spec[:cross] && (minute + length) < 60

  end_hour = total / 60
  end_minute = total % 60
  answer = format("%d:%02d", end_hour, end_minute)
  # The distractors are the two standard slips: forgetting to carry into the
  # hour, and carrying twice. A time is not a number ExactValue can parse, so
  # this family is multiple choice rather than a typed answer.
  # The "no carry" slip only looks like a clock reading while the minutes stay
  # under 100; past that the option gives itself away.
  no_carry = minute + length < 100 ? format("%d:%02d", hour, minute + length) : format("%d:%02d", end_hour, (end_minute + 10) % 60)
  extra_hour = format("%d:%02d", end_hour + 1, end_minute)
  same_minutes = format("%d:%02d", end_hour, minute)

  c.q(
    text: "Филм започва в #{format('%d:%02d', hour, minute)} ч и продължава #{length} минути. " \
          "В колко часа свършва?",
    options: c.options(answer, no_carry, extra_hour, same_minutes),
    answer: answer,
    explanation: Explain.build(
      idea: "Добавяме минутите към началния час; всеки пълен час е 60 минути.",
      steps: [
        "#{minute} + #{length} = #{minute + length} минути.",
        (minute + length) >= 60 ? "#{minute + length} минути са #{(minute + length) / 60} ч и #{(minute + length) % 60} мин." : "Минутите не стигат до цял час.",
        "Часът става #{hour} + #{(minute + length) / 60} = #{end_hour}, а минутите — #{end_minute}."
      ],
      answer: "#{answer} ч",
      check: "От #{answer} назад #{length} минути се връщаме в #{format('%d:%02d', hour, minute)}.",
      watch: "Часът има 60 минути, не 100 — затова 1:70 се записва като 2:10."
    )
  )
end

Authoring.family "add.units_length", topic: "Събиране и изваждане", area: "arithmetic",
                 rungs: [ 820, 900, 980, 1060, 1150, 1240 ] do |c|
  spec = c.by_level([
    { unit: [ "м", "см", 100 ], big: 1..5, small: 10..90 },
    { unit: [ "м", "см", 100 ], big: 2..9, small: 15..95 },
    { unit: [ "кг", "г", 1000 ], big: 1..6, small: 100..900 },
    { unit: [ "км", "м", 1000 ], big: 2..12, small: 150..950 },
    { unit: [ "кг", "г", 1000 ], big: 3..25, small: 250..980 },
    { unit: [ "км", "м", 1000 ], big: 5..48, small: 120..990 }
  ])
  big_unit, small_unit, factor = spec[:unit]
  a_big = c.int(spec[:big])
  a_small = c.int(spec[:small])
  b_small = c.int(spec[:small])
  total_small = (a_big * factor) + a_small + b_small

  c.q(
    text: "Колко #{small_unit} са #{a_big} #{big_unit} #{a_small} #{small_unit} и още #{b_small} #{small_unit}?",
    answer: Num.ans(total_small),
    explanation: Explain.build(
      idea: "Първо превръщаме всичко в по-малката мерна единица, после събираме.",
      steps: [
        "1 #{big_unit} = #{factor} #{small_unit}, затова #{a_big} #{big_unit} = #{a_big * factor} #{small_unit}.",
        "#{a_big * factor} + #{a_small} = #{(a_big * factor) + a_small} #{small_unit}.",
        "#{(a_big * factor) + a_small} + #{b_small} = #{total_small} #{small_unit}."
      ],
      answer: "#{total_small} #{small_unit}",
      check: "#{total_small} #{small_unit} са #{total_small / factor} #{big_unit} и #{total_small % factor} #{small_unit}.",
      watch: "Не се събират числа с различни мерни единици — първо се изравняват."
    )
  )
end

Authoring.family "add.pyramid", topic: "Събиране и изваждане", area: "arithmetic",
                 rungs: [ 760, 840, 920, 1000, 1080, 1170 ] do |c|
  spec = c.by_level([ 1..9, 3..15, 5..30, 10..60, 20..150, 50..400 ])
  a = c.int(spec)
  b = c.int(spec)
  d = c.int(spec)
  top = a + (2 * b) + d

  c.q(
    text: "В сборна пирамида всяко квадратче е сборът на двете под него. " \
          "На долния ред стоят #{a}, #{b} и #{d}. Кое число застава най-горе?",
    answer: Num.ans(top),
    explanation: Explain.build(
      idea: "Изкачваме се ред по ред: първо средният ред, после върхът.",
      steps: [
        "Среден ред: #{a} + #{b} = #{a + b} и #{b} + #{d} = #{b + d}.",
        "Връх: #{a + b} + #{b + d} = #{top}."
      ],
      answer: Num.ans(top),
      check: "Средното число участва два пъти: #{a} + 2 · #{b} + #{d} = #{top}.",
      watch: "Средното число влиза и в двата сбора на средния ред — затова се брои двойно."
    )
  )
end

Authoring.family "sub.temperature", topic: "Събиране и изваждане", area: "arithmetic",
                 rungs: [ 900, 980, 1060, 1140, 1230, 1320 ] do |c|
  spec = c.by_level([
    { start: 1..12, drop: 2..10 }, { start: 2..15, drop: 5..18 },
    { start: -5..8, drop: 4..15 }, { start: -8..10, drop: 6..22 },
    { start: -12..12, drop: 8..30 }, { start: -20..15, drop: 10..40 }
  ])
  start = c.int(spec[:start])
  drop = c.int(spec[:drop])
  result = start - drop

  c.q(
    text: "Вечерта температурата е #{Num.bg(start)}°C. През нощта пада с #{drop} градуса. " \
          "Колко градуса показва термометърът сутринта?",
    answer: Num.ans(result),
    explanation: Explain.build(
      idea: "Спадането на температурата е изваждане; по числовата ос се движим наляво.",
      steps: [
        "Тръгваме от #{Num.bg(start)} и вървим #{drop} наляво.",
        start >= 0 && result < 0 ? "Първо стигаме до 0 (#{start} градуса), остават още #{drop - start} градуса под нулата." : "#{Num.bg(start)} − #{drop} = #{Num.bg(result)}.",
        "Резултатът е #{Num.bg(result)}°C."
      ],
      answer: "#{Num.bg(result)}°C",
      check: "Сутрин #{Num.bg(result)} плюс спадналите #{drop} градуса дава пак #{Num.bg(start)}.",
      watch: result.negative? ? "Под нулата числата растат наопаки: −8°C е по-студено от −3°C." : nil
    )
  )
end

# ----------------------------------------------------- Умножение и деление ---

Authoring.family "mul.equal_groups", topic: "Умножение и деление", area: "arithmetic",
                 rungs: [ 700, 780, 860, 950, 1040, 1140 ] do |c|
  spec = c.by_level([ [ 2..5, 2..6 ], [ 3..9, 3..9 ], [ 4..12, 5..12 ], [ 6..20, 7..15 ],
                      [ 12..40, 8..25 ], [ 25..90, 12..40 ] ])
  groups = c.int(spec[0])
  per = c.int(spec[1])
  box = c.container
  item = c.thing
  total = groups * per

  c.q(
    text: "Във всяка от #{box.count(groups)} има по #{item.count(per)}. Колко #{item.many} има всичко?",
    answer: Num.ans(total),
    explanation: Explain.build(
      idea: "Равни групи се събират най-бързо с умножение: брой групи по брой в група.",
      steps: [
        "#{groups} групи по #{per} значи #{groups} · #{per}.",
        "#{groups} · #{per} = #{total}."
      ],
      answer: "#{item.count(total)}",
      check: "#{total} : #{groups} = #{per} — толкова, колкото са в една #{box.one}.",
      watch: "Числата не се събират (#{groups} + #{per} = #{groups + per}) — групите се повтарят."
    )
  )
end

Authoring.family "mul.price_total", topic: "Умножение и деление", area: "arithmetic",
                 rungs: [ 740, 820, 900, 990, 1080, 1180 ] do |c|
  spec = c.by_level([ 2..5, 3..8, 4..12, 6..15, 8..24, 12..40 ])
  who = c.person
  item, band = c.goods
  count = c.int(spec)
  price = c.int(band)
  price = Rational((price * 100) + c.pick([ 50, 20, 80 ]), 100) if c.level >= 3
  total = price * count

  c.q(
    text: "#{who} купува #{item.count(count)} по #{Num.money(price)}. Колко лева струва цялата покупка?",
    answer: Num.dec2(total),
    explanation: Explain.build(
      idea: "Цена на един брой, умножена по броя — това е общата сума.",
      steps: [
        "#{count} · #{Num.money(price)}",
        price.is_a?(Rational) && price.denominator != 1 ?
          "Умножаваме поотделно: #{count} · #{price.truncate} = #{count * price.truncate} лв. и #{count} · #{Num.dec2(price - price.truncate)} = #{Num.dec2(count * (price - price.truncate))} лв." :
          "#{count} · #{price} = #{total}",
        "Общо: #{Num.money(total)}."
      ],
      answer: Num.money(total),
      check: "#{Num.money(total)} : #{count} = #{Num.money(price)} — връщаме се към единичната цена.",
      watch: "Цената #{Num.money(price)} е за един брой — общата сума расте толкова пъти, колкото са броевете."
    )
  )
end

Authoring.family "div.share_remainder", topic: "Умножение и деление", area: "arithmetic",
                 rungs: [ 760, 850, 930, 1020, 1110, 1210 ] do |c|
  spec = c.by_level([ [ 7..20, 2..4 ], [ 15..40, 3..6 ], [ 25..80, 4..8 ],
                      [ 60..150, 5..12 ], [ 120..400, 7..15 ], [ 300..900, 8..24 ] ])
  total = c.int(spec[0])
  people = c.int(spec[1])
  each = total / people
  rest = total % people
  raise Authoring::Duplicate if each.zero?

  item = c.thing

  c.q(
    text: "#{item.count(total)} се разделят по равно между #{people} деца. " \
          "По колко получава всяко дете и колко остават неразделени?" \
          " (Запиши отговора като брой за едно дете.)",
    answer: Num.ans(each),
    explanation: Explain.build(
      idea: "Делим на равни части: колко пъти #{people} се съдържа в #{total}.",
      steps: [
        "#{total} : #{people} = #{each}#{rest.zero? ? '' : " и остатък #{rest}"}.",
        "Всяко дете получава по #{each}#{rest.zero? ? ", без остатък" : ", а #{rest} остават неразделени"}."
      ],
      answer: "по #{item.count(each)}#{rest.zero? ? '' : ", остават #{rest}"}",
      check: "#{people} · #{each}#{rest.zero? ? '' : " + #{rest}"} = #{total}.",
      watch: rest.zero? ? "Тук делението е точно — остатъкът е 0." : "Остатъкът винаги е по-малък от делителя: #{rest} < #{people}."
    )
  )
end

Authoring.family "mul.long_single", topic: "Умножение и деление", area: "arithmetic",
                 rungs: [ 780, 860, 940, 1030, 1120, 1220 ] do |c|
  spec = c.by_level([ [ 12..40, 2..4 ], [ 23..99, 3..6 ], [ 104..480, 3..7 ],
                      [ 235..980, 4..9 ], [ 1200..4800, 4..9 ], [ 2500..9800, 6..9 ] ])
  a = c.int(spec[0])
  b = c.int(spec[1])
  total = a * b
  units = (a % 10) * b
  tens = ((a / 10) % 10) * b

  c.q(
    text: "Пресметни: #{a} · #{b}.",
    answer: Num.ans(total),
    explanation: Explain.build(
      idea: "Умножаваме всеки разред на #{a} по #{b} и пренасяме наум.",
      steps: [
        "Единици: #{a % 10} · #{b} = #{units}#{units >= 10 ? " — пишем #{units % 10}, наум #{units / 10}" : ''}.",
        "Десетици: #{(a / 10) % 10} · #{b} = #{tens}#{units >= 10 ? " и +#{units / 10} наум = #{tens + (units / 10)}" : ''}.",
        a >= 100 ? "Продължаваме с останалите разреди: #{a} · #{b} = #{total}." : "Резултатът е #{total}."
      ],
      answer: Num.ans(total),
      check: "#{total} : #{b} = #{a} — делението връща първия множител.",
      watch: "Разложете иначе: #{a} · #{b} = #{a} · #{b - 1} + #{a} = #{a * (b - 1)} + #{a} = #{total}."
    )
  )
end

Authoring.family "mul.long_double", topic: "Умножение и деление", area: "arithmetic",
                 rungs: [ 900, 980, 1060, 1150, 1240, 1340 ] do |c|
  spec = c.by_level([ [ 11..25, 11..19 ], [ 14..40, 12..25 ], [ 21..60, 14..32 ],
                      [ 32..90, 18..45 ], [ 105..480, 12..40 ], [ 210..980, 21..75 ] ])
  a = c.int(spec[0])
  b = c.int(spec[1])
  tens = (b / 10) * 10
  ones = b % 10
  raise Authoring::Duplicate if ones.zero?

  total = a * b

  c.q(
    text: "Пресметни: #{a} · #{b}.",
    answer: Num.ans(total),
    explanation: Explain.build(
      idea: "Разлагаме втория множител на десетици и единици — така се получават два лесни продукта.",
      steps: [
        "#{b} = #{tens} + #{ones}.",
        "#{a} · #{tens} = #{a * tens}.",
        "#{a} · #{ones} = #{a * ones}.",
        "Събираме: #{a * tens} + #{a * ones} = #{total}."
      ],
      answer: Num.ans(total),
      check: "Приблизително #{a} · #{b} ≈ #{(a.to_f / 10).round * 10} · #{(b.to_f / 10).round * 10} = #{(a.to_f / 10).round * 10 * ((b.to_f / 10).round * 10)} — резултатът #{total} е в този порядък.",
      watch: "При умножение с десетици нулата не се губи: #{a} · #{tens} е #{a * (tens / 10)} и една нула."
    )
  )
end

Authoring.family "div.long", topic: "Умножение и деление", area: "arithmetic",
                 rungs: [ 820, 900, 990, 1080, 1170, 1270 ] do |c|
  spec = c.by_level([ [ 2..9, 4..12 ], [ 3..9, 8..30 ], [ 4..9, 20..60 ],
                      [ 6..12, 40..120 ], [ 7..19, 80..400 ], [ 12..32, 150..900 ] ])
  divisor = c.int(spec[0])
  quotient = c.int(spec[1])
  dividend = divisor * quotient

  c.q(
    text: "Пресметни: #{dividend} : #{divisor}.",
    answer: Num.ans(quotient),
    explanation: Explain.build(
      idea: "Търсим числото, което умножено по #{divisor} дава #{dividend}.",
      steps: [
        "Колко пъти #{divisor} се съдържа в #{dividend}?",
        quotient >= 10 ? "Първо в десетиците: #{divisor} · #{(quotient / 10) * 10} = #{divisor * (quotient / 10) * 10}, остават #{dividend - (divisor * (quotient / 10) * 10)}." : "#{divisor} · #{quotient} = #{dividend}.",
        if quotient < 10
          "Частното е #{quotient}."
        elsif (quotient % 10).zero?
          "Не остава нищо за деление, затова частното е #{quotient}."
        else
          "После: #{dividend - (divisor * (quotient / 10) * 10)} : #{divisor} = #{quotient % 10}. Частното е #{quotient}."
        end
      ],
      answer: Num.ans(quotient),
      check: "#{divisor} · #{quotient} = #{dividend} — умножението потвърждава делението.",
      watch: "Делението не е разместимо: #{dividend} : #{divisor} и #{divisor} : #{dividend} са различни."
    )
  )
end

Authoring.family "div.missing_factor", topic: "Умножение и деление", area: "arithmetic",
                 rungs: [ 780, 860, 940, 1030, 1120, 1220 ] do |c|
  spec = c.by_level([ [ 2..9, 2..9 ], [ 3..9, 4..12 ], [ 4..12, 6..20 ],
                      [ 6..15, 8..40 ], [ 7..25, 12..80 ], [ 12..40, 20..150 ] ])
  known = c.int(spec[0])
  missing = c.int(spec[1])
  product = known * missing
  reversed = c.coin

  c.q(
    text: reversed ? "Намери числото, което липсва: ☐ · #{known} = #{product}." :
                     "Намери числото, което липсва: #{known} · ☐ = #{product}.",
    answer: Num.ans(missing),
    explanation: Explain.build(
      idea: "Липсващият множител се намира с деление: произведението, разделено на известния множител.",
      steps: [
        "#{product} : #{known} = #{missing}."
      ],
      answer: Num.ans(missing),
      check: "#{known} · #{missing} = #{product} — равенството е изпълнено.",
      watch: "Умножението и делението са обратни действия; тук се дели, макар в записа да има точка."
    )
  )
end

Authoring.family "mul.rows_columns", topic: "Умножение и деление", area: "arithmetic",
                 rungs: [ 720, 800, 880, 970, 1060, 1160 ] do |c|
  spec = c.by_level([ [ 2..5, 3..6 ], [ 3..8, 4..9 ], [ 4..12, 5..12 ],
                      [ 6..18, 7..15 ], [ 9..25, 8..24 ], [ 14..45, 12..35 ] ])
  rows = c.int(spec[0])
  cols = c.int(spec[1])
  total = rows * cols

  c.q(
    text: "В залата столовете са наредени в #{rows} реда по #{cols} стола. Колко стола има залата?",
    answer: Num.ans(total),
    explanation: Explain.build(
      idea: "Правоъгълна подредба се брои с умножение: редове по места в ред.",
      steps: [
        "#{rows} · #{cols} = #{total}."
      ],
      answer: "#{total} стола",
      check: "#{total} : #{cols} = #{rows} — толкова реда се получават обратно.",
      watch: "Ако редовете и местата се разменят, произведението е същото: #{cols} · #{rows} = #{total}."
    )
  )
end

Authoring.family "div.unit_price", topic: "Умножение и деление", area: "arithmetic",
                 rungs: [ 800, 890, 970, 1060, 1150, 1250 ] do |c|
  spec = c.by_level([ [ 2..5, 2..6 ], [ 3..8, 2..9 ], [ 4..10, 3..12 ],
                      [ 5..12, 4..20 ], [ 6..20, 5..30 ], [ 8..30, 6..45 ] ])
  count = c.int(spec[0])
  price = c.int(spec[1])
  total = count * price

  item, = c.goods

  c.q(
    text: "#{item.count(count)} струват #{Num.money(total)}. Колко лева струва #{item.one}?",
    answer: Num.ans(price),
    explanation: Explain.build(
      idea: "От обща сума към единична цена се минава с деление.",
      steps: [
        "#{Num.money(total)} : #{count} = #{Num.money(price)}."
      ],
      answer: Num.money(price),
      check: "#{count} · #{Num.money(price)} = #{Num.money(total)}.",
      watch: "Делим на броя, не на цената — резултатът е цена за един брой."
    )
  )
end

Authoring.family "mul.powers_of_ten", topic: "Умножение и деление", area: "arithmetic",
                 rungs: [ 760, 840, 920, 1010, 1100, 1200 ] do |c|
  spec = c.by_level([ [ 10, 10 ], [ 10, 100 ], [ 100, 100 ], [ 100, 1000 ], [ 1000, 1000 ], [ 1000, 10_000 ] ])
  factor = c.pick(spec.uniq)
  a = c.int(2..99)
  divide = c.level >= 2 && c.coin
  if divide
    product = a * factor
    c.q(
      text: "Пресметни: #{product} : #{factor}.",
      answer: Num.ans(a),
      explanation: Explain.build(
        idea: "Деление на #{factor} премества запетаята с #{Math.log10(factor).round} места назад — тук просто махаме нулите.",
        steps: [ "#{product} : #{factor} = #{a}." ],
        answer: Num.ans(a),
        check: "#{a} · #{factor} = #{product}.",
        watch: "Махат се точно толкова нули, колкото има делителят."
      )
    )
  else
    product = a * factor
    c.q(
      text: "Пресметни: #{a} · #{factor}.",
      answer: Num.ans(product),
      explanation: Explain.build(
        idea: "Умножение с #{factor} добавя #{Math.log10(factor).round} нули.",
        steps: [ "#{a} · #{factor} = #{product}." ],
        answer: Num.ans(product),
        check: "#{product} : #{factor} = #{a}.",
        watch: "Броят на нулите в отговора е броят на нулите в #{factor}."
      )
    )
  end
end

Authoring.family "mul.two_step_story", topic: "Умножение и деление", area: "arithmetic",
                 rungs: [ 860, 950, 1040, 1130, 1220, 1320 ] do |c|
  spec = c.by_level([ [ 2..5, 2..6, 1..5 ], [ 3..7, 3..8, 2..10 ], [ 4..10, 4..10, 3..20 ],
                      [ 5..14, 5..12, 5..40 ], [ 8..20, 6..18, 10..70 ], [ 12..35, 8..25, 20..150 ] ])
  boxes = c.int(spec[0])
  per = c.int(spec[1])
  taken = c.int(spec[2])
  total = boxes * per
  raise Authoring::Duplicate if taken >= total

  left = total - taken
  item = c.thing
  box = c.container

  c.q(
    text: "В #{box.count(boxes)} има по #{item.count(per)}. Продават #{item.count(taken)}. " \
          "Колко #{item.many} остават?",
    answer: Num.ans(left),
    explanation: Explain.build(
      idea: "Първо цялото количество (умножение), после отнемаме продаденото (изваждане).",
      steps: [
        "Всичко: #{boxes} · #{per} = #{total}.",
        "Остават: #{total} − #{taken} = #{left}."
      ],
      answer: "#{item.count(left)}",
      check: "#{left} + #{taken} = #{total} — сборът връща цялото количество.",
      watch: "Редът на действията има значение: умножението е преди изваждането."
    )
  )
end

Authoring.family "div.how_many_boxes", topic: "Умножение и деление", area: "arithmetic",
                 rungs: [ 900, 990, 1080, 1170, 1260, 1360 ] do |c|
  spec = c.by_level([ [ 9..25, 3..5 ], [ 20..50, 4..7 ], [ 40..120, 5..9 ],
                      [ 90..250, 6..12 ], [ 200..600, 8..18 ], [ 500..1500, 12..30 ] ])
  total = c.int(spec[0])
  per = c.int(spec[1])
  raise Authoring::Duplicate if (total % per).zero?

  full = total / per
  boxes = full + 1
  rest = total % per
  item = c.thing
  box = c.container

  c.q(
    text: "#{item.count(total)} се пакетират по #{per} в #{box.one}. " \
          "Колко #{box.many} са нужни, за да се опакова всичко?",
    answer: Num.ans(boxes),
    explanation: Explain.build(
      idea: "Делим с остатък, а после решаваме какво да правим с остатъка според въпроса.",
      steps: [
        "#{total} : #{per} = #{full} и остатък #{rest}.",
        "#{full} пълни #{box.many} не стигат — за последните #{rest} трябва още една.",
        "#{full} + 1 = #{boxes}."
      ],
      answer: "#{box.count(boxes)}",
      check: "#{full} · #{per} + #{rest} = #{total}, а #{boxes} #{box.many} вместват до #{boxes * per}.",
      watch: "Тук остатъкът не се изхвърля: частичната #{box.one} също е #{box.one}."
    )
  )
end

# ------------------------------------------------------- Ред на действията ---

Authoring.family "order.two_ops", topic: "Ред на действията", area: "arithmetic",
                 rungs: [ 850, 930, 1010, 1100, 1190, 1290 ] do |c|
  spec = c.by_level([ 2..9, 3..12, 4..20, 6..40, 10..80, 15..150 ])
  a = c.int(spec)
  b = c.int(2..9)
  d = c.int(spec)
  product = a * b
  result = product + d
  swap = c.coin

  c.q(
    text: swap ? "Пресметни: #{d} + #{a} · #{b}." : "Пресметни: #{a} · #{b} + #{d}.",
    answer: Num.ans(result),
    explanation: Explain.build(
      idea: "Умножението е действие от по-висок ред: върши се преди събирането, независимо къде стои.",
      steps: [
        "#{a} · #{b} = #{product}.",
        swap ? "#{d} + #{product} = #{result}." : "#{product} + #{d} = #{result}."
      ],
      answer: Num.ans(result),
      check: "Ако събирането беше първо, щеше да излезе #{swap ? (d + a) * b : a * (b + d)} — различно число.",
      watch: "Няма скоби, затова редът е даден от действията, не от подредбата отляво надясно."
    )
  )
end

Authoring.family "order.brackets", topic: "Ред на действията", area: "arithmetic",
                 rungs: [ 880, 960, 1050, 1140, 1230, 1330 ] do |c|
  spec = c.by_level([ 2..9, 3..12, 4..20, 5..30, 8..60, 12..120 ])
  a = c.int(spec)
  b = c.int(2..spec.max)
  m = c.int(2..9)
  inner = a + b
  result = inner * m

  c.q(
    text: "Пресметни: (#{a} + #{b}) · #{m}.",
    answer: Num.ans(result),
    explanation: Explain.build(
      idea: "Скобите се пресмятат първи — те „сглобяват“ едно число, което после се умножава.",
      steps: [
        "В скобите: #{a} + #{b} = #{inner}.",
        "#{inner} · #{m} = #{result}."
      ],
      answer: Num.ans(result),
      check: "Разкрито: #{a} · #{m} + #{b} · #{m} = #{a * m} + #{b * m} = #{result} — същият отговор.",
      watch: "Без скоби изразът #{a} + #{b} · #{m} дава #{a + (b * m)} — скобите променят резултата."
    )
  )
end

Authoring.family "order.four_ops", topic: "Ред на действията", area: "arithmetic",
                 rungs: [ 950, 1040, 1130, 1220, 1310, 1400 ] do |c|
  spec = c.by_level([ 2..6, 3..9, 4..12, 5..20, 8..40, 12..80 ])
  a = c.int(spec)
  b = c.int(2..9)
  d = c.int(2..9)
  e = c.int(spec)
  quotient_ok = ((a * b) % d).zero?
  raise Authoring::Duplicate unless quotient_ok

  first = a * b
  second = first / d
  result = second + e

  c.q(
    text: "Пресметни: #{a} · #{b} : #{d} + #{e}.",
    answer: Num.ans(result),
    explanation: Explain.build(
      idea: "Умножение и деление са от един ред и се изпълняват отляво надясно; събирането е след тях.",
      steps: [
        "#{a} · #{b} = #{first}.",
        "#{first} : #{d} = #{second}.",
        "#{second} + #{e} = #{result}."
      ],
      answer: Num.ans(result),
      check: "Проверка наопаки: (#{result} − #{e}) · #{d} = #{second * d} = #{a} · #{b}.",
      watch: "Делението не се „прескача“: ако първо се събере #{second} + #{e}, отговорът се разваля."
    )
  )
end

Authoring.family "order.powers", topic: "Ред на действията", area: "arithmetic",
                 rungs: [ 1050, 1140, 1230, 1320, 1410, 1500 ] do |c|
  base = c.by_level([ 2..3, 2..4, 2..5, 2..6, 3..8, 4..12 ])
  a = c.int(base)
  exponent = c.pick(c.level >= 3 ? [ 2, 3, 3 ] : [ 2, 2, 3 ])
  m = c.int(2..9)
  d = c.int(2..20)
  power = a**exponent
  result = (power * m) - d
  raise Authoring::Duplicate if result.negative?

  c.q(
    text: "Пресметни: #{Num.power(a, exponent)} · #{m} − #{d}.",
    answer: Num.ans(result),
    explanation: Explain.build(
      idea: "Степенуването е най-силното действие: първо степен, после умножение, накрая изваждане.",
      steps: [
        "#{Num.power(a, exponent)} = #{([ a ] * exponent).join(' · ')} = #{power}.",
        "#{power} · #{m} = #{power * m}.",
        "#{power * m} − #{d} = #{result}."
      ],
      answer: Num.ans(result),
      check: "Обратно: #{result} + #{d} = #{power * m}, а #{power * m} : #{m} = #{power}.",
      watch: "#{Num.power(a, exponent)} не е #{a} · #{exponent} = #{a * exponent} — степента е повторено умножение."
    )
  )
end

Authoring.family "order.which_expression", topic: "Ред на действията", area: "arithmetic",
                 rungs: [ 980, 1070, 1160, 1250, 1340, 1440 ] do |c|
  spec = c.by_level([ 2..8, 3..12, 4..20, 6..30, 8..50, 12..90 ])
  price = c.int(spec)
  count = c.int(2..9)
  paid = (price * count) + c.int(1..20)
  who = c.person
  item, = c.goods

  correct = "#{paid} − #{count} · #{price}"

  c.q(
    text: "#{who} плаща с #{paid} лв. за #{item.count(count)} по #{price} лв. " \
          "Кой израз показва колко лева остават?",
    options: c.options(correct, "(#{paid} − #{count}) · #{price}", "#{paid} − #{count} + #{price}", "#{count} · #{price} − #{paid}"),
    answer: correct,
    explanation: Explain.build(
      idea: "Превеждаме условието стъпка по стъпка: „за #{count} броя по #{price} лв.“ е умножение, „остават“ е изваждане.",
      steps: [
        "Покупката е #{count} · #{price} = #{count * price} лв.",
        "Остатъкът е платеното минус покупката: #{paid} − #{count} · #{price}.",
        "Без скоби умножението се извършва първо, точно както трябва: #{paid} − #{count * price} = #{paid - (count * price)} лв."
      ],
      answer: "#{correct} (= #{paid - (count * price)} лв.)",
      check: "#{paid - (count * price)} + #{count * price} = #{paid} лв.",
      watch: "Изразът (#{paid} − #{count}) · #{price} първо намалява парите с броя — това не значи нищо в тази задача."
    )
  )
end

Authoring.family "order.with_negatives", topic: "Ред на действията", area: "arithmetic",
                 rungs: [ 1100, 1190, 1280, 1370, 1460, 1560 ] do |c|
  spec = c.by_level([ 2..6, 3..9, 4..12, 5..20, 8..40, 12..80 ])
  a = c.int(spec)
  b = c.int(2..9)
  d = c.int(spec)
  result = -(a * b) + d

  c.q(
    text: "Пресметни: #{Num::MINUS}#{a} · #{b} + #{d}.",
    answer: Num.ans(result),
    explanation: Explain.build(
      idea: "Знакът минус остава пред произведението: първо умножаваме, после събираме със знаците.",
      steps: [
        "#{Num::MINUS}#{a} · #{b} = #{Num.bg(-(a * b))}.",
        "#{Num.bg(-(a * b))} + #{d} = #{Num.bg(result)}."
      ],
      answer: Num.bg(result),
      check: "#{Num.bg(result)} − #{d} = #{Num.bg(-(a * b))} — връщаме се към произведението.",
      watch: "Събиране на положително число премества резултата надясно по числовата ос, но той може да остане отрицателен."
    )
  )
end
