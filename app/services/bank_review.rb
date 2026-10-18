# What the question bank covers against the МОН curriculum and the Bulgarian
# competitions — read from config/bank_review.yml, shown at /matematika/programa.
#
# The scores are a reviewer's judgement, not a query, so they live in a file a
# person edits and dates rather than being worked out per request. The live
# counts on the same page come from the database; the opinion comes from here.
module BankReview
  PATH = Rails.root.join("config/bank_review.yml")

  # The current locale, else Bulgarian — the language every entry is written in.
  Localized = Struct.new(:by_locale) do
    def to_s = by_locale[I18n.locale.to_s] || by_locale[I18n.default_locale.to_s]
  end

  Grade = Struct.new(:number, :score, :covered, :gaps, :note, keyword_init: true) do
    def curriculum_grade = Curriculum.grades.find { |grade| grade.number == number }
  end

  Level = Struct.new(:name, :score, :note, keyword_init: true)
  Source = Struct.new(:name, :url, keyword_init: true)

  MAX_SCORE = 5

  module_function

  def reviewed_on = Date.iso8601(data.fetch("reviewed_on"))

  def grades
    data.fetch("grades").map do |row|
      Grade.new(number: row.fetch("number"), score: row.fetch("score"),
                covered: row.fetch("covered"), gaps: row.fetch("gaps"),
                note: Localized.new(row.fetch("note")))
    end
  end

  def competitions
    data.fetch("competitions").map do |row|
      Level.new(name: Localized.new(row.fetch("name")), score: row.fetch("score"), note: Localized.new(row.fetch("note")))
    end
  end

  def sources
    data.fetch("sources").map { |row| Source.new(name: row.fetch("name"), url: row.fetch("url")) }
  end

  def data
    YAML.load_file(PATH)
  end
end
