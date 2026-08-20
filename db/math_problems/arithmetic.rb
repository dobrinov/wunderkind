def seed_arithmethic_questions
  addition = Topic.find_or_create_by!(name: "Събиране")
  subtraction = Topic.find_or_create_by!(name: "Изваждане")

  1.upto(10) do |x|
    1.upto(10) do |y|
      Question.create!(
        body: RichContent.text_to_doc("#{x} + #{y} = ?"),
        answer_type: :exact_value,
        grading: { "expected" => (x + y).to_s },
        status: :published,
        topics: [ addition ]
      )
    end
  end

  (10..20).each do |x|
    1.upto(10) do |y|
      Question.create!(
        body: RichContent.text_to_doc("#{x} - #{y} = ?"),
        answer_type: :exact_value,
        grading: { "expected" => (x - y).to_s },
        status: :published,
        topics: [ subtraction ]
      )
    end
  end
end

def seed_widget_questions
  fractions = Topic.find_or_create_by!(name: "Дроби")
  numbers = Topic.find_or_create_by!(name: "Числа")

  2.upto(9) do |denominator|
    1.upto(denominator - 1) do |numerator|
      Question.create!(
        body: RichContent.text_to_doc("Оцвети #{numerator}/#{denominator} от лентата"),
        answer_type: :interactive,
        grading: {
          "widget" => "fraction_bars",
          "params" => { "segments" => denominator },
          "solution" => { "shaded" => numerator }
        },
        status: :published,
        topics: [ fractions ]
      )
    end
  end

  1.upto(9) do |value|
    Question.create!(
      body: RichContent.text_to_doc("Постави #{value} върху числовата ос"),
      answer_type: :interactive,
      grading: {
        "widget" => "number_line",
        "params" => { "min" => 0, "max" => 10, "step" => 1 },
        "solution" => { "value" => value, "tolerance" => 0 }
      },
      status: :published,
      topics: [ numbers ]
    )
  end

  5.times do |index|
    numbers_to_sort = Array.new(4) { rand(1..100) }.uniq
    next if numbers_to_sort.size < 4

    sorted = numbers_to_sort.sort
    Question.create!(
      body: RichContent.text_to_doc("Подреди числата от най-малкото към най-голямото"),
      answer_type: :interactive,
      grading: {
        "widget" => "ordering",
        "params" => { "items" => sorted.each_with_index.map { |n, i| { "id" => "i#{i + 1}", "label" => n.to_s } } },
        "solution" => { "order" => sorted.each_index.map { |i| "i#{i + 1}" } }
      },
      status: :published,
      topics: [ numbers ]
    )
  end
end
