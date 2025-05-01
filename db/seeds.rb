require_relative './math_problems/circle'
require_relative './math_problems/arithmetic'
require_relative './math_problems/uncategorized'

user = User.new(name: "Виктор Добринов", email: "victor@example.com", password: "1")
user.save!(validate: false)

seed_uncategorized_questions
seed_circle_questions
# seed_arithmethic_questions
