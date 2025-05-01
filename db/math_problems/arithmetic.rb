def seed_arithmethic_questions
  10.times do |x|
    10.times do |y|
      Question.create! text: "#{x} + #{y} = ?", answer: x + y
    end
  end

  (10..20).each do |x|
    10.times do |y|
      Question.create! text: "#{x} - #{y} = ?", answer: x - y
    end
  end
end
