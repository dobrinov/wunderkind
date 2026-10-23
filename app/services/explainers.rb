# The "Обяснено просто" articles: short, plain explanations of one idea each —
# what a prime number is, why the Pythagorean theorem holds, what a vector is —
# with something on the page to play with. Public, crawlable, and read by no
# part of the answer flow.
#
# They exist for the parent and the child who search for the idea rather than
# for problems: „какво е просто число" is a different query from „задачи за
# прости числа", and the topic pages only answer the second. Each article links
# to its topic's page and shows a few of the bank's worked problems, so the
# reader who understood the idea has somewhere to try it.
#
# One file per article in config/explainers/, written by a person, with the
# whole text in both locales — the way config/competitions.yml is. Text, not
# templates: an article is edited by someone fixing a sentence, and a sentence
# belongs in a file a sentence can be fixed in. The grades are the МОН
# programme's (see Curriculum), the same stance as the grade pages: school
# grades at the door, Elo inside.
module Explainers
  DIR = Rails.root.join("config/explainers")

  # The languages every article is written in: the app's two.
  LOCALES = %w[bg en].freeze

  # The bands the hub groups articles in, by the first grade an article is for.
  BANDS = [ 1..2, 3..4, 5..6, 7..8, 9..10, 11..12 ].freeze

  Article = Struct.new(:slug, :grade_min, :grade_max, :minutes, :topic_name, :related, :playgrounds,
                       :by_locale, keyword_init: true) do
    def grades = grade_min..grade_max

    # The article in the current locale, else Bulgarian — the language every
    # article is written in first.
    def content = by_locale[I18n.locale.to_s] || by_locale[I18n.default_locale.to_s]

    def title = content["title"]
    def lede = content["lede"]
    def summary = Array(content["summary"])
    def sections = Array(content["sections"])
    def traps = Array(content["traps"])
    def quiz = Array(content["quiz"])
    def seo_title = content["seo_title"].presence || title
    def seo_description = content["seo_description"].presence || lede

    # The copy one playground's partial reads: labels, buttons, notes.
    def playground(name) = content.dig("playgrounds", name.to_s) || {}

    def topic = Topic.find_by(name: topic_name)
    def band = BANDS.find { |band| band.cover?(grade_min) }
    def grade_label = grade_min == grade_max ? grade_min.to_s : "#{grade_min}–#{grade_max}"
  end

  module_function

  def all
    @all = nil if Rails.env.development?
    @all ||= Dir[DIR.join("*.yml")].sort.map { |path| load(path) }.sort_by { |article| [ article.grade_min, article.grade_max, article.slug ] }
  end

  def find(slug) = all.find { |article| article.slug == slug.to_s }

  def for_topic(topic) = all.select { |article| article.topic_name == topic.name }

  def by_band = all.group_by(&:band).sort_by { |band, _| band.min }

  def load(path)
    data = YAML.safe_load_file(path)
    Article.new(
      slug: data.fetch("slug"),
      grade_min: data.fetch("grade_min"),
      grade_max: data.fetch("grade_max"),
      minutes: data.fetch("minutes"),
      topic_name: data["topic"],
      related: Array(data["related"]),
      playgrounds: Array(data["playgrounds"]),
      by_locale: data.slice(*LOCALES)
    )
  end
end
