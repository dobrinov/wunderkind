FactoryBot.define do
  factory :question do
    text { Faker::Lorem.sentence }
    answer { Faker::Lorem.sentence }
    elo { Faker::Number.between(from: 100, to: 3000) }
  end
end
