require_relative './math_problems/circle'
require_relative './math_problems/arithmetic'
require_relative './math_problems/uncategorized'

def create_user(name:, email:, admin: false)
  User.new(name: name, email: email, password: '1', admin:).save!(validate: false)
end

create_user name: "Деян", email: "admin@example.com", admin: true
create_user name: "Виктор", email: "student@example.com"

seed_uncategorized_questions
seed_circle_questions
seed_arithmethic_questions
