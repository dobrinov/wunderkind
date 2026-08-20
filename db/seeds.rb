require_relative './math_problems/arithmetic'
require_relative './math_problems/uncategorized'

def create_user(name:, email:, role: :student, verified: false)
  User.create!(name: name, email: email, password: 'password', role:, verified_at: verified ? Time.current : nil)
end

create_user name: "Деян", email: "admin@example.com", role: :admin, verified: true
create_user name: "Виктор", email: "student@example.com"
create_user name: "Мария", email: "teacher@example.com", role: :teacher, verified: true
create_user name: "Ивана", email: "parent@example.com", role: :parent, verified: true

seed_arithmethic_questions
seed_widget_questions
seed_uncategorized_questions
