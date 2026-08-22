# One keystroke to sign in. Below User::MINIMUM_PASSWORD_LENGTH on purpose, so
# seed saves skip validations — the real form still enforces the minimum.
SEED_PASSWORD = "1"

def create_user(name:, email:, role: :student, verified: false)
  User.find_by(email: email) || begin
    user = User.new_student(
      name: name, email: email, password: SEED_PASSWORD, role:,
      verified_at: verified ? Time.current : nil
    )
    user.save!(validate: false)
    user
  end
end

create_user name: "Деян", email: "admin@example.com", role: :admin, verified: true
create_user name: "Виктор", email: "student@example.com"
create_user name: "Мария", email: "teacher@example.com", role: :teacher, verified: true
parent = create_user name: "Ивана", email: "parent@example.com", role: :parent, verified: true

# A child too young for an email: no login of her own, reached by switching
# profiles inside Ивана's account.
User.create_managed_child!(parent: parent, name: "Ния") if parent.managed_children.none?

# The topic tree is part of the app, and so is the ladder corpus: a fresh
# database should be able to run a practice session, not just show empty
# screens. The other shipped sets are optional extras — the arithmetic fact
# tables (`db/seeds/arithmetic_facts.yml`, 7.6k drills) and the earlier authored
# batches (`db/seeds/authored_problems*.yml`) — imported the same way:
#
#   bin/rails problems:import FILE=db/seeds/arithmetic_facts.yml
Rake::Task["topics:import"].invoke

if Question.none?
  ENV["FILE"] = "db/seeds/ladders"
  Rake::Task["problems:import"].invoke
else
  puts "Question bank already has #{Question.count} questions — skipping the ladder import."
end

# A cast of users with real history — every screen has something to show.
# See the header of db/seeds/development.rb for who exists and why.
load Rails.root.join("db/seeds/development.rb") if Rails.env.development?
