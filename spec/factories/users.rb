FactoryBot.define do
  factory :user do
    name { Faker::Name.name }
    email { Faker::Internet.email }
    password { "secret123" }
    # Every page that shows a student to other children asks for one first
    # (NicknamesController); a spec about a student without one says so.
    nickname { Faker::Internet.unique.username(specifier: 5..12) if role.to_s.in?([ "", "student" ]) }
  end
end
