module ProblemGenerators
  # Counting, combinatorics, pigeonhole, and logic — the reasoning types that
  # competitions lean on. Every type gets an easy on-ramp before the hard form.
  module Logic
    extend self

    def generate
      problems = []
      problems += counting
      problems += handshakes
      problems += pigeonhole
      problems += logic_puzzles
      problems += calendar_and_clock
      problems
    end

    private

    def counting
      out = []

      # Multiplication principle — outfits, routes, menus.
      (2..8).each do |shirts|
        (2..8).each do |trousers|
          out << ProblemGenerators.problem(
            text: "Дете има #{shirts} тениски и #{trousers} панталона. По колко различни начина може да се облече?",
            answer: shirts * trousers,
            topic: "Броене и комбинаторика", grade: 3, tier: shirts <= 4 && trousers <= 4 ? :intro : :easy,
            explanation: "За всяка от #{shirts} тениски има #{trousers} възможни панталона: #{shirts} · #{trousers} = #{shirts * trousers} начина."
          )
        end
      end

      # Three-factor version.
      [ [ 2, 3, 2 ], [ 3, 3, 2 ], [ 2, 4, 3 ], [ 3, 4, 2 ], [ 4, 3, 3 ], [ 2, 5, 4 ] ].each do |a, b, c|
        out << ProblemGenerators.problem(
          text: "В сладкарница има #{a} вида сладолед, #{b} вида сироп и #{c} вида поръска. По колко начина може да се направи десерт от по един вид от всяко?",
          answer: a * b * c,
          topic: "Броене и комбинаторика", grade: 5, tier: :medium,
          explanation: "#{a} · #{b} · #{c} = #{a * b * c} начина."
        )
      end

      # Permutations of distinct objects, laddered by n.
      (2..6).each do |n|
        factorial = (1..n).reduce(:*)
        out << ProblemGenerators.problem(
          text: "По колко различни начина може да се подредят #{n} различни книги на един ред?",
          answer: factorial,
          topic: "Броене и комбинаторика", grade: [ n + 1, 7 ].min, tier: n <= 3 ? :easy : :competition,
          explanation: "За първото място има #{n} възможности, за второто #{n - 1} и така нататък: #{(1..n).to_a.reverse.join(' · ')} = #{factorial}."
        )
      end

      # Choosing 2 from n — the combination idea, laddered.
      (3..10).each do |n|
        pairs = n * (n - 1) / 2
        out << ProblemGenerators.problem(
          text: "От #{n} деца трябва да се изберат 2 за дежурни. По колко начина може да стане това?",
          answer: pairs,
          topic: "Броене и комбинаторика", grade: 6, tier: n <= 5 ? :medium : :hard,
          explanation: "Двойките са #{n} · #{n - 1} : 2 = #{pairs}, защото редът на избиране няма значение."
        )
      end

      # How many numbers can be formed from given digits (no repetition).
      [ [ 2, 2 ], [ 3, 6 ], [ 4, 24 ] ].each do |digits, count|
        out << ProblemGenerators.problem(
          text: "Колко различни #{digits}-цифрени числа може да се съставят от цифрите #{(1..digits).to_a.join(', ')}, ако всяка се използва точно веднъж?",
          answer: count,
          topic: "Броене и комбинаторика", grade: 5, tier: :medium,
          explanation: "Подреждаме #{digits} различни цифри: #{(1..digits).to_a.reverse.join(' · ')} = #{count} числа."
        )
      end

      out
    end

    def handshakes
      out = []

      # The n(n-1)/2 family, from tiny to competition scale.
      (2..12).each do |n|
        total = n * (n - 1) / 2
        tier = n <= 4 ? :intro : (n <= 7 ? :medium : :competition)
        grade = n <= 4 ? 3 : (n <= 7 ? 5 : 6)
        out << ProblemGenerators.problem(
          text: "На среща има #{n} души и всеки се здрависва с всеки друг точно веднъж. Колко здрависвания има общо?",
          answer: total,
          topic: "Броене и комбинаторика", grade: grade, tier: tier,
          explanation: "Всеки от #{n} души се здрависва с #{n - 1} други, което дава #{n} · #{n - 1} = #{n * (n - 1)}. Но всяко здрависване е преброено двойно, значи #{n * (n - 1)} : 2 = #{total}."
        )
      end

      # Same structure, different clothing — teaches transfer.
      (3..10).each do |n|
        total = n * (n - 1) / 2
        out << ProblemGenerators.problem(
          text: "В турнир участват #{n} отбора и всеки играе с всеки друг по един мач. Колко мача се играят?",
          answer: total,
          topic: "Броене и комбинаторика", grade: 6, tier: :hard,
          explanation: "Това е същото като брой двойки: #{n} · #{n - 1} : 2 = #{total} мача."
        )
      end

      (3..8).each do |n|
        out << ProblemGenerators.problem(
          text: "Колко отсечки могат да се начертаят между #{n} точки, никои три от които не лежат на една права?",
          answer: n * (n - 1) / 2,
          topic: "Броене и комбинаторика", grade: 6, tier: :hard,
          explanation: "Всяка отсечка се определя от 2 точки: #{n} · #{n - 1} : 2 = #{n * (n - 1) / 2}."
        )
      end

      out
    end

    def pigeonhole
      out = []

      # The on-ramp: "worst case, then one more" with tiny numbers.
      [ [ 2, 3 ], [ 3, 4 ], [ 4, 5 ], [ 5, 6 ], [ 6, 7 ], [ 10, 11 ] ].each do |colors, answer|
        out << ProblemGenerators.problem(
          text: "В кутия има чорапи в #{colors} цвята, много от всеки цвят. Колко най-малко чорапа трябва да извадим на тъмно, за да сме сигурни, че имаме два с еднакъв цвят?",
          answer: answer,
          topic: "Логически задачи", grade: colors <= 4 ? 5 : 6, tier: colors <= 3 ? :medium : :competition,
          explanation: "В най-лошия случай първите #{colors} чорапа са в различни цветове. Следващият задължително повтаря някой цвят: #{colors} + 1 = #{answer}."
        )
      end

      # Guaranteeing a pair of the same colour.
      [ [ 2, 3 ], [ 3, 5 ], [ 4, 7 ], [ 5, 9 ] ].each do |colors, answer|
        out << ProblemGenerators.problem(
          text: "В чекмедже има чорапи в #{colors} цвята. Колко най-малко трябва да извадим, за да сме сигурни, че имаме поне един пълен чифт от един цвят?",
          answer: answer,
          topic: "Логически задачи", grade: 6, tier: :competition,
          explanation: "Най-лошият случай е по един чорап от всеки цвят (#{colors} чорапа) и после още един — общо #{colors + 1}. За чифт при #{colors} цвята: #{answer}."
        ) if answer == colors + 1
      end

      # Birthday/month pigeonhole.
      [ [ 12, 13, "месеца" ], [ 7, 8, "дни в седмицата" ] ].each do |holes, answer, label|
        out << ProblemGenerators.problem(
          text: "Колко най-малко деца трябва да има в една група, за да сме сигурни, че поне две са родени в един и същ от #{holes} #{label}?",
          answer: answer,
          topic: "Логически задачи", grade: 6, tier: :competition,
          explanation: "При #{holes} възможности, #{holes} деца могат да са различни. #{answer}-ото дете задължително съвпада с някое: #{holes} + 1 = #{answer}."
        )
      end

      out
    end

    def logic_puzzles
      out = []
      rng = ProblemGenerators.rng("logic")

      # True/false counting with a twist — "how many are lying".
      30.times do
        total = rng.rand(3..9)
        heads = rng.rand(1..(total - 1))
        out << ProblemGenerators.problem(
          text: "В двор има #{total} животни — кокошки и зайци. Кокошките са #{heads}. Колко крака имат всички животни заедно?",
          answer: heads * 2 + (total - heads) * 4,
          topic: "Логически задачи", grade: 4, tier: :medium,
          explanation: "Кокошките имат #{heads} · 2 = #{heads * 2} крака, зайците — #{total - heads} · 4 = #{(total - heads) * 4}. Общо #{heads * 2 + (total - heads) * 4}."
        )
      end

      # The classic inverse: heads and legs given, find how many of each.
      30.times do
        chickens = rng.rand(2..12)
        rabbits = rng.rand(2..12)
        heads = chickens + rabbits
        legs = chickens * 2 + rabbits * 4
        out << ProblemGenerators.problem(
          text: "В двор има кокошки и зайци — общо #{heads} глави и #{legs} крака. Колко зайци има?",
          answer: rabbits,
          topic: "Логически задачи", grade: 6, tier: :competition,
          explanation: "Ако всички бяха кокошки, краката щяха да са #{heads} · 2 = #{heads * 2}. Излишните #{legs} − #{heads * 2} = #{legs - heads * 2} крака идват от зайците, всеки от които добавя по 2: #{legs - heads * 2} : 2 = #{rabbits} зайци."
        )
      end

      # Weighing/balance reasoning.
      [ [ 2, 600 ], [ 3, 900 ], [ 4, 1200 ], [ 5, 1000 ], [ 6, 1800 ] ].each do |apples, grams|
        out << ProblemGenerators.problem(
          text: "#{apples} еднакви ябълки тежат #{grams} грама. Колко грама тежи една ябълка?",
          answer: grams / apples,
          topic: "Логически задачи", grade: 4, tier: :easy,
          explanation: "#{grams} : #{apples} = #{grams / apples} грама."
        )
      end

      # Age/order logic with three people.
      30.times do
        names = WordProblems::NAMES.sample(3, random: rng)
        base = rng.rand(7..12)
        d1 = rng.rand(1..4)
        d2 = rng.rand(1..4)
        out << ProblemGenerators.problem(
          text: "#{names[0]} е с #{d1} години по-голяма от #{names[1]}, а #{names[1]} е с #{d2} години по-голяма от #{names[2]}. #{names[2]} е на #{base} години. На колко години е #{names[0]}?",
          answer: base + d1 + d2,
          topic: "Логически задачи", grade: 4, tier: :medium,
          explanation: "#{names[1]} е на #{base} + #{d2} = #{base + d2}. #{names[0]} е на #{base + d2} + #{d1} = #{base + d1 + d2} години."
        )
      end

      out
    end

    def calendar_and_clock
      out = []
      days = %w[понеделник вторник сряда четвъртък петък събота неделя]

      # Day-of-week arithmetic — modular thinking in disguise.
      days.each_with_index do |day, index|
        [ 7, 10, 14, 20, 30, 100 ].each do |offset|
          target = days[(index + offset) % 7]
          out << ProblemGenerators.problem(
            text: "Днес е #{day}. Кой ден от седмицата ще бъде след #{offset} дни?",
            answer: target,
            topic: "Логически задачи", grade: offset <= 14 ? 4 : 5, tier: offset <= 14 ? :medium : :competition,
            options: days,
            explanation: "#{offset} : 7 дава остатък #{offset % 7}. Значи броим #{offset % 7} дни след #{day} — това е #{target}."
          )
        end
      end

      # Clock/time arithmetic.
      rng = ProblemGenerators.rng("clock")
      30.times do
        start_hour = rng.rand(1..10)
        duration = rng.rand(1..8)
        out << ProblemGenerators.problem(
          text: "Филм започва в #{start_hour} часа и продължава #{duration} часа. В колко часа свършва?",
          answer: start_hour + duration,
          topic: "Логически задачи", grade: 3, tier: :easy
        )
      end

      25.times do
        minutes = [ 15, 20, 30, 40, 45, 50 ].sample(random: rng)
        out << ProblemGenerators.problem(
          text: "Урок продължава #{minutes} минути и започва в 9 часа и 10 минути. В колко минути след 9 часа свършва?",
          answer: 10 + minutes,
          topic: "Логически задачи", grade: 4, tier: :medium,
          explanation: "10 + #{minutes} = #{10 + minutes} минути след 9 часа."
        )
      end

      out
    end
  end
end
