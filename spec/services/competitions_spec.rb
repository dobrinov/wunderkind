require "rails_helper"

# The calendar is a file a person edits, so most of what can go wrong with it
# is a typo: a topic the bank does not have (and a preparation session that
# silently draws from nothing), a missing translation, a date in the wrong
# school year. Those are caught here, against the real file.
RSpec.describe Competitions do
  describe "config/competitions.yml" do
    let(:events) { Competitions.load }
    let(:leaf_topics) { YAML.load_file(Rails.root.join("db/seeds/topics.yml")).fetch("topics").values.flatten }

    it "names every event once, with a latin slug" do
      slugs = events.map(&:slug)

      expect(slugs).to eq(slugs.uniq)
      expect(slugs).to all(match(/\A[a-z0-9]+(-[a-z0-9]+)*\z/))
    end

    it "uses only the known kinds and marking styles" do
      expect(events.map(&:kind)).to all(be_in(Competitions::KINDS))
      expect(events.map(&:style)).to all(be_in(Competitions::STYLES))
    end

    it "writes every name, description and format in both languages" do
      events.each do |event|
        [ event.name, event.description, event.format, *event.rounds.map(&:name) ].each do |text|
          expect(text.by_locale.values_at("bg", "en")).to all(be_present), "#{event.slug} is missing a translation"
        end
      end
    end

    it "is for school grades, lowest first" do
      events.each do |event|
        expect(event.grade_min).to be_between(1, 12)
        expect(event.grade_max).to be_between(event.grade_min, 12)
      end
    end

    it "draws preparation only from topics the bank has" do
      events.each do |event|
        expect(event.topic_names).to be_present, "#{event.slug} has no topics to practise"
        expect(event.topic_names - leaf_topics).to be_empty, "#{event.slug} names topics the bank does not have"
      end
    end

    it "keeps each event's rounds inside one school year" do
      events.each do |event|
        expect(event.rounds).to be_present
        expect(event.rounds.map { |round| Competitions.season_for(round.date) }.uniq.size).to eq(1), event.slug
      end
    end

    it "has the exam pages the public layout links to" do
      expect(Competitions.find("matura")).to be_exam
      expect(events.select(&:exam?).filter_map(&:grade_page)).to all(satisfy { |grade| Curriculum.grade("#{grade}-klas") })
    end
  end

  describe ".season_for" do
    it "turns over on the first of September" do
      expect(Competitions.season_for(Date.new(2026, 8, 31))).to eq("2025/2026")
      expect(Competitions.season_for(Date.new(2026, 9, 1))).to eq("2026/2027")
      expect(Competitions.season_for(Date.new(2027, 3, 18))).to eq("2026/2027")
    end
  end

  describe "the calendar" do
    let(:early) { competition_event(slug: "early", rounds: [ { "date" => "2026-11-10" }, { "date" => "2027-02-01" } ]) }
    let(:late) { competition_event(slug: "late", rounds: [ { "date" => "2026-12-05" } ]) }
    let(:over) { competition_event(slug: "over", rounds: [ { "date" => "2026-10-01" } ]) }

    before { stub_calendar(late, over, early) }

    it "lists what is still to come soonest first, and a finished event after it" do
      travel_to Date.new(2026, 10, 22) do
        expect(Competitions.upcoming.map(&:slug)).to eq(%w[early late])
        expect(Competitions.calendar.map(&:slug)).to eq(%w[early late over])
      end
    end

    it "puts every round on the schedule as its own date" do
      travel_to Date.new(2026, 10, 22) do
        expect(Competitions.schedule.map { |event, round| [ event.slug, round.date.iso8601 ] }).to eq(
          [ %w[early 2026-11-10], %w[late 2026-12-05], %w[early 2027-02-01] ]
        )
      end
    end

    it "moves on to the next round once one has passed" do
      travel_to Date.new(2026, 11, 11) do
        expect(early.next_round.date).to eq(Date.new(2027, 2, 1))
      end
    end
  end
end
