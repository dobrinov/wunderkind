module ProblemGenerators
  # Fractions, decimals, and percentages — grades 3-7.
  module Fractions
    extend self

    def generate
      problems = []
      problems += fraction_of_a_number
      problems += fraction_arithmetic
      problems += comparing_fractions
      problems += decimals
      problems += percentages
      problems
    end

    private

    def fraction_of_a_number
      out = []

      # "Part of a whole" with whole-number answers only — the on-ramp.
      [ [ 2, 3 ], [ 3, 3 ], [ 4, 4 ], [ 5, 4 ], [ 6, 4 ], [ 8, 5 ], [ 10, 5 ] ].each do |denominator, grade|
        (1...denominator).each do |numerator|
          [ denominator, denominator * 2, denominator * 3, denominator * 5, denominator * 10 ].each do |whole|
            value = whole * numerator / denominator
            next unless (whole * numerator) % denominator == 0

            tier = numerator == 1 ? :intro : (whole <= denominator * 3 ? :easy : :medium)
            out << ProblemGenerators.problem(
              text: "Колко е #{numerator}/#{denominator} от #{whole}?", answer: value,
              topic: "Дроби", grade: grade, tier: tier,
              explanation: "Разделяме #{whole} на #{denominator} равни части: #{whole} : #{denominator} = #{whole / denominator}. Вземаме #{numerator} от тях: #{whole / denominator} · #{numerator} = #{value}."
            )
          end
        end
      end

      out
    end

    def fraction_arithmetic
      out = []

      # Same denominator first (grade 4), then different (grade 5-6).
      [ 3, 4, 5, 6, 8, 10, 12 ].each do |d|
        (1...d).each do |a|
          (1...d).each do |b|
            next if a + b >= d

            out << ProblemGenerators.problem(
              text: "#{a}/#{d} + #{b}/#{d} = ? (Запиши като дроб или десетично число.)",
              answer: Rational(a + b, d).to_s.include?("/") ? "#{a + b}/#{d}" : (a + b) / d,
              topic: "Дроби", grade: 4, tier: :easy,
              explanation: "При равни знаменатели събираме числителите: (#{a} + #{b})/#{d} = #{a + b}/#{d}."
            )
          end
        end
      end

      rng = ProblemGenerators.rng("fracadd")
      40.times do
        d1 = [ 2, 3, 4, 5, 6 ].sample(random: rng)
        d2 = [ 2, 3, 4, 5, 6, 8, 10 ].reject { |d| d == d1 }.sample(random: rng)
        n1 = rng.rand(1...d1)
        n2 = rng.rand(1...d2)
        sum = Rational(n1, d1) + Rational(n2, d2)
        next if sum > 1

        out << ProblemGenerators.problem(
          text: "#{n1}/#{d1} + #{n2}/#{d2} = ? (Запиши като дроб.)",
          answer: sum.denominator == 1 ? sum.numerator : "#{sum.numerator}/#{sum.denominator}",
          topic: "Дроби", grade: 5, tier: :medium,
          explanation: "Общ знаменател е #{d1.lcm(d2)}: #{n1}/#{d1} = #{n1 * (d1.lcm(d2) / d1)}/#{d1.lcm(d2)} и #{n2}/#{d2} = #{n2 * (d1.lcm(d2) / d2)}/#{d1.lcm(d2)}. Сборът е #{sum.numerator}/#{sum.denominator}."
        )
      end

      # Simplifying — trains the GCD idea before it is named.
      30.times do
        base = rng.rand(2..9)
        factor = rng.rand(2..8)
        num = base * factor
        den = (base + rng.rand(1..5)) * factor
        simplified = Rational(num, den)
        out << ProblemGenerators.problem(
          text: "Съкрати дробта #{num}/#{den}.",
          answer: "#{simplified.numerator}/#{simplified.denominator}",
          topic: "Дроби", grade: 5, tier: :medium,
          explanation: "Най-големият общ делител на #{num} и #{den} е #{num.gcd(den)}. Делим и двете: #{simplified.numerator}/#{simplified.denominator}."
        )
      end

      out
    end

    def comparing_fractions
      out = []
      rng = ProblemGenerators.rng("fraccmp")

      35.times do
        d1 = [ 2, 3, 4, 5, 6, 8, 10, 12 ].sample(random: rng)
        d2 = [ 2, 3, 4, 5, 6, 8, 10, 12 ].sample(random: rng)
        n1 = rng.rand(1...d1)
        n2 = rng.rand(1...d2)
        next if Rational(n1, d1) == Rational(n2, d2)

        bigger = Rational(n1, d1) > Rational(n2, d2) ? "#{n1}/#{d1}" : "#{n2}/#{d2}"
        out << ProblemGenerators.problem(
          text: "Коя дроб е по-голяма: #{n1}/#{d1} или #{n2}/#{d2}?", answer: bigger,
          topic: "Дроби", grade: 5, tier: :medium,
          options: [ "#{n1}/#{d1}", "#{n2}/#{d2}" ],
          explanation: "Приведени под общ знаменател #{d1.lcm(d2)}: #{n1 * (d1.lcm(d2) / d1)}/#{d1.lcm(d2)} и #{n2 * (d1.lcm(d2) / d2)}/#{d1.lcm(d2)}. По-голямата е #{bigger}."
        )
      end

      # Unit fractions — the counter-intuitive "bigger denominator, smaller
      # fraction" idea that competitions test early.
      [ [ 2, 3 ], [ 3, 4 ], [ 4, 5 ], [ 5, 6 ], [ 6, 8 ], [ 8, 10 ] ].each do |a, b|
        out << ProblemGenerators.problem(
          text: "Коя дроб е по-голяма: 1/#{a} или 1/#{b}?", answer: "1/#{a}",
          topic: "Дроби", grade: 4, tier: :easy,
          options: [ "1/#{a}", "1/#{b}" ],
          explanation: "Колкото повече части разделим едно цяло, толкова по-малка е всяка част. #{a} < #{b}, значи 1/#{a} е по-голяма."
        )
      end

      out
    end

    def decimals
      out = []
      rng = ProblemGenerators.rng("dec")

      30.times do
        a = rng.rand(1..90) / 10.0
        b = rng.rand(1..90) / 10.0
        sum = ((a + b) * 10).round / 10.0
        out << ProblemGenerators.problem(
          text: "#{format('%g', a).tr('.', ',')} + #{format('%g', b).tr('.', ',')} = ?",
          answer: format("%g", sum),
          topic: "Десетични числа", grade: 5, tier: :easy,
          explanation: "Подравняваме десетичните запетаи и събираме: #{format('%g', sum).tr('.', ',')}."
        )
      end

      25.times do
        a = rng.rand(20..99) / 10.0
        b = rng.rand(1..19) / 10.0
        diff = ((a - b) * 10).round / 10.0
        out << ProblemGenerators.problem(
          text: "#{format('%g', a).tr('.', ',')} − #{format('%g', b).tr('.', ',')} = ?",
          answer: format("%g", diff),
          topic: "Десетични числа", grade: 5, tier: :easy
        )
      end

      25.times do
        a = rng.rand(11..99) / 10.0
        b = rng.rand(2..9)
        product = ((a * b) * 10).round / 10.0
        out << ProblemGenerators.problem(
          text: "#{format('%g', a).tr('.', ',')} · #{b} = ?",
          answer: format("%g", product),
          topic: "Десетични числа", grade: 5, tier: :medium,
          explanation: "Умножаваме без запетаята: #{(a * 10).round} · #{b} = #{(a * 10).round * b}, после връщаме една цифра след запетаята: #{format('%g', product).tr('.', ',')}."
        )
      end

      # Fraction ↔ decimal conversion, which the answer checker accepts either way.
      [ [ 1, 2 ], [ 1, 4 ], [ 3, 4 ], [ 1, 5 ], [ 2, 5 ], [ 3, 5 ], [ 4, 5 ], [ 1, 10 ], [ 7, 10 ], [ 1, 8 ], [ 3, 8 ] ].each do |n, d|
        out << ProblemGenerators.problem(
          text: "Запиши дробта #{n}/#{d} като десетично число.",
          answer: format("%g", n.to_f / d),
          topic: "Десетични числа", grade: 5, tier: :medium,
          explanation: "#{n} : #{d} = #{format('%g', n.to_f / d).tr('.', ',')}."
        )
      end

      out
    end

    def percentages
      out = []

      # Anchor percentages on friendly numbers first.
      [ 10, 20, 25, 50, 75 ].each do |percent|
        [ 20, 40, 60, 80, 100, 200, 400 ].each do |whole|
          value = whole * percent / 100.0
          next unless value == value.to_i

          out << ProblemGenerators.problem(
            text: "Колко е #{percent}% от #{whole}?", answer: value.to_i,
            topic: "Проценти", grade: 6, tier: percent == 50 || percent == 10 ? :easy : :medium,
            explanation: "#{percent}% означава #{percent}/100. #{whole} · #{percent} : 100 = #{value.to_i}."
          )
        end
      end

      rng = ProblemGenerators.rng("pct")
      25.times do
        percent = [ 5, 15, 30, 40, 60, 80 ].sample(random: rng)
        whole = [ 50, 100, 150, 200, 250, 300, 500 ].sample(random: rng)
        value = whole * percent / 100.0
        next unless value == value.to_i

        out << ProblemGenerators.problem(
          text: "Колко е #{percent}% от #{whole}?", answer: value.to_i,
          topic: "Проценти", grade: 6, tier: :medium
        )
      end

      # Discounts and increases — the applied form.
      25.times do
        price = [ 40, 50, 60, 80, 100, 120, 200 ].sample(random: rng)
        percent = [ 10, 20, 25, 50 ].sample(random: rng)
        final = price - price * percent / 100
        out << ProblemGenerators.problem(
          text: "Играчка струва #{price} лв. Намалена е с #{percent}%. Колко струва след намалението?",
          answer: final,
          topic: "Проценти", grade: 6, tier: :medium,
          explanation: "Намалението е #{price} · #{percent} : 100 = #{price * percent / 100} лв. Новата цена е #{price} − #{price * percent / 100} = #{final} лв."
        )
      end

      20.times do
        whole = [ 20, 25, 40, 50, 80, 100 ].sample(random: rng)
        part = whole / [ 2, 4, 5 ].sample(random: rng)
        percent = part * 100 / whole
        out << ProblemGenerators.problem(
          text: "Колко процента е #{part} от #{whole}?", answer: percent,
          topic: "Проценти", grade: 7, tier: :medium,
          explanation: "#{part} : #{whole} = #{format('%g', part.to_f / whole)}, което е #{percent}%."
        )
      end

      out
    end
  end
end
