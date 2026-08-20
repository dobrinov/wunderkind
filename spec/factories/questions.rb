FactoryBot.define do
  factory :question do
    transient do
      text { Faker::Lorem.sentence }
    end

    body { RichContent.text_to_doc(text) }
    answer { "42" }
    answer_type { :exact_value }
    grading { { "expected" => answer } }
    status { :published }
    elo { Faker::Number.between(from: 100, to: 3000) }

    trait :multiple_choice do
      answer_type { :multiple_choice }
      grading { {} }

      after(:build) do |question|
        question.possible_answers.build(value: question.answer, correct: true, position: 1)
        question.possible_answers.build(value: "wrong", correct: false, position: 2)
      end
    end

    trait :interactive do
      answer_type { :interactive }
      grading do
        {
          "widget" => "number_line",
          "params" => { "min" => 0, "max" => 10, "step" => 1 },
          "solution" => { "value" => 7, "tolerance" => 0 }
        }
      end
    end
  end
end
