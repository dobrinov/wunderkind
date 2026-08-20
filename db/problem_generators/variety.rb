module ProblemGenerators
  # Breadth generator: many distinct problem *kinds* with modest instance
  # counts each, to balance the drill generators that produce many
  # parameterisations of a few shapes.
  module Variety
    extend self

    def generate
      problems = []
      problems += off_by_one_classics
      problems += averages_and_totals
      problems += parity_and_extremes
      problems += digit_counting
      problems += money_and_measures
      problems += rate_and_capacity
      problems += geometry_variety
      problems += polygon_and_solid_facts
      problems += counting_variety
      problems += reasoning_variety
      problems += number_curiosities
      problems
    end

    private

    # --- The off-by-one family: different stories, one insight --------------
    def off_by_one_classics
      out = []

      (2..12).each do |pieces|
        out << ProblemGenerators.problem(
          text: "Дървен кол се разрязва на #{pieces} равни части. Колко разреза са необходими?",
          answer: pieces - 1,
          topic: "Логически задачи", grade: pieces <= 4 ? 3 : 4, tier: pieces <= 4 ? :easy : :medium,
          explanation: "Всеки разрез добавя по една част. За #{pieces} части трябват #{pieces} − 1 = #{pieces - 1} разреза."
        )
      end

      [ 3, 4, 5, 6, 8, 10 ].each do |floor|
        out << ProblemGenerators.problem(
          text: "Изкачването между два съседни етажа отнема 6 секунди. За колко секунди се стига от 1-ви до #{floor}-ти етаж?",
          answer: (floor - 1) * 6,
          topic: "Логически задачи", grade: 5, tier: :competition,
          explanation: "От 1-ви до #{floor}-ти етаж има #{floor - 1} междуетажия, а не #{floor}: #{floor - 1} · 6 = #{(floor - 1) * 6} секунди."
        )
      end

      [ 5, 6, 8, 10, 12, 20 ].each do |trees|
        out << ProblemGenerators.problem(
          text: "По права алея са засадени #{trees} дървета на равни разстояния от 3 метра. Колко метра е от първото до последното дърво?",
          answer: (trees - 1) * 3,
          topic: "Логически задачи", grade: 5, tier: :hard,
          explanation: "Между #{trees} дървета има #{trees - 1} разстояния: #{trees - 1} · 3 = #{(trees - 1) * 3} метра."
        )
      end

      [ 4, 5, 6, 7, 9 ].each do |floors|
        out << ProblemGenerators.problem(
          text: "В блок с #{floors} етажа по колко площадки има между етажите?",
          answer: floors - 1,
          topic: "Логически задачи", grade: 4, tier: :medium,
          explanation: "Площадките са с една по-малко от етажите: #{floors} − 1 = #{floors - 1}."
        )
      end

      out
    end

    # --- Averages, totals, and "find the missing one" ----------------------
    def averages_and_totals
      out = []
      rng = ProblemGenerators.rng("avg")

      15.times do
        count = rng.rand(3..5)
        average = rng.rand(3..20)
        values = Array.new(count - 1) { rng.rand(1..(average * 2)) }
        last = average * count - values.sum
        next if last < 1

        out << ProblemGenerators.problem(
          text: "Средното на #{count} числа е #{average}. #{count - 1} от тях са #{values.join(', ')}. Кое е останалото число?",
          answer: last,
          topic: "Текстови задачи", grade: 6, tier: :hard,
          explanation: "Сборът на всички е #{average} · #{count} = #{average * count}. Известните дават #{values.sum}, значи последното е #{average * count} − #{values.sum} = #{last}."
        )
      end

      15.times do
        count = rng.rand(3..6)
        values = Array.new(count) { rng.rand(2..30) }
        next unless (values.sum % count).zero?

        out << ProblemGenerators.problem(
          text: "Колко е средното аритметично на числата #{values.join(', ')}?",
          answer: values.sum / count,
          topic: "Текстови задачи", grade: 5, tier: :medium,
          explanation: "(#{values.join(' + ')}) : #{count} = #{values.sum} : #{count} = #{values.sum / count}."
        )
      end

      # Sum of the first n odd numbers is a perfect square — a lovely pattern.
      (2..10).each do |n|
        out << ProblemGenerators.problem(
          text: "Колко е сборът на първите #{n} нечетни числа (1 + 3 + 5 + …)?",
          answer: n * n,
          topic: "Числа и редици", grade: 6, tier: :competition,
          explanation: "Сборът на първите #{n} нечетни числа винаги е #{n} · #{n} = #{n * n}."
        )
      end

      out
    end

    # --- Parity, and largest/smallest reasoning ----------------------------
    def parity_and_extremes
      out = []
      rng = ProblemGenerators.rng("parity")

      15.times do
        a = rng.rand(10..99)
        b = rng.rand(10..99)
        parity = ((a + b) % 2).zero? ? "четно" : "нечетно"
        out << ProblemGenerators.problem(
          text: "Числото #{a} + #{b} четно ли е или нечетно? (Отговори без да пресмяташ сбора.)",
          answer: parity,
          topic: "Делимост", grade: 5, tier: :medium,
          options: %w[четно нечетно],
          explanation: "#{a} е #{a.even? ? 'четно' : 'нечетно'}, #{b} е #{b.even? ? 'четно' : 'нечетно'}. Сборът им е #{parity}."
        )
      end

      # Largest/smallest number from given digits.
      [ [ 3, 7, 1 ], [ 5, 2, 8 ], [ 4, 9, 6 ], [ 2, 0, 5 ], [ 7, 3, 9 ], [ 1, 6, 4 ] ].each do |digits|
        largest = digits.sort.reverse.join.to_i
        smallest = digits.include?(0) ? (digits.reject(&:zero?).min.to_s + digits.sort.drop(1).reject { |d| d == digits.reject(&:zero?).min }.join) : digits.sort.join
        out << ProblemGenerators.problem(
          text: "Кое е най-голямото трицифрено число, съставено от цифрите #{digits.join(', ')} (всяка веднъж)?",
          answer: largest,
          topic: "Числа и редици", grade: 3, tier: :easy,
          explanation: "Подреждаме цифрите в намаляващ ред: #{digits.sort.reverse.join(', ')} → #{largest}."
        )
        next if digits.include?(0)

        out << ProblemGenerators.problem(
          text: "Кое е най-малкото трицифрено число, съставено от цифрите #{digits.join(', ')} (всяка веднъж)?",
          answer: smallest.to_i,
          topic: "Числа и редици", grade: 4, tier: :medium,
          explanation: "Подреждаме цифрите в растящ ред: #{digits.sort.join(', ')} → #{smallest}."
        )
      end

      # Consecutive integers with a given sum.
      [ [ 3, 12 ], [ 3, 18 ], [ 3, 24 ], [ 5, 25 ], [ 5, 40 ], [ 4, 26 ] ].each do |count, total|
        next unless (total - (0...count).sum) % count == 0

        first = (total - (0...count).sum) / count
        next if first < 1

        out << ProblemGenerators.problem(
          text: "Сборът на #{count} последователни числа е #{total}. Кое е най-малкото от тях?",
          answer: first,
          topic: "Числа и редици", grade: 6, tier: :competition,
          explanation: "Ако най-малкото е n, сборът е #{count}n + #{(0...count).sum} = #{total}, значи n = #{first}."
        )
      end

      out
    end

    # --- Counting digits and occurrences ----------------------------------
    def digit_counting
      out = []

      (1..9).each do |digit|
        count = (1..100).sum { |n| n.to_s.count(digit.to_s) }
        out << ProblemGenerators.problem(
          text: "Колко пъти се среща цифрата #{digit} при записване на числата от 1 до 100?",
          answer: count,
          topic: "Броене и комбинаторика", grade: 6, tier: :competition,
          explanation: "Цифрата #{digit} се среща #{count} пъти — по веднъж на позицията на единиците във всяка десетица и по десет пъти като цифра на десетиците."
        )
      end

      [ 20, 50, 100, 200 ].each do |limit|
        digits = (1..limit).sum { |n| n.to_s.length }
        out << ProblemGenerators.problem(
          text: "Колко цифри се използват общо, за да се запишат числата от 1 до #{limit}?",
          answer: digits,
          topic: "Броене и комбинаторика", grade: 6, tier: :competition,
          explanation: "Едноцифрените (1–9) дават 9 цифри, двуцифрените по 2, трицифрените по 3. Общо #{digits}."
        )
      end

      # Palindromes — a shape kids find fun.
      [ 100, 200, 300, 500 ].each do |limit|
        count = (10..limit).count { |n| n.to_s == n.to_s.reverse }
        out << ProblemGenerators.problem(
          text: "Колко числа от 10 до #{limit} се четат еднакво отпред назад и отзад напред (например 121)?",
          answer: count,
          topic: "Броене и комбинаторика", grade: 6, tier: :hard,
          explanation: "Двуцифрените такива числа са 11, 22, …, 99 — девет на брой. Към тях се добавят трицифрените до #{limit}. Общо #{count}."
        )
      end

      out
    end

    # --- Money, coins, and unit conversion --------------------------------
    def money_and_measures
      out = []

      # Coin combinations — a real counting problem with small numbers.
      [ 5, 6, 7, 8, 10, 12, 15, 20 ].each do |amount|
        ways = 0
        (0..amount / 5).each do |fives|
          (0..(amount - 5 * fives) / 2).each do |twos|
            ways += 1 if (amount - 5 * fives - 2 * twos) >= 0
          end
        end
        out << ProblemGenerators.problem(
          text: "По колко начина може да се плати #{amount} лева с монети от 1, 2 и 5 лева? (Редът няма значение.)",
          answer: ways,
          topic: "Броене и комбинаторика", grade: 6, tier: :competition,
          explanation: "Броим по броя петолевки, после по броя двулевки, а останалото се допълва с единици — общо #{ways} начина."
        )
      end

      # Unit conversion, one shape per unit family.
      [ [ "метра", "сантиметра", 100, 5 ], [ "километра", "метра", 1000, 4 ],
        [ "килограма", "грама", 1000, 4 ], [ "часа", "минути", 60, 3 ],
        [ "минути", "секунди", 60, 3 ], [ "литра", "милилитра", 1000, 5 ] ].each do |from, to, factor, grade|
        [ 2, 3, 5, 7 ].each do |value|
          out << ProblemGenerators.problem(
            text: "Колко #{to} са #{value} #{from}?",
            answer: value * factor,
            topic: "Логически задачи", grade: grade, tier: :easy,
            explanation: "1 #{from.sub(/а\z/, '')} = #{factor} #{to}, значи #{value} · #{factor} = #{value * factor}."
          )
        end
      end

      out
    end

    # --- Rates, capacity, and two-agent filling ---------------------------
    def rate_and_capacity
      out = []

      # Two taps filling a tank — laddered from "together per minute" upward.
      [ [ 2, 3 ], [ 3, 6 ], [ 4, 4 ], [ 5, 5 ], [ 2, 6 ], [ 3, 4 ] ].each do |a, b|
        per_minute = a + b
        out << ProblemGenerators.problem(
          text: "Една тръба налива #{a} литра в минута, друга — #{b} литра в минута. Колко литра наливат заедно за 1 минута?",
          answer: per_minute,
          topic: "Работа", grade: 4, tier: :easy,
          explanation: "#{a} + #{b} = #{per_minute} литра."
        )
        out << ProblemGenerators.problem(
          text: "Две тръби наливат #{a} и #{b} литра в минута. За колко минути ще напълнят съд от #{per_minute * 6} литра?",
          answer: 6,
          topic: "Работа", grade: 6, tier: :hard,
          explanation: "Заедно наливат #{per_minute} литра в минута: #{per_minute * 6} : #{per_minute} = 6 минути."
        )
      end

      # Candle burning / draining — decreasing quantities.
      [ [ 20, 2 ], [ 30, 3 ], [ 24, 4 ], [ 45, 5 ], [ 60, 6 ] ].each do |height, rate|
        out << ProblemGenerators.problem(
          text: "Свещ е висока #{height} см и изгаря по #{rate} см на час. За колко часа ще изгори напълно?",
          answer: height / rate,
          topic: "Работа", grade: 5, tier: :medium,
          explanation: "#{height} : #{rate} = #{height / rate} часа."
        )
      end

      # Bus passengers on/off — signed accumulation.
      rng = ProblemGenerators.rng("bus")
      12.times do
        start = rng.rand(10..30)
        off1 = rng.rand(2..8)
        on1 = rng.rand(2..10)
        off2 = rng.rand(1..(start - off1 + on1 - 1))
        final = start - off1 + on1 - off2
        out << ProblemGenerators.problem(
          text: "В автобус има #{start} пътници. На първата спирка слизат #{off1} и се качват #{on1}. На втората слизат #{off2}. Колко пътници остават?",
          answer: final,
          topic: "Текстови задачи", grade: 4, tier: :medium,
          explanation: "#{start} − #{off1} + #{on1} = #{start - off1 + on1}, после − #{off2} = #{final}."
        )
      end

      out
    end

    # --- Geometry beyond the standard formulas ----------------------------
    def geometry_variety
      out = []

      # Composite shape perimeter: an L made of two rectangles.
      [ [ 6, 4, 2 ], [ 8, 5, 3 ], [ 10, 6, 4 ], [ 7, 5, 2 ], [ 9, 4, 3 ] ].each do |a, b, cut|
        perimeter = 2 * (a + b)
        out << ProblemGenerators.problem(
          text: "От правоъгълник #{a} см на #{b} см е изрязано квадратче със страна #{cut} см от единия ъгъл. Колко сантиметра е периметърът на останалата фигура?",
          answer: perimeter,
          topic: "Периметър", grade: 6, tier: :competition,
          explanation: "Двете нови страни заместват точно изрязаните части, затова периметърът не се променя: 2 · (#{a} + #{b}) = #{perimeter} см."
        )
      end

      # Matchstick squares in a row.
      (1..8).each do |squares|
        out << ProblemGenerators.problem(
          text: "От кибритени клечки се редят #{squares} квадратчета едно до друго в редица. Колко клечки са необходими?",
          answer: 3 * squares + 1,
          topic: "Броене и комбинаторика", grade: 5, tier: :hard,
          explanation: "Първото квадратче иска 4 клечки, всяко следващо — само 3: 4 + #{squares - 1} · 3 = #{3 * squares + 1}."
        )
      end

      # Painted cube — the classic 3D counting ladder.
      (2..5).each do |n|
        out << ProblemGenerators.problem(
          text: "Куб #{n} × #{n} × #{n} е боядисан отвън и разрязан на #{n**3} единични кубчета. Колко кубчета имат точно 3 боядисани стени?",
          answer: 8,
          topic: "Броене и комбинаторика", grade: 7, tier: :competition,
          explanation: "Само кубчетата в осемте върха имат по три боядисани стени — винаги 8, независимо от размера."
        )
        next if n < 3

        out << ProblemGenerators.problem(
          text: "Куб #{n} × #{n} × #{n} е боядисан отвън и разрязан на единични кубчета. Колко кубчета остават изцяло небоядисани?",
          answer: (n - 2)**3,
          topic: "Броене и комбинаторика", grade: 7, tier: :competition,
          explanation: "Небоядисани са само вътрешните кубчета — куб със страна #{n} − 2 = #{n - 2}, значи #{(n - 2)**3}."
        )
      end

      # Squares cut from a rectangle.
      [ [ 6, 4, 2 ], [ 12, 8, 4 ], [ 10, 5, 5 ], [ 9, 6, 3 ], [ 8, 6, 2 ] ].each do |a, b, side|
        out << ProblemGenerators.problem(
          text: "Правоъгълник #{a} см на #{b} см се разрязва на квадратчета със страна #{side} см. Колко квадратчета се получават?",
          answer: (a / side) * (b / side),
          topic: "Площ", grade: 5, tier: :medium,
          explanation: "По дължина се получават #{a / side}, по широчина #{b / side}: #{a / side} · #{b / side} = #{(a / side) * (b / side)}."
        )
      end

      out
    end

    # --- Facts about polygons and solids ----------------------------------
    def polygon_and_solid_facts
      out = []

      (3..10).each do |sides|
        out << ProblemGenerators.problem(
          text: "Колко е сборът на вътрешните ъгли на #{sides}-ъгълник в градуси?",
          answer: (sides - 2) * 180,
          topic: "Ъгли", grade: 7, tier: :hard,
          explanation: "Всеки #{sides}-ъгълник се разделя на #{sides - 2} триъгълника: #{sides - 2} · 180° = #{(sides - 2) * 180}°."
        )
      end

      (4..10).each do |sides|
        out << ProblemGenerators.problem(
          text: "Колко диагонала има #{sides}-ъгълник?",
          answer: sides * (sides - 3) / 2,
          topic: "Броене и комбинаторика", grade: 7, tier: :competition,
          explanation: "От всеки от #{sides} върха излизат #{sides - 3} диагонала, но всеки се брои двойно: #{sides} · #{sides - 3} : 2 = #{sides * (sides - 3) / 2}."
        )
      end

      [ [ "куб", 6, 12, 8 ], [ "правоъгълен паралелепипед", 6, 12, 8 ],
        [ "триъгълна пирамида", 4, 6, 4 ], [ "четириъгълна пирамида", 5, 8, 5 ],
        [ "триъгълна призма", 5, 9, 6 ] ].each do |name, faces, edges, vertices|
        out << ProblemGenerators.problem(
          text: "Колко стени има #{name}?", answer: faces,
          topic: "Обем", grade: 6, tier: :medium
        )
        out << ProblemGenerators.problem(
          text: "Колко ръба има #{name}?", answer: edges,
          topic: "Обем", grade: 6, tier: :hard
        )
        out << ProblemGenerators.problem(
          text: "Колко върха има #{name}?", answer: vertices,
          topic: "Обем", grade: 6, tier: :medium
        )
      end

      out
    end

    # --- Counting shapes not covered by the standard formulas -------------
    def counting_variety
      out = []

      # Lattice paths — Pascal's triangle in disguise.
      [ [ 2, 2, 6 ], [ 2, 3, 10 ], [ 3, 3, 20 ], [ 1, 4, 5 ], [ 2, 4, 15 ] ].each do |w, h, paths|
        out << ProblemGenerators.problem(
          text: "В мрежа #{w} × #{h} се движим от долния ляв до горния десен ъгъл само надясно и нагоре. Колко различни пътя има?",
          answer: paths,
          topic: "Броене и комбинаторика", grade: 7, tier: :competition,
          explanation: "Броят пътища до всяко кръстовище е сборът на пътищата отляво и отдолу. Натрупването дава #{paths}."
        )
      end

      # Dice sums — how many ways to roll a total.
      (2..12).each do |total|
        ways = (1..6).sum { |first| (1..6).count { |second| first + second == total } }
        out << ProblemGenerators.problem(
          text: "Хвърляме два зара. По колко начина може сборът да е #{total}?",
          answer: ways,
          topic: "Броене и комбинаторика", grade: 6, tier: :hard,
          explanation: "Изброяваме двойките (първи, втори) със сбор #{total} — те са #{ways}."
        )
      end

      # Coin flip outcomes.
      (1..6).each do |flips|
        out << ProblemGenerators.problem(
          text: "Хвърляме монета #{flips} пъти. Колко различни последователности от лица и гербове са възможни?",
          answer: 2**flips,
          topic: "Броене и комбинаторика", grade: 6, tier: :hard,
          explanation: "Всяко хвърляне има 2 възможности: #{Array.new(flips, 2).join(' · ')} = #{2**flips}."
        )
      end

      out
    end

    # --- Logic shapes with distinct stories -------------------------------
    def reasoning_variety
      out = []

      # Find the counterfeit coin by weighing — reasoning about information.
      [ [ 3, 1 ], [ 9, 2 ], [ 27, 3 ] ].each do |coins, weighings|
        out << ProblemGenerators.problem(
          text: "Имаме #{coins} монети, една от които е по-лека. С везна без теглилки колко най-малко претегляния гарантирано намират по-лената монета?",
          answer: weighings,
          topic: "Логически задачи", grade: 7, tier: :competition,
          explanation: "Всяко претегляне разделя монетите на три групи, значи с #{weighings} претегляния различаваме до 3^#{weighings} = #{3**weighings} монети."
        )
      end

      # Interleaved sequences — two patterns alternating.
      [ [ [ 1, 10, 2, 20, 3, 30 ], 4 ], [ [ 2, 5, 4, 10, 6, 15 ], 8 ], [ [ 1, 2, 3, 4, 9, 8 ], 27 ] ].each do |terms, answer|
        out << ProblemGenerators.problem(
          text: "Кое число следва в редицата: #{terms.join(', ')}, ?",
          answer: answer,
          topic: "Числа и редици", grade: 6, tier: :competition,
          explanation: "Редицата съдържа две редици, преплетени една в друга — гледай числата на четните и на нечетните места отделно."
        )
      end

      # Clock hands angle.
      [ 1, 2, 3, 4, 5, 6, 9 ].each do |hour|
        angle = (hour * 30) % 360
        angle = 360 - angle if angle > 180
        out << ProblemGenerators.problem(
          text: "Колко градуса е ъгълът между часовниковата и минутната стрелка в #{hour} часа точно?",
          answer: angle,
          topic: "Ъгли", grade: 6, tier: :hard,
          explanation: "Всеки час е 360° : 12 = 30°. В #{hour} часа ъгълът е #{hour} · 30° = #{hour * 30}°#{angle != hour * 30 ? ", а по-малкият ъгъл е #{angle}°" : ''}."
        )
      end

      # Knights and knaves, kept small and concrete.
      [ [ 3, 1 ], [ 4, 2 ], [ 5, 2 ], [ 6, 3 ] ].each do |total, liars|
        out << ProblemGenerators.problem(
          text: "В група от #{total} деца всяко твърди: „Аз казвам истината.“ Знаем, че точно #{liars} лъжат. Колко деца казват истината?",
          answer: total - liars,
          topic: "Логически задачи", grade: 4, tier: :easy,
          explanation: "#{total} − #{liars} = #{total - liars} деца казват истината."
        )
      end

      out
    end

    # --- Number curiosities: squares, cubes, Roman numerals ---------------
    def number_curiosities
      out = []

      (2..15).each do |n|
        out << ProblemGenerators.problem(
          text: "Колко е #{n} на квадрат (#{n} · #{n})?", answer: n * n,
          topic: "Умножение и деление", grade: 5, tier: :easy
        )
      end

      (2..8).each do |n|
        out << ProblemGenerators.problem(
          text: "Колко е #{n} на трета степен (#{n} · #{n} · #{n})?", answer: n**3,
          topic: "Умножение и деление", grade: 6, tier: :medium
        )
      end

      [ 16, 25, 36, 49, 64, 81, 100, 121, 144 ].each do |square|
        out << ProblemGenerators.problem(
          text: "Кое число, умножено само по себе си, дава #{square}?", answer: Integer.sqrt(square),
          topic: "Умножение и деление", grade: 5, tier: :medium
        )
      end

      { "IV" => 4, "IX" => 9, "XII" => 12, "XIX" => 19, "XL" => 40, "LXIV" => 64, "XC" => 90, "CXXIII" => 123 }.each do |roman, value|
        out << ProblemGenerators.problem(
          text: "Кое число е записано с римските цифри #{roman}?", answer: value,
          topic: "Числа и редици", grade: 5, tier: :medium,
          explanation: "#{roman} = #{value}."
        )
      end

      # Perfect-square recognition — a "which of these" shape.
      [ [ 36, 35 ], [ 49, 48 ], [ 64, 63 ], [ 81, 80 ], [ 100, 99 ] ].each do |square, near|
        out << ProblemGenerators.problem(
          text: "Кое от двете числа е точен квадрат: #{near} или #{square}?", answer: square.to_s,
          topic: "Умножение и деление", grade: 6, tier: :medium,
          options: [ near.to_s, square.to_s ],
          explanation: "#{square} = #{Integer.sqrt(square)} · #{Integer.sqrt(square)}, а #{near} не е точен квадрат."
        )
      end

      out
    end
  end
end
