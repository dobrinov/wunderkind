require "rails_helper"

# Curriculum keeps two maps of topics by grade, by hand and by name: PROGRAMME
# is what the МОН programme teaches (the public pages, the formula sheets, the
# handbook) and TOPICS is when a child may first be served a topic (the grade
# hold, the exams' topic sets). A name neither file knows shows nowhere, and
# the two drifting into one would either put combinatorics on the 4th-grade
# page or keep counting problems from a child until 7th grade.
RSpec.describe Curriculum do
  let(:leaves) do
    YAML.safe_load_file(Rails.root.join("db/seeds/topics.yml")).fetch("topics").values.flatten
  end

  it "names only leaves of the topic tree, in every grade of both maps" do
    [ described_class::PROGRAMME, described_class::TOPICS ].each do |map|
      expect(map.keys).to eq((1..12).to_a)
      expect(map.values.flatten.uniq - leaves).to be_empty
      map.each_value { |names| expect(names).to eq(names.uniq) }
    end
  end

  it "gives a grade page the programme's topics" do
    expect(described_class.grade("9-klas").topic_names).to include("Питагорова теорема")
    expect(described_class.grade("8-klas").topic_names).not_to include("Питагорова теорема")
    expect(described_class.grade("4-klas").topic_names).not_to include("Броене и комбинаторика")
  end

  it "leaves the practice map where the grade hold needs it" do
    expect(described_class::TOPICS[4]).to include("Броене и комбинаторика")
    expect(described_class::TOPICS[8]).to include("Питагорова теорема")
  end

  it "serves nothing later than the programme teaches it" do
    described_class::PROGRAMME.each do |grade, names|
      names.each do |name|
        served = described_class::TOPICS.select { |_, list| list.include?(name) }.keys.min
        expect(served).to be <= grade, "#{name}: on the #{grade}th-grade page but served from #{served.inspect}"
      end
    end
  end
end
