def create_user(name:, email:, role: :student, verified: false)
  user = User.new_student(
    name: name, email: email, password: 'password', role:,
    verified_at: verified ? Time.current : nil
  )
  user.save!
  user
end

create_user name: "Деян", email: "admin@example.com", role: :admin, verified: true
create_user name: "Виктор", email: "student@example.com"
create_user name: "Мария", email: "teacher@example.com", role: :teacher, verified: true
parent = create_user name: "Ивана", email: "parent@example.com", role: :parent, verified: true

# A child too young for an email: no login of her own, reached by switching
# profiles inside Ивана's account.
User.create_managed_child!(parent: parent, name: "Ния")

# The topic tree is part of the app; the question bank is not. Questions are
# authored in the admin UI (or imported with `rake problems:import FILE=...`)
# and can be written back out with `rake problems:export`.
Rake::Task["topics:import"].invoke
