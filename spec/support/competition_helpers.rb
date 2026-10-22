# Builds a calendar event the way config/competitions.yml would, so a spec can
# put its own competitions on the calendar instead of depending on whatever
# dates the real file holds on the day the suite runs.
module CompetitionHelpers
  def competition_event(slug: "test-kenguru", kind: "competition", style: "choice", grades: [ 1, 4 ],
                        topics: [ "Логически задачи" ], rounds: [ { "date" => "2027-03-18" } ], **extra)
    Competitions.build({
      "slug" => slug, "kind" => kind, "short" => extra[:short], "style" => style, "grades" => grades,
      "organizer" => "Тестов организатор", "url" => "https://example.org", "topics" => topics,
      "grade_page" => extra[:grade_page],
      "name" => { "bg" => extra.fetch(:name, "Тестово кенгуру"), "en" => "Test Kangaroo" },
      "description" => { "bg" => "Състезание с избор на отговор.", "en" => "A multiple-choice contest." },
      "format" => { "bg" => "24 задачи за 75 минути.", "en" => "24 problems in 75 minutes." },
      "rounds" => rounds.map { |round| { "name" => { "bg" => "Кръг", "en" => "Round" } }.merge(round) }
    })
  end

  def stub_calendar(*events)
    allow(Competitions).to receive(:all).and_return(events)
  end
end

RSpec.configure do |config|
  config.include CompetitionHelpers
end
