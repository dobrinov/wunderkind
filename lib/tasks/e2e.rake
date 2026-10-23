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
      # Order matters: anything with a foreign key to a table comes before it.
      [ GoalAward, Goal, Friendship, ChallengeAnswer, ChallengeQuestion, ChallengeTopic, ChallengeParticipant, Challenge,
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
    # Two categories with leaves under them, because the duel browser filters
    # by category and a flat single topic cannot show that working.
    topic = Topic.create!(name: "E2E")
    geometry = Topic.create!(name: "Геометрия")
    geometry_leaf = Topic.create!(name: "Ъгли", parent: geometry)
    fractions = Topic.create!(name: "Дроби")

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
      # Every question is in the flat topic the practice specs use, and also in
      # one of the two categories the duel browser offers.
      question.topics << topic
      question.topics << (index.even? ? geometry_leaf : fractions)
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
    # Its own pair, so the browser spec is not racing the ready-room spec for
    # the same two accounts' lobbies. Nicknames, because the lobby browser
    # shows a waiting player by nickname and falls back to „Противник" — which
    # is right for a stranger with no nickname and useless to assert on.
    make(:student, "lobby-a@e2e.test", "Лора").update!(nickname: "lora")
    make(:student, "lobby-b@e2e.test", "Любо").update!(nickname: "lyubo")

    # A pair who are already friends, so the invite journey does not have to
    # swap codes before it can start, and one of them is freshly here so the
    # presence dot has something true to say.
    friend_a = make(:student, "friend-a@e2e.test", "Фани")
    friend_b = make(:student, "friend-b@e2e.test", "Филип")
    friend_a.update!(nickname: "fani", friend_code: "FANI01")
    friend_b.update!(nickname: "filip", friend_code: "FILIP1", last_seen_at: Time.current)
    Friendship.create!(requester: friend_a, addressee: friend_b, status: :accepted, accepted_at: Time.current)
    # And one who has to be added by code, which is the only way in.
    make(:student, "friend-c@e2e.test", "Фиро").update!(nickname: "firo", friend_code: "FIRO01")
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

    seed_widgets

    puts "e2e fixture: #{User.count} users, #{Question.published.count} published questions, " \
         "student=#{student.email} password=#{PASSWORD}"
  end

  # One problem per "showing the working" widget, in the shape
  # tools/authoring/lib/widget_kit.rb writes them, each taken from
  # db/seeds/ladders/interactive_working.yml — the harder variant where there
  # is one (a subtraction that borrows, a 9 × 9 board, 15° steps with two
  # angles, a line in halves), since that is where a widget breaks.
  WIDGET_PROBLEMS = {
    "column_arithmetic" => [ "Извади в колонка: 144 − 105.", 880,
      { "params" => { "operands" => %w[144 105], "op" => "−" }, "solution" => { "result" => "39" } } ],
    "balance_scale" => [ "Реши с везната: 3x + 4 = x + 16.", 1100,
      { "params" => { "left" => { "x" => 3, "units" => 4 }, "right" => { "x" => 1, "units" => 16 } },
        "solution" => { "x" => 6, "steps" => [ { "op" => "x", "k" => 1 }, { "op" => "units", "k" => 4 }, { "op" => "divide", "k" => 2 } ] } } ],
    "geoboard" => [ "На дъска от 9 × 9 точки начертай правоъгълник с лице 2 и обиколка 6.", 950,
      { "params" => { "size" => 9 },
        "solution" => { "shape" => "rectangle", "points" => [ [ 0, 0 ], [ 2, 0 ], [ 2, 1 ], [ 0, 1 ] ], "area" => 2, "perimeter" => 6 } } ],
    "unit_circle" => [ "Отбележи всички ъгли α, за които 0° ≤ α < 360° и cos α = √2/2.", 2060,
      { "params" => { "step" => 15, "count" => 2, "values" => false }, "solution" => { "angles" => [ 45, 315 ] } } ],
    "find_mistake" => [ "Ани пресметна 2/11 + 9/11 и сбърка на един ред. На кой ред е грешката?", 1100,
      { "params" => { "lines" => [ "2/11 + 9/11", "= (2 + 9)/(11 + 11)", "= 1/2" ] }, "solution" => { "line" => 1 } } ],
    "number_hops" => [ "Пресметни със скокове по числовата ос: 18 − 6.", 650,
      { "params" => { "start" => 18, "change" => -6, "hops" => [ 1, 2, 5, 10 ] }, "solution" => { "value" => "12", "hops" => [ -5, -1 ] } } ],
    "inequality_line" => [ "Покажи на числовата ос решенията на 2x + 1 < 12. Делението на оста е през 0,5.", 1650,
      { "params" => { "min" => 2.5, "max" => 8.5, "step" => 0.5 }, "solution" => { "edge" => 5.5, "closed" => false, "direction" => "left" } } ]
  }.freeze

  # Students per widget — one answers it right, one wrong — each holding a
  # session that opens on it, reached the way a child resumes a session:
  # /assignments → „Продължи". Feedback is on, because the feedback card is
  # what the specs read the verdict and the „Верен отговор" chip off.
  #
  # The questions are *not* published, deliberately. A published question is
  # in Dispatcher.practice_pool, so the practice and duel specs could be dealt
  # one, and the placement spec — which answers „42" to everything and gallops
  # up to the pool's ceiling — certainly would be: these sit above the sixty
  # multiple-choice problems. Nothing on the way from an assignment to a
  # graded answer reads the status, so the widgets are exercised exactly as in
  # a published session.
  def seed_widgets
    topic = Topic.create!(name: "Виджети")
    filler = Question.published.first

    WIDGET_PROBLEMS.each do |key, (text, elo, widget)|
      question = Question.create!(
        body: RichContent.text_to_doc(text), answer_type: :interactive,
        grading: { "widget" => key }.merge(widget), explanation: "Обяснение за #{key}.",
        status: :private_library, elo: elo
      )
      question.topics << topic

      # And a third for the phone-width checks, which only tap and never
      # submit, but still should not share a session with a spec that does.
      [ "", "-wrong", "-phone" ].each do |suffix|
        student = make(:student, "widget-#{key}#{suffix}@e2e.test", "Виджет")
        student.update!(feedback_after_answer: true)
        session = Assignment.create!(user: student)
        session.assignment_questions.create!(question: question, position: 1)
        # A second problem after it, because the feedback card is only shown
        # in place when there is a next one: the last answer of a session
        # goes straight to its summary.
        session.assignment_questions.create!(question: filler, position: 2)
      end
    end
  end

  def make(role, email, name)
    User.new_student(name: name, email: email, password: PASSWORD, role: role).tap(&:save!)
  end

  def current_database
    ActiveRecord::Base.connection_db_config.database.to_s
  end
end
