require "rails_helper"

# config/formulas.yml is written by hand, so the rules in its header are
# checked here: a formula filed under a topic that does not exist, or marked as
# taught in a grade that does not teach its topic, would quietly vanish from
# every page but the hub.
RSpec.describe Formulas do
  let(:leaves) do
    YAML.safe_load_file(Rails.root.join("db/seeds/topics.yml")).fetch("topics").values.flatten
  end

  it "files every formula under a leaf of the topic tree" do
    unknown = described_class.all.map(&:topic_name).uniq - leaves
    expect(unknown).to be_empty, "not in db/seeds/topics.yml: #{unknown.join(", ")}"
  end

  it "dates every formula inside the grades that teach its topic" do
    described_class.all.each do |formula|
      next if described_class::BEYOND.include?(formula.topic_name)

      grades = described_class.grades_for(formula.topic_name)
      expect(grades).not_to be_empty, "#{formula.topic_name} is taught in no grade of Curriculum::PROGRAMME"
      expect(formula.from).to be_between(grades.min, grades.max),
        "#{formula.topic_name} / #{formula.name}: from #{formula.from}, but the topic is taught in #{grades.join(", ")}"
    end
  end

  it "writes every formula in both languages" do
    described_class.all.each do |formula|
      described_class::LOCALES.each do |locale|
        content = formula.by_locale.fetch(locale)
        expect(content["name"]).to be_present, "#{formula.topic_name}: no #{locale} name"
        expect(content["formula"]).to be_present, "#{formula.topic_name} / #{content["name"]}: no #{locale} formula"
        expect(content["example"]).to be_present, "#{formula.topic_name} / #{content["name"]}: no #{locale} example"
      end
    end
  end

  it "keeps what the general programme does not teach on the hub alone" do
    expect(described_class.beyond).to match_array(described_class::BEYOND)
    expect(described_class.for(described_class::ALL).map(&:first)).to include(*described_class::BEYOND)
    expect(described_class.for(described_class.view("matura")).map(&:first)).not_to include(*described_class::BEYOND)
    expect(described_class.for(described_class.view("12-klas")).map(&:first)).not_to include(*described_class::BEYOND)
  end

  it "names only calculators that exist" do
    named = described_class.all.filter_map(&:calculator).uniq
    expect(named - described_class::CALCULATORS).to be_empty
  end

  it "has a formula for every topic but the ones that are a way of thinking" do
    expect(described_class.without_formulas(described_class::ALL)).to contain_exactly("Текстови задачи", "Логически задачи")
  end

  describe ".for" do
    it "keeps a later grade's formulas off an earlier grade's page" do
      fourth = described_class.for(described_class.view("4-klas")).to_h
      names = fourth.fetch("Площ").map(&:name)

      expect(names).to include("Лице на правоъгълник")
      expect(names).not_to include("Лице на триъгълник")
      expect(fourth).not_to have_key("Решаване на триъгълник")
    end

    it "shows an exam sheet the formulas of every grade it covers" do
      sheet = described_class.for(described_class.view("nvo-7-klas")).to_h

      expect(sheet).to include("Рационални изрази", "Проценти", "Обем")
      expect(sheet).not_to have_key("Квадратни уравнения")
    end
  end
end
