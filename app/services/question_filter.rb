# Filtering for the admin question browser. Kept as a service so the
# controller stays thin and the option lists have one home.
class QuestionFilter
  ELO_BANDS = {
    "640-800" => (640..800),
    "800-1000" => (801..1000),
    "1000-1200" => (1001..1200),
    "1200-1400" => (1201..1400),
    "1400-1600" => (1401..1600),
    "1600+" => (1601..9999)
  }.freeze

  SORTS = {
    "elo_asc" => { elo: :asc },
    "elo_desc" => { elo: :desc },
    "newest" => { created_at: :desc }
  }.freeze

  def initialize(params)
    @params = params
  end

  def results
    scope = Question.includes(:topics, :hint, :possible_answers)
    scope = scope.joins(:topics).where(topics: { id: @params[:topic_id] }) if @params[:topic_id].present?
    scope = scope.where(answer_type: @params[:answer_type]) if @params[:answer_type].present?
    scope = scope.where(status: @params[:status]) if @params[:status].present?
    scope = scope.where(grade_min: @params[:grade]) if @params[:grade].present?
    scope = scope.where(elo: ELO_BANDS[@params[:elo_band]]) if ELO_BANDS.key?(@params[:elo_band])
    scope = scope.where("body_text ILIKE ?", "%#{@params[:q].strip}%") if @params[:q].present?
    scope.order(SORTS.fetch(@params[:sort], SORTS["elo_asc"]))
  end

  def any_filters?
    @params.values_at(:topic_id, :answer_type, :status, :grade, :elo_band, :q).any?(&:present?)
  end

  def topic_options
    Topic.roots.ordered.flat_map do |root|
      [ [ root.name, root.id ] ] + root.children.ordered.map { |child| [ "— #{child.name}", child.id ] }
    end
  end
end
