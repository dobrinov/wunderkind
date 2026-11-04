require "rails_helper"

# The competition calendar: public pages that answer „кога е …" and „задачи от
# …", and the student's side of it — saying „ще участвам", seeing it count down
# at home, and preparing for it.
RSpec.describe "Competitions", type: :request do
  let(:logic) { Topic.create!(name: "Логически задачи", parent: Topic.create!(name: "Логика")) }
  let(:kangaroo) do
    competition_event(slug: "test-kenguru", short: "Кенгуру", name: "Тестово кенгуру",
                      rounds: [ { "date" => "2027-03-18" } ])
  end
  let(:olympiad) do
    competition_event(slug: "test-olimpiada", style: "proof", name: "Тестова олимпиада", grades: [ 4, 12 ],
                      rounds: [ { "date" => "2026-12-06", "approximate" => true }, { "date" => "2027-03-20" } ])
  end
  let(:matura) do
    competition_event(slug: "matura", kind: "exam", style: "mixed", name: "Тестова матура", grades: [ 12, 12 ],
                      topics: [ "Производна" ], grade_page: 12, rounds: [ { "date" => "2027-05-21" } ])
  end

  before do
    stub_calendar(kangaroo, olympiad, matura)
    travel_to Time.zone.local(2026, 10, 22, 10)
    5.times { |index| create(:question, elo: 900 + index * 50, explanation: "Обяснение #{index}").topics << logic }
  end

  after { travel_back }

  def json_ld(body)
    body.scan(%r{<script type="application/ld\+json">(.*?)</script>}m).flat_map { |match| Array.wrap(JSON.parse(match.first)) }
  end

  describe "the public calendar" do
    it "lists every round month by month and is open to search" do
      get "/sastezaniya"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("index, follow")
      expect(response.body).to include("Тестово кенгуру", "Тестова олимпиада", "Тестова матура")
      expect(response.body).to include(competition_page_path("test-kenguru"), exam_page_path("matura"))
    end

    it "says „около“ in front of a date nobody has published yet" do
      get "/sastezaniya"

      expect(response.body).to include("event-date is-approximate")
    end
  end

  describe "a competition page" do
    it "leads with the date and carries worked problems from its topics" do
      get "/sastezaniya/test-kenguru"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("<title>Тестово кенгуру 2027")
      expect(response.body).to include(I18n.t("curriculum.answer_label"), "Обяснение 0")
    end

    it "marks up a published date as an Event and leaves a guessed one out" do
      get "/sastezaniya/test-olimpiada"

      events = json_ld(response.body).select { |node| node["@type"] == "Event" }
      expect(events.map { |event| event["startDate"] }).to eq([ "2027-03-20" ])
      expect(events.first).to include("endDate" => "2027-03-20", "image" => a_string_ending_with("/og-card.png"))
      expect(events.first["performer"]).to eq(events.first["organizer"])
    end

    it "carries FAQ markup that matches the answers on the page" do
      get "/sastezaniya/test-olimpiada"

      faq = json_ld(response.body).find { |node| node["@type"] == "FAQPage" }
      faq["mainEntity"].each do |entry|
        expect(response.body).to include(ERB::Util.html_escape(entry["name"]))
      end
    end

    it "is honest that a proof competition is marked on what is written" do
      get "/sastezaniya/test-olimpiada"

      expect(response.body).to include(ERB::Util.html_escape(I18n.t("competitions.faq.prepare.a_proof", name: "Тестова олимпиада")))
    end

    it "lives at one address: an exam under /izpiti, a competition under /sastezaniya" do
      get "/sastezaniya/matura"
      expect(response).to redirect_to(exam_page_path("matura"))
      expect(response).to have_http_status(:moved_permanently)

      get "/izpiti/matura"
      expect(response).to have_http_status(:ok)
    end

    it "is a 404 for a competition that does not exist" do
      get "/sastezaniya/nyama-takova"

      expect(response).to have_http_status(:not_found)
    end

    it "sends a visitor to sign up with the competition riding along" do
      get "/sastezaniya/test-kenguru"

      expect(response.body).to include(sign_up_path(competition: "test-kenguru"))
    end
  end

  it "puts the calendar and every event in the sitemap" do
    Rails.cache.clear
    get "/sitemap.xml"

    expect(response.body).to include("/sastezaniya</loc>", "/sastezaniya/test-kenguru</loc>", "/izpiti/matura</loc>")
  end

  describe "a student" do
    let(:student) { create(:user, elo: 1100, placed_at: Time.current) }

    before { sign_in(student) }

# The public pages close on a button that sends a signed-in visitor home,
# which used to be a 500 for anyone signed in.
it "reads the public calendar and a competition page while signed in" do
  get "/sastezaniya"
  expect(response).to have_http_status(:ok)
  expect(response.body).to include(%(href="#{home_path}"))

  get "/sastezaniya/test-kenguru"
  expect(response).to have_http_status(:ok)
end

it "says „ще участвам“ once per season, and can take it back" do
      2.times { post competition_entry_path("test-kenguru") }

      expect(student.competition_entries.pluck(:competition_slug, :season)).to eq([ [ "test-kenguru", "2026/2027" ] ])

      delete competition_entry_path("test-kenguru")
      expect(student.competition_entries).to be_empty
    end

    it "sees the competition they entered counting down on the home page" do
      post competition_entry_path("test-kenguru")
      get home_path

      expect(response.body).to include(I18n.t("home.competition_countdown", name: "Тестово кенгуру",
                                                                            when: I18n.t("competitions.in_days", count: 147)))
      expect(response.body).to include(competition_practice_path("test-kenguru"))
    end

    it "finds the competitions under „Упражнения“, not on a home page they have not entered any from" do
      get home_path
      expect(response.body).not_to include(I18n.t("home.competitions_sub"))

      get practice_path
      expect(response.body).to include(I18n.t("practice_page.competitions_all"), competitions_path)
    end

    it "prepares for a competition in a session of its own" do
      10.times { |index| create(:question, elo: 1100 + index).topics << logic }

      post competition_practice_path("test-kenguru")

      assignment = student.assignments.last
      expect(assignment).to be_competition
      expect(response).to redirect_to(question_path(assignment.next_assignment_question))
    end

    it "goes back to the round under way instead of starting another" do
      10.times { |index| create(:question, elo: 1100 + index).topics << logic }

      post competition_practice_path("test-kenguru")
      first = student.assignments.last
      post competition_practice_path("test-kenguru")

      expect(student.assignments.competition.count).to eq(1)
      expect(response).to redirect_to(question_path(first.next_assignment_question))
    end

    it "practises as usual, and says why, when the bank holds too few of the event's problems" do
      20.times { |index| create(:question, elo: 1000 + index * 5).topics << logic }
      post competition_practice_path("matura")

      assignment = student.assignments.last
      expect(assignment).to be_daily
      expect(response).to redirect_to(question_path(assignment.next_assignment_question))
      expect(flash[:notice]).to eq(I18n.t("competitions.practising_as_usual", name: "Тестова матура"))
    end

    it "offers ordinary practice instead of „Подготви се“ where the session could not be filled" do
      get competitions_path

      expect(response.body).not_to include(competition_practice_path("matura"))
      expect(response.body).to include(I18n.t("competitions.not_ready", name: "Тестова матура"))
    end

    it "lists what they entered above what they have not" do
      post competition_entry_path("test-olimpiada")
      get competitions_path

      expect(response.body.index("Тестова олимпиада")).to be < response.body.index("Тестово кенгуру")
    end
  end

  it "enters a visitor in the competition they signed up from" do
    post sign_up_path, params: { name: "Ива", email: "iva@example.com", password: "secret123", role: "student",
                                 competition: "test-kenguru" }

    expect(User.find_by(email: "iva@example.com").competition_entries.pluck(:competition_slug)).to eq([ "test-kenguru" ])
  end

  describe "signing up from a competition's page" do
    before { 10.times { |index| create(:question, elo: 1100 + index).topics << logic } }

    it "leads the new student from the placement result straight to preparing for it" do
      post sign_up_path, params: { name: "Ива", email: "iva@example.com", password: "secret123", role: "student",
                                   competition: "test-kenguru" }
      get new_placement_path
      expect(response.body).to include(I18n.t("placement.then_competition", name: "Кенгуру"))

      user = User.find_by(email: "iva@example.com")
      placement = user.assignments.create!(kind: :placement, completed_at: Time.current)
      get placement_path(placement)

      expect(response.body).to include(I18n.t("placement.next_competition", name: "Кенгуру"), competition_practice_path("test-kenguru"))
    end

    it "enters a parent's first child in it and opens the exam's preset for an exam" do
      post sign_up_path, params: { name: "Мила", email: "mila@example.com", password: "secret123", role: "parent",
                                   competition: "matura" }
      post parents_children_path, params: { name: "Ани" }

      child = User.find_by(name: "Ани")
      expect(child.competition_entries.pluck(:competition_slug)).to eq([ "matura" ])
      expect(response).to redirect_to(parents_child_path(child, tab: "practice", welcome: 1, preset: "matura"))

      post parents_children_path, params: { name: "Боби" }
      expect(User.find_by(name: "Боби").competition_entries).to be_empty
    end
  end

  it "keeps a parent out of the student's list" do
    parent = create(:user, role: :parent)
    sign_in(parent)

    get competitions_path

    expect(response).to redirect_to(home_path_for_parent)
  end

  def home_path_for_parent = parents_children_path
end
