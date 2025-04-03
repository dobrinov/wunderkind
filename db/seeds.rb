# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

# Clear existing data
puts "Clearing existing data..."
Question.destroy_all
KenguruAnswer.destroy_all
KenguruQuestion.destroy_all

# First Grade Math Questions (2024)
first_grade_questions = [
  {
    text: "В градината на баба Ани цъфнали 18 рози, от които 5 жълти, а останалите червени. Колко червени рози е откъснала малката Ани, ако след това в градината останали 8 червени рози?",
    answers: ["10", "8", "5", "4", "3"],
    correct_answer: "5"
  },
  {
    text: "В класа на Петър има 25 ученика. 12 от тях са момчета, а останалите са момичета. Колко момичета има в класа?",
    answers: ["13", "12", "14", "11", "15"],
    correct_answer: "13"
  },
  {
    text: "В магазин имаше 30 ябълки. Продадени са 8 ябълки, а 5 са изгнили. Колко ябълки останаха в магазина?",
    answers: ["17", "18", "16", "15", "19"],
    correct_answer: "17"
  },
  {
    text: "Мария има 24 цветя в градината си. 9 от тях са рози, а останалите са лалета. Колко лалета има в градината?",
    answers: ["15", "14", "16", "13", "17"],
    correct_answer: "15"
  },
  {
    text: "В парка имаше 20 птички. 7 отлетяха, а 3 се прибраха. Колко птички останаха в парка?",
    answers: ["16", "15", "17", "14", "18"],
    correct_answer: "16"
  },
  {
    text: "В кутия имаше 16 бонбона. 6 са изядени, а 4 са дадени на приятели. Колко бонбона останаха в кутията?",
    answers: ["6", "5", "7", "4", "8"],
    correct_answer: "6"
  },
  {
    text: "В библиотеката имаше 35 книги. 12 са заети, а 8 са изгубени. Колко книги останаха в библиотеката?",
    answers: ["15", "14", "16", "13", "17"],
    correct_answer: "15"
  },
  {
    text: "В градината имаше 28 цветя. 10 са увяхнали, а 6 са откъснати. Колко цветя останаха в градината?",
    answers: ["12", "11", "13", "10", "14"],
    correct_answer: "12"
  },
  {
    text: "В класа имаше 30 ученика. 8 са отсъстващи, а 5 са излезли за почивка. Колко ученика останаха в класа?",
    answers: ["17", "16", "18", "15", "19"],
    correct_answer: "17"
  },
  {
    text: "В магазин имаше 40 играчки. 15 са продадени, а 8 са повредени. Колко играчки останаха в магазина?",
    answers: ["17", "16", "18", "15", "19"],
    correct_answer: "17"
  },
  {
    text: "Асен, Боби, Вили и Гошо живеят в един вход. Асен живее на петия етаж. Боби живее 3 етажа над Асен. Вили живее 2 етажа под Боби. Гошо живее 4 етажа над Вили. На кой етаж живее Гошо?",
    answers: ["на петия", "на седмия", "на деветия", "на десетия", "на четиринадесетия"],
    correct_answer: "на десетия"
  },
  {
    text: "Петър, Иван, Мария и Стефан живеят в един вход. Петър живее на третия етаж. Иван живее 2 етажа над Петър. Мария живее 1 етаж под Иван. Стефан живее 3 етажа над Мария. На кой етаж живее Стефан?",
    answers: ["на петия", "на шестия", "на седмия", "на осмия", "на деветия"],
    correct_answer: "на седмия"
  },
  {
    text: "Георги, Димитър, Елена и Николай живеят в един вход. Георги живее на четвъртия етаж. Димитър живее 4 етажа над Георги. Елена живее 2 етажа под Димитър. Николай живее 1 етаж над Елена. На кой етаж живее Николай?",
    answers: ["на петия", "на шестия", "на седмия", "на осмия", "на деветия"],
    correct_answer: "на шестия"
  },
  {
    text: "Кристина, Лили, Мартин и Павел живеят в един вход. Кристина живее на втория етаж. Лили живее 3 етажа над Кристина. Мартин живее 1 етаж под Лили. Павел живее 2 етажа над Мартин. На кой етаж живее Павел?",
    answers: ["на третия", "на четвъртия", "на петия", "на шестия", "на седмия"],
    correct_answer: "на шестия"
  },
  {
    text: "Ралица, Стефан, Тодор и Уляна живеят в един вход. Ралица живее на първия етаж. Стефан живее 5 етажа над Ралица. Тодор живее 2 етажа под Стефан. Уляна живее 3 етажа над Тодор. На кой етаж живее Уляна?",
    answers: ["на четвъртия", "на петия", "на шестия", "на седмия", "на осмия"],
    correct_answer: "на седмия"
  },
  {
    text: "Христо, Яна, Златина и Борис живеят в един вход. Христо живее на шестия етаж. Яна живее 2 етажа под Христо. Златина живее 3 етажа над Яна. Борис живее 1 етаж под Златина. На кой етаж живее Борис?",
    answers: ["на четвъртия", "на петия", "на шестия", "на седмия", "на осмия"],
    correct_answer: "на четвъртия"
  },
  {
    text: "Даниел, Емилия, Филип и Габриела живеят в един вход. Даниел живее на третия етаж. Емилия живее 4 етажа над Даниел. Филип живее 2 етажа под Емилия. Габриела живее 1 етаж над Филип. На кой етаж живее Габриела?",
    answers: ["на четвъртия", "на петия", "на шестия", "на седмия", "на осмия"],
    correct_answer: "на шестия"
  },
  {
    text: "Ивайло, Катя, Любомир и Милена живеят в един вход. Ивайло живее на петия етаж. Катя живее 3 етажа под Ивайло. Любомир живее 2 етажа над Катя. Милена живее 4 етажа над Любомир. На кой етаж живее Милена?",
    answers: ["на четвъртия", "на петия", "на шестия", "на седмия", "на осмия"],
    correct_answer: "на осмия"
  },
  {
    text: "Никола, Оля, Петър и Рая живеят в един вход. Никола живее на четвъртия етаж. Оля живее 2 етажа над Никола. Петър живее 3 етажа под Оля. Рая живее 1 етаж над Петър. На кой етаж живее Рая?",
    answers: ["на третия", "на четвъртия", "на петия", "на шестия", "на седмия"],
    correct_answer: "на третия"
  },
  {
    text: "Светлана, Тома, Уляна и Васил живеят в един вход. Светлана живее на първия етаж. Тома живее 4 етажа над Светлана. Уляна живее 2 етажа под Тома. Васил живее 3 етажа над Уляна. На кой етаж живее Васил?",
    answers: ["на третия", "на четвъртия", "на петия", "на шестия", "на седмия"],
    correct_answer: "на шестия"
  }
]

# Create questions for 2024
first_grade_questions.each_with_index do |question_data, index|
  kenguru_question = KenguruQuestion.create!(
    text: question_data[:text],
    year: 2024,
    grade: 1,
    index: index + 1
  )

  # Create answers for the question
  question_data[:answers].each do |answer_text|
    KenguruAnswer.create!(
      kenguru_question: kenguru_question,
      text: answer_text,
      correct: answer_text == question_data[:correct_answer]
    )
  end

  # Create the polymorphic question entry
  Question.create!(
    questionable: kenguru_question,
    minimum_age: 6  # First grade students are typically 6-7 years old
  )
end
