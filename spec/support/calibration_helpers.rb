module CalibrationHelpers
  # Gives a student enough answer history that Dispatcher trusts their rating
  # and stops running its calibration ladder. The questions are drafts so they
  # stay out of the practice pool the spec under test is building from.
  def calibrated!(user)
    assignment = Assignment.create!(user:)

    Dispatcher::CALIBRATION_ANSWERS.times do |index|
      question = FactoryBot.create(:question, status: :draft, elo: user.elo)
      assignment.assignment_questions.create!(question:, position: index + 1).
        create_user_answer!(user:, value: "42", correct: true, response: { "value" => "42" })
    end

    user
  end
end

RSpec.configure do |config|
  config.include CalibrationHelpers
end
