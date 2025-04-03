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
