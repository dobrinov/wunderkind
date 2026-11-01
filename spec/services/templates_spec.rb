require "rails_helper"

# „The same problem again" inside a session: a ladder family however reworded,
# one past-paper task and ours on its model, or else the text's shape.
RSpec.describe Templates do
  let(:topic) { Topic.create!(name: "Логически задачи", parent: Topic.create!(name: "Логика")) }

  def question(text, family: nil, source: nil, elo: 1000)
    create(:question, text: text, family: family, source: source, elo: elo).tap { |q| q.topics << topic }
  end

  it "keys a problem by its family, then its past-paper task, then its shape" do
    taller = question("Борис е по-нисък от Тодор. Кое дете е най-високо?", family: "logic.early_order")
    reworded = question("Ива е по-висока от Мария. Кое дете е най-високо?", family: "logic.early_order")
    task = { "kind" => "original", "competition" => "smt", "year" => 2021, "number" => "7" }
    original = question("Везна с два пакета", source: task)
    modelled = question("Везна с три пакета", source: task.merge("kind" => "modelled", "level" => "easy"))
    plain = question("Колко е 3 + 4?")

    Templates.key(taller).should eq(Templates.key(reworded))
    Templates.key(original).should eq(Templates.key(modelled))
    Templates.key(plain).should eq("shape:Колко е # + #?")
  end

  it "keeps one of a family or a task, and the session cap of a shape" do
    family = Array.new(3) { |index| question("Подреди #{%w[Ани Боби Цвети][index]} по ръст", family: "logic.early_order") }
    facts = Array.new(3) { |index| question("Колко е #{index} + 4?") }

    Templates.capped(family + facts).should eq([ family.first ] + facts.first(SessionComposer::MAX_PER_SHAPE))
  end

  it "leaves the named templates out of a query, and placement asks a new one" do
    first = question("Монети: една е по-лека", family: "puzzle.weighings", elo: 1000)
    question("Топчета: едно е по-тежко", family: "puzzle.weighings", elo: 1000)
    other = question("Колко са триъгълниците?", elo: 1100)
    user = create(:user, elo: 1000)

    Templates.excluding(Question.where(id: [ first.id, other.id ]), [ Templates.key(first) ]).should eq([ other ])
    Dispatcher.at_rung(user, rung: 1000, excluding: [ first ], templates: [ Templates.key(first) ]).should eq(other)
  end
end
