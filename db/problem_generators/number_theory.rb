module ProblemGenerators
  # Divisibility, primes, GCD/LCM, remainders, sequences, and equations —
  # grades 4-7, the analytical core of competition mathematics.
  module NumberTheory
    extend self

    def generate
      problems = []
      problems += divisibility
      problems += primes
      problems += gcd_lcm
      problems += remainders
      problems += sequences
      problems += equations
      problems
    end

    private

    def divisibility
      out = []

      # Divisibility rules, one rule at a time.
      { 2 => "2", 5 => "5", 10 => "10", 3 => "3", 9 => "9" }.each do |divisor, label|
        rng = ProblemGenerators.rng("div#{divisor}")
        12.times do
          n = rng.rand(100..999)
          divisible = (n % divisor).zero?
          out << ProblemGenerators.problem(
            text: "Дели ли се числото #{n} на #{label}?",
            answer: divisible ? "да" : "не",
            topic: "Делимост", grade: divisor <= 5 ? 4 : 5, tier: divisor <= 10 ? :easy : :medium,
            options: %w[да не],
            explanation: divisibility_reason(n, divisor, divisible)
          )
        end
      end

      # Counting multiples in a range — a competition staple.
      [ [ 2, 100 ], [ 3, 100 ], [ 4, 100 ], [ 5, 100 ], [ 6, 100 ], [ 7, 100 ], [ 9, 100 ], [ 3, 50 ], [ 4, 50 ], [ 5, 200 ] ].each do |divisor, limit|
        out << ProblemGenerators.problem(
          text: "Колко числа от 1 до #{limit} се делят на #{divisor}?", answer: limit / divisor,
          topic: "Делимост", grade: 5, tier: :medium,
          explanation: "Това са #{divisor}, #{divisor * 2}, #{divisor * 3}, … до #{(limit / divisor) * divisor}. Броят им е #{limit} : #{divisor} = #{limit / divisor}."
        )
      end

      # Smallest/largest multiples.
      rng = ProblemGenerators.rng("divbounds")
      25.times do
        divisor = [ 3, 4, 6, 7, 8, 9, 11, 12 ].sample(random: rng)
        threshold = rng.rand(50..500)
        smallest = ((threshold / divisor) + 1) * divisor
        out << ProblemGenerators.problem(
          text: "Кое е най-малкото число, по-голямо от #{threshold}, което се дели на #{divisor}?",
          answer: smallest,
          topic: "Делимост", grade: 6, tier: :medium,
          explanation: "#{threshold} : #{divisor} = #{threshold / divisor} и остатък. Следващото кратно е #{threshold / divisor + 1} · #{divisor} = #{smallest}."
        )
      end

      # Digit-sum divisibility — connects two rules.
      20.times do
        base = rng.rand(10..99)
        n = base * 9
        out << ProblemGenerators.problem(
          text: "Колко е сборът на цифрите на числото #{n}? (Той се дели на 9, защото и числото се дели на 9.)",
          answer: n.digits.sum,
          topic: "Делимост", grade: 5, tier: :medium,
          explanation: "#{n.digits.reverse.join(' + ')} = #{n.digits.sum}, което наистина се дели на 9."
        )
      end

      out
    end

    def divisibility_reason(n, divisor, divisible)
      case divisor
      when 2 then "Последната цифра е #{n % 10}, значи числото #{divisible ? 'се дели' : 'не се дели'} на 2."
      when 5 then "Последната цифра е #{n % 10}, значи числото #{divisible ? 'се дели' : 'не се дели'} на 5."
      when 10 then "Числото се дели на 10 само ако завършва на 0. Тук завършва на #{n % 10}."
      when 3 then "Сборът на цифрите е #{n.digits.sum}, който #{divisible ? 'се дели' : 'не се дели'} на 3."
      when 9 then "Сборът на цифрите е #{n.digits.sum}, който #{divisible ? 'се дели' : 'не се дели'} на 9."
      end
    end

    def primes
      out = []
      primes_list = (2..100).select { |n| (2..Integer.sqrt(n)).none? { |d| (n % d).zero? } }

      # Is it prime? — mixed primes and composites.
      rng = ProblemGenerators.rng("prime")
      40.times do
        n = rng.rand(11..99)
        prime = primes_list.include?(n)
        out << ProblemGenerators.problem(
          text: "Просто число ли е #{n}?", answer: prime ? "да" : "не",
          topic: "Прости числа", grade: 5, tier: :medium,
          options: %w[да не],
          explanation: prime ? "#{n} се дели само на 1 и на себе си, значи е просто." : "#{n} = #{smallest_factor(n)} · #{n / smallest_factor(n)}, значи не е просто."
        )
      end

      # Counting primes up to n, laddered.
      [ 10, 20, 30, 50, 100 ].each do |limit|
        count = primes_list.count { |p| p <= limit }
        out << ProblemGenerators.problem(
          text: "Колко прости числа има от 1 до #{limit}?", answer: count,
          topic: "Прости числа", grade: 6, tier: :competition,
          explanation: "Простите числа до #{limit} са #{primes_list.select { |p| p <= limit }.first(8).join(', ')}#{count > 8 ? ' и т.н.' : ''} — общо #{count}."
        )
      end

      # Prime factorisation.
      [ 12, 18, 20, 24, 28, 30, 36, 40, 45, 48, 50, 54, 60, 72, 80, 90, 96, 100 ].each do |n|
        factors = prime_factors(n)
        out << ProblemGenerators.problem(
          text: "На колко прости множителя (с повторенията) се разлага числото #{n}? Например 12 = 2 · 2 · 3 има 3 множителя.",
          answer: factors.size,
          topic: "Прости числа", grade: 6, tier: :hard,
          explanation: "#{n} = #{factors.join(' · ')} — общо #{factors.size} множителя."
        )
      end

      # Number of divisors — connects factorisation to counting.
      [ 12, 16, 18, 24, 28, 30, 36, 48, 60, 72, 100 ].each do |n|
        divisors = (1..n).select { |d| (n % d).zero? }
        out << ProblemGenerators.problem(
          text: "Колко делителя има числото #{n}?", answer: divisors.size,
          topic: "Прости числа", grade: 6, tier: :competition,
          explanation: "Делителите са #{divisors.join(', ')} — общо #{divisors.size}."
        )
      end

      out
    end

    def smallest_factor(n)
      (2..n).find { |d| (n % d).zero? }
    end

    def prime_factors(n)
      factors = []
      remaining = n
      divisor = 2
      while remaining > 1
        while (remaining % divisor).zero?
          factors << divisor
          remaining /= divisor
        end
        divisor += 1
      end
      factors
    end

    def gcd_lcm
      out = []
      rng = ProblemGenerators.rng("gcdlcm")

      40.times do
        a = rng.rand(4..60)
        b = rng.rand(4..60)
        next if a == b

        out << ProblemGenerators.problem(
          text: "Колко е най-големият общ делител (НОД) на #{a} и #{b}?", answer: a.gcd(b),
          topic: "НОД и НОК", grade: 6, tier: a.gcd(b) == 1 ? :hard : :medium,
          explanation: a.gcd(b) == 1 ? "#{a} и #{b} нямат общи делители освен 1, значи НОД = 1." : "Общите делители на #{a} и #{b} са до #{a.gcd(b)}, значи НОД = #{a.gcd(b)}."
        )
      end

      35.times do
        a = rng.rand(2..15)
        b = rng.rand(2..15)
        next if a == b

        out << ProblemGenerators.problem(
          text: "Колко е най-малкото общо кратно (НОК) на #{a} и #{b}?", answer: a.lcm(b),
          topic: "НОД и НОК", grade: 6, tier: :medium,
          explanation: "Кратните на #{a} са #{a}, #{a * 2}, #{a * 3}…; първото, което се дели и на #{b}, е #{a.lcm(b)}."
        )
      end

      # The applied LCM form — the "when do they meet again" type.
      [ [ 3, 4 ], [ 4, 6 ], [ 5, 6 ], [ 6, 8 ], [ 4, 10 ], [ 6, 9 ], [ 8, 12 ] ].each do |a, b|
        out << ProblemGenerators.problem(
          text: "Един автобус минава на всеки #{a} минути, друг — на всеки #{b} минути. Тръгват заедно. След колко минути ще тръгнат заедно отново?",
          answer: a.lcm(b),
          topic: "НОД и НОК", grade: 6, tier: :competition,
          explanation: "Търсим НОК(#{a}, #{b}) = #{a.lcm(b)} минути."
        )
      end

      out
    end

    def remainders
      out = []
      rng = ProblemGenerators.rng("rem")

      35.times do
        divisor = rng.rand(3..12)
        n = rng.rand(20..300)
        out << ProblemGenerators.problem(
          text: "Колко е остатъкът при деление на #{n} на #{divisor}?", answer: n % divisor,
          topic: "Остатъци", grade: 5, tier: :medium,
          explanation: "#{n} = #{divisor} · #{n / divisor} + #{n % divisor}, значи остатъкът е #{n % divisor}."
        )
      end

      # Last-digit patterns — competition favourite, laddered by exponent.
      [ 2, 3, 4, 7, 8, 9 ].each do |base|
        [ 2, 3, 4, 5, 10, 20 ].each do |exponent|
          cycle = [ base % 10 ]
          current = base % 10
          9.times do
            current = (current * base) % 10
            break if current == cycle.first

            cycle << current
          end
          last_digit = cycle[(exponent - 1) % cycle.size]
          out << ProblemGenerators.problem(
            text: "Каква е последната цифра на #{base}^#{exponent}?", answer: last_digit,
            topic: "Остатъци", grade: 7, tier: exponent <= 4 ? :hard : :competition,
            explanation: "Последните цифри на степените на #{base} се повтарят циклично: #{cycle.join(', ')}. Периодът е #{cycle.size}, а #{exponent} дава позиция #{(exponent - 1) % cycle.size + 1} — цифрата е #{last_digit}."
          )
        end
      end

      out
    end

    def sequences
      out = []

      # Arithmetic progressions — find the next term.
      rng = ProblemGenerators.rng("seq")
      40.times do
        start = rng.rand(1..20)
        step = rng.rand(2..12)
        terms = (0..3).map { |i| start + i * step }
        out << ProblemGenerators.problem(
          text: "Кое число следва в редицата: #{terms.join(', ')}, ?",
          answer: start + 4 * step,
          topic: "Числа и редици", grade: 3, tier: step <= 5 ? :easy : :medium,
          explanation: "Всяко число е с #{step} повече от предишното: #{terms.last} + #{step} = #{start + 4 * step}."
        )
      end

      # Geometric progressions.
      25.times do
        start = rng.rand(1..5)
        ratio = [ 2, 3 ].sample(random: rng)
        terms = (0..3).map { |i| start * ratio**i }
        out << ProblemGenerators.problem(
          text: "Кое число следва в редицата: #{terms.join(', ')}, ?",
          answer: start * ratio**4,
          topic: "Числа и редици", grade: 5, tier: :medium,
          explanation: "Всяко число е #{ratio} пъти по-голямо от предишното: #{terms.last} · #{ratio} = #{start * ratio**4}."
        )
      end

      # Nth term of an arithmetic sequence — the competition form.
      25.times do
        start = rng.rand(1..15)
        step = rng.rand(2..9)
        n = [ 10, 20, 50, 100 ].sample(random: rng)
        value = start + (n - 1) * step
        out << ProblemGenerators.problem(
          text: "Редица започва с #{start} и всяко следващо число е с #{step} повече. Кое е #{n}-тото число?",
          answer: value,
          topic: "Числа и редици", grade: 6, tier: :competition,
          explanation: "От първото до #{n}-тото има #{n - 1} стъпки: #{start} + #{n - 1} · #{step} = #{value}."
        )
      end

      # Squares, triangular numbers, Fibonacci-style patterns.
      (2..10).each do |n|
        triangular = n * (n + 1) / 2
        out << ProblemGenerators.problem(
          text: "Триъгълните числа са 1, 3, 6, 10, 15, … Кое е #{n}-тото триъгълно число?",
          answer: triangular,
          topic: "Числа и редици", grade: 6, tier: :hard,
          explanation: "#{n}-тото триъгълно число е сборът 1 + 2 + … + #{n} = #{n} · #{n + 1} : 2 = #{triangular}."
        )
      end

      fib = [ 1, 1 ]
      12.times { fib << fib[-1] + fib[-2] }
      (4..11).each do |index|
        out << ProblemGenerators.problem(
          text: "В редицата 1, 1, 2, 3, 5, 8, … всяко число е сборът на двете преди него. Кое е #{index + 1}-вото число?",
          answer: fib[index],
          topic: "Числа и редици", grade: 5, tier: :medium,
          explanation: "Продължаваме: #{fib.first(index + 1).join(', ')} — значи #{index + 1}-вото число е #{fib[index]}."
        )
      end

      out
    end

    def equations
      out = []
      rng = ProblemGenerators.rng("eq")

      # ax = b
      35.times do
        a = rng.rand(2..12)
        x = rng.rand(2..20)
        out << ProblemGenerators.problem(
          text: "Реши уравнението: #{a} · x = #{a * x}. Колко е x?", answer: x,
          topic: "Уравнения", grade: 4, tier: :easy,
          explanation: "x = #{a * x} : #{a} = #{x}."
        )
      end

      # ax + b = c
      35.times do
        a = rng.rand(2..9)
        x = rng.rand(2..15)
        b = rng.rand(1..20)
        out << ProblemGenerators.problem(
          text: "Реши уравнението: #{a} · x + #{b} = #{a * x + b}. Колко е x?", answer: x,
          topic: "Уравнения", grade: 5, tier: :medium,
          explanation: "Първо изваждаме #{b}: #{a} · x = #{a * x}. После делим на #{a}: x = #{x}."
        )
      end

      # ax - b = c
      25.times do
        a = rng.rand(2..9)
        x = rng.rand(3..15)
        b = rng.rand(1..15)
        out << ProblemGenerators.problem(
          text: "Реши уравнението: #{a} · x − #{b} = #{a * x - b}. Колко е x?", answer: x,
          topic: "Уравнения", grade: 5, tier: :medium,
          explanation: "Добавяме #{b} към двете страни: #{a} · x = #{a * x}. Значи x = #{x}."
        )
      end

      # Variables on both sides — grade 7.
      25.times do
        a = rng.rand(3..9)
        b = rng.rand(2..(a - 1))
        x = rng.rand(2..12)
        c = rng.rand(1..15)
        # a·x + c = b·x + (a-b)·x + c  →  keep it honest: a·x + c = b·x + d
        d = (a - b) * x + c
        out << ProblemGenerators.problem(
          text: "Реши уравнението: #{a} · x + #{c} = #{b} · x + #{d}. Колко е x?", answer: x,
          topic: "Уравнения", grade: 7, tier: :hard,
          explanation: "Събираме неизвестните отляво: #{a - b} · x = #{d} − #{c} = #{d - c}. Значи x = #{d - c} : #{a - b} = #{x}."
        )
      end

      out
    end
  end
end
