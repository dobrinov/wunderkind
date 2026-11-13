# The formula sheets: every formula and rule of school maths, read from
# config/formulas.yml and shown at /matematika/formuli — all of them on the hub,
# and one page per grade and per exam sheet.
#
# Those pages answer a search of their own. „формули 7 клас", „формули за НВО
# 10 клас" and „формули за съкратено умножение" are typed by students the week
# before a test, and a student who finds the sheet and then the worked
# problems under it is the one the rest of the site is for.
#
# Like Curriculum, this is presentation only and speaks in grades: a formula is
# filed under a topic of the tree and carries the grade it is first taught in
# (`from`), and a page shows the formulas of the topics its grades teach
# (Curriculum::PROGRAMME) that are taught by then. Nothing in the answer flow
# reads it.
module Formulas
  PATH = Rails.root.join("config/formulas.yml")

  LOCALES = %w[bg en].freeze

  # The pages a formula can be shown on besides the hub. A grade page is that
  # grade's programme; an exam sheet is the stretch of school the exam covers —
  # НВО after 4th grade covers 1st to 4th, after 7th the 5th to 7th, after
  # 10th the 8th to 10th, and the матура (ДЗИ) the 8th to 12th.
  View = Struct.new(:slug, :kind, :grades, keyword_init: true) do
    def grade = grades.max
    def all? = kind == :all
    def grade? = kind == :grade
    def sheet? = kind == :sheet
  end

  SHEETS = {
    "nvo-4-klas" => 1..4,
    "nvo-7-klas" => 5..7,
    "nvo-10-klas" => 8..10,
    "matura" => 8..12
  }.freeze

  ALL = View.new(slug: nil, kind: :all, grades: 1..12)

  VIEWS = [
    *Curriculum.grades.map { |grade| View.new(slug: grade.slug, kind: :grade, grades: grade.number..grade.number) },
    *SHEETS.map { |slug, grades| View.new(slug: slug, kind: :sheet, grades: grades) }
  ].freeze

  # The pages with a calculator for a figure or a solid, by slug. A formula
  # names one (`calculator:`) and its card links there once the page is live.
  CALCULATORS = %w[
    litse-na-triagalnik litse-na-pravoagalnik litse-na-usporednik litse-na-trapets litse-na-romb litse-na-krag
    kub paralelepiped prizma piramida tsilindar konus kalbo
  ].freeze

  Formula = Struct.new(:topic_name, :from, :calculator, :by_locale, keyword_init: true) do
    def content = by_locale[I18n.locale.to_s] || by_locale[I18n.default_locale.to_s]

    def name = content["name"]
    def formula = content["formula"]
    def where = content["where"].presence
    def example = content["example"].presence

    # What the page's search box matches, in the page's language.
    def search_text = [ topic_name, name, formula, where ].compact.join(" ").downcase
  end

  module_function

  def all
    @all = nil if Rails.env.development?
    @all ||= load
  end

  def view(slug) = VIEWS.find { |candidate| candidate.slug == slug.to_s }

  # The topics taught in any of the given grades, in the order school meets
  # them: by the first grade that teaches each, then the programme's order.
  def topic_names(grades = 1..12)
    grades.flat_map { |number| Curriculum::PROGRAMME.fetch(number) }.uniq
  end

  # The topics to show on a page and the formulas under each, in school order.
  # A topic with no formula on this page is left out; the hub keeps a word for
  # the topics that have none at all (`without_formulas`).
  def for(view)
    names = topic_names(view.grades)
    names += beyond if view.all?
    by_topic = all.select { |formula| formula.from <= view.grade }.group_by(&:topic_name)

    names.filter_map do |name|
      formulas = by_topic[name]
      [ name, formulas ] if formulas.present?
    end
  end

  # Topics with formulas that the general programme teaches in no grade — the
  # derivative, which is профилирана подготовка. They are on the hub, after
  # everything else, and on no grade's or exam's sheet.
  BEYOND = [ "Производна" ].freeze

  def beyond
    all.map(&:topic_name).uniq - topic_names(Curriculum::PROGRAMME.keys)
  end

  # Topics of these grades that no formula is filed under — word problems and
  # logic puzzles are a way of thinking, not a formula, and the page says so
  # rather than leaving them out without a word.
  def without_formulas(view)
    filed = all.map(&:topic_name).to_set
    topic_names(view.grades).reject { |name| filed.include?(name) }
  end

  # The grades a topic is taught in, for the line under its heading.
  def grades_for(topic_name)
    Curriculum::PROGRAMME.select { |_, names| names.include?(topic_name) }.keys
  end

  def load
    data = YAML.safe_load_file(PATH)
    data.fetch("topics").flat_map do |topic_name, entries|
      entries.map do |entry|
        shared = entry.slice("formula")
        Formula.new(
          topic_name: topic_name,
          from: entry.fetch("from"),
          calculator: entry["calculator"],
          by_locale: LOCALES.index_with { |locale| shared.merge(entry.fetch(locale, {})) }
        )
      end
    end
  end
end
