# The database and fixture the Playwright suite runs against.
#
# Its own database, never the development one: the suite answers questions,
# starts duels and sets goals, and a browser test that quietly rearranges the
# demo cast is a browser test nobody will run twice. `DATABASE_URL` is what
# points Rails at it — see e2e/playwright.config.js, which sets the same value
# for the server it boots.
#
# The fixture is deliberately small and flat: a handful of named accounts, one
# topic, and enough published problems to fill a session and a duel. Everything
# a spec needs is created here rather than by the spec, so a spec reads as a
# user journey and not as setup.
namespace :e2e do
  PASSWORD = "e2epassword".freeze
  QUESTION_COUNT = 60

  desc "Create and seed the e2e database"
  task prepare: :environment do
    raise "refusing to seed anything but the e2e database (got #{current_database})" unless current_database.include?("e2e")

    # Create and load the schema, never db:prepare: that runs db/seeds.rb,
    # which imports the whole 23k-problem ladder corpus and then simulates ten
    # weeks of a demo cast. The suite wants sixty questions and eight accounts.
    Rake::Task["db:create"].invoke
    Rake::Task["db:schema:load"].invoke
    Rake::Task["e2e:seed"].invoke
  end

  desc "Reset the e2e fixture, bringing the schema up to date first"
  task seed: :environment do
    raise "refusing to seed anything but the e2e database (got #{current_database})" unless current_database.include?("e2e")

    # Migrate before seeding. The suite runs this on every start, and nothing
    # else ever touches this database — so without it the first schema change
    # after `e2e:prepare` leaves every spec failing on a 500 from
    # PendingMigrationError, which looks like a broken feature and is not one.
    Rake::Task["db:migrate"].invoke

    ActiveRecord::Base.transaction do
      [ GoalAward, Goal, ChallengeAnswer, ChallengeQuestion, ChallengeParticipant, Challenge,
        UserAnswer, AssignmentQuestion, Assignment, XpEvent, BadgeAward, Skill, ParentLink,
        PossibleAnswer, Question, Topic, User ].each(&:delete_all)
    end

    # Multiple choice, every one of them, and that is a decision rather than
    # laziness: an exact-value answer is typed into MathLive, which is a custom
    # element with its own keyboard handling and by some distance the flakiest
    # thing on the page to drive. A smoke suite meant to run after every change
    # has to be boring. The helper in support/helpers.js still answers all
    # three input types, so a fixture that grows an exact-value question later
    # will not break the specs — see the note in e2e/README.md about what this
    # deliberately does not cover.
    topic = Topic.create!(name: "E2E")
    QUESTION_COUNT.times do |index|
      # Built, not created-then-filled: a multiple-choice question validates
      # that it has a correct option, so the options have to be there before
      # the first save.
      question = Question.new(
        body: RichContent.text_to_doc("Колко е 40 + 2? (#{index + 1})"),
        answer: "42", answer_type: :multiple_choice, grading: {},
        explanation: "40 + 2 = 42.", status: :published, elo: 900 + (index % 20) * 10
      )
      question.possible_answers.build(value: "42", correct: true, position: 1)
      question.possible_answers.build(value: "41", correct: false, position: 2)
      question.save!
      question.topics << topic
    end

    student = make(:student, "student@e2e.test", "Стефан")
    # users.feedback_after_answer defaults to false — an answer goes straight
    # on to the next problem. One account turns it on so the feedback card is
    # covered too, rather than the suite asserting a screen most students
    # never see.
    make(:student, "feedback@e2e.test", "Фильо").update!(feedback_after_answer: true)
    # One account per journey. Two specs sharing a student is how the second
    # one starts finding a calendar the first one has already changed.
    make(:student, "skip@e2e.test", "Скоби")
    make(:student, "behind@e2e.test", "Боби").update!(last_changelog_version: nil)
    # Its own account, because placement is the one journey that can only be
    # taken once: a spec sharing a student with another would find it already
    # placed the second time the suite ran.
    make(:student, "placement@e2e.test", "Пенчо")
    make(:student, "duel-a@e2e.test", "Ана")
    make(:student, "duel-b@e2e.test", "Боян")
    make(:admin, "admin@e2e.test", "Админ")

    # One wrong answer, through the real submission path, so /review has
    # something to list and something to build a session from.
    wrong = make(:student, "wrong@e2e.test", "Мими")
    assignment = Assignment.create!(user: wrong)
    aq = assignment.assignment_questions.create!(question: Question.first, position: 1)
    wrong_option = Question.first.possible_answers.find_by(correct: false)
    AnswerSubmission.call(assignment_question: aq, user: wrong, raw: { selected_ids: [ wrong_option.id.to_s ] })

    parent = make(:parent, "parent@e2e.test", "Ивана")
    parent.update!(verified_at: Time.current)
    child = User.create_managed_child!(parent: parent, name: "Ния")
    Goal.create!(parent: parent, child: child, metric: :minutes, mode: :daily, period: :week,
                 threshold: 10, target: 3, starts_on: Time.zone.today, reward: "Сладолед в събота")

    puts "e2e fixture: #{User.count} users, #{Question.published.count} published questions, " \
         "student=#{student.email} password=#{PASSWORD}"
  end

  def make(role, email, name)
    User.new_student(name: name, email: email, password: PASSWORD, role: role).tap(&:save!)
  end

  def current_database
    ActiveRecord::Base.connection_db_config.database.to_s
  end
end
