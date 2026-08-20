module ProblemGenerators
  # Addition, subtraction, multiplication, division, order of operations, and
  # the digit/number-puzzle types competitions build on.
  module Arithmetic
    extend self

    def generate
      problems = []
      problems += addition_subtraction
      problems += multiplication_division
      problems += order_of_operations
      problems += missing_number
      problems += digit_puzzles
      problems += rounding_and_place_value
      problems
    end

    private

    def addition_subtraction
      out = []

      # Grade 1: within 20, then within 100 — the on-ramp for every later type.
      (1..9).each do |a|
        (1..9).each do |b|
          next if a + b > 20

          out << ProblemGenerators.problem(
            text: "#{a} + #{b} = ?", answer: a + b,
            topic: "Събиране и изваждане", grade: 1, tier: :intro
          )
        end
      end

      (11..20).each do |a|
        (2..9).each do |b|
          next if a - b < 1

          out << ProblemGenerators.problem(
            text: "#{a} − #{b} = ?", answer: a - b,
            topic: "Събиране и изваждане", grade: 1, tier: :easy
          )
        end
      end

      # Grade 2: two-digit with and without carrying.
      rng = ProblemGenerators.rng("add2")
      40.times do
        a = rng.rand(21..89)
        b = rng.rand(11..(99 - a > 10 ? 99 - a : 10))
        out << ProblemGenerators.problem(
          text: "#{a} + #{b} = ?", answer: a + b,
          topic: "Събиране и изваждане", grade: 2, tier: :easy
        )
      end

      30.times do
        a = rng.rand(40..99)
        b = rng.rand(11..(a - 5))
        out << ProblemGenerators.problem(
          text: "#{a} − #{b} = ?", answer: a - b,
          topic: "Събиране и изваждане", grade: 2, tier: :medium
        )
      end

      # Grade 3-4: three-digit, and chained sums (competitions love these).
      30.times do
        a = rng.rand(120..880)
        b = rng.rand(110..(999 - a))
        out << ProblemGenerators.problem(
          text: "#{a} + #{b} = ?", answer: a + b,
          topic: "Събиране и изваждане", grade: 3, tier: :easy
        )
      end

      25.times do
        a = rng.rand(30..99)
        b = rng.rand(20..99)
        c = rng.rand(10..80)
        out << ProblemGenerators.problem(
          text: "#{a} + #{b} − #{c} = ?", answer: a + b - c,
          topic: "Събиране и изваждане", grade: 3, tier: :medium,
          explanation: "Действията са на едно ниво, затова се извършват отляво надясно: #{a} + #{b} = #{a + b}, после #{a + b} − #{c} = #{a + b - c}."
        )
      end

      # Sum of consecutive numbers — the Gauss trick, laddered.
      [ [ 10, 2 ], [ 20, 3 ], [ 50, 4 ], [ 100, 5 ] ].each do |limit, grade|
        total = (1..limit).sum
        out << ProblemGenerators.problem(
          text: "Колко е сборът на всички числа от 1 до #{limit}?", answer: total,
          topic: "Събиране и изваждане", grade: grade, tier: :competition,
          explanation: "Групирай числата по двойки от краищата: 1 + #{limit} = #{1 + limit}, 2 + #{limit - 1} = #{1 + limit} и така нататък. Има #{limit / 2} такива двойки, значи сборът е #{limit / 2} · #{1 + limit} = #{total}."
        )
      end

      out
    end

    def multiplication_division
      out = []

      # The full times table, split into tiers by size — grade 2-3 backbone.
      (2..10).each do |a|
        (2..10).each do |b|
          tier = a * b <= 30 ? :intro : :easy
          out << ProblemGenerators.problem(
            text: "#{a} · #{b} = ?", answer: a * b,
            topic: "Умножение и деление", grade: 2, tier: tier
          )
        end
      end

      (2..10).each do |b|
        (2..10).each do |q|
          product = b * q
          out << ProblemGenerators.problem(
            text: "#{product} : #{b} = ?", answer: q,
            topic: "Умножение и деление", grade: 3, tier: product <= 40 ? :intro : :easy
          )
        end
      end

      rng = ProblemGenerators.rng("muldiv")

      # Two-digit by one-digit, then two-digit by two-digit.
      30.times do
        a = rng.rand(12..49)
        b = rng.rand(3..9)
        out << ProblemGenerators.problem(
          text: "#{a} · #{b} = ?", answer: a * b,
          topic: "Умножение и деление", grade: 3, tier: :medium
        )
      end

      25.times do
        a = rng.rand(12..40)
        b = rng.rand(11..30)
        out << ProblemGenerators.problem(
          text: "#{a} · #{b} = ?", answer: a * b,
          topic: "Умножение и деление", grade: 4, tier: :medium
        )
      end

      25.times do
        q = rng.rand(12..60)
        b = rng.rand(3..12)
        out << ProblemGenerators.problem(
          text: "#{q * b} : #{b} = ?", answer: q,
          topic: "Умножение и деление", grade: 4, tier: :easy
        )
      end

      # Division with remainder — the gateway to modular arithmetic.
      30.times do
        b = rng.rand(3..9)
        q = rng.rand(4..20)
        r = rng.rand(1..(b - 1))
        out << ProblemGenerators.problem(
          text: "При деление на #{q * b + r} на #{b} колко е остатъкът?", answer: r,
          topic: "Умножение и деление", grade: 4, tier: :medium,
          explanation: "#{q * b + r} = #{b} · #{q} + #{r}, значи частното е #{q}, а остатъкът е #{r}."
        )
      end

      out
    end

    def order_of_operations
      out = []
      rng = ProblemGenerators.rng("order")

      35.times do
        a = rng.rand(2..9)
        b = rng.rand(2..9)
        c = rng.rand(2..20)
        out << ProblemGenerators.problem(
          text: "#{c} + #{a} · #{b} = ?", answer: c + a * b,
          topic: "Ред на действията", grade: 3, tier: :easy,
          explanation: "Първо умножението: #{a} · #{b} = #{a * b}. После събирането: #{c} + #{a * b} = #{c + a * b}."
        )
      end

      30.times do
        a = rng.rand(2..9)
        b = rng.rand(2..9)
        c = rng.rand(2..9)
        d = rng.rand(2..9)
        out << ProblemGenerators.problem(
          text: "#{a} · #{b} + #{c} · #{d} = ?", answer: a * b + c * d,
          topic: "Ред на действията", grade: 4, tier: :medium,
          explanation: "Двете умножения първо: #{a * b} и #{c * d}. Сборът е #{a * b + c * d}."
        )
      end

      30.times do
        a = rng.rand(2..9)
        b = rng.rand(2..12)
        c = rng.rand(2..9)
        out << ProblemGenerators.problem(
          text: "#{a} · (#{b} + #{c}) = ?", answer: a * (b + c),
          topic: "Ред на действията", grade: 4, tier: :medium,
          explanation: "Скобите първо: #{b} + #{c} = #{b + c}. После #{a} · #{b + c} = #{a * (b + c)}."
        )
      end

      25.times do
        a = rng.rand(2..9)
        b = rng.rand(2..9)
        c = rng.rand(2..9)
        d = rng.rand(2..6)
        value = (a + b) * c - d
        out << ProblemGenerators.problem(
          text: "(#{a} + #{b}) · #{c} − #{d} = ?", answer: value,
          topic: "Ред на действията", grade: 5, tier: :medium,
          explanation: "Скоби, после умножение, после изваждане: (#{a + b}) · #{c} = #{(a + b) * c}, и #{(a + b) * c} − #{d} = #{value}."
        )
      end

      out
    end

    def missing_number
      out = []
      rng = ProblemGenerators.rng("missing")

      25.times do
        a = rng.rand(3..19)
        sum = a + rng.rand(3..20)
        out << ProblemGenerators.problem(
          text: "#{a} + ? = #{sum}", answer: sum - a,
          topic: "Уравнения", grade: 1, tier: :easy,
          explanation: "Търсим колко трябва да добавим към #{a}, за да стане #{sum}: #{sum} − #{a} = #{sum - a}."
        )
      end

      25.times do
        b = rng.rand(2..9)
        q = rng.rand(2..12)
        out << ProblemGenerators.problem(
          text: "? · #{b} = #{b * q}", answer: q,
          topic: "Уравнения", grade: 3, tier: :easy,
          explanation: "#{b * q} : #{b} = #{q}."
        )
      end

      25.times do
        a = rng.rand(20..90)
        d = rng.rand(5..19)
        out << ProblemGenerators.problem(
          text: "? − #{d} = #{a}", answer: a + d,
          topic: "Уравнения", grade: 2, tier: :medium,
          explanation: "Обратното действие на изваждане е събиране: #{a} + #{d} = #{a + d}."
        )
      end

      out
    end

    def digit_puzzles
      out = []

      # Two-digit numbers with a given digit sum — a classic competition warm-up,
      # laddered from "list them" to "find the largest".
      (3..12).each do |digit_sum|
        candidates = (10..99).select { |n| n.digits.sum == digit_sum }
        next if candidates.empty?

        out << ProblemGenerators.problem(
          text: "Колко двуцифрени числа имат сбор на цифрите #{digit_sum}?", answer: candidates.size,
          topic: "Броене и комбинаторика", grade: 4, tier: :medium,
          explanation: "Това са числата #{candidates.first(6).join(', ')}#{candidates.size > 6 ? ' и т.н.' : ''} — общо #{candidates.size}."
        )
        out << ProblemGenerators.problem(
          text: "Кое е най-голямото двуцифрено число със сбор на цифрите #{digit_sum}?", answer: candidates.max,
          topic: "Броене и комбинаторика", grade: 3, tier: :easy,
          explanation: "За да е числото най-голямо, цифрата на десетиците трябва да е възможно най-голяма: #{candidates.max}."
        )
      end

      # Digit reversal — introduces the 9-divisibility pattern.
      [ [ 2, 41 ], [ 3, 52 ], [ 4, 63 ], [ 5, 74 ] ].each do |grade, number|
        reversed = number.to_s.reverse.to_i
        out << ProblemGenerators.problem(
          text: "Числото #{number} се записва с разменени цифри. Колко е разликата между по-голямото и по-малкото от двете числа?",
          answer: (number - reversed).abs,
          topic: "Броене и комбинаторика", grade: grade, tier: :medium,
          explanation: "Другото число е #{reversed}. Разликата е #{[ number, reversed ].max} − #{[ number, reversed ].min} = #{(number - reversed).abs}. Забележи, че тя винаги се дели на 9."
        )
      end

      out
    end

    def rounding_and_place_value
      out = []
      rng = ProblemGenerators.rng("place")

      25.times do
        n = rng.rand(105..995)
        rounded = (n / 10.0).round * 10
        out << ProblemGenerators.problem(
          text: "Закръгли #{n} до десетици.", answer: rounded,
          topic: "Числа и редици", grade: 3, tier: :easy,
          explanation: "Цифрата на единиците е #{n % 10}, затова закръгляме #{n % 10 >= 5 ? 'нагоре' : 'надолу'}: #{rounded}."
        )
      end

      20.times do
        n = rng.rand(1050..9950)
        rounded = (n / 100.0).round * 100
        out << ProblemGenerators.problem(
          text: "Закръгли #{n} до стотици.", answer: rounded,
          topic: "Числа и редици", grade: 4, tier: :medium,
          explanation: "Гледаме цифрата на десетиците (#{(n / 10) % 10}): закръгляме #{(n % 100) >= 50 ? 'нагоре' : 'надолу'} до #{rounded}."
        )
      end

      20.times do
        n = rng.rand(1234..9876)
        out << ProblemGenerators.problem(
          text: "Колко е сборът на цифрите на числото #{n}?", answer: n.digits.sum,
          topic: "Числа и редици", grade: 3, tier: :easy,
          explanation: "#{n.digits.reverse.join(' + ')} = #{n.digits.sum}."
        )
      end

      out
    end
  end
end
