# The admin question browser's query: one set of GET params in, the ordered
# result, the facet counts and the removable tokens out. Kept as a service so
# the list, the preview pane and the editor's „1 от 214" all read the same
# ordering — the editor's prev/next is only honest if it walks exactly the
# list the admin came from.
class QuestionFilter
  # Presets over the whole bank, each answering a question the team actually
  # asks. There is no „too easy for its Elo" view: telling that honestly needs
  # each answerer's rating at the time they answered, which nothing stores, and
  # the Elo of a question that is too easy already falls with every answer.
  VIEWS = %w[published reported skipped no_hints retired].freeze

  # „Много пропускани": a skip share this high, out of enough answers that
  # three skips of four is not the whole story.
  SKIPPED_SHARE = 0.3
  SKIPPED_MIN_ANSWERS = 20

  HAS = %w[image hints report suggested].freeze
  ANSWER_TYPES = %w[multiple_choice exact_value interactive].freeze

  # Each sort is a column of the derived table the list reads from, so the
  # same words order the page, a template's representative and the editor's
  # neighbours. `id` breaks ties, or a page boundary could repeat a row.
  SORTS = {
    "elo_asc" => "questions.elo ASC, questions.id ASC",
    "elo_desc" => "questions.elo DESC, questions.id ASC",
    "skipped" => "questions.answers_skipped DESC, questions.answers_total DESC, questions.id ASC",
    "answered" => "questions.answers_total DESC, questions.id ASC",
    "newest" => "questions.created_at DESC, questions.id DESC"
  }.freeze
  STAT_SORTS = %w[skipped answered].freeze
  DEFAULT_SORT = "elo_asc"

  # The Elo histogram's fixed axis: the bank runs 600-2800, and an axis that
  # rescaled to every result set would make two histograms impossible to
  # compare.
  HISTOGRAM_FROM = 600
  HISTOGRAM_TO = 2800
  HISTOGRAM_STEP = 200

  PERMITTED = [ :q, :view, :elo_min, :elo_max, :status, :template, :sort, :group, :page, :topic_id, :answer_type,
                { topic_ids: [], answer_types: [], has: [] } ].freeze

  Token = Struct.new(:label, :remove)
  Position = Struct.new(:index, :total, :previous_id, :next_id)

  attr_reader :params

  def initialize(params)
    raw = params.respond_to?(:permit) ? params.permit(*PERMITTED).to_h : params.to_h
    @params = normalize(raw.deep_symbolize_keys)
  end

  def sort = params[:sort] || DEFAULT_SORT
  def grouped? = params[:group] == "1"

  # The params that reproduce this list, page included — what the editor
  # carries so it can walk the list and come back to the same page of it.
  def to_params
    params.compact_blank
  end

  # The same without the page: changing a filter starts the list over.
  def filter_params
    to_params.except(:page)
  end

  def any_filters?
    filter_params.except(:sort, :group).any?
  end

  # The ordered result: a derived table of the filtered questions, with their
  # answer counts when the sort or view needs them and their template when
  # grouping, so a template collapses to its first row in the chosen order.
  def results
    relation = Question.from(derived, :questions)
    relation = relation.where("questions.shape_rank = 1") if grouped?
    relation.order(Arel.sql(SORTS.fetch(sort)))
  end

  # Where `id` sits in the list, and its neighbours — one window query over the
  # same derived table, so „Запази и следваща" goes where the list would.
  def position_of(id)
    order = SORTS.fetch(sort)
    ranked = results.unscope(:order).select(
      "questions.id",
      "row_number() OVER (ORDER BY #{order}) AS position",
      "lag(questions.id) OVER (ORDER BY #{order}) AS previous_id",
      "lead(questions.id) OVER (ORDER BY #{order}) AS next_id",
      "count(*) OVER () AS total"
    )
    row = Question.connection.select_one(
      Question.sanitize_sql([ "SELECT * FROM (#{ranked.to_sql}) ranked WHERE ranked.id = ?", id.to_i ])
    )
    Position.new(row["position"], row["total"], row["previous_id"], row["next_id"]) if row
  end

  # --- Facets -----------------------------------------------------------------

  # Every view counted over the whole bank — they are presets, and a preset's
  # number should not shrink because of an unrelated filter.
  def view_counts
    VIEWS.index_with { |view| apply_view(Question.all, view).count }
  end

  # Areas and their leaves, each counted within the current result with the
  # topic filter itself lifted, the way a facet counts what choosing it would
  # give. A question in two leaves of one area counts once for the area.
  def topic_counts
    ids = base(without: :topics).select(:id)
    leaves = Question.connection.select_rows(<<~SQL).to_h
      SELECT topic_id, count(*) FROM questions_topics WHERE question_id IN (#{ids.to_sql}) GROUP BY topic_id
    SQL
    areas = Question.connection.select_rows(<<~SQL).to_h
      SELECT COALESCE(topics.parent_id, topics.id), count(DISTINCT questions_topics.question_id)
      FROM questions_topics JOIN topics ON topics.id = questions_topics.topic_id
      WHERE questions_topics.question_id IN (#{ids.to_sql})
      GROUP BY 1
    SQL
    { leaves: leaves, areas: areas }
  end

  def answer_type_counts
    base(without: :answer_types).group(:answer_type).count
  end

  # The current result's Elo spread, with the Elo range lifted so the range
  # can be seen against what lies outside it.
  def histogram
    bucket = "LEAST(GREATEST(questions.elo, #{HISTOGRAM_FROM}), #{HISTOGRAM_TO - 1}) / #{HISTOGRAM_STEP}"
    counts = base(without: :elo).group(Arel.sql(bucket)).count
    (HISTOGRAM_FROM...HISTOGRAM_TO).step(HISTOGRAM_STEP).map do |from|
      { from: from, to: from + HISTOGRAM_STEP, count: counts.fetch(from / HISTOGRAM_STEP, 0), inside: in_elo_range?(from) }
    end
  end

  def topic_tree
    Topic.roots.ordered.includes(:children).map { |root| [ root, root.children.sort_by { |child| [ child.position.to_i, child.name ] } ] }
  end

  def template_question
    @template_question ||= Question.find_by(id: params[:template]) if params[:template].present?
  end

  # --- Tokens -----------------------------------------------------------------

  def tokens
    list = []
    list << token(:view, I18n.t("overseer.questions.browser.views.#{params[:view]}")) if params[:view]
    list << token(:q, "„#{params[:q]}“") if params[:q]
    Array(params[:topic_ids]).each do |id|
      next unless (topic = topics_by_id[id.to_i])

      list << Token.new(I18n.t("overseer.questions.browser.tokens.topic", name: topic.name), without(:topic_ids, id))
    end
    Array(params[:answer_types]).each do |type|
      list << Token.new(I18n.t("overseer.questions.answer_types.#{type}"), without(:answer_types, type))
    end
    Array(params[:has]).each do |key|
      list << Token.new(I18n.t("overseer.questions.browser.has.#{key}"), without(:has, key))
    end
    if params[:elo_min] || params[:elo_max]
      list << Token.new(I18n.t("overseer.questions.browser.tokens.elo", from: params[:elo_min] || "…", to: params[:elo_max] || "…"),
                        filter_params.except(:elo_min, :elo_max))
    end
    list << token(:status, I18n.t("overseer.questions.statuses.#{params[:status]}")) if params[:status]
    list << token(:template, I18n.t("overseer.questions.browser.tokens.template", id: params[:template])) if params[:template]
    list
  end

  private

  def token(key, label)
    Token.new(label, filter_params.except(key))
  end

  def without(key, value)
    filter_params.merge(key => params[key] - [ value ]).compact_blank
  end

  def normalize(raw)
    out = {}
    out[:q] = raw[:q].to_s.strip.presence
    out[:view] = raw[:view] if VIEWS.include?(raw[:view])
    out[:topic_ids] = (Array(raw[:topic_ids]) + Array(raw[:topic_id])).map(&:to_s).select { |id| id.match?(/\A\d+\z/) }.uniq.presence
    out[:answer_types] = (Array(raw[:answer_types]) + Array(raw[:answer_type])).map(&:to_s).select { |type| Question.answer_types.key?(type) }.uniq.presence
    out[:has] = Array(raw[:has]).map(&:to_s).select { |key| HAS.include?(key) }.uniq.presence
    out[:elo_min] = raw[:elo_min].to_s[/\A\d+\z/]
    out[:elo_max] = raw[:elo_max].to_s[/\A\d+\z/]
    out[:status] = raw[:status] if Question.statuses.key?(raw[:status])
    out[:template] = raw[:template].to_s[/\A\d+\z/]
    # The default stays out of the params, so it stays out of every URL.
    out[:sort] = raw[:sort] if SORTS.key?(raw[:sort]) && raw[:sort] != DEFAULT_SORT
    out[:group] = "1" if raw[:group] == "1"
    out[:page] = raw[:page].to_s[/\A\d+\z/]
    out.compact
  end

  def needs_stats?
    STAT_SORTS.include?(sort)
  end

  def derived
    scope = base
    columns = [ "questions.*" ]
    if needs_stats?
      columns << "COALESCE(answer_stats.total, 0) AS answers_total" << "COALESCE(answer_stats.skipped, 0) AS answers_skipped"
    end
    if grouped?
      shape = SessionComposer::SHAPE_SQL
      inner_order = SORTS.fetch(sort).
        gsub("questions.answers_skipped", "COALESCE(answer_stats.skipped, 0)").
        gsub("questions.answers_total", "COALESCE(answer_stats.total, 0)")
      columns << "count(*) OVER (PARTITION BY #{shape}) AS shape_count"
      columns << "row_number() OVER (PARTITION BY #{shape} ORDER BY #{inner_order}) AS shape_rank"
    end
    scope.select(columns.join(", "))
  end

  # The filtered questions, unordered. `without` lifts one facet's own filter,
  # which is how that facet's counts are taken.
  def base(without: nil)
    scope = Question.all
    scope = scope.joins("LEFT JOIN (#{QuestionStats::BANK_SQL}) answer_stats ON answer_stats.question_id = questions.id") if needs_stats?
    scope = apply_view(scope, params[:view]) if params[:view]
    scope = filter_text(scope) if params[:q]
    scope = scope.where("questions.id IN (SELECT question_id FROM questions_topics WHERE topic_id IN (?))", topic_ids) if params[:topic_ids] && without != :topics
    scope = scope.where(answer_type: params[:answer_types]) if params[:answer_types] && without != :answer_types
    scope = scope.where(status: params[:status]) if params[:status]
    scope = scope.where(questions: { elo: params[:elo_min].to_i.. }) if params[:elo_min] && without != :elo
    scope = scope.where(questions: { elo: ..params[:elo_max].to_i }) if params[:elo_max] && without != :elo
    scope = filter_template(scope) if params[:template]
    Array(params[:has]).each { |key| scope = apply_has(scope, key) }
    scope
  end

  def apply_view(scope, view)
    case view
    when "published" then scope.where(status: :published)
    when "retired" then scope.where(status: :retired)
    when "reported" then apply_has(scope, "report")
    when "no_hints" then scope.where(status: :published).where.not(id: QuestionHint.where("jsonb_array_length(ladder) > 0").select(:question_id))
    when "skipped"
      scope.where(<<~SQL.squish)
        questions.id IN (SELECT question_id FROM (#{QuestionStats::BANK_SQL}) bank
                         WHERE bank.total >= #{SKIPPED_MIN_ANSWERS} AND bank.skipped > bank.total * #{SKIPPED_SHARE})
      SQL
    else scope
    end
  end

  def apply_has(scope, key)
    case key
    when "image" then scope.where(attachable_type: "QuestionImage")
    when "hints" then scope.where(id: QuestionHint.where("jsonb_array_length(ladder) > 0").select(:question_id))
    when "report" then scope.where(id: QuestionReport.active.select(:question_id))
    when "suggested" then scope.where.not(suggested_by_id: nil)
    else scope
    end
  end

  # „#18204" is a question's number; anything else is a piece of its text.
  def filter_text(scope)
    if (id = params[:q][/\A#?\s*(\d+)\z/, 1])
      scope.where(id: id.to_i)
    else
      scope.where("questions.body_text ILIKE ?", "%#{Question.sanitize_sql_like(params[:q])}%")
    end
  end

  # Every question cut from the same template as the given one — the same
  # SessionComposer::SHAPE_SQL that keeps a session from asking one template
  # five times.
  def filter_template(scope)
    shape = Question.where(id: params[:template]).pick(Arel.sql(SessionComposer::SHAPE_SQL))
    shape ? scope.where("#{SessionComposer::SHAPE_SQL} = :shape", shape: shape) : scope.none
  end

  # A chosen area stands for all of its leaves.
  def topic_ids
    ids = params[:topic_ids].map(&:to_i)
    ids + Topic.where(parent_id: ids).pluck(:id)
  end

  def topics_by_id
    @topics_by_id ||= Topic.where(id: params[:topic_ids]).index_by(&:id)
  end

  def in_elo_range?(from)
    low = params[:elo_min]&.to_i || -Float::INFINITY
    high = params[:elo_max]&.to_i || Float::INFINITY
    from + HISTOGRAM_STEP > low && from <= high
  end
end
