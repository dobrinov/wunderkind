require "rails_helper"

# The real problem files under db/seeds/past, ours and the papers', checked the
# way the ladder corpus is: a problem a child cannot answer is worse than none.
describe "past paper files" do
  rows = Dir[Rails.root.join("db/seeds/past/*/*/*.yml")].sort.flat_map do |file|
    path = Pathname(file)
    list = file.end_with?("-modelled.yml") ? PastPapers.send(:modelled_from, path) : PastPapers.send(:problems_from, path)
    list.map { |row| [ path.relative_path_from(Rails.root).to_s, row.stringify_keys ] }
  end

  # A clock time („14:05“) and a word („неделя“) are typed into a text field and
  # compared as text, which works. A ratio is not: „1:3“ looks like a number, a
  # child types it on the number pad, which writes „:“ as a fraction bar, and
  # 1/3 never matches the text „1:3“ — so a ratio is stored as the fraction.
  it "stores every typed answer as a number, a clock time or a word" do
    typed = rows.reject { |_, row| row["options"] || row["widget"] || row["rubric"] }
    typed.size.should be > 1000

    unreadable = typed.reject do |_, row|
      answer = row["answer"].to_s
      ExactValue.stored(answer) || answer.match?(/\A([01]?\d|2[0-3]):[0-5]\d\z/) || !answer.match?(/\d/)
    end
    unreadable.map { |file, row| "#{file}: #{row['answer']}" }.should be_empty
  end

  it "offers the right answer among the options of every multiple-choice problem" do
    rows.select { |_, row| row["options"] }.each do |file, row|
      row["options"].map(&:to_s).should include(row["answer"].to_s), "#{file}: #{row['text']}"
    end
  end
end
