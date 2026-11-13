# The calculator pages: one figure or solid each — the area of a triangle, the
# volume of a cylinder — with its formula, a figure that moves with the
# numbers and the sum written out, at /matematika/formuli/:slug.
#
# „лице на триъгълник" is the most searched thing in school maths after the
# exams themselves, and what is typed is the name of a figure, not a topic:
# neither the formula sheet (a card among a hundred) nor „Обяснено просто"
# (an article about area as an idea) is the page for it. So each of these is
# small and about one thing — the formula, why it holds, the mistakes, a few
# of the bank's problems that are about this very figure.
#
# One file per page in config/calculators/, in both locales, like the
# articles. The numbers a page starts on and the range of each slider are in
# the file; the arithmetic and the drawing are in
# app/javascript/lib/calculators/, one module per page, keyed by the slug. A
# page exists once its file does: `Formulas::CALCULATORS` is the list a
# formula may name, and a formula's card links only to the ones that are live.
module Calculators
  DIR = Rails.root.join("config/calculators")

  LOCALES = %w[bg en].freeze

  # How many of the bank's problems a page shows.
  SAMPLES = 4

  Input = Struct.new(:key, :min, :max, :value, :step, keyword_init: true)

  Mode = Struct.new(:key, :inputs, keyword_init: true)

  Calculator = Struct.new(:slug, :topic_name, :grade_min, :grade_max, :match, :related, :modes, :by_locale,
                          keyword_init: true) do
    def content = by_locale[I18n.locale.to_s] || by_locale[I18n.default_locale.to_s]

    def title = content["title"]
    def lede = content["lede"]
    def seo_title = content["seo_title"].presence || title
    def seo_description = content["seo_description"].presence || lede
    def why = content["why"] || {}
    def mistakes = Array(content["mistakes"])

    # The strings the page's script writes: units, the note for numbers that
    # make no figure.
    def copy = content["copy"] || {}

    # One mode's words: its name on the tab, its formula, the sum for the
    # numbers the page starts on, and a label per input.
    def mode_copy(key) = content.dig("modes", key.to_s) || {}

    def topic = Topic.where.not(parent_id: nil).find_by(name: topic_name)
    def grades = grade_min..grade_max
    def grade_label = grade_min == grade_max ? grade_min.to_s : "#{grade_min}–#{grade_max}"
  end

  module_function

  def all
    @all = nil if Rails.env.development?
    @all ||= Dir[DIR.join("*.yml")].sort.map { |path| load(path) }
  end

  def find(slug) = all.find { |calculator| calculator.slug == slug.to_s }

  def live?(slug) = find(slug).present?

  # The bank's problems about this very figure: the topic's showable problems
  # whose text names it, taken at even steps from the easiest to the hardest
  # so the four are not the same problem in different numbers. Deterministic,
  # like every public page's samples. Where the bank has too few that name
  # the figure, the topic's own samples stand in.
  #
  # `match` is a POSIX pattern, not a substring: „куб" as a substring is also
  # every „кубически сантиметра", which is most volume problems, and the cube's
  # page showed prisms. A plain word is still a pattern that matches itself.
  def samples(calculator, limit: SAMPLES)
    topic = calculator.topic
    return [] if topic.nil?

    ids = matching_ids(calculator, topic)
    return Curriculum.sample_questions(elo_range: 0.., topic: topic, limit: limit) if ids.size < limit

    picked = (0...limit).map { |index| ids[(index * (ids.size - 1)).fdiv(limit - 1).round] }.uniq
    Question.where(id: picked).includes(:possible_answers, :topics).sort_by { |question| picked.index(question.id) }
  end

  # Each matching question once, easiest first. Asked of the ids alone:
  # `showable` eager-loads the options, and a pluck over that join returned a
  # multiple-choice question once per option — so two problems looked like
  # eight, enough to skip the fallback and show a page of two.
  def matching_ids(calculator, topic)
    return [] if calculator.match.blank?

    Question.where(id: Curriculum.showable(topic).select(:id))
            .where("questions.body_text ~* ?", calculator.match.to_s)
            .order(:elo, :id).pluck(:id)
  end

  def load(path)
    data = YAML.safe_load_file(path)
    Calculator.new(
      slug: data.fetch("slug"),
      topic_name: data.fetch("topic"),
      grade_min: data.fetch("grade_min"),
      grade_max: data.fetch("grade_max"),
      match: data["match"],
      related: Array(data["related"]),
      modes: data.fetch("modes").map do |mode|
        Mode.new(key: mode.fetch("key"), inputs: mode.fetch("inputs").map { |input| Input.new(**input.symbolize_keys) })
      end,
      by_locale: data.slice(*LOCALES)
    )
  end
end
