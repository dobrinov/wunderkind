require "rails_helper"

RSpec.describe MockExam do
  let(:topic) { Topic.create!(name: "Логически задачи", parent: Topic.create!(name: "Логика")) }
  let(:exam) { competition_event(slug: "nvo-7", kind: "exam", grades: [ 7, 7 ], topics: [ topic.name ]) }

  # Another event's paper problems carry broad topics and an Elo inside the
  # exam's window; a 3rd-grade СМТ problem on an НВО 7 mock tells a
  # thirteen-year-old the app is for small children.
  it "never puts another event's papers on the paper" do
    middle = exam.elo_range.begin + 100
    ours = Array.new(6) { |index| create(:question, elo: middle + index, text: "Задача #{("a".."f").to_a[index] * 6}").tap { |question| question.topics << topic } }
    Array.new(6) do |index|
      create(:question, elo: middle + index, text: "Турнир #{("g".."l").to_a[index] * 6}",
                        source: { "kind" => "modelled", "competition" => "sofiyski-matematicheski-turnir", "grade" => 3 })
        .tap { |question| question.topics << topic }
    end

    MockExam.pick(exam, 6).should match_array(ours)
  end
end
