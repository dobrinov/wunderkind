require_relative './math_problems/arithmetic'
require_relative './math_problems/uncategorized'

def create_user(name:, email:, role: :student)
  User.create!(name: name, email: email, password: 'password', role:)
end

create_user name: "Деян", email: "admin@example.com", role: :admin
create_user name: "Виктор", email: "student@example.com"

seed_arithmethic_questions
seed_widget_questions
seed_uncategorized_questions
