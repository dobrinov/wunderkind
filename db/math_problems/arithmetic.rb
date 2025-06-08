def seed_arithmethic_questions
  1.upto(10) do |x|
    1.upto(10) do |y|
      Question.create! text: "#{x} + #{y} = ?", answer: x + y
    end
  end

  (10..20).each do |x|
    1.upto(10) do |y|
      Question.create! text: "#{x} - #{y} = ?", answer: x - y
    end
  end
end
