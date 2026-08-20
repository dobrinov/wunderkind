module ProblemGenerators
  # Grades 1-2 need many *kinds* of small problem, not many additions. Without
  # this, a first-grader's session is three templates repeated, because the
  # drill generators are the only thing producing content at that level.
  module EarlyGrades
    extend self

    def generate
      problems = []
      problems += number_sense
      problems += comparisons
      problems += counting_by_steps
      problems += place_value
      problems += doubles_and_halves
      problems += money_basics
      problems += shapes_basics
      problems += time_and_order
      problems += small_stories
      problems
    end

    private

    def number_sense
      out = []

      (2..19).each do |n|
        out << ProblemGenerators.problem(
          text: "Кое число е с 1 по-голямо от #{n}?", answer: n + 1,
          topic: "Числа и редици", grade: 1, tier: :intro
        )
        out << ProblemGenerators.problem(
          text: "Кое число е с 1 по-малко от #{n}?", answer: n - 1,
          topic: "Числа и редици", grade: 1, tier: :intro
        )
      end

      (2..18).each do |n|
        out << ProblemGenerators.problem(
          text: "Кое число е между #{n - 1} и #{n + 1}?", answer: n,
          topic: "Числа и редици", grade: 1, tier: :intro
        )
      end

      # Number bonds to ten — the foundation of mental arithmetic.
      (1..9).each do |n|
        out << ProblemGenerators.problem(
          text: "Колко трябва да добавим към #{n}, за да получим 10?", answer: 10 - n,
          topic: "Събиране и изваждане", grade: 1, tier: :easy,
          explanation: "#{n} + #{10 - n} = 10."
        )
      end

      (11..19).each do |n|
        out << ProblemGenerators.problem(
          text: "Колко трябва да добавим към #{n}, за да получим 20?", answer: 20 - n,
          topic: "Събиране и изваждане", grade: 2, tier: :easy
        )
      end

      out
    end

    def comparisons
      out = []
      rng = ProblemGenerators.rng("early_cmp")

      15.times do
        a = rng.rand(3..20)
        b = rng.rand(3..20)
        next if a == b

        out << ProblemGenerators.problem(
          text: "С колко е по-голямо #{[ a, b ].max} от #{[ a, b ].min}?", answer: (a - b).abs,
          topic: "Събиране и изваждане", grade: 1, tier: :easy,
          explanation: "#{[ a, b ].max} − #{[ a, b ].min} = #{(a - b).abs}."
        )
      end

      12.times do
        numbers = (1..30).to_a.sample(4, random: rng)
        out << ProblemGenerators.problem(
          text: "Кое е най-голямото от числата #{numbers.join(', ')}?", answer: numbers.max,
          topic: "Числа и редици", grade: 1, tier: :easy
        )
      end

      12.times do
        numbers = (1..30).to_a.sample(4, random: rng)
        out << ProblemGenerators.problem(
          text: "Кое е най-малкото от числата #{numbers.join(', ')}?", answer: numbers.min,
          topic: "Числа и редици", grade: 1, tier: :easy
        )
      end

      # Comparison in a story, which is harder than comparing bare numbers.
      12.times do
        mine = rng.rand(3..15)
        theirs = rng.rand(3..15)
        next if mine == theirs

        out << ProblemGenerators.problem(
          text: "Иван има #{mine} стикера, а Мария има #{theirs}. С колко стикера повече има #{mine > theirs ? 'Иван' : 'Мария'}?",
          answer: (mine - theirs).abs,
          topic: "Текстови задачи", grade: 2, tier: :medium,
          explanation: "#{[ mine, theirs ].max} − #{[ mine, theirs ].min} = #{(mine - theirs).abs}."
        )
      end

      out
    end

    def counting_by_steps
      out = []

      [ [ 2, 1 ], [ 5, 1 ], [ 10, 1 ], [ 3, 2 ], [ 4, 2 ] ].each do |step, grade|
        [ 0, step * 2, step * 4 ].each do |start|
          terms = (0..3).map { |i| start + i * step }
          out << ProblemGenerators.problem(
            text: "Броим през #{step}: #{terms.join(', ')}, ? Кое число следва?",
            answer: start + 4 * step,
            topic: "Числа и редици", grade: grade, tier: :easy,
            explanation: "Всяко следващо число е с #{step} повече: #{terms.last} + #{step} = #{start + 4 * step}."
          )
        end
      end

      # Counting backwards, which children find markedly harder.
      [ [ 2, 20 ], [ 5, 30 ], [ 10, 50 ] ].each do |step, start|
        terms = (0..3).map { |i| start - i * step }
        out << ProblemGenerators.problem(
          text: "Броим назад през #{step}: #{terms.join(', ')}, ? Кое число следва?",
          answer: start - 4 * step,
          topic: "Числа и редици", grade: 2, tier: :medium,
          explanation: "Всяко следващо число е с #{step} по-малко: #{terms.last} − #{step} = #{start - 4 * step}."
        )
      end

      out
    end

    def place_value
      out = []

      (11..99).select { |n| (n % 10) != 0 }.sample(14, random: ProblemGenerators.rng("pv1")).each do |n|
        out << ProblemGenerators.problem(
          text: "Колко десетици има числото #{n}?", answer: n / 10,
          topic: "Числа и редици", grade: 2, tier: :easy,
          explanation: "#{n} = #{n / 10} десетици и #{n % 10} единици."
        )
      end

      (11..99).select { |n| (n % 10) != 0 }.sample(14, random: ProblemGenerators.rng("pv2")).each do |n|
        out << ProblemGenerators.problem(
          text: "Колко единици има числото #{n}?", answer: n % 10,
          topic: "Числа и редици", grade: 2, tier: :easy
        )
      end

      (2..9).each do |tens|
        (1..9).each do |ones|
          next unless (tens + ones).even?

          out << ProblemGenerators.problem(
            text: "Кое число има #{tens} десетици и #{ones} единици?", answer: tens * 10 + ones,
            topic: "Числа и редици", grade: 2, tier: :medium
          )
        end
      end

      out
    end

    def doubles_and_halves
      out = []

      (1..15).each do |n|
        out << ProblemGenerators.problem(
          text: "Колко е двойно по-голямо от #{n}?", answer: n * 2,
          topic: "Умножение и деление", grade: 2, tier: :easy,
          explanation: "#{n} + #{n} = #{n * 2}."
        )
      end

      (1..15).each do |n|
        out << ProblemGenerators.problem(
          text: "Колко е половината на #{n * 2}?", answer: n,
          topic: "Умножение и деление", grade: 2, tier: :easy,
          explanation: "#{n * 2} : 2 = #{n}."
        )
      end

      # Equal groups — multiplication before it is called multiplication.
      (2..6).each do |groups|
        (2..6).each do |each|
          out << ProblemGenerators.problem(
            text: "Има #{groups} кошници с по #{each} ябълки. Колко ябълки има общо?",
            answer: groups * each,
            topic: "Умножение и деление", grade: 2, tier: :medium,
            explanation: "#{groups} пъти по #{each} = #{groups * each} ябълки."
          )
        end
      end

      out
    end

    def money_basics
      out = []

      [ 2, 5, 10 ].each do |coin|
        (2..6).each do |count|
          out << ProblemGenerators.problem(
            text: "Колко лева са #{count} монети по #{coin} лева?", answer: coin * count,
            topic: "Текстови задачи", grade: 2, tier: :easy,
            explanation: "#{count} · #{coin} = #{coin * count} лева."
          )
        end
      end

      [ [ 2, 10 ], [ 2, 14 ], [ 5, 15 ], [ 5, 25 ], [ 10, 30 ], [ 10, 50 ] ].each do |coin, total|
        out << ProblemGenerators.problem(
          text: "Колко монети по #{coin} лева са нужни, за да се съберат #{total} лева?", answer: total / coin,
          topic: "Текстови задачи", grade: 3, tier: :medium,
          explanation: "#{total} : #{coin} = #{total / coin} монети."
        )
      end

      out
    end

    def shapes_basics
      out = []

      { "триъгълник" => 3, "четириъгълник" => 4, "петоъгълник" => 5,
        "шестоъгълник" => 6, "осмоъгълник" => 8 }.each do |name, sides|
        out << ProblemGenerators.problem(
          text: "Колко страни има #{name}?", answer: sides,
          topic: "Периметър", grade: 1, tier: :intro
        )
        out << ProblemGenerators.problem(
          text: "Колко върха има #{name}?", answer: sides,
          topic: "Периметър", grade: 2, tier: :easy,
          explanation: "Върховете са толкова, колкото и страните: #{sides}."
        )
      end

      (2..8).each do |count|
        out << ProblemGenerators.problem(
          text: "Колко страни имат общо #{count} триъгълника?", answer: count * 3,
          topic: "Периметър", grade: 2, tier: :medium,
          explanation: "#{count} · 3 = #{count * 3} страни."
        )
      end

      out
    end

    def time_and_order
      out = []
      days = %w[понеделник вторник сряда четвъртък петък събота неделя]

      days.each_with_index do |day, index|
        out << ProblemGenerators.problem(
          text: "Кой ден от седмицата е след #{day}?", answer: days[(index + 1) % 7],
          topic: "Логически задачи", grade: 2, tier: :easy,
          options: days
        )
      end

      days.each_with_index do |day, index|
        out << ProblemGenerators.problem(
          text: "Кой по ред е #{day} в седмицата?", answer: index + 1,
          topic: "Логически задачи", grade: 2, tier: :medium
        )
      end

      %w[януари февруари март април май юни].each_with_index do |month, index|
        out << ProblemGenerators.problem(
          text: "Кой по ред месец в годината е #{month}?", answer: index + 1,
          topic: "Логически задачи", grade: 2, tier: :medium
        )
      end

      # Ordinal position in a queue.
      (2..8).each do |position|
        out << ProblemGenerators.problem(
          text: "На опашка чакат 10 деца. Колко деца стоят пред детето на #{position}-то място?",
          answer: position - 1,
          topic: "Логически задачи", grade: 2, tier: :medium,
          explanation: "Пред него стоят #{position} − 1 = #{position - 1} деца."
        )
      end

      out
    end

    def small_stories
      out = []
      rng = ProblemGenerators.rng("early_story")

      # Animal legs — small multiplication in a concrete story.
      { "кокошки" => 2, "котки" => 4, "паяци" => 8 }.each do |animal, legs|
        (2..5).each do |count|
          out << ProblemGenerators.problem(
            text: "Колко крака имат #{count} #{animal}?", answer: count * legs,
            topic: "Умножение и деление", grade: 2, tier: :medium,
            explanation: "Всяка има #{legs} крака: #{count} · #{legs} = #{count * legs}."
          )
        end
      end

      # Three-addend sums in a story.
      12.times do
        a = rng.rand(1..8)
        b = rng.rand(1..8)
        c = rng.rand(1..8)
        out << ProblemGenerators.problem(
          text: "В една ваза има #{a} червени, #{b} бели и #{c} жълти цветя. Колко цветя има общо?",
          answer: a + b + c,
          topic: "Текстови задачи", grade: 2, tier: :medium,
          explanation: "#{a} + #{b} + #{c} = #{a + b + c} цветя."
        )
      end

      # Take-away story with a remainder to find.
      12.times do
        start = rng.rand(8..20)
        gone = rng.rand(2..(start - 2))
        out << ProblemGenerators.problem(
          text: "На една чиния имало #{start} бисквити. Децата изяли #{gone}. Колко бисквити останали?",
          answer: start - gone,
          topic: "Текстови задачи", grade: 1, tier: :easy,
          explanation: "#{start} − #{gone} = #{start - gone} бисквити."
        )
      end

      out
    end
  end
end
