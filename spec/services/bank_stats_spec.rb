require "rails_helper"

RSpec.describe BankStats do
  before { stub_const("BankStats::MINIMUM", 3) }

  # The test environment runs a null store; these examples are about what the
  # cache does, so they get a real one.
  around do |example|
    original = Rails.cache
    Rails.cache = ActiveSupport::Cache::MemoryStore.new
    example.run
  ensure
    Rails.cache = original
  end

  it "says nothing while the bank is too small to quote" do
    create_list(:question, 2)

    expect(described_class.current).to be_nil
  end

  it "counts the published bank by answer kind, grade, paper and figure" do
    create_list(:question, 2, taught_from_grade: 3, explanation: "Защото.")
    create(:question, :interactive, taught_from_grade: 5)
    create(:question, :multiple_choice, source: { "kind" => "original", "year" => 2019 })
    create(:question, source: { "kind" => "original", "year" => 2025 })
    create(:question, source: { "kind" => "modelled", "year" => 2010 })
    create(:question, status: :retired, taught_from_grade: 3)

    stats = described_class.current

    expect(stats.total).to eq(6)
    expect(stats.explained_percent).to eq(33)
    expect(stats.answer_types).to eq(exact_value: 67, interactive: 17, multiple_choice: 17)
    expect(stats.widget_kinds).to eq(1)
    expect(stats.past_papers).to eq(2)
    expect(stats.past_paper_years).to eq(2019..2025)
    expect(stats.by_grade.values_at(3, 5, 12)).to eq([ 2, 1, 0 ])
  end

  it "follows the bank as soon as a question is added, retired or deleted" do
    questions = create_list(:question, 4)
    expect(described_class.current.total).to eq(4)

    create(:question)
    expect(described_class.current.total).to eq(5)

    questions.first.retire!
    expect(described_class.current.total).to eq(4)

    questions.last.destroy!
    expect(described_class.current.total).to eq(3)
  end

  it "floors to hundreds in the thousands and to tens below" do
    expect(described_class.floor(29_863)).to eq(29_800)
    expect(described_class.floor(360)).to eq(360)
    expect(described_class.floor(367)).to eq(360)
  end
end
