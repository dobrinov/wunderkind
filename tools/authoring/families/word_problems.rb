# Задачи: текстови задачи, движение, работа, уравнения.

# ------------------------------------------------------------ Текстови задачи ---

Authoring.family "word.share_unequally", topic: "Текстови задачи", area: "word_problems",
                 rungs: [ 830, 920, 1010, 1100, 1190, 1290 ] do |c|
  spec = c.by_level([ 2..10, 4..25, 8..50, 15..120, 30..300, 60..800 ])
  smaller = c.int(spec)
  more = c.int(1..(spec.max / 2))
  bigger = smaller + more
  total = smaller + bigger
  first, second = c.people(2)
  item = c.thing

  c.q(
    text: "#{first} и #{second} имат заедно #{item.count(total)}. #{first} има с #{more} повече от #{second}. " \
          "Колко #{item.many} има #{first}?",
    answer: Num.ans(bigger),
    explanation: Explain.build(
      idea: "Махаме разликата, за да станат двете части равни, делим наполовина и я връщаме на по-голямата част.",
      steps: [
        "#{total} − #{more} = #{total - more} — толкова щеше да е сборът, ако имаха поравно.",
        "#{total - more} : 2 = #{smaller} — това има #{second}.",
        "#{smaller} + #{more} = #{bigger} — това има #{first}."
      ],
      answer: "#{item.count(bigger)}",
      check: "#{bigger} + #{smaller} = #{total} и #{bigger} − #{smaller} = #{more}.",
      watch: "Половината от сбора (#{total / 2}) е отговорът само при равни части."
    )
  )
end

Authoring.family "word.ratio_split", topic: "Текстови задачи", area: "word_problems",
                 rungs: [ 1080, 1170, 1260, 1350, 1440, 1540 ] do |c|
  a = c.int(c.by_level([ 1..3, 1..4, 2..5, 2..7, 3..9, 4..12 ]))
  b = c.int(c.by_level([ 1..3, 1..4, 2..5, 2..7, 3..9, 4..12 ]))
  raise Authoring::Duplicate if a == b || Num.gcd(a, b) != 1

  unit = c.int(c.by_level([ 2..10, 3..20, 4..40, 6..80, 10..200, 15..500 ]))
  total = (a + b) * unit
  bigger_share = [ a, b ].max * unit

  c.q(
    text: "Сума от #{total} лв. се разделя в отношение #{a} : #{b}. Колко лева е по-голямата част?",
    answer: Num.ans(bigger_share),
    explanation: Explain.build(
      idea: "Отношението #{a} : #{b} значи #{a + b} равни части — намираме една част и я умножаваме.",
      steps: [
        "Части общо: #{a} + #{b} = #{a + b}.",
        "Една част: #{total} : #{a + b} = #{unit} лв.",
        "По-голямата част е #{[ a, b ].max} · #{unit} = #{bigger_share} лв."
      ],
      answer: "#{bigger_share} лв.",
      check: "#{bigger_share} + #{[ a, b ].min * unit} = #{total} лв., а #{bigger_share} : #{[ a, b ].min * unit} = #{Num.frac([ a, b ].max, [ a, b ].min)}.",
      watch: "Сумата не се дели на 2 — частите не са равни."
    )
  )
end

Authoring.family "word.average_needed", topic: "Текстови задачи", area: "word_problems",
                 rungs: [ 1150, 1240, 1330, 1420, 1510, 1610 ] do |c|
  count = c.by_level([ 2, 3, 3, 4, 5, 6 ])
  target = c.pick([ 4, 5, 6 ])
  marks = Array.new(count) { c.int(2..6) }
  needed = (target * (count + 1)) - marks.sum
  raise Authoring::Duplicate unless needed.between?(2, 6)

  who = c.person

  c.q(
    text: "#{who} има оценки #{marks.join(', ')}. Каква оценка трябва да получи на следващото изпитване, " \
          "за да стане средният успех точно #{target}?",
    answer: Num.ans(needed),
    explanation: Explain.build(
      idea: "Средният успех е сборът на оценките, разделен на броя им — работим наобратно от желания сбор.",
      steps: [
        "След новата оценка оценките ще са #{count + 1}.",
        "За среден успех #{target} сборът трябва да е #{target} · #{count + 1} = #{target * (count + 1)}.",
        "Сега сборът е #{marks.join(' + ')} = #{marks.sum}, значи липсва #{target * (count + 1)} − #{marks.sum} = #{needed}."
      ],
      answer: Num.ans(needed),
      check: "(#{marks.join(' + ')} + #{needed}) : #{count + 1} = #{target}.",
      watch: "Новата оценка увеличава и броя на оценките — не се дели на #{count}."
    )
  )
end

Authoring.family "word.consecutive", topic: "Текстови задачи", area: "word_problems",
                 rungs: [ 1120, 1210, 1300, 1390, 1480, 1580 ] do |c|
  count = c.by_level([ 2, 3, 3, 4, 5, 5 ])
  start = c.int(c.by_level([ 2..15, 3..30, 5..60, 8..150, 12..400, 20..1000 ]))
  even_only = c.level >= 3 && c.coin
  step = even_only ? 2 : 1
  numbers = (0...count).map { |i| start + (i * step) }
  sum = numbers.sum

  c.q(
    text: "Сборът на #{count} последователни #{even_only ? 'четни ' : ''}числа е #{sum}. Кое е най-малкото от тях?",
    answer: Num.ans(start),
    explanation: Explain.build(
      idea: "Означаваме най-малкото с x; следващите са с #{step}, #{2 * step}, ... повече от него.",
      steps: [
        "Сборът е #{count}x + #{numbers.sum - (count * start)} = #{sum}.",
        "#{count}x = #{sum} − #{numbers.sum - (count * start)} = #{count * start}.",
        "x = #{count * start} : #{count} = #{start}."
      ],
      answer: Num.ans(start),
      check: "#{numbers.join(' + ')} = #{sum}.",
      watch: count.odd? ? "При нечетен брой средното число е #{sum} : #{count} = #{sum / count} — оттам може да се тръгне наум." : "Средното аритметично (#{Num.dec(Rational(sum, count), 1)}) тук не е едно от числата."
    )
  )
end

Authoring.family "word.saving_plan", topic: "Текстови задачи", area: "word_problems",
                 rungs: [ 950, 1040, 1130, 1220, 1310, 1410 ] do |c|
  weekly = c.int(c.by_level([ 2..6, 3..10, 4..15, 5..25, 8..50, 10..90 ]))
  weeks = c.int(c.by_level([ 3..8, 4..12, 5..20, 6..30, 8..50, 10..80 ]))
  have = c.int(c.by_level([ 0..10, 2..20, 5..40, 10..80, 20..200, 30..500 ]))
  goal = have + (weekly * weeks)
  who = c.person

  c.q(
    text: "#{who} има спестени #{have} лв. и слага по #{weekly} лв. всяка седмица. " \
          "След колко седмици ще има #{goal} лв.?",
    answer: Num.ans(weeks),
    explanation: Explain.build(
      idea: "Първо колко още липсват, после на колко седмици се събират.",
      steps: [
        "Липсват #{goal} − #{have} = #{goal - have} лв.",
        "#{goal - have} : #{weekly} = #{weeks} седмици."
      ],
      answer: "#{weeks} седмици",
      check: "#{have} + #{weeks} · #{weekly} = #{goal} лв.",
      watch: "Спестените #{have} лв. вече ги има — те не се спестяват отново."
    )
  )
end

Authoring.family "word.tickets_mixed", topic: "Текстови задачи", area: "word_problems",
                 rungs: [ 1050, 1140, 1230, 1320, 1410, 1510 ] do |c|
  adult = c.int(c.by_level([ 4..8, 5..12, 6..18, 8..25, 10..40, 12..80 ]))
  child = c.int(2..(adult - 1))
  adults = c.int(c.by_level([ 2..4, 2..6, 3..8, 4..12, 6..20, 8..40 ]))
  children = c.int(c.by_level([ 2..5, 3..8, 4..12, 5..18, 8..30, 10..60 ]))
  total = (adult * adults) + (child * children)

  c.q(
    text: "Билет за възрастен струва #{adult} лв., а за дете — #{child} лв. " \
          "Група от #{adults} възрастни и #{children} деца купува билети. Колко лева плащат общо?",
    answer: Num.ans(total),
    explanation: Explain.build(
      idea: "Двете групи се смятат поотделно и се събират.",
      steps: [
        "Възрастни: #{adults} · #{adult} = #{adults * adult} лв.",
        "Деца: #{children} · #{child} = #{children * child} лв.",
        "Общо: #{adults * adult} + #{children * child} = #{total} лв."
      ],
      answer: "#{total} лв.",
      check: "Средно по #{Num.dec(Rational(total, adults + children), 2)} лв. на човек за #{adults + children} души — между #{child} и #{adult} лв.",
      watch: "Цените са различни — не може да се умножи общият брой хора по една цена."
    )
  )
end

Authoring.family "word.recipe_scale", topic: "Текстови задачи", area: "word_problems",
                 rungs: [ 1000, 1090, 1180, 1270, 1360, 1460 ] do |c|
  people = c.int(c.by_level([ 2..4, 2..6, 3..8, 4..10, 5..15, 6..25 ]))
  grams = c.int(c.by_level([ 2..10, 3..20, 4..40, 6..80, 10..200, 15..500 ])) * 10
  wanted = c.int(2..(people * 4))
  raise Authoring::Duplicate if wanted == people || ((grams * wanted) % people) != 0

  needed = grams * wanted / people

  c.q(
    text: "Рецепта за #{people} души иска #{grams} г брашно. Колко грама брашно трябват за #{wanted} души?",
    answer: Num.ans(needed),
    explanation: Explain.build(
      idea: "Количеството расте право пропорционално на броя хора — минаваме през дозата за един човек.",
      steps: [
        "За един човек: #{grams} : #{people} = #{grams / people} г.",
        "За #{wanted} души: #{grams / people} · #{wanted} = #{needed} г."
      ],
      answer: "#{needed} г",
      check: "#{needed} : #{wanted} = #{grams / people} г на човек — същото както в рецептата.",
      watch: "Пропорцията е права: повече хора значи повече брашно."
    )
  )
end

Authoring.family "word.remaining_pages", topic: "Текстови задачи", area: "word_problems",
                 rungs: [ 900, 990, 1080, 1170, 1260, 1360 ] do |c|
  per_day = c.int(c.by_level([ 3..10, 5..20, 8..35, 12..60, 20..120, 30..250 ]))
  days = c.int(c.by_level([ 2..5, 3..8, 4..12, 5..20, 8..40, 10..80 ]))
  left = c.int(c.by_level([ 3..20, 5..40, 10..80, 20..150, 40..400, 60..900 ]))
  total = (per_day * days) + left
  who = c.person

  c.q(
    text: "Книгата има #{total} страници. #{who} чете по #{per_day} страници на ден в продължение на #{days} дни. " \
          "Колко страници остават непрочетени?",
    answer: Num.ans(left),
    explanation: Explain.build(
      idea: "Прочетеното е скорост по време; останалото е разликата до всичко.",
      steps: [
        "Прочетени: #{per_day} · #{days} = #{per_day * days} страници.",
        "Остават: #{total} − #{per_day * days} = #{left} страници."
      ],
      answer: "#{left} страници",
      check: "#{per_day * days} + #{left} = #{total}.",
      watch: "Броят дни умножава страниците на ден — не се събира с тях."
    )
  )
end

Authoring.family "word.two_step_shopping", topic: "Текстови задачи", area: "word_problems",
                 rungs: [ 1100, 1190, 1280, 1370, 1460, 1560 ] do |c|
  first_item, first_band = c.goods
  second_item, second_band = c.goods
  raise Authoring::Duplicate if first_item.one == second_item.one

  first_count = c.int(c.by_level([ 2..3, 2..5, 3..7, 4..10, 5..15, 6..25 ]))
  second_count = c.int(c.by_level([ 2..3, 2..5, 3..7, 4..10, 5..15, 6..25 ]))
  first_price = c.int(first_band)
  second_price = c.int(second_band)
  total = (first_count * first_price) + (second_count * second_price)
  paid = total + c.int(1..40)
  change = paid - total

  c.q(
    text: "Купуваме #{first_item.count(first_count)} по #{first_price} лв. и #{second_item.count(second_count)} по #{second_price} лв. " \
          "Плащаме с #{paid} лв. Колко лева е рестото?",
    answer: Num.ans(change),
    explanation: Explain.build(
      idea: "Всяка покупка се смята поотделно, събира се, и чак тогава се вади от платеното.",
      steps: [
        "#{first_count} · #{first_price} = #{first_count * first_price} лв.",
        "#{second_count} · #{second_price} = #{second_count * second_price} лв.",
        "Общо #{first_count * first_price} + #{second_count * second_price} = #{total} лв.",
        "Ресто: #{paid} − #{total} = #{change} лв."
      ],
      answer: "#{change} лв.",
      check: "#{total} + #{change} = #{paid} лв.",
      watch: "Двете умножения се правят преди изваждането — това е редът на действията в задачата."
    )
  )
end

# ---------------------------------------------------------------- Движение ---

Authoring.family "move.distance", topic: "Движение", area: "word_problems",
                 rungs: [ 980, 1070, 1160, 1250, 1340, 1440 ] do |c|
  speed = c.int(c.by_level([ 3..10, 5..20, 10..40, 20..70, 40..110, 60..160 ]))
  time = c.int(c.by_level([ 2..4, 2..6, 3..8, 4..9, 5..10, 6..12 ]))
  distance = speed * time
  vehicle = c.vehicle_for(speed)

  c.q(
    text: "Един #{vehicle} се движи със скорост #{speed} км/ч в продължение на #{time} часа. Колко километра изминава?",
    answer: Num.ans(distance),
    explanation: Explain.build(
      idea: "Разстоянието е скорост по време: s = v · t.",
      steps: [
        "За един час се изминават #{speed} км.",
        "За #{time} часа: #{speed} · #{time} = #{distance} км."
      ],
      answer: "#{distance} км",
      check: "#{distance} : #{time} = #{speed} км/ч — връщаме се към скоростта.",
      watch: "Мерните единици трябва да си пасват: км/ч с часове дава километри."
    )
  )
end

Authoring.family "move.time", topic: "Движение", area: "word_problems",
                 rungs: [ 1050, 1140, 1230, 1320, 1410, 1510 ] do |c|
  speed = c.int(c.by_level([ 3..10, 5..20, 10..40, 20..70, 30..110, 50..160 ]))
  time = c.int(c.by_level([ 2..4, 2..6, 3..8, 4..9, 5..10, 6..12 ]))
  distance = speed * time
  vehicle = c.vehicle_for(speed)

  c.q(
    text: "Един #{vehicle} изминава #{distance} км със скорост #{speed} км/ч. За колко часа изминава разстоянието?",
    answer: Num.ans(time),
    explanation: Explain.build(
      idea: "От s = v · t следва t = s : v.",
      steps: [ "#{distance} : #{speed} = #{time} часа." ],
      answer: "#{time} часа",
      check: "#{speed} · #{time} = #{distance} км.",
      watch: "Дели се разстоянието на скоростта; обратното (#{speed} : #{distance}) няма смисъл тук."
    )
  )
end

Authoring.family "move.speed", topic: "Движение", area: "word_problems",
                 rungs: [ 1020, 1110, 1200, 1290, 1380, 1480 ] do |c|
  speed = c.int(c.by_level([ 3..12, 5..25, 10..45, 20..75, 30..120, 45..180 ]))
  time = c.int(c.by_level([ 2..4, 2..6, 3..8, 4..9, 5..10, 6..12 ]))
  distance = speed * time
  vehicle = c.vehicle_for(speed)

  c.q(
    text: "Един #{vehicle} изминава #{distance} км за #{time} часа. Колко километра в час е средната му скорост?",
    answer: Num.ans(speed),
    explanation: Explain.build(
      idea: "Средната скорост е изминатият път, разделен на времето: v = s : t.",
      steps: [ "#{distance} : #{time} = #{speed} км/ч." ],
      answer: "#{speed} км/ч",
      check: "#{speed} · #{time} = #{distance} км.",
      watch: "Средната скорост не е средно аритметично на скоростите по отделните участъци."
    )
  )
end

Authoring.family "move.towards", topic: "Движение", area: "word_problems",
                 rungs: [ 1200, 1290, 1380, 1470, 1560, 1660 ] do |c|
  first = c.int(c.by_level([ 3..10, 4..20, 8..40, 15..60, 25..90, 40..130 ]))
  second = c.int(c.by_level([ 3..10, 4..20, 8..40, 15..60, 25..90, 40..130 ]))
  raise Authoring::Duplicate if first == second

  time = c.int(c.by_level([ 2..3, 2..4, 2..6, 3..8, 4..10, 5..12 ]))
  distance = (first + second) * time

  c.q(
    text: "Два града са на #{distance} км един от друг. Едновременно от тях тръгват един срещу друг два автомобила " \
          "със скорости #{first} км/ч и #{second} км/ч. След колко часа ще се срещнат?",
    answer: Num.ans(time),
    explanation: Explain.build(
      idea: "При движение един срещу друг разстоянието между тях намалява със сбора на скоростите.",
      steps: [
        "Скорост на сближаване: #{first} + #{second} = #{first + second} км/ч.",
        "#{distance} : #{first + second} = #{time} часа."
      ],
      answer: "#{time} часа",
      check: "Първият изминава #{first * time} км, вторият #{second * time} км, заедно #{distance} км.",
      watch: "Скоростите се събират само когато телата се движат едно срещу друго."
    )
  )
end

Authoring.family "move.catch_up", topic: "Движение", area: "word_problems",
                 rungs: [ 1350, 1440, 1530, 1620, 1710, 1810 ] do |c|
  slow = c.int(c.by_level([ 3..10, 4..20, 8..35, 12..55, 20..80, 30..120 ]))
  gap_speed = c.int(c.by_level([ 2..6, 3..10, 4..15, 5..25, 8..40, 10..60 ]))
  fast = slow + gap_speed
  time = c.int(c.by_level([ 2..3, 2..4, 2..6, 3..8, 4..10, 5..12 ]))
  head_start = gap_speed * time
  # The cyclist sets off first, not the day before.
  raise Authoring::Duplicate if head_start > 60

  c.q(
    text: "Велосипедист се движи с #{slow} км/ч. След като изминава #{head_start} км, след него тръгва автомобил " \
          "с #{fast} км/ч по същия път. След колко часа автомобилът ще го настигне?",
    answer: Num.ans(time),
    explanation: Explain.build(
      idea: "При движение в една посока разстоянието между двамата намалява с разликата на скоростите.",
      steps: [
        "Скорост на догонване: #{fast} − #{slow} = #{gap_speed} км/ч.",
        "#{head_start} : #{gap_speed} = #{time} часа."
      ],
      answer: "#{time} часа",
      check: "За #{time} часа автомобилът изминава #{fast * time} км, а велосипедистът — #{head_start} + #{slow * time} = #{head_start + (slow * time)} км. Равни са.",
      watch: "Тук скоростите се изваждат, не се събират — движението е в една посока."
    )
  )
end

Authoring.family "move.average_speed", topic: "Движение", area: "word_problems",
                 rungs: [ 1400, 1490, 1580, 1670, 1760, 1860 ] do |c|
  first_speed = c.int(c.by_level([ 4..10, 5..20, 10..40, 15..60, 25..90, 40..130 ]))
  second_speed = c.int(c.by_level([ 4..10, 5..20, 10..40, 15..60, 25..90, 40..130 ]))
  raise Authoring::Duplicate if first_speed == second_speed

  first_time = c.int(1..4)
  second_time = c.int(1..4)
  distance = (first_speed * first_time) + (second_speed * second_time)
  total_time = first_time + second_time
  raise Authoring::Duplicate unless (distance % total_time).zero?

  average = distance / total_time

  c.q(
    text: "Автомобил се движи #{first_time} #{first_time == 1 ? 'час' : 'часа'} с #{first_speed} км/ч, " \
          "след това #{second_time} #{second_time == 1 ? 'час' : 'часа'} с #{second_speed} км/ч. " \
          "Колко километра в час е средната му скорост за целия път?",
    answer: Num.ans(average),
    explanation: Explain.build(
      idea: "Средната скорост е целият път, разделен на цялото време — не средното на двете скорости.",
      steps: [
        "Път: #{first_speed} · #{first_time} + #{second_speed} · #{second_time} = #{first_speed * first_time} + #{second_speed * second_time} = #{distance} км.",
        "Време: #{first_time} + #{second_time} = #{total_time} часа.",
        "#{distance} : #{total_time} = #{average} км/ч."
      ],
      answer: "#{average} км/ч",
      check: "#{average} · #{total_time} = #{distance} км — същият път.",
      watch: "Средното аритметично на скоростите е #{Num.dec(Rational(first_speed + second_speed, 2), 1)} км/ч и съвпада само когато времената са равни."
    )
  )
end

Authoring.family "move.round_trip", topic: "Движение", area: "word_problems",
                 rungs: [ 1250, 1340, 1430, 1520, 1610, 1710 ] do |c|
  # Built from the return leg outwards, so both legs come out as whole hours at
  # a speed a vehicle can actually hold.
  speed_back = c.int(c.by_level([ 20..40, 20..60, 25..80, 30..100, 40..130, 50..160 ]))
  time_back = c.int(c.by_level([ 1..2, 1..3, 2..4, 2..5, 3..6, 3..8 ]))
  distance = speed_back * time_back
  speed_there = c.pick(Num.divisors(distance).select { |value| value.between?(20, 160) && value != speed_back })

  time_there = distance / speed_there
  raise Authoring::Duplicate if time_there > 12

  total_time = time_there + time_back

  c.q(
    text: "Разстоянието между два града е #{distance} км. Отиването е със #{speed_there} км/ч, " \
          "а връщането — за #{time_back} #{time_back == 1 ? 'час' : 'часа'}. Колко часа продължава цялото пътуване?",
    answer: Num.ans(total_time),
    explanation: Explain.build(
      idea: "Двете посоки се смятат поотделно: времето за отиване се намира от скоростта, времето за връщане е дадено.",
      steps: [
        "Отиване: #{distance} : #{speed_there} = #{count_noun(time_there, 'час', 'часа')}.",
        "Връщане: #{count_noun(time_back, 'час', 'часа')}.",
        "Общо: #{time_there} + #{time_back} = #{count_noun(total_time, 'час', 'часа')}."
      ],
      answer: count_noun(total_time, "час", "часа"),
      check: "Скоростта при връщане е #{distance} : #{time_back} = #{Num.ans(speed_back)} км/ч.",
      watch: "Пътят е един и същ в двете посоки, но времената са различни, защото скоростите са различни."
    )
  )
end

# ------------------------------------------------------------------ Работа ---

Authoring.family "work.rate_time", topic: "Работа", area: "word_problems",
                 rungs: [ 1050, 1140, 1230, 1320, 1410, 1510 ] do |c|
  per_hour = c.int(c.by_level([ 2..8, 3..15, 5..25, 8..40, 12..80, 20..150 ]))
  hours = c.int(c.by_level([ 2..5, 3..8, 4..12, 5..20, 6..30, 8..50 ]))
  total = per_hour * hours
  worker = c.pick(Props::WORKERS)

  c.q(
    text: "Един #{worker} изработва по #{per_hour} детайла на час. За колко часа ще изработи #{total} детайла?",
    answer: Num.ans(hours),
    explanation: Explain.build(
      idea: "Времето е количество работа, разделено на производителността.",
      steps: [ "#{total} : #{per_hour} = #{hours} часа." ],
      answer: "#{hours} часа",
      check: "#{per_hour} · #{hours} = #{total} детайла.",
      watch: "Производителността е за час — не се умножава по броя детайли."
    )
  )
end

Authoring.family "work.together", topic: "Работа", area: "word_problems",
                 rungs: [ 1300, 1390, 1480, 1570, 1660, 1760 ] do |c|
  first = c.int(c.by_level([ 2..6, 2..8, 3..12, 4..18, 5..30, 6..60 ]))
  second = c.int(c.by_level([ 2..6, 2..8, 3..12, 4..18, 5..30, 6..60 ]))
  raise Authoring::Duplicate if first == second

  together = Rational(first * second, first + second)

  c.q(
    text: "Един работник свършва работата за #{first} часа, друг — за #{second} часа. " \
          "За колко часа ще я свършат заедно? (Ако отговорът не е цяло число, запиши го като дроб или десетично число.)",
    answer: Num.ans(together),
    explanation: Explain.build(
      idea: "Събират се производителностите (частта от работата за час), не времената.",
      steps: [
        "Първият върши #{Num.frac(1, first)} от работата за час, вторият — #{Num.frac(1, second)}.",
        "Заедно: #{Num.frac(1, first)} + #{Num.frac(1, second)} = #{Num.frac(Rational(1, first) + Rational(1, second))} от работата за час.",
        "Времето е обратното: 1 : #{Num.frac(Rational(1, first) + Rational(1, second))} = #{Num.frac(together)} часа#{together.denominator == 1 ? '' : " ≈ #{Num.dec(together, 2)} часа"}."
      ],
      answer: "#{Num.frac(together)} часа",
      check: "За #{Num.frac(together)} часа първият върши #{Num.frac(together / first)}, вторият #{Num.frac(together / second)} — заедно точно 1.",
      watch: "Времената не се събират (#{first} + #{second} = #{first + second}) и не се осредняват: заедно е по-бързо и от по-бързия сам."
    )
  )
end

Authoring.family "work.remaining", topic: "Работа", area: "word_problems",
                 rungs: [ 1250, 1340, 1430, 1520, 1610, 1710 ] do |c|
  parts = c.int(c.by_level([ 2..4, 3..5, 3..6, 4..8, 5..10, 6..12 ]))
  done = c.int(1...parts)
  per_day = c.int(c.by_level([ 3..10, 5..20, 8..35, 12..60, 20..120, 30..250 ]))
  total = parts * per_day * c.int(1..3)
  raise Authoring::Duplicate unless ((total * done) % parts).zero?

  finished = total * done / parts
  left = total - finished
  days_left = Rational(left, per_day)
  raise Authoring::Duplicate unless days_left.denominator == 1

  c.q(
    text: "От #{total} детайла са готови #{Num.frac(done, parts)}. Останалите се правят по #{per_day} на ден. " \
          "За колко дни ще бъдат готови?",
    answer: Num.ans(days_left),
    explanation: Explain.build(
      idea: "Първо колко остават, после на колко дни се правят.",
      steps: [
        "Готови: #{total} · #{Num.frac(done, parts)} = #{finished} детайла.",
        "Остават: #{total} − #{finished} = #{left}.",
        "#{left} : #{per_day} = #{Num.ans(days_left)} дни."
      ],
      answer: "#{Num.ans(days_left)} дни",
      check: "#{per_day} · #{Num.ans(days_left)} = #{left} — точно останалите детайли.",
      watch: "Дробта се отнася за целите #{total} детайла, не за останалите."
    )
  )
end

Authoring.family "work.inverse_people", topic: "Работа", area: "word_problems",
                 rungs: [ 1320, 1410, 1500, 1590, 1680, 1780 ] do |c|
  people = c.int(c.by_level([ 2..4, 2..6, 3..8, 4..12, 5..20, 6..40 ]))
  days = c.int(c.by_level([ 2..8, 3..12, 4..20, 5..30, 6..50, 8..90 ]))
  work = people * days
  new_people = c.int(2..(people * 3))
  raise Authoring::Duplicate if new_people == people || (work % new_people) != 0

  new_days = work / new_people

  c.q(
    text: "#{people} работници свършват една работа за #{days} дни. За колко дни ще я свършат #{new_people} работници " \
          "със същата производителност?",
    answer: Num.ans(new_days),
    explanation: Explain.build(
      idea: "Броят работници и времето са обратно пропорционални: произведението им (общата работа) е постоянно.",
      steps: [
        "Работата е #{people} · #{days} = #{work} работнико-дни.",
        "#{work} : #{new_people} = #{new_days} дни."
      ],
      answer: "#{new_days} дни",
      check: "#{new_people} · #{new_days} = #{work} — същата работа.",
      watch: new_people > people ? "Повече работници значи по-малко дни — отговорът трябва да е под #{days}." : "По-малко работници значи повече дни — отговорът трябва да е над #{days}."
    )
  )
end

Authoring.family "work.pipes", topic: "Работа", area: "word_problems",
                 rungs: [ 1400, 1490, 1580, 1670, 1760, 1860 ] do |c|
  fill = c.int(c.by_level([ 2..5, 2..7, 3..10, 4..15, 5..25, 6..40 ]))
  drain = c.int((fill + 1)..(fill + c.by_level([ 3, 5, 8, 12, 20, 40 ])))
  together = Rational(fill * drain, drain - fill)

  c.q(
    text: "Една тръба пълни басейн за #{fill} часа, а друга го изпразва за #{drain} часа. " \
          "За колко часа ще се напълни басейнът, ако и двете са отворени?",
    answer: Num.ans(together),
    explanation: Explain.build(
      idea: "Пълненето е положителна производителност, изпразването — отрицателна; те се събират.",
      steps: [
        "За час се пълни #{Num.frac(1, fill)}, изпразва се #{Num.frac(1, drain)}.",
        "Нето за час: #{Num.frac(1, fill)} − #{Num.frac(1, drain)} = #{Num.frac(Rational(1, fill) - Rational(1, drain))}.",
        "Време: 1 : #{Num.frac(Rational(1, fill) - Rational(1, drain))} = #{Num.frac(together)} часа#{together.denominator == 1 ? '' : " ≈ #{Num.dec(together, 2)} часа"}."
      ],
      answer: "#{Num.frac(together)} часа",
      check: "За #{Num.frac(together)} часа влиза #{Num.frac(together / fill)} и излиза #{Num.frac(together / drain)} — разликата е точно 1 басейн.",
      watch: "Пълненето трябва да е по-бързо от изпразването, иначе басейнът никога не се напълва."
    )
  )
end

# --------------------------------------------------------------- Уравнения ---

Authoring.family "eq.linear_two_step", topic: "Уравнения", area: "word_problems",
                 rungs: [ 940, 1030, 1120, 1210, 1300, 1400 ] do |c|
  a = c.int(c.by_level([ 2..5, 2..9, 3..12, 4..20, 5..40, 6..90 ]))
  x = c.int(c.by_level([ 2..9, 2..15, 3..25, 4..50, 5..120, 6..300 ]))
  b = c.int(c.by_level([ 1..15, 2..30, 3..60, 5..150, 8..400, 10..900 ]))
  minus = c.coin
  right = minus ? (a * x) - b : (a * x) + b

  c.q(
    text: "Намери x от уравнението #{a}x #{minus ? Num::MINUS : '+'} #{b} = #{Num.bg(right)}.",
    answer: Num.ans(x),
    explanation: Explain.build(
      idea: "Освобождаваме x на две стъпки: първо махаме свободния член, после делим на коефициента.",
      steps: [
        minus ? "Прибавяме #{b} от двете страни: #{a}x = #{Num.bg(right)} + #{b} = #{a * x}." :
                "Изваждаме #{b} от двете страни: #{a}x = #{Num.bg(right)} − #{b} = #{a * x}.",
        "Делим на #{a}: x = #{a * x} : #{a} = #{x}."
      ],
      answer: "x = #{x}",
      check: "#{a} · #{x} #{minus ? Num::MINUS : '+'} #{b} = #{Num.bg(right)} — уравнението е изпълнено.",
      watch: "Каквото се прави от едната страна, се прави и от другата — иначе равенството се разваля."
    )
  )
end

Authoring.family "eq.brackets", topic: "Уравнения", area: "word_problems",
                 rungs: [ 1120, 1210, 1300, 1390, 1480, 1580 ] do |c|
  a = c.int(c.by_level([ 2..4, 2..6, 2..9, 3..12, 4..20, 5..40 ]))
  x = c.int(c.by_level([ 2..8, 2..12, 3..20, 4..40, 5..90, 6..200 ]))
  b = c.int(c.by_level([ 1..8, 1..12, 2..20, 3..40, 4..90, 5..200 ]))
  minus = c.coin
  inner = minus ? x - b : x + b
  raise Authoring::Duplicate if inner <= 0

  right = a * inner

  c.q(
    text: "Намери x от уравнението #{a}(x #{minus ? Num::MINUS : '+'} #{b}) = #{right}.",
    answer: Num.ans(x),
    explanation: Explain.build(
      idea: "Скобата е един множител — първо я освобождаваме, като разделим на #{a}.",
      steps: [
        "#{right} : #{a} = #{inner}, значи x #{minus ? Num::MINUS : '+'} #{b} = #{inner}.",
        minus ? "x = #{inner} + #{b} = #{x}." : "x = #{inner} − #{b} = #{x}."
      ],
      answer: "x = #{x}",
      check: "#{a}(#{x} #{minus ? Num::MINUS : '+'} #{b}) = #{a} · #{inner} = #{right}.",
      watch: "Може и с разкриване на скобите: #{a}x #{minus ? Num::MINUS : '+'} #{a * b} = #{right} — резултатът е същият."
    )
  )
end

Authoring.family "eq.both_sides", topic: "Уравнения", area: "word_problems",
                 rungs: [ 1200, 1290, 1380, 1470, 1560, 1660 ] do |c|
  a = c.int(c.by_level([ 3..6, 3..9, 4..12, 5..20, 6..40, 8..90 ]))
  d = c.int(1...a)
  x = c.int(c.by_level([ 2..8, 2..12, 3..20, 4..40, 5..90, 6..200 ]))
  b = c.int(c.by_level([ 1..10, 2..20, 3..40, 4..80, 6..200, 8..500 ]))
  right_const = ((a - d) * x) + b

  c.q(
    text: "Намери x от уравнението #{a}x + #{b} = #{d}x + #{right_const}.",
    answer: Num.ans(x),
    explanation: Explain.build(
      idea: "Събираме неизвестните от едната страна, числата — от другата.",
      steps: [
        "Изваждаме #{d}x от двете страни: #{a - d}x + #{b} = #{right_const}.",
        "Изваждаме #{b}: #{a - d}x = #{right_const - b}.",
        "x = #{right_const - b} : #{a - d} = #{x}."
      ],
      answer: "x = #{x}",
      check: "Лявата страна: #{a} · #{x} + #{b} = #{(a * x) + b}. Дясната: #{d} · #{x} + #{right_const} = #{(d * x) + right_const}. Равни са.",
      watch: "Членовете с x се събират помежду си, а числата — помежду си; не се смесват."
    )
  )
end

Authoring.family "eq.with_fraction", topic: "Уравнения", area: "word_problems",
                 rungs: [ 1250, 1340, 1430, 1520, 1610, 1710 ] do |c|
  denominator = c.int(c.by_level([ 2..4, 2..6, 3..8, 4..12, 5..20, 6..40 ]))
  x = c.int(2..c.by_level([ 8, 12, 20, 40, 90, 200 ])) * denominator
  b = c.int(c.by_level([ 1..10, 2..20, 3..40, 4..80, 6..200, 8..500 ]))
  minus = c.coin
  right = minus ? (x / denominator) - b : (x / denominator) + b

  c.q(
    text: "Намери x от уравнението x : #{denominator} #{minus ? Num::MINUS : '+'} #{b} = #{Num.bg(right)}.",
    answer: Num.ans(x),
    explanation: Explain.build(
      idea: "Първо освобождаваме частното от свободния член, после умножаваме по знаменателя.",
      steps: [
        minus ? "x : #{denominator} = #{Num.bg(right)} + #{b} = #{x / denominator}." : "x : #{denominator} = #{Num.bg(right)} − #{b} = #{x / denominator}.",
        "x = #{x / denominator} · #{denominator} = #{x}."
      ],
      answer: "x = #{x}",
      check: "#{x} : #{denominator} = #{x / denominator}, а #{x / denominator} #{minus ? Num::MINUS : '+'} #{b} = #{Num.bg(right)}.",
      watch: "Делението се маха с умножение — обратното действие, приложено към двете страни."
    )
  )
end

Authoring.family "eq.from_story", topic: "Уравнения", area: "word_problems",
                 rungs: [ 1150, 1240, 1330, 1420, 1510, 1610 ] do |c|
  times = c.int(c.by_level([ 2..3, 2..4, 2..5, 3..6, 3..8, 4..12 ]))
  x = c.int(c.by_level([ 2..10, 3..20, 4..40, 5..80, 8..200, 10..500 ]))
  extra = c.int(c.by_level([ 1..10, 2..20, 3..40, 5..80, 8..200, 10..500 ]))
  total = (times * x) + extra
  who = c.person
  item = c.thing

  c.q(
    text: "#{who} има #{times} пъти повече #{item.many} от брата си и още #{extra} отгоре. " \
          "Общо двамата имат #{total + x} #{item.many}. Колко #{item.many} има братът?",
    answer: Num.ans(x),
    explanation: Explain.build(
      idea: "Означаваме търсеното с x и записваме условието като уравнение.",
      steps: [
        "Брат: x. #{who}: #{times}x + #{extra}.",
        "Заедно: x + #{times}x + #{extra} = #{total + x}, значи #{times + 1}x = #{total + x - extra}.",
        "x = #{total + x - extra} : #{times + 1} = #{x}."
      ],
      answer: "#{item.count(x)}",
      check: "#{who} има #{times} · #{x} + #{extra} = #{total} — заедно #{total + x}.",
      watch: "Неизвестното е количеството на брата; на #{who} се пада изразът, не числото."
    )
  )
end

Authoring.family "eq.proportion", topic: "Уравнения", area: "word_problems",
                 rungs: [ 1180, 1270, 1360, 1450, 1540, 1640 ] do |c|
  a = c.int(c.by_level([ 2..6, 2..9, 3..12, 4..20, 5..40, 6..90 ]))
  b = c.int(c.by_level([ 2..6, 2..9, 3..12, 4..20, 5..40, 6..90 ]))
  k = c.int(2..c.by_level([ 4, 6, 8, 12, 20, 40 ]))
  x = a * k
  d = b * k

  c.q(
    text: "Намери x от пропорцията #{a} : #{b} = x : #{d}.",
    answer: Num.ans(x),
    explanation: Explain.build(
      idea: "В пропорция произведението на крайните членове е равно на произведението на средните.",
      steps: [
        "#{a} · #{d} = #{b} · x, значи #{a * d} = #{b}x.",
        "x = #{a * d} : #{b} = #{x}."
      ],
      answer: "x = #{x}",
      check: "#{a} : #{b} = #{Num.frac(a, b)} и #{x} : #{d} = #{Num.frac(x, d)} — двете отношения са равни.",
      watch: "Умножават се „кръстосано“ — не се събират съответните членове."
    )
  )
end

Authoring.family "eq.check_solution", topic: "Уравнения", area: "word_problems",
                 rungs: [ 1080, 1170, 1260, 1350, 1440, 1540 ] do |c|
  a = c.int(c.by_level([ 2..5, 2..8, 3..12, 4..20, 5..40, 6..90 ]))
  x = c.int(c.by_level([ 2..9, 2..15, 3..25, 4..50, 5..120, 6..300 ]))
  b = c.int(c.by_level([ 1..12, 2..25, 3..50, 5..120, 8..300, 10..800 ]))
  right = (a * x) + b
  wrong = [ x + 1, x - 1, right - b, (right / a).to_i + 2 ].uniq.reject { |value| value == x || value <= 0 }
  raise Authoring::Duplicate if wrong.size < 3

  c.q(
    text: "Кое от числата е решение на уравнението #{a}x + #{b} = #{right}?",
    options: c.options(x, wrong.first(3)),
    answer: Num.ans(x),
    explanation: Explain.build(
      idea: "Решение е числото, което прави равенството вярно — може да се провери направо, като се замести.",
      steps: [
        "Заместваме x = #{x}: #{a} · #{x} + #{b} = #{a * x} + #{b} = #{right}. Вярно.",
        "За x = #{wrong.first}: #{a} · #{wrong.first} + #{b} = #{(a * wrong.first) + b} ≠ #{right}."
      ],
      answer: "x = #{x}",
      check: "Решаването дава същото: #{right} − #{b} = #{a * x}, а #{a * x} : #{a} = #{x}.",
      watch: "Линейно уравнение с ненулев коефициент има точно едно решение."
    )
  )
end

Authoring.family "eq.perimeter_equation", topic: "Уравнения", area: "word_problems",
                 rungs: [ 1220, 1310, 1400, 1490, 1580, 1680 ] do |c|
  width = c.int(c.by_level([ 2..8, 3..15, 4..25, 5..50, 8..120, 10..300 ]))
  extra = c.int(c.by_level([ 1..6, 2..10, 3..18, 4..40, 5..90, 6..200 ]))
  length = width + extra
  perimeter = 2 * (width + length)

  c.q(
    text: "Правоъгълник има периметър #{perimeter} см, а дължината му е с #{extra} см по-голяма от ширината. " \
          "Колко сантиметра е ширината?",
    answer: Num.ans(width),
    explanation: Explain.build(
      idea: "Означаваме ширината с x; тогава дължината е x + #{extra}, а периметърът дава уравнението.",
      steps: [
        "2(x + x + #{extra}) = #{perimeter}, значи 2(2x + #{extra}) = #{perimeter}.",
        "4x + #{2 * extra} = #{perimeter}, откъдето 4x = #{perimeter - (2 * extra)}.",
        "x = #{perimeter - (2 * extra)} : 4 = #{width} см."
      ],
      answer: "#{width} см",
      check: "Дължина #{length} см, ширина #{width} см: P = 2 · (#{length} + #{width}) = #{perimeter} см.",
      watch: "Периметърът съдържа всяка страна по два пъти — затова делението е на 4, не на 2."
    )
  )
end
