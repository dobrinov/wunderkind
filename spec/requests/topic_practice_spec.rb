require "rails_helper"

# „Тренирай тема" and „Слаби места": every exam-age child in the family field
# test asked to drill what they were bad at, and the only way was to re-ask
# old mistakes.
describe "Practising one topic", type: :request do
  let(:student) { create(:user, elo: 1200, placed_at: 1.day.ago) }
  let(:fractions) { Topic.create!(name: "Дроби", parent: Topic.create!(name: "Дроби и проценти")) }
  let(:angles) { Topic.create!(name: "Ъгли", parent: Topic.create!(name: "Геометрия")) }

  before do
    [ fractions, angles ].each do |topic|
      (PracticeFocuses::MINIMUM + TopicPractice::QUESTION_COUNT).times { |index| create(:question, elo: 1000 + (index % 12) * 10, text: "#{topic.name} задача #{("а".."я").to_a.sample(6).join}").topics << topic }
    end
    sign_in student
  end

  it "lists the topics with the weakest first, and builds ten from the one picked" do
    student.skills.create!(topic: fractions, rating: 900, games_count: 6)
    student.skills.create!(topic: angles, rating: 1300, games_count: 6)

    get topic_practices_path
    body = Nokogiri::HTML(response.body)
    body.at_css("section[aria-labelledby=weak-spots]").text.should include("Дроби")
    body.at_css("section[aria-labelledby=weak-spots]").text.should_not include("Ъгли")

    post topic_practice_path(fractions)
    session = student.assignments.order(:id).last
    response.should redirect_to(question_path(session.next_assignment_question))
    session.questions.size.should eq(TopicPractice::QUESTION_COUNT)
    session.questions.flat_map(&:topics).uniq.should eq([ fractions ])
    session.should be_measured
  end

  it "shows „Слаби места“ on „Аз“ only once a topic is really behind" do
    get profile_path
    response.body.should_not include(I18n.t("topic_practice.weak_title"))

    student.skills.create!(topic: fractions, rating: 900, games_count: 6)
    get profile_path
    response.body.should include(I18n.t("topic_practice.weak_title"), "Дроби")
  end

  it "is offered on „Упражнения“" do
    get practice_path
    response.body.should include(topic_practices_path)
  end
end
