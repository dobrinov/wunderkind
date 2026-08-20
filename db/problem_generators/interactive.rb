module ProblemGenerators
  # Problems answered through the widget library rather than by typing.
  module Interactive
    extend self

    def generate
      problems = []
      problems += number_line
      problems += fraction_bars
      problems += ordering
      problems
    end

    private

    def number_line
      out = []

      # Whole numbers on 0..10 and 0..20 — the earliest grades.
      (1..9).each do |value|
        out << ProblemGenerators.problem(
          text: "Постави точката върху числото #{value}.",
          answer: value, topic: "Числа и редици", grade: 1, tier: :intro,
          widget: { "widget" => "number_line",
                    "params" => { "min" => 0, "max" => 10, "step" => 1 },
                    "solution" => { "value" => value, "tolerance" => 0 } }
        )
      end

      (2..19).each do |value|
        out << ProblemGenerators.problem(
          text: "Постави точката върху числото #{value}.",
          answer: value, topic: "Числа и редици", grade: 2, tier: :easy,
          widget: { "widget" => "number_line",
                    "params" => { "min" => 0, "max" => 20, "step" => 1 },
                    "solution" => { "value" => value, "tolerance" => 0 } }
        )
      end

      # Arithmetic answered on the line — links the two representations.
      rng = ProblemGenerators.rng("nl_arith")
      30.times do
        a = rng.rand(1..9)
        b = rng.rand(1..(10 - a))
        out << ProblemGenerators.problem(
          text: "Колко е #{a} + #{b}? Постави точката върху отговора.",
          answer: a + b, topic: "Събиране и изваждане", grade: 1, tier: :easy,
          widget: { "widget" => "number_line",
                    "params" => { "min" => 0, "max" => 10, "step" => 1 },
                    "solution" => { "value" => a + b, "tolerance" => 0 } },
          explanation: "#{a} + #{b} = #{a + b}."
        )
      end

      # Halves and quarters on the line — fractions as positions.
      [ [ 2, 1 ], [ 4, 1 ], [ 4, 3 ], [ 2, 3 ], [ 4, 5 ], [ 4, 7 ] ].each do |denominator, numerator|
        value = numerator.to_f / denominator
        next if value > 5

        out << ProblemGenerators.problem(
          text: "Постави точката върху #{numerator}/#{denominator}.",
          answer: value, topic: "Дроби", grade: 4, tier: :medium,
          widget: { "widget" => "number_line",
                    "params" => { "min" => 0, "max" => 5, "step" => 0.25 },
                    "solution" => { "value" => value, "tolerance" => 0.01 } },
          explanation: "#{numerator}/#{denominator} = #{format('%g', value).tr('.', ',')}."
        )
      end

      # Negative numbers — grade 6.
      (-9..-1).each do |value|
        out << ProblemGenerators.problem(
          text: "Постави точката върху числото #{value}.",
          answer: value, topic: "Числа и редици", grade: 6, tier: :medium,
          widget: { "widget" => "number_line",
                    "params" => { "min" => -10, "max" => 10, "step" => 1 },
                    "solution" => { "value" => value, "tolerance" => 0 } }
        )
      end

      out
    end

    def fraction_bars
      out = []

      (2..10).each do |segments|
        (1...segments).each do |shaded|
          grade = segments <= 4 ? 3 : (segments <= 6 ? 4 : 5)
          tier = shaded == 1 ? :intro : (segments <= 5 ? :easy : :medium)
          out << ProblemGenerators.problem(
            text: "Оцвети #{shaded}/#{segments} от лентата.",
            answer: "#{shaded}/#{segments}", topic: "Дроби", grade: grade, tier: tier,
            widget: { "widget" => "fraction_bars",
                      "params" => { "segments" => segments },
                      "solution" => { "shaded" => shaded } }
          )
        end
      end

      # Equivalent fractions — shade the same amount, different denominator.
      [ [ 4, 2, "1/2" ], [ 6, 3, "1/2" ], [ 8, 4, "1/2" ], [ 10, 5, "1/2" ],
        [ 6, 2, "1/3" ], [ 9, 3, "1/3" ], [ 8, 2, "1/4" ], [ 10, 2, "1/5" ] ].each do |segments, shaded, label|
        out << ProblemGenerators.problem(
          text: "Оцвети #{label} от лентата.",
          answer: "#{shaded}/#{segments}", topic: "Дроби", grade: 5, tier: :hard,
          widget: { "widget" => "fraction_bars",
                    "params" => { "segments" => segments },
                    "solution" => { "shaded" => shaded } },
          explanation: "#{label} от #{segments} части е #{segments} : #{label.split('/').last.to_i} · #{label.split('/').first.to_i} = #{shaded} части."
        )
      end

      out
    end

    def ordering
      out = []
      rng = ProblemGenerators.rng("order_widget")

      # Whole numbers, ascending — grades 1-3 by magnitude.
      [ [ 1, 20, 1 ], [ 2, 100, 2 ], [ 3, 1000, 4 ] ].each do |grade, ceiling, count|
        20.times do
          numbers = (1..ceiling).to_a.sample(4, random: rng).sort
          out << ProblemGenerators.problem(
            text: "Подреди числата от най-малкото към най-голямото.",
            answer: numbers.join(" → "), topic: "Числа и редици", grade: grade, tier: :easy,
            widget: { "widget" => "ordering",
                      "params" => { "items" => numbers.each_with_index.map { |n, i| { "id" => "i#{i + 1}", "label" => n.to_s } } },
                      "solution" => { "order" => numbers.each_index.map { |i| "i#{i + 1}" } } }
          )
        end
      end

      # Fractions, ascending — genuinely hard ordering.
      20.times do
        fractions = [ [ 1, 2 ], [ 1, 3 ], [ 1, 4 ], [ 2, 3 ], [ 3, 4 ], [ 2, 5 ], [ 3, 5 ], [ 4, 5 ], [ 5, 6 ], [ 1, 6 ] ].
          sample(4, random: rng).uniq { |n, d| Rational(n, d) }
        next if fractions.size < 4

        sorted = fractions.sort_by { |n, d| Rational(n, d) }
        out << ProblemGenerators.problem(
          text: "Подреди дробите от най-малката към най-голямата.",
          answer: sorted.map { |n, d| "#{n}/#{d}" }.join(" → "), topic: "Дроби", grade: 6, tier: :hard,
          widget: { "widget" => "ordering",
                    "params" => { "items" => sorted.each_with_index.map { |(n, d), i| { "id" => "i#{i + 1}", "label" => "#{n}/#{d}" } } },
                    "solution" => { "order" => sorted.each_index.map { |i| "i#{i + 1}" } } }
        )
      end

      # Decimals — the "0,9 vs 0,15" trap.
      20.times do
        decimals = (1..99).to_a.sample(4, random: rng).map { |n| (n / 10.0).round(2) }.uniq
        next if decimals.size < 4

        sorted = decimals.sort
        out << ProblemGenerators.problem(
          text: "Подреди числата от най-малкото към най-голямото.",
          answer: sorted.map { |d| format("%g", d) }.join(" → "), topic: "Десетични числа", grade: 5, tier: :medium,
          widget: { "widget" => "ordering",
                    "params" => { "items" => sorted.each_with_index.map { |d, i| { "id" => "i#{i + 1}", "label" => format("%g", d).tr(".", ",") } } },
                    "solution" => { "order" => sorted.each_index.map { |i| "i#{i + 1}" } } }
        )
      end

      # Measurement units — ordering across units, a competition-style trap.
      [ [ [ "1 м", 100 ], [ "50 см", 50 ], [ "2 м", 200 ], [ "80 см", 80 ] ],
        [ [ "1 кг", 1000 ], [ "500 г", 500 ], [ "2 кг", 2000 ], [ "750 г", 750 ] ],
        [ [ "1 час", 60 ], [ "30 мин", 30 ], [ "90 мин", 90 ], [ "2 часа", 120 ] ],
        [ [ "1 л", 1000 ], [ "250 мл", 250 ], [ "500 мл", 500 ], [ "2 л", 2000 ] ] ].each do |items|
        sorted = items.sort_by(&:last)
        out << ProblemGenerators.problem(
          text: "Подреди мерките от най-малката към най-голямата.",
          answer: sorted.map(&:first).join(" → "), topic: "Логически задачи", grade: 4, tier: :hard,
          widget: { "widget" => "ordering",
                    "params" => { "items" => sorted.each_with_index.map { |(label, _), i| { "id" => "i#{i + 1}", "label" => label } } },
                    "solution" => { "order" => sorted.each_index.map { |i| "i#{i + 1}" } } },
          explanation: "Приведени към една мерна единица: #{sorted.map { |label, value| "#{label} = #{value}" }.join(', ')}."
        )
      end

      out
    end
  end
end
