def create_user(name:, email:, role: :student, grade: nil, verified: false)
  User.create!(
    name: name, email: email, password: 'password', role:, grade:,
    verified_at: verified ? Time.current : nil
  )
end

create_user name: "Деян", email: "admin@example.com", role: :admin, verified: true
create_user name: "Виктор", email: "student@example.com", grade: 4
create_user name: "Мария", email: "teacher@example.com", role: :teacher, verified: true
create_user name: "Ивана", email: "parent@example.com", role: :parent, verified: true

# The question bank is generated: original problems with calibrated Elo, a
# topic tree, and curriculum prerequisites. See db/problem_generators/.
Rake::Task["problems:generate"].invoke
