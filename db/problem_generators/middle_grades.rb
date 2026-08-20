module ProblemGenerators
  # Grades 4-6 were the narrowest part of the bank: plenty of problems, but the
  # fraction and multiplication clusters dominated their rating bands, so a
  # session repeated a few templates. This adds breadth in the standard
  # competition repertoire for those ages.
  module MiddleGrades
    extend self

    def generate
      problems = []
      problems += work_backwards
      problems += overlapping_sets
      problems += inclusion_exclusion
      problems += ratio_sharing
      problems += percent_chains
      problems += better_buy
      problems += balance_substitution
      problems += magic_squares
      problems += triangle_inequality
      problems += parallel_line_angles
      problems += fixed_perimeter
      problems += tiling
      problems += staircase_counting
      problems += inverse_counting
      problems += calendar_arithmetic
      problems += fraction_of_fraction
      problems += divisibility_by_eleven
      problems += squares_between
      problems
    end

    private

    # "I think of a number" — undo the operations in reverse order.
    def work_backwards
      out = []
      rng = ProblemGenerators.rng("backwards")

      12.times do
        start = rng.rand(2..20)
        mult = rng.rand(2..5)
        add = rng.rand(1..20)
        result = start * mult + add
        out << ProblemGenerators.problem(
          text: "Мисля си число. Умножавам го по #{mult}, добавям #{add} и получавам #{result}. Кое число съм намислил?",
          answer: start,
          topic: "Уравнения", grade: 5, tier: :medium,
          explanation: "Връщаме се назад: #{result} − #{add} = #{start * mult}, после #{start * mult} : #{mult} = #{start}."
        )
      end

      12.times do
        start = rng.rand(4..40)
        sub = rng.rand(1..(start - 1))
        div = [ 2, 3, 4 ].sample(random: rng)
        next unless ((start - sub) % div).zero?

        result = (start - sub) / div
        out << ProblemGenerators.problem(
          text: "Мисля си число. Изваждам #{sub}, деля на #{div} и получавам #{result}. Кое число съм намислил?",
          answer: start,
          topic: "Уравнения", grade: 6, tier: :hard,
          explanation: "Назад: #{result} · #{div} = #{start - sub}, после #{start - sub} + #{sub} = #{start}."
        )
      end

      out
    end

    # Two overlapping groups — the Venn diagram idea without the diagram.
    def overlapping_sets
      out = []
      rng = ProblemGenerators.rng("venn")

      12.times do
        both = rng.rand(2..8)
        only_a = rng.rand(3..12)
        only_b = rng.rand(3..12)
        total = only_a + only_b + both
        out << ProblemGenerators.problem(
          text: "В клас #{only_a + both} деца играят футбол, #{only_b + both} играят шах, а #{both} играят и двете. Колко деца играят поне една от двете игри?",
          answer: total,
          topic: "Логически задачи", grade: 6, tier: :competition,
          explanation: "Събираме и изваждаме преброените двойно: #{only_a + both} + #{only_b + both} − #{both} = #{total}."
        )
      end

      12.times do
        both = rng.rand(2..6)
        only_a = rng.rand(3..10)
        only_b = rng.rand(3..10)
        neither = rng.rand(1..5)
        total = only_a + only_b + both + neither
        out << ProblemGenerators.problem(
          text: "В група от #{total} деца #{only_a + both} обичат ябълки, #{only_b + both} обичат банани, а #{both} обичат и двете. Колко деца не обичат нито едно от двете?",
          answer: neither,
          topic: "Логически задачи", grade: 6, tier: :competition,
          explanation: "Поне едно обичат #{only_a + both} + #{only_b + both} − #{both} = #{only_a + only_b + both}. Значи нито едно: #{total} − #{only_a + only_b + both} = #{neither}."
        )
      end

      out
    end

    # Counting multiples of one number or another.
    def inclusion_exclusion
      out = []

      [ [ 2, 3, 100 ], [ 3, 5, 100 ], [ 2, 5, 100 ], [ 4, 6, 100 ], [ 3, 4, 60 ], [ 2, 7, 70 ] ].each do |a, b, limit|
        count = limit / a + limit / b - limit / a.lcm(b)
        out << ProblemGenerators.problem(
          text: "Колко числа от 1 до #{limit} се делят на #{a} или на #{b}?",
          answer: count,
          topic: "Делимост", grade: 6, tier: :competition,
          explanation: "На #{a} се делят #{limit / a}, на #{b} — #{limit / b}, а на двете (#{a.lcm(b)}) — #{limit / a.lcm(b)}. Общо #{limit / a} + #{limit / b} − #{limit / a.lcm(b)} = #{count}."
        )
      end

      [ [ 2, 3, 100 ], [ 3, 5, 100 ], [ 4, 5, 100 ] ].each do |a, b, limit|
        neither = limit - (limit / a + limit / b - limit / a.lcm(b))
        out << ProblemGenerators.problem(
          text: "Колко числа от 1 до #{limit} не се делят нито на #{a}, нито на #{b}?",
          answer: neither,
          topic: "Делимост", grade: 7, tier: :competition,
          explanation: "На #{a} или #{b} се делят #{limit - neither}, значи останалите са #{limit} − #{limit - neither} = #{neither}."
        )
      end

      out
    end

    # Sharing in a given ratio — proportional reasoning.
    def ratio_sharing
      out = []

      [ [ 2, 3 ], [ 1, 4 ], [ 3, 5 ], [ 2, 5 ], [ 3, 4 ], [ 1, 2 ] ].each do |first, second|
        [ 4, 6, 10 ].each do |unit|
          total = (first + second) * unit
          out << ProblemGenerators.problem(
            text: "#{total} лева се разделят между двама в отношение #{first} : #{second}. Колко лева получава първият?",
            answer: first * unit,
            topic: "Проценти", grade: 6, tier: :hard,
            explanation: "Частите са #{first} + #{second} = #{first + second}. Една част е #{total} : #{first + second} = #{unit} лева, значи първият получава #{first} · #{unit} = #{first * unit} лева."
          )
        end
      end

      [ [ 1, 2, 3 ], [ 2, 3, 4 ], [ 1, 1, 2 ] ].each do |a, b, c|
        unit = 6
        total = (a + b + c) * unit
        out << ProblemGenerators.problem(
          text: "#{total} стикера се разделят между трима в отношение #{a} : #{b} : #{c}. Колко стикера получава последният?",
          answer: c * unit,
          topic: "Проценти", grade: 7, tier: :competition,
          explanation: "Частите са #{a + b + c}, една част е #{unit}, значи последният получава #{c} · #{unit} = #{c * unit}."
        )
      end

      out
    end

    # Percent applied twice — where intuition usually fails.
    def percent_chains
      out = []

      [ [ 100, 10 ], [ 200, 10 ], [ 100, 20 ], [ 400, 25 ], [ 200, 50 ] ].each do |price, percent|
        raised = price + price * percent / 100
        final = raised - raised * percent / 100
        out << ProblemGenerators.problem(
          text: "Цена от #{price} лева се увеличава с #{percent}%, а след това новата цена се намалява с #{percent}%. Колко лева е крайната цена?",
          answer: final,
          topic: "Проценти", grade: 7, tier: :competition,
          explanation: "След увеличението: #{raised} лева. След намалението: #{raised} − #{raised * percent / 100} = #{final} лева. Крайната цена е по-ниска от началната, защото процентът се взема от по-голямо число."
        )
      end

      [ [ 50, 100 ], [ 30, 200 ], [ 25, 80 ], [ 40, 150 ] ].each do |percent, whole|
        increased = whole + whole * percent / 100
        out << ProblemGenerators.problem(
          text: "Число #{whole} се увеличава с #{percent}%. Колко става?",
          answer: increased,
          topic: "Проценти", grade: 6, tier: :medium,
          explanation: "Увеличението е #{whole * percent / 100}, значи #{whole} + #{whole * percent / 100} = #{increased}."
        )
      end

      out
    end

    # Unit-price comparison — "which is the better buy".
    def better_buy
      out = []
      rng = ProblemGenerators.rng("buy")

      14.times do
        unit1 = rng.rand(2..9)
        count1 = rng.rand(2..6)
        count2 = rng.rand(2..6)
        unit2 = unit1 + rng.rand(1..3)
        next if unit1 == unit2

        out << ProblemGenerators.problem(
          text: "Кутия A съдържа #{count1} сока за #{count1 * unit1} лева. Кутия Б съдържа #{count2} сока за #{count2 * unit2} лева. Колко лева струва един сок в по-изгодната кутия?",
          answer: [ unit1, unit2 ].min,
          topic: "Текстови задачи", grade: 6, tier: :hard,
          explanation: "В A един сок е #{unit1} лева, в Б — #{unit2} лева. По-изгодната дава #{[ unit1, unit2 ].min} лева за сок."
        )
      end

      out
    end

    # Balance puzzles: substitute one shape for another.
    def balance_substitution
      out = []

      [ [ 2, 6 ], [ 3, 9 ], [ 2, 8 ], [ 4, 12 ], [ 3, 12 ], [ 5, 10 ] ].each do |circles, squares|
        per = squares / circles
        out << ProblemGenerators.problem(
          text: "#{circles} кръгчета тежат колкото #{squares} квадратчета. Колко квадратчета тежат колкото 1 кръгче?",
          answer: per,
          topic: "Логически задачи", grade: 5, tier: :hard,
          explanation: "#{squares} : #{circles} = #{per} квадратчета за едно кръгче."
        )
        out << ProblemGenerators.problem(
          text: "Едно кръгче тежи колкото #{per} квадратчета. Колко квадратчета тежат колкото #{circles + 1} кръгчета?",
          answer: (circles + 1) * per,
          topic: "Логически задачи", grade: 5, tier: :medium,
          explanation: "#{circles + 1} · #{per} = #{(circles + 1) * per} квадратчета."
        )
      end

      out
    end

    # Magic squares: one missing entry.
    def magic_squares
      out = []

      # Rows of a 3x3 magic square all sum to the same value.
      [ [ 15, [ 2, 7, 6 ] ], [ 15, [ 9, 5, 1 ] ], [ 15, [ 4, 3, 8 ] ],
        [ 18, [ 3, 8, 7 ] ], [ 21, [ 4, 9, 8 ] ], [ 24, [ 5, 10, 9 ] ] ].each do |total, row|
        missing = row.last
        out << ProblemGenerators.problem(
          text: "В магически квадрат всеки ред има сбор #{total}. Един ред съдържа #{row[0]} и #{row[1]}. Кое е третото число в реда?",
          answer: missing,
          topic: "Логически задачи", grade: 5, tier: :medium,
          explanation: "#{total} − #{row[0]} − #{row[1]} = #{missing}."
        )
      end

      out
    end

    # Can three lengths form a triangle?
    def triangle_inequality
      out = []
      rng = ProblemGenerators.rng("tri")

      14.times do
        a = rng.rand(2..12)
        b = rng.rand(2..12)
        valid = rng.rand(2).zero?
        c = valid ? rng.rand([ (a - b).abs + 1, 1 ].max...(a + b)) : a + b + rng.rand(1..4)
        next if c < 1

        possible = (a + b > c) && (a + c > b) && (b + c > a)
        out << ProblemGenerators.problem(
          text: "Може ли да съществува триъгълник със страни #{a} см, #{b} см и #{c} см?",
          answer: possible ? "да" : "не",
          topic: "Периметър", grade: 6, tier: :competition,
          options: %w[да не],
          explanation: possible ? "Сборът на всеки две страни е по-голям от третата, значи такъв триъгълник съществува." : "#{a} + #{b} = #{a + b}, което не е по-голямо от #{c}. Такъв триъгълник не съществува."
        )
      end

      out
    end

    # Angles at parallel lines cut by a transversal.
    def parallel_line_angles
      out = []

      (20..160).step(10).each do |angle|
        out << ProblemGenerators.problem(
          text: "Две успоредни прави са пресечени от трета. Един от ъглите е #{angle}°. Колко градуса е съответният му ъгъл (на същото място при другата права)?",
          answer: angle,
          topic: "Ъгли", grade: 7, tier: :hard,
          explanation: "Съответните ъгли при успоредни прави са равни: #{angle}°."
        )
      end

      (20..160).step(20).each do |angle|
        out << ProblemGenerators.problem(
          text: "Две успоредни прави са пресечени от трета. Един от ъглите е #{angle}°. Колко градуса е прилежащият му ъгъл от същата страна?",
          answer: 180 - angle,
          topic: "Ъгли", grade: 7, tier: :competition,
          explanation: "Двата ъгъла са съседни и се допълват до 180°: 180° − #{angle}° = #{180 - angle}°."
        )
      end

      out
    end

    # Same perimeter, different area — the classic surprise.
    def fixed_perimeter
      out = []

      [ 12, 16, 20, 24, 28, 36 ].each do |perimeter|
        half = perimeter / 2
        best = (1..half / 2).max_by { |w| w * (half - w) }
        out << ProblemGenerators.problem(
          text: "Правоъгълник има периметър #{perimeter} см и цели дължини на страните. Колко е най-голямото възможно лице в квадратни сантиметри?",
          answer: best * (half - best),
          topic: "Площ", grade: 7, tier: :competition,
          explanation: "Полупериметърът е #{half}. Лицето е най-голямо, когато страните са възможно най-близки: #{best} и #{half - best}, което дава #{best * (half - best)} кв. см."
        )
      end

      out
    end

    # Covering a floor with tiles.
    def tiling
      out = []

      [ [ 6, 4, 2 ], [ 8, 6, 2 ], [ 12, 9, 3 ], [ 10, 10, 5 ], [ 15, 12, 3 ], [ 20, 16, 4 ] ].each do |a, b, tile|
        count = (a / tile) * (b / tile)
        out << ProblemGenerators.problem(
          text: "Стая #{a} м на #{b} м се покрива с квадратни плочки със страна #{tile} м. Колко плочки са необходими?",
          answer: count,
          topic: "Площ", grade: 5, tier: :hard,
          explanation: "По дължина влизат #{a / tile} плочки, по широчина #{b / tile}: #{a / tile} · #{b / tile} = #{count}."
        )
      end

      out
    end

    # Ways to climb stairs taking 1 or 2 steps — Fibonacci in a story.
    def staircase_counting
      out = []
      ways = [ 1, 1 ]
      10.times { ways << ways[-1] + ways[-2] }

      (2..8).each do |steps|
        out << ProblemGenerators.problem(
          text: "Стълба има #{steps} стъпала. Може да се изкачва по едно или по две стъпала наведнъж. По колко различни начина може да се изкачи?",
          answer: ways[steps],
          topic: "Броене и комбинаторика", grade: steps <= 4 ? 6 : 7, tier: :competition,
          explanation: "Начините за #{steps} стъпала са сборът от начините за #{steps - 1} и за #{steps - 2} стъпала: #{ways[steps - 1]} + #{ways[steps - 2]} = #{ways[steps]}."
        )
      end

      out
    end

    # Inverse counting: given the number of pairs, find the group size.
    def inverse_counting
      out = []

      (4..12).each do |people|
        handshakes = people * (people - 1) / 2
        out << ProblemGenerators.problem(
          text: "На среща всеки се здрависал с всеки друг точно веднъж и здрависванията били #{handshakes}. Колко души е имало?",
          answer: people,
          topic: "Броене и комбинаторика", grade: 7, tier: :competition,
          explanation: "Търсим n с n · (n − 1) : 2 = #{handshakes}. Опитваме: #{people} · #{people - 1} : 2 = #{handshakes}, значи хората са #{people}."
        )
      end

      out
    end

    # Dates: what day of the month falls N days later.
    def calendar_arithmetic
      out = []

      [ [ 5, 10, 31 ], [ 12, 20, 31 ], [ 25, 10, 31 ], [ 28, 5, 30 ], [ 20, 15, 30 ], [ 15, 20, 28 ] ].each do |day, offset, month_length|
        target = day + offset
        answer = target > month_length ? target - month_length : target
        out << ProblemGenerators.problem(
          text: "Днес е #{day}-ти ден от месец с #{month_length} дни. Кой ден от месеца ще бъде след #{offset} дни?",
          answer: answer,
          topic: "Логически задачи", grade: 5, tier: :hard,
          explanation: target > month_length ? "#{day} + #{offset} = #{target}, което надхвърля #{month_length}. Значи #{target} − #{month_length} = #{answer}-ти от следващия месец." : "#{day} + #{offset} = #{answer}."
        )
      end

      out
    end

    # A fraction of a fraction — multiplication of fractions in a story.
    def fraction_of_fraction
      out = []

      [ [ 2, 3, 12 ], [ 3, 4, 20 ], [ 2, 5, 30 ], [ 1, 2, 24 ], [ 3, 5, 40 ], [ 1, 3, 36 ] ].each do |num, den, whole|
        first_part = whole * num / den
        half_of_that = first_part / 2
        next unless (first_part % 2).zero?

        out << ProblemGenerators.problem(
          text: "От #{whole} ябълки #{num}/#{den} са червени. Половината от червените са едри. Колко ябълки са едри и червени?",
          answer: half_of_that,
          topic: "Дроби", grade: 6, tier: :hard,
          explanation: "Червените са #{whole} · #{num} : #{den} = #{first_part}. Половината от тях са #{first_part} : 2 = #{half_of_that}."
        )
      end

      out
    end

    # The alternating-sum rule for 11.
    def divisibility_by_eleven
      out = []
      rng = ProblemGenerators.rng("eleven")

      14.times do
        n = rng.rand(100..999)
        divisible = (n % 11).zero?
        digits = n.digits.reverse
        alternating = digits.each_with_index.sum { |d, i| i.even? ? d : -d }
        out << ProblemGenerators.problem(
          text: "Дели ли се числото #{n} на 11?",
          answer: divisible ? "да" : "не",
          topic: "Делимост", grade: 7, tier: :competition,
          options: %w[да не],
          explanation: "Редуваме знаците на цифрите: #{digits[0]} − #{digits[1]} + #{digits[2]} = #{alternating}. Числото се дели на 11 точно когато този резултат се дели на 11 — тук #{divisible ? 'се дели' : 'не се дели'}."
        )
      end

      out
    end

    # Perfect squares in a range.
    def squares_between
      out = []

      [ [ 10, 50 ], [ 20, 100 ], [ 50, 200 ], [ 1, 30 ], [ 100, 300 ], [ 30, 90 ] ].each do |low, high|
        squares = (1..40).map { |n| n * n }.select { |s| s >= low && s <= high }
        out << ProblemGenerators.problem(
          text: "Колко точни квадрата има между #{low} и #{high} (включително)?",
          answer: squares.size,
          topic: "Умножение и деление", grade: 6, tier: :hard,
          explanation: "Това са #{squares.join(', ')} — общо #{squares.size}."
        )
      end

      out
    end
  end
end
