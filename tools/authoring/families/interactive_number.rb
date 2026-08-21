# Интерактивни задачи: числа, аритметика, дроби, проценти.
#
# Every family here asks the student to *do* something — choose every number
# that fits, sort into groups, fill the holes in a table, shade a fraction —
# rather than type a single number. The widget kit builds the JSON; the text
# still carries all the numbers, so the question reads on its own.

# ---------------------------------------------------- Избор на всички верни ---

Authoring.family "pick.divisible", topic: "Делимост", area: "interactive_number", variants: 11,
                 rungs: [ 900, 990, 1080, 1170, 1260, 1350 ] do |c|
  divisor = c.pick(c.by_level([ [ 2, 5 ], [ 2, 3, 5 ], [ 3, 4, 9 ], [ 4, 6, 9 ], [ 6, 8, 12 ], [ 7, 11, 12 ] ]))
  size = c.by_level([ 2, 2, 3, 3, 4, 4 ])
  pool = []
  12.times do
    number = c.int((10**(size - 1))..((10**size) - 1))
    pool << number unless pool.include?(number)
  end
  hits = pool.select { |number| (number % divisor).zero? }
  hits = hits.first(3)
  misses = (pool - hits).first(6 - hits.size)
  raise Authoring::Duplicate if hits.size < 2 || misses.size < 2

  options = (hits + misses).sort.map { |number| [ number.to_s, hits.include?(number) ] }

  c.q(
    text: "Избери всички числа от списъка #{options.map(&:first).join(', ')}, които се делят на #{divisor}.",
    widget: WidgetKit.multi_select(options),
    explanation: Explain.build(
      idea: divisor == 2 || divisor == 5 ? "Признакът за делимост на #{divisor} гледа последната цифра." :
            [ 3, 9 ].include?(divisor) ? "Число се дели на #{divisor}, когато сборът на цифрите му се дели на #{divisor}." :
            "Проверяваме всяко число поотделно: дели ли се точно на #{divisor}.",
      steps: [
        hits.map { |n| "#{n} : #{divisor} = #{n / divisor}" }.join(", ") + " — тези се делят.",
        misses.map { |n| "#{n} : #{divisor} дава остатък #{n % divisor}" }.join(", ") + " — тези не се делят."
      ],
      answer: hits.sort.join(", "),
      check: "Всяко избрано число трябва да е кратно на #{divisor}: #{hits.sort.map { |n| "#{divisor} · #{n / divisor}" }.join(', ')}.",
      watch: "Търсят се всички подходящи числа — спирането на първото намерено е половин отговор."
    )
  )
end

Authoring.family "pick.primes", topic: "Прости числа", area: "interactive_number", variants: 11,
                 rungs: [ 1000, 1090, 1180, 1270, 1360, 1450 ] do |c|
  band = c.by_level([ 2..40, 10..70, 20..120, 40..200, 80..400, 150..900 ])
  primes = Num.primes_upto(band.max).select { |p| band.include?(p) }
  composites = band.to_a - primes
  chosen_primes = c.sample(primes, c.int(2..3))
  chosen_composites = c.sample(composites.reject { |n| n < 4 }, 6 - chosen_primes.size)
  raise Authoring::Duplicate if chosen_primes.size < 2 || chosen_composites.size < 2

  options = (chosen_primes + chosen_composites).sort.map { |n| [ n.to_s, chosen_primes.include?(n) ] }

  c.q(
    text: "Избери всички прости числа сред #{options.map(&:first).join(', ')}.",
    widget: WidgetKit.multi_select(options),
    explanation: Explain.build(
      idea: "Просто число има точно два делителя: 1 и себе си. Достатъчно е да пробваме прости делители до корена му.",
      steps: [
        "Прости: #{chosen_primes.sort.join(', ')} — не се делят на нищо освен на 1 и на себе си.",
        "Съставни: #{chosen_composites.sort.map { |n| "#{n} = #{Num.factor_string(n)}" }.join('; ')}."
      ],
      answer: chosen_primes.sort.join(", "),
      check: "Всяко просто число тук е нечетно (освен 2) и не се дели на 3, 5 или 7.",
      watch: "1 не е просто число, а 2 е — единственото четно просто."
    )
  )
end

Authoring.family "pick.equivalent_fractions", topic: "Дроби", area: "interactive_number", variants: 11,
                 rungs: [ 1050, 1140, 1230, 1320, 1410, 1500 ] do |c|
  denominator = c.int(c.by_level([ 2..4, 2..5, 3..6, 3..8, 4..10, 5..12 ]))
  numerator = c.int(1...denominator)
  raise Authoring::Duplicate if Num.gcd(numerator, denominator) != 1

  target = Rational(numerator, denominator)
  equal = c.sample((2..6).to_a, 2).map { |k| Rational(numerator * k, denominator * k) }
  others = []
  10.times do
    d = c.int(2..12)
    n = c.int(1...d)
    candidate = Rational(n, d)
    others << candidate if candidate != target && !others.include?(candidate)
  end
  others = others.first(3)
  raise Authoring::Duplicate if others.size < 3

  options = (equal + others).map { |value| [ "#{value.numerator}/#{value.denominator}", value == target ] }.uniq { |label, _| label }

  c.q(
    text: "Избери всички дроби, равни на #{Num.frac(target)}, сред #{options.map(&:first).join(', ')}.",
    widget: WidgetKit.multi_select(options),
    explanation: Explain.build(
      idea: "Дроб не се променя, ако числителят и знаменателят се умножат по едно и също число.",
      steps: [
        equal.map { |value| "#{value.numerator}/#{value.denominator} : #{Num.gcd(value.numerator, value.denominator)} = #{Num.frac(target)}" }.join(", ") + ".",
        others.map { |value| "#{value.numerator}/#{value.denominator} = #{Num.dec(value, 3)}, а #{Num.frac(target)} = #{Num.dec(target, 3)}" }.join("; ") + "."
      ],
      answer: equal.map { |value| "#{value.numerator}/#{value.denominator}" }.join(", "),
      check: "Всички избрани дроби дават една и съща десетична стойност: #{Num.dec(target, 3)}.",
      watch: "Съкращаването е деление и на двете части — не изваждане на едно и също число."
    )
  )
end

Authoring.family "pick.multiples_of", topic: "Умножение и деление", area: "interactive_number", variants: 11,
                 rungs: [ 760, 850, 940, 1030, 1120, 1210 ] do |c|
  base = c.int(c.by_level([ 2..5, 2..7, 3..9, 4..12, 6..15, 7..25 ]))
  count = c.by_level([ 5, 5, 6, 6, 6, 6 ])
  multiples = c.sample((2..12).to_a, 3).map { |k| base * k }
  others = []
  12.times do
    candidate = c.int((base * 2)..(base * 13))
    others << candidate if !(candidate % base).zero? && !others.include?(candidate) && !multiples.include?(candidate)
  end
  others = others.first(count - 3)
  raise Authoring::Duplicate if others.size < 2

  options = (multiples + others).sort.map { |n| [ n.to_s, multiples.include?(n) ] }

  c.q(
    text: "Избери всички кратни на #{base} сред числата #{options.map(&:first).join(', ')}.",
    widget: WidgetKit.multi_select(options),
    explanation: Explain.build(
      idea: "Кратните на #{base} са числата, които се получават при умножение на #{base} с цяло число.",
      steps: [
        "Кратни: #{multiples.sort.map { |n| "#{n} = #{base} · #{n / base}" }.join(', ')}.",
        "Останалите дават остатък: #{others.sort.map { |n| "#{n} : #{base} → остатък #{n % base}" }.join(', ')}."
      ],
      answer: multiples.sort.join(", "),
      check: "Всяко кратно се дели точно на #{base}.",
      watch: "Кратно и делител са различни неща: 12 е кратно на 3, а 3 е делител на 12."
    )
  )
end

Authoring.family "pick.rounding_targets", topic: "Числа и редици", area: "interactive_number", variants: 11,
                 rungs: [ 950, 1040, 1130, 1220, 1310, 1400 ] do |c|
  unit = c.by_level([ 10, 10, 100, 100, 1000, 1000 ])
  target = c.int(2..40) * unit
  hits = c.sample(((target - (unit / 2))...(target + (unit / 2))).to_a, 3)
  misses = c.sample((((target + (unit / 2))...(target + (unit * 3 / 2))).to_a + ((target - (unit * 3 / 2))...(target - (unit / 2))).to_a), 3)
  raise Authoring::Duplicate if hits.size < 3 || misses.size < 3

  options = (hits + misses).sort.map { |n| [ n.to_s, hits.include?(n) ] }

  c.q(
    text: "Избери всички числа сред #{options.map(&:first).join(', ')}, които при закръгляне до най-близките " \
          "#{unit == 10 ? 'десетици' : unit == 100 ? 'стотици' : 'хиляди'} дават #{target}.",
    widget: WidgetKit.multi_select(options),
    explanation: Explain.build(
      idea: "До #{target} се закръглят числата, които стоят по-близо до #{target}, отколкото до съседните кръгли числа.",
      steps: [
        "Границите са #{target - (unit / 2)} и #{target + (unit / 2)}.",
        "Вътре попадат #{hits.sort.join(', ')}.",
        "Извън остават #{misses.sort.join(', ')} — те се закръглят до #{misses.sort.map { |n| ((n + (unit / 2)) / unit) * unit }.uniq.join(' или ')}."
      ],
      answer: hits.sort.join(", "),
      check: "Всяко избрано число се различава от #{target} с по-малко от #{unit / 2}.",
      watch: "Точно на средата (#{target + (unit / 2)}) закръгляваме нагоре, тоест до следващото кръгло число."
    )
  )
end

Authoring.family "pick.percent_of", topic: "Проценти", area: "interactive_number", variants: 11,
                 rungs: [ 1150, 1240, 1330, 1420, 1510, 1600 ] do |c|
  base = c.int(c.by_level([ 2..8, 2..12, 3..20, 4..40, 6..90, 8..200 ])) * 100
  correct_pairs = c.sample([ 10, 20, 25, 50, 5, 40, 75 ], 2).map { |pct| [ pct, base * pct / 100 ] }
  wrong_pairs = correct_pairs.map { |pct, value| [ pct, value + c.pick([ base / 100, -base / 100, base / 50 ]) ] }
  extra = [ [ c.pick([ 15, 30, 60, 80 ]), base / 3 ] ]
  options = (correct_pairs.map { |pct, value| [ "#{pct}% от #{base} = #{value}", true ] } +
             wrong_pairs.map { |pct, value| [ "#{pct}% от #{base} = #{value}", false ] } +
             extra.map { |pct, value| [ "#{pct}% от #{base} = #{value}", false ] }).uniq { |label, _| label }
  raise Authoring::Duplicate if options.count { |_, ok| ok } < 2 || options.size < 5

  c.q(
    text: "Избери всички верни твърдения за числото #{base}.",
    widget: WidgetKit.multi_select(options),
    explanation: Explain.build(
      idea: "1% от #{base} е #{base / 100}, затова всеки процент се пресмята като #{base / 100} · процента.",
      steps: correct_pairs.map { |pct, value| "#{pct}% = #{base / 100} · #{pct} = #{value}" } +
             [ "Останалите твърдения се разминават с точната стойност." ],
      answer: correct_pairs.map { |pct, value| "#{pct}% от #{base} = #{value}" }.join("; "),
      check: "Сборът 100% трябва да върне самото число: #{base / 100} · 100 = #{base}.",
      watch: "Проверява се всяко твърдение поотделно — верните може да са повече от едно."
    )
  )
end

# --------------------------------------------------------------- Групиране ---

Authoring.family "sortbins.prime_composite", topic: "Прости числа", area: "interactive_number", variants: 11,
                 rungs: [ 1020, 1110, 1200, 1290, 1380, 1470 ] do |c|
  band = c.by_level([ 2..30, 5..60, 10..100, 20..200, 40..400, 80..900 ])
  primes = Num.primes_upto(band.max).select { |p| band.include?(p) }
  composites = (band.to_a - primes).reject { |n| n < 4 }
  chosen = c.sample(primes, 2) + c.sample(composites, 3)
  raise Authoring::Duplicate if chosen.uniq.size < 5

  items = chosen.sort.each_with_index.map { |n, i| [ "n#{i}", n.to_s, Num.prime?(n) ? "p" : "c" ] }

  c.q(
    text: "Разпредели числата #{chosen.sort.join(', ')} на прости и съставни.",
    widget: WidgetKit.categorize(bins: [ [ "p", "просто" ], [ "c", "съставно" ] ], items: items),
    explanation: Explain.build(
      idea: "Просто число има точно два делителя; съставното има поне три.",
      steps: [
        "Прости: #{chosen.select { |n| Num.prime?(n) }.sort.join(', ')}.",
        "Съставни: #{chosen.reject { |n| Num.prime?(n) }.sort.map { |n| "#{n} = #{Num.factor_string(n)}" }.join('; ')}."
      ],
      answer: "прости: #{chosen.select { |n| Num.prime?(n) }.sort.join(', ')}; съставни: #{chosen.reject { |n| Num.prime?(n) }.sort.join(', ')}",
      check: "Всяко съставно число тук е записано като произведение на по-малки множители.",
      watch: "Достатъчно е един делител, различен от 1 и от самото число, за да е съставно."
    )
  )
end

Authoring.family "sortbins.fraction_size", topic: "Дроби", area: "interactive_number", variants: 11,
                 rungs: [ 1100, 1190, 1280, 1370, 1460, 1550 ] do |c|
  pivot = c.pick(c.by_level([ [ Rational(1, 2) ], [ Rational(1, 2) ], [ Rational(1, 2), Rational(1, 3) ],
                              [ Rational(1, 2), Rational(2, 3) ], [ Rational(1, 3), Rational(3, 4) ], [ Rational(2, 5), Rational(5, 6) ] ]))
  values = []
  10.times do
    d = c.int(2..c.by_level([ 6, 8, 9, 10, 12, 16 ]))
    n = c.int(1...d)
    value = Rational(n, d)
    values << value if value != pivot && !values.include?(value)
  end
  values = values.first(5)
  raise Authoring::Duplicate if values.size < 5 || values.count { |v| v < pivot } < 2 || values.count { |v| v > pivot } < 2

  items = values.each_with_index.map { |value, i| [ "f#{i}", Num.frac(value), value < pivot ? "lt" : "gt" ] }

  c.q(
    text: "Разпредели дробите #{values.map { |v| Num.frac(v) }.join(', ')} според това дали са по-малки или по-големи от #{Num.frac(pivot)}.",
    widget: WidgetKit.categorize(bins: [ [ "lt", "по-малки" ], [ "gt", "по-големи" ] ], items: items),
    explanation: Explain.build(
      idea: "Сравняваме всяка дроб с #{Num.frac(pivot)} — най-бързо през десетичния ѝ вид или през общ знаменател.",
      steps: [
        values.map { |v| "#{Num.frac(v)} ≈ #{Num.dec(v, 3)}" }.join(", ") + ".",
        "#{Num.frac(pivot)} = #{Num.dec(pivot, 3)}, затова по-малки са #{values.select { |v| v < pivot }.map { |v| Num.frac(v) }.join(', ')}."
      ],
      answer: "по-малки: #{values.select { |v| v < pivot }.map { |v| Num.frac(v) }.join(', ')}",
      check: "Всяка дроб от втората група минус #{Num.frac(pivot)} дава положително число.",
      watch: "Голям знаменател не значи голяма дроб — важно е отношението между числителя и знаменателя."
    )
  )
end

Authoring.family "sortbins.number_kind", topic: "Числа и редици", area: "interactive_number", variants: 11,
                 rungs: [ 880, 970, 1060, 1150, 1240, 1330 ] do |c|
  kind = c.by_level([ :parity, :parity, :sign, :sign, :square, :square ])
  case kind
  when :parity
    values = c.sample((c.by_level([ 1..40, 1..80, 10..200, 20..500, 50..2000, 100..9000 ])).to_a, 5)
    bins = [ [ "e", "четни" ], [ "o", "нечетни" ] ]
    assign = ->(n) { n.even? ? "e" : "o" }
    idea = "Четно е числото, което се дели на 2 без остатък; последната му цифра е 0, 2, 4, 6 или 8."
  when :sign
    bound = c.by_level([ 9, 20, 50, 100, 500, 2000 ])
    values = c.sample((-bound..bound).to_a, 5)
    raise Authoring::Duplicate if values.none?(&:negative?) || values.none?(&:positive?)

    bins = [ [ "n", "отрицателни" ], [ "p", "положителни" ] ]
    assign = ->(n) { n.negative? ? "n" : "p" }
    idea = "Отрицателните числа стоят вляво от нулата по числовата ос."
  else
    squares = (2..30).map { |n| n * n }
    values = c.sample(squares, 2) + c.sample((4..900).to_a - squares, 3)
    bins = [ [ "s", "точни квадрати" ], [ "x", "не са" ] ]
    assign = ->(n) { squares.include?(n) ? "s" : "x" }
    idea = "Точен квадрат е числото, което е квадрат на цяло число."
  end
  raise Authoring::Duplicate if values.uniq.size < 5

  items = values.each_with_index.map { |n, i| [ "v#{i}", Num.bg(n), assign.call(n) ] }

  c.q(
    text: "Разпредели числата #{values.map { |n| Num.bg(n) }.join(', ')} в правилните групи.",
    widget: WidgetKit.categorize(bins: bins, items: items),
    explanation: Explain.build(
      idea: idea,
      steps: bins.map { |id, label| "#{label.capitalize}: #{values.select { |n| assign.call(n) == id }.map { |n| Num.bg(n) }.join(', ')}." },
      answer: bins.map { |id, label| "#{label}: #{values.select { |n| assign.call(n) == id }.map { |n| Num.bg(n) }.join(', ')}" }.join("; "),
      check: "Всяко число попада в точно една от двете групи.",
      watch: kind == :square ? "16 е точен квадрат (4²), но 18 не е — между 4² и 5² няма друг квадрат." : "Групите не се застъпват — числото е или в едната, или в другата."
    )
  )
end

# --------------------------------------------------------------- Свързване ---

Authoring.family "match.fraction_percent", topic: "Проценти", area: "interactive_number", variants: 11,
                 rungs: [ 1080, 1170, 1260, 1350, 1440, 1530 ] do |c|
  pool = c.by_level([
    [ [ Rational(1, 2), "50%" ], [ Rational(1, 4), "25%" ], [ Rational(3, 4), "75%" ], [ Rational(1, 10), "10%" ] ],
    [ [ Rational(1, 5), "20%" ], [ Rational(2, 5), "40%" ], [ Rational(3, 5), "60%" ], [ Rational(4, 5), "80%" ] ],
    [ [ Rational(1, 20), "5%" ], [ Rational(3, 10), "30%" ], [ Rational(7, 10), "70%" ], [ Rational(9, 10), "90%" ] ],
    [ [ Rational(1, 8), "12,5%" ], [ Rational(3, 8), "37,5%" ], [ Rational(5, 8), "62,5%" ], [ Rational(7, 8), "87,5%" ] ],
    [ [ Rational(1, 25), "4%" ], [ Rational(7, 20), "35%" ], [ Rational(13, 20), "65%" ], [ Rational(21, 25), "84%" ] ],
    [ [ Rational(3, 16), "18,75%" ], [ Rational(11, 40), "27,5%" ], [ Rational(17, 25), "68%" ], [ Rational(29, 50), "58%" ] ]
  ])
  pairs = c.sample(pool, 3).map { |value, label| [ Num.frac(value), label ] }
  raise Authoring::Duplicate if pairs.size < 3

  c.q(
    text: "Свържи всяка дроб с равния ѝ процент: #{pairs.map(&:first).join(', ')}.",
    widget: WidgetKit.matcher(pairs),
    explanation: Explain.build(
      idea: "Дроб се превръща в процент чрез умножение по 100.",
      steps: pairs.map { |fraction, percent| "#{fraction} · 100 = #{percent.delete('%')} → #{percent}" },
      answer: pairs.map { |fraction, percent| "#{fraction} = #{percent}" }.join(", "),
      check: "Сборът на дроб и допълнението ѝ до 1 дава 100%.",
      watch: "Числителят не е процентът: 3/8 не е 3%."
    )
  )
end

Authoring.family "match.expression_value", topic: "Ред на действията", area: "interactive_number", variants: 11,
                 rungs: [ 1000, 1090, 1180, 1270, 1360, 1450 ] do |c|
  spec = c.by_level([ 2..6, 2..9, 3..12, 4..20, 6..40, 8..90 ])
  pairs = 3.times.map do
    a = c.int(spec)
    b = c.int(2..9)
    d = c.int(spec)
    kind = c.pick([ :mul_add, :brackets, :mul_sub ])
    case kind
    when :mul_add then [ "#{a} · #{b} + #{d}", (a * b) + d ]
    when :mul_sub then [ "#{a} · #{b} #{Num::MINUS} #{d}", (a * b) - d ]
    else [ "(#{a} + #{d}) · #{b}", (a + d) * b ]
    end
  end
  raise Authoring::Duplicate if pairs.map(&:last).uniq.size < 3 || pairs.map(&:last).any?(&:negative?)

  c.q(
    text: "Свържи всеки израз със стойността му: #{pairs.map(&:first).join('; ')}.",
    widget: WidgetKit.matcher(pairs.map { |expression, value| [ expression, value.to_s ] }),
    explanation: Explain.build(
      idea: "Първо скобите, после умножението и делението, накрая събирането и изваждането.",
      steps: pairs.map { |expression, value| "#{expression} = #{value}" },
      answer: pairs.map { |expression, value| "#{expression} → #{value}" }.join(", "),
      check: "Две различни подредби на едни и същи числа обикновено дават различни стойности — затова редът има значение.",
      watch: "Скобите променят реда: (a + b) · c не е a + b · c."
    )
  )
end

Authoring.family "match.number_property", topic: "Делимост", area: "interactive_number", variants: 11,
                 rungs: [ 1120, 1210, 1300, 1390, 1480, 1570 ] do |c|
  numbers = c.sample((c.by_level([ 6..40, 10..80, 12..150, 20..300, 30..600, 40..900 ])).to_a, 3)
  raise Authoring::Duplicate if numbers.any? { |n| Num.divisors(n).size < 3 }

  kind = c.by_level([ :divisors, :divisors, :factorization, :factorization, :sum_digits, :largest_divisor ])
  pairs = numbers.map do |n|
    case kind
    when :divisors then [ n.to_s, "#{Num.divisors(n).size} делителя" ]
    when :factorization then [ n.to_s, Num.factor_string(n) ]
    when :sum_digits then [ n.to_s, "сбор на цифрите #{n.to_s.chars.map(&:to_i).sum}" ]
    else [ n.to_s, "най-голям собствен делител #{Num.divisors(n)[-2]}" ]
    end
  end
  raise Authoring::Duplicate if pairs.map(&:last).uniq.size < 3

  c.q(
    text: "Свържи всяко число с описанието му: #{numbers.join(', ')}.",
    widget: WidgetKit.matcher(pairs),
    explanation: Explain.build(
      idea: "Разлагаме всяко число на прости множители — оттам се четат и делителите му.",
      steps: numbers.map { |n| "#{n} = #{Num.factor_string(n)}, делители: #{Num.divisors(n).join(', ')}" },
      answer: pairs.map { |left, right| "#{left} → #{right}" }.join(", "),
      check: "Броят делители се чете от степените в разлагането: (a+1)(b+1)...",
      watch: "1 и самото число също са делители."
    )
  )
end

# ---------------------------------------------------------------- Попълване ---

Authoring.family "blank.division_remainder", topic: "Остатъци", area: "interactive_number", variants: 11,
                 rungs: [ 980, 1070, 1160, 1250, 1340, 1430 ] do |c|
  divisor = c.int(c.by_level([ 3..6, 3..9, 4..12, 5..20, 6..40, 8..90 ]))
  quotient = c.int(c.by_level([ 2..9, 3..15, 4..30, 6..60, 8..150, 10..400 ]))
  rest = c.int(1...divisor)
  dividend = (divisor * quotient) + rest

  c.q(
    text: "Раздели #{dividend} на #{divisor} и попълни частното и остатъка.",
    widget: WidgetKit.blanks([ [ "q", "частно", quotient ], [ "r", "остатък", rest ] ],
                             prompt: "#{dividend} : #{divisor}"),
    explanation: Explain.build(
      idea: "Търсим най-голямото кратно на #{divisor}, което не надминава #{dividend}; остатъкът е това, което остава.",
      steps: [
        "#{divisor} · #{quotient} = #{divisor * quotient} ≤ #{dividend}.",
        "#{dividend} − #{divisor * quotient} = #{rest}.",
        "Значи #{dividend} = #{divisor} · #{quotient} + #{rest}."
      ],
      answer: "частно #{quotient}, остатък #{rest}",
      check: "Остатъкът винаги е по-малък от делителя: #{rest} < #{divisor}.",
      watch: "Ако остатъкът излезе по-голям от #{divisor - 1}, частното е взето твърде малко."
    )
  )
end

Authoring.family "blank.missing_digits_sum", topic: "Събиране и изваждане", area: "interactive_number", variants: 11,
                 rungs: [ 1050, 1140, 1230, 1320, 1410, 1500 ] do |c|
  size = c.by_level([ 2, 2, 3, 3, 4, 4 ])
  a = c.int((10**(size - 1))..((10**size) - 1))
  b = c.int((10**(size - 1))..((10**size) - 1))
  sum = a + b
  hidden_a = c.int(0...size)
  hidden_b = c.int(0...size)
  digits_a = a.to_s.chars
  digits_b = b.to_s.chars
  masked_a = digits_a.each_with_index.map { |digit, i| i == hidden_a ? "☐" : digit }.join
  masked_b = digits_b.each_with_index.map { |digit, i| i == hidden_b ? "☐" : digit }.join

  c.q(
    text: "В събирането #{masked_a} + #{masked_b} = #{sum} са скрити две цифри. " \
          "Попълни първо скритата цифра от #{masked_a}, после тази от #{masked_b}.",
    widget: WidgetKit.blanks([ [ "a", "първо число", digits_a[hidden_a] ], [ "b", "второ число", digits_b[hidden_b] ] ]),
    explanation: Explain.build(
      idea: "Възстановяваме сбора разред по разред, започвайки от единиците, където няма наум отвън.",
      steps: [
        "Единиците на сбора са #{sum % 10}: #{digits_a.last} + #{digits_b.last} = #{digits_a.last.to_i + digits_b.last.to_i}.",
        "Продължаваме нагоре, като следим пренасянето.",
        "Скритите цифри са #{digits_a[hidden_a]} и #{digits_b[hidden_b]}: #{a} + #{b} = #{sum}."
      ],
      answer: "#{digits_a[hidden_a]} и #{digits_b[hidden_b]}",
      check: "#{a} + #{b} = #{sum} — събирането излиза точно.",
      watch: "Пренесената единица идва от предишния разред — без нея цифрата излиза с 1 по-малка."
    )
  )
end

Authoring.family "blank.gcd_lcm_pair", topic: "НОД и НОК", area: "interactive_number", variants: 11,
                 rungs: [ 1200, 1290, 1380, 1470, 1560, 1650 ] do |c|
  spec = c.by_level([ 2..10, 3..16, 4..24, 6..40, 8..70, 10..120 ])
  a = c.int(spec)
  b = c.int(spec)
  raise Authoring::Duplicate if a == b

  gcd = Num.gcd(a, b)
  lcm = Num.lcm(a, b)

  c.q(
    text: "За числата #{a} и #{b} попълни най-големия общ делител и най-малкото общо кратно.",
    widget: WidgetKit.blanks([ [ "gcd", "НОД", gcd ], [ "lcm", "НОК", lcm ] ], prompt: "#{a} и #{b}"),
    explanation: Explain.build(
      idea: "Разлагаме двете числа на прости множители: общите множители дават НОД, всички множители — НОК.",
      steps: [
        "#{a} = #{Num.factor_string(a)}, #{b} = #{Num.factor_string(b)}.",
        "НОД(#{a}, #{b}) = #{gcd}.",
        "НОК = #{a} · #{b} : НОД = #{a * b} : #{gcd} = #{lcm}."
      ],
      answer: "НОД = #{gcd}, НОК = #{lcm}",
      check: "#{gcd} · #{lcm} = #{gcd * lcm} = #{a} · #{b}.",
      watch: "НОД не може да е по-голям от по-малкото число, а НОК не може да е по-малък от по-голямото."
    )
  )
end

Authoring.family "blank.fraction_to_mixed", topic: "Дроби", area: "interactive_number", variants: 11,
                 rungs: [ 1000, 1090, 1180, 1270, 1360, 1450 ] do |c|
  denominator = c.int(c.by_level([ 2..5, 3..7, 3..9, 4..12, 5..16, 6..24 ]))
  whole = c.int(c.by_level([ 1..3, 1..5, 2..8, 2..12, 3..20, 4..40 ]))
  rest = c.int(1...denominator)
  improper = (whole * denominator) + rest

  c.q(
    text: "Запиши #{improper}/#{denominator} като смесено число: попълни цялата част и числителя на дробната част.",
    widget: WidgetKit.blanks([ [ "w", "цяло", whole ], [ "n", "числител", rest ] ],
                             prompt: "#{improper}/#{denominator} = ☐ цяло и ☐/#{denominator}"),
    explanation: Explain.build(
      idea: "Делим числителя на знаменателя: частното е цялата част, остатъкът остава в дробта.",
      steps: [
        "#{improper} : #{denominator} = #{whole} и остатък #{rest}.",
        "Значи #{improper}/#{denominator} = #{whole} цяло и #{rest}/#{denominator}."
      ],
      answer: "#{whole} цяло и #{rest}/#{denominator}",
      check: "#{whole} · #{denominator} + #{rest} = #{improper}.",
      watch: "Знаменателят не се променя при превръщането."
    )
  )
end

Authoring.family "blank.percent_triple", topic: "Проценти", area: "interactive_number", variants: 11,
                 rungs: [ 1250, 1340, 1430, 1520, 1610, 1700 ] do |c|
  pct = c.pick(c.by_level([ [ 10, 50 ], [ 20, 25 ], [ 15, 40 ], [ 12, 35 ], [ 8, 65 ], [ 6, 44 ] ]))
  unit = c.int(c.by_level([ 1..8, 2..15, 3..30, 4..60, 6..120, 8..250 ]))
  base = 100 * unit
  part = pct * unit
  rest = base - part

  c.q(
    text: "От #{base} лв. #{pct}% са похарчени. Попълни колко лева са похарчени и колко остават.",
    widget: WidgetKit.blanks([ [ "spent", "похарчени", part, "лв." ], [ "left", "остават", rest, "лв." ] ]),
    explanation: Explain.build(
      idea: "Процентът се смята от цялото, а остатъкът е допълнението до 100%.",
      steps: [
        "1% от #{base} е #{unit} лв.",
        "#{pct}% са #{pct} · #{unit} = #{part} лв.",
        "Остават #{base} − #{part} = #{rest} лв., тоест #{100 - pct}%."
      ],
      answer: "#{part} лв. похарчени, #{rest} лв. остават",
      check: "#{part} + #{rest} = #{base} лв.",
      watch: "Двете числа заедно дават цялото — ако не дават, някъде има грешка."
    )
  )
end

# ------------------------------------------------------------------ Таблици ---

Authoring.family "table.times_gaps", topic: "Умножение и деление", area: "interactive_number", variants: 11,
                 rungs: [ 780, 870, 960, 1050, 1140, 1230 ] do |c|
  factors = c.sample((2..c.by_level([ 6, 8, 10, 12, 15, 20 ])).to_a, 3).sort
  others = c.sample((2..c.by_level([ 6, 8, 10, 12, 15, 20 ])).to_a, 3).sort
  answers = factors.map { |a| others.map { |b| a * b } }
  blanks = c.sample((0..8).to_a, c.by_level([ 2, 3, 3, 4, 4, 5 ]))
  rows = answers.each_with_index.map { |row, r| row.each_with_index.map { |value, cc| blanks.include?((r * 3) + cc) ? nil : value } }
  raise Authoring::Duplicate if rows.flatten.compact.size == 9

  c.q(
    text: "Попълни празните клетки в таблицата за умножение (редове #{factors.join(', ')}; колони #{others.join(', ')}).",
    widget: WidgetKit.grid_fill(rows: rows, answers: answers,
                                column_headers: others.map(&:to_s), row_headers: factors.map(&:to_s)),
    explanation: Explain.build(
      idea: "Всяка клетка е произведението на числото от реда и числото от колоната.",
      steps: blanks.first(3).map do |index|
        r = index / 3
        cc = index % 3
        "Ред #{factors[r]}, колона #{others[cc]}: #{factors[r]} · #{others[cc]} = #{answers[r][cc]}."
      end,
      answer: blanks.sort.map { |index| "#{factors[index / 3]} · #{others[index % 3]} = #{answers[index / 3][index % 3]}" }.join(", "),
      check: "Таблицата е симетрична: #{factors.first} · #{others.first} = #{others.first} · #{factors.first}.",
      watch: "Заглавията на реда и колоната са множителите, а не резултатът."
    )
  )
end

Authoring.family "table.function_machine", topic: "Числа и редици", area: "interactive_number", variants: 11,
                 rungs: [ 950, 1040, 1130, 1220, 1310, 1400 ] do |c|
  multiplier = c.int(c.by_level([ 2..4, 2..6, 2..9, 3..12, 4..20, 5..40 ]))
  offset = c.int(c.by_level([ 0..5, 1..10, 1..20, 2..40, 3..90, 5..200 ]))
  minus = c.level >= 3 && c.coin
  inputs = c.sample((1..c.by_level([ 8, 12, 20, 40, 90, 200 ])).to_a, 4).sort
  outputs = inputs.map { |x| minus ? (multiplier * x) - offset : (multiplier * x) + offset }
  raise Authoring::Duplicate if outputs.any?(&:negative?)

  hidden = c.sample((0..3).to_a, c.by_level([ 2, 2, 2, 3, 3, 3 ]))
  rows = [ inputs.map(&:to_s), outputs.each_with_index.map { |value, i| hidden.include?(i) ? nil : value } ]

  c.q(
    text: "Машината превръща всяко число x в #{multiplier}x #{minus ? Num::MINUS : '+'} #{offset}. " \
          "Попълни липсващите изходи за входовете #{inputs.join(', ')}.",
    widget: WidgetKit.grid_fill(rows: rows, answers: [ inputs.map(&:to_s), outputs ],
                                row_headers: [ "вход", "изход" ]),
    explanation: Explain.build(
      idea: "Прилагаме едно и също правило към всеки вход: умножаваме по #{multiplier} и #{minus ? 'изваждаме' : 'прибавяме'} #{offset}.",
      steps: hidden.sort.map { |i| "#{inputs[i]} → #{multiplier} · #{inputs[i]} #{minus ? Num::MINUS : '+'} #{offset} = #{outputs[i]}" },
      answer: hidden.sort.map { |i| outputs[i] }.join(", "),
      check: "Разликата между два изхода е #{multiplier} пъти разликата между входовете им.",
      watch: "Правилото се прилага изцяло — и умножението, и #{minus ? 'изваждането' : 'събирането'}."
    )
  )
end

Authoring.family "table.place_value", topic: "Числа и редици", area: "interactive_number", variants: 11,
                 rungs: [ 900, 990, 1080, 1170, 1260, 1350 ] do |c|
  size = c.by_level([ 3, 3, 4, 4, 5, 6 ])
  number = c.int((10**(size - 1))..((10**size) - 1))
  digits = number.to_s.chars.map(&:to_i)
  values = digits.each_with_index.map { |digit, i| digit * (10**(digits.size - 1 - i)) }
  hidden = c.sample((0...size).to_a, c.by_level([ 1, 2, 2, 2, 3, 3 ]))
  rows = [ values.each_with_index.map { |value, i| hidden.include?(i) ? nil : value } ]
  names = { 1 => "единици", 10 => "десетици", 100 => "стотици", 1000 => "хиляди",
            10_000 => "десетохилядни", 100_000 => "стохилядни" }

  c.q(
    text: "Разложи числото #{number} по разредни единици: попълни липсващите стойности.",
    widget: WidgetKit.grid_fill(rows: rows, answers: [ values ],
                                column_headers: digits.each_index.map { |i| names.fetch(10**(digits.size - 1 - i), "") }),
    explanation: Explain.build(
      idea: "Стойността на всяка цифра е самата цифра, умножена по теглото на разреда ѝ.",
      steps: hidden.sort.map { |i| "Цифрата #{digits[i]} стои в разряда на #{names.fetch(10**(digits.size - 1 - i), '')}: #{digits[i]} · #{10**(digits.size - 1 - i)} = #{values[i]}." },
      answer: hidden.sort.map { |i| values[i] }.join(", "),
      check: "Сборът на всички стойности е самото число: #{values.reject(&:zero?).join(' + ')} = #{number}.",
      watch: "Нулата също заема разред — тя просто добавя 0 към сбора."
    )
  )
end

# ------------------------------------------------------------- Числова ос ---

Authoring.family "line.place_operation", topic: "Ред на действията", area: "interactive_number", variants: 11,
                 rungs: [ 1000, 1090, 1180, 1270, 1360, 1450 ] do |c|
  step = c.by_level([ 1, 2, 5, 5, 10, 20 ])
  a = c.int(2..9)
  b = c.int(2..9)
  d = c.int(1..c.by_level([ 5, 10, 20, 40, 90, 200 ]))
  result = (a * b) + d
  result -= result % step
  raise Authoring::Duplicate if result <= 0

  max = ((result / step) + c.int(2..6)) * step
  raise Authoring::Duplicate if max / step > 40

  c.q(
    text: "Пресметни #{a} · #{b} + #{d} и постави точката върху резултата (най-близката отметка).",
    widget: WidgetKit.number_line(min: 0, max: max, step: step, value: result, tolerance: 0.001),
    explanation: Explain.build(
      idea: "Първо умножението, после събирането — и чак тогава търсим мястото по оста.",
      steps: [
        "#{a} · #{b} = #{a * b}.",
        "#{a * b} + #{d} = #{(a * b) + d}#{result == (a * b) + d ? '' : ", а най-близката отметка е #{result}"}.",
        "Отметките са през #{step}, значи търсим #{result / step}-тата след нулата."
      ],
      answer: result.to_s,
      check: "Съседните отметки са #{result - step} и #{result + step}.",
      watch: "Ако първо се събере, отговорът става #{a * (b + d)} — съвсем друго място по оста."
    )
  )
end

# ------------------------------------------------------------------ Часовник ---

Authoring.family "clock.set_time", topic: "Събиране и изваждане", area: "interactive_number", variants: 11,
                 rungs: [ 700, 780, 860, 940, 1030, 1120 ] do |c|
  hour = c.int(1..12)
  minute = c.pick(c.by_level([ [ 0, 30 ], [ 0, 15, 30, 45 ], [ 0, 10, 20, 40, 50 ], [ 5, 25, 35, 55 ], [ 5, 10, 20, 35, 50 ], [ 5, 15, 25, 40, 55 ] ]))

  c.q(
    text: "Нагласи часовника да показва #{hour}:#{format('%02d', minute)}.",
    widget: WidgetKit.clock(hours: hour, minutes: minute),
    explanation: Explain.build(
      idea: "Малката стрелка сочи часа, голямата — минутите; едно деление на голямата стрелка е 5 минути.",
      steps: [
        "Часът е #{hour}, значи малката стрелка е при #{hour}#{minute.zero? ? '' : " (леко след него)"}.",
        "#{minute} минути са #{count_noun(minute / 5, 'деление', 'деления')} след 12 за голямата стрелка."
      ],
      answer: "#{hour}:#{format('%02d', minute)}",
      check: "60 минути правят пълна обиколка на голямата стрелка.",
      watch: "При #{minute} минути малката стрелка вече не сочи точно към #{hour} — тя се движи през целия час."
    )
  )
end

Authoring.family "clock.after_minutes", topic: "Събиране и изваждане", area: "interactive_number", variants: 11,
                 rungs: [ 900, 990, 1080, 1170, 1260, 1350 ] do |c|
  hour = c.int(1..12)
  minute = c.pick([ 0, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55 ])
  length = c.int(c.by_level([ 2..12, 3..24, 4..36, 6..48, 8..72, 10..140 ])) * 5
  total = (hour * 60) + minute + length
  end_hour = ((total / 60 - 1) % 12) + 1
  end_minute = total % 60

  c.q(
    text: "Часът е #{hour}:#{format('%02d', minute)}. Нагласи часовника да показва колко ще бъде след #{length} минути.",
    widget: WidgetKit.clock(hours: end_hour, minutes: end_minute),
    explanation: Explain.build(
      idea: "Добавяме минутите; всеки пълен час е 60 минути и премества малката стрелка с едно деление.",
      steps: [
        "#{minute} + #{length} = #{minute + length} минути.",
        "#{(minute + length) / 60} пълни часа и #{end_minute} минути остатък.",
        "Часът става #{end_hour}:#{format('%02d', end_minute)}."
      ],
      answer: "#{end_hour}:#{format('%02d', end_minute)}",
      check: "Назад #{length} минути от #{end_hour}:#{format('%02d', end_minute)} се връщаме на #{hour}:#{format('%02d', minute)}.",
      watch: "Часовникът брои до 12 и започва отначало — след 12 идва 1, не 13."
    )
  )
end

# ---------------------------------------------------------- Оцветяване (дроби) ---

Authoring.family "shade.fraction_grid", topic: "Дроби", area: "interactive_number", variants: 11,
                 rungs: [ 900, 990, 1080, 1170, 1260, 1350 ] do |c|
  cols = c.pick(c.by_level([ [ 4, 5 ], [ 4, 5, 6 ], [ 5, 6, 8 ], [ 6, 8, 10 ], [ 8, 10 ], [ 8, 10, 12 ] ]))
  rows = c.pick([ 2, 3, 4 ])
  total = rows * cols
  denominator = c.pick(Num.divisors(total).select { |d| d.between?(2, 12) })
  numerator = c.int(1...denominator)
  shaded = total * numerator / denominator

  c.q(
    text: "Мрежата има #{rows} реда по #{cols} квадратчета. Оцвети #{Num.frac(numerator, denominator)} от нея.",
    widget: WidgetKit.grid_shade(rows: rows, cols: cols, count: shaded),
    explanation: Explain.build(
      idea: "Дробта от мрежата се брои в квадратчета: делим на знаменателя и умножаваме по числителя.",
      steps: [
        "Всички квадратчета: #{rows} · #{cols} = #{total}.",
        "Едно #{denominator}-то: #{total} : #{denominator} = #{total / denominator}.",
        "#{numerator} такива части: #{total / denominator} · #{numerator} = #{shaded} квадратчета."
      ],
      answer: "#{shaded} от #{total} квадратчета",
      check: "#{shaded}/#{total} = #{Num.frac(numerator, denominator)} след съкращаване.",
      watch: "Кои точно квадратчета се оцветяват няма значение — важен е броят им."
    )
  )
end

Authoring.family "shade.percent_grid", topic: "Проценти", area: "interactive_number", variants: 11,
                 rungs: [ 1050, 1140, 1230, 1320, 1410, 1500 ] do |c|
  cols = 10
  rows = c.pick(c.by_level([ [ 2, 5 ], [ 2, 4, 5 ], [ 4, 5 ], [ 5, 10 ], [ 5, 10 ], [ 10 ] ]))
  total = rows * cols
  pct = c.pick((1..99).select { |p| ((total * p) % 100).zero? })
  shaded = total * pct / 100
  raise Authoring::Duplicate if shaded.zero? || shaded == total

  c.q(
    text: "Мрежата има #{total} квадратчета (#{rows} на #{cols}). Оцвети #{pct}% от тях.",
    widget: WidgetKit.grid_shade(rows: rows, cols: cols, count: shaded),
    explanation: Explain.build(
      idea: "Процентът се превръща в брой квадратчета: цялото по процента, делено на 100.",
      steps: [
        "1% от #{total} е #{Num.dec(Rational(total, 100), 2)} квадратчета.",
        "#{pct}% са #{total} · #{pct} : 100 = #{shaded} квадратчета."
      ],
      answer: "#{shaded} квадратчета",
      check: "#{shaded} : #{total} = #{Num.dec(Rational(shaded, total), 2)} = #{pct}%.",
      watch: "Ако мрежата има 100 квадратчета, процентите съвпадат с броя — тук обаче са #{total}."
    )
  )
end
