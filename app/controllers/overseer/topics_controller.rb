# The topic tree, three ways of reading it, and the editor.
#
# The tree is two levels — areas over topics — and is the skeleton everything
# else hangs off (skills, prerequisites, the public pages, a parent's focus), so
# the index is about the shape of the bank rather than a paginated table: how
# many problems each topic has, over what Elo range, and how often students
# say „не съм го учил" to it.
module Overseer
  class TopicsController < BaseController
    VIEWS = %w[tree grades map].freeze
    PANEL_FRAME = "topic_panel".freeze

    before_action :set_topic, only: %i[edit update destroy merge]

    def index
      @selected = Topic.find_by(id: params[:selected])
      @detail = TopicDetail.new(@selected) if @selected
      @stats = TopicStats.new

      # Choosing a topic replaces only the side panel; the tree around it does
      # not need its aggregates run again for that.
      return render(partial: "panel", locals: { detail: @detail, stats: @stats }) if turbo_frame_request_id == PANEL_FRAME

      @view = VIEWS.include?(params[:view]) ? params[:view] : VIEWS.first
      @areas = Topic.roots.ordered.includes(:children).to_a
      @leaves = @areas.flat_map(&:children)
      @layers = prerequisite_layers(@leaves) if @view == "map"
    end

    def new
      @topic = Topic.new(parent_id: params[:parent_id])
      prepare_form
    end

    def create
      @topic = Topic.new(topic_params)

      if @topic.save(context: :editor)
        redirect_to overseer_topics_path(selected: @topic.id), notice: t("overseer.topics.created")
      else
        prepare_form
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      prepare_form
    end

    def update
      @topic.assign_attributes(topic_params)

      if @topic.save(context: :editor)
        redirect_to overseer_topics_path(selected: @topic.id), notice: t("overseer.topics.updated")
      else
        prepare_form
        render :edit, status: :unprocessable_entity
      end
    end

    # Only an empty topic goes: one with questions is merged instead, so the
    # questions, the students' ratings and the public address all land
    # somewhere.
    def destroy
      if @topic.questions.exists? || @topic.children.exists?
        return redirect_to edit_overseer_topic_path(@topic), alert: t("overseer.topics.delete_refused")
      end

      @topic.destroy!
      redirect_to overseer_topics_path, notice: t("overseer.topics.deleted", name: @topic.name)
    end

    def merge
      target = Topic.find_by(id: params[:into_id])
      result = TopicMerge.call(@topic, into: target)

      if result.ok?
        redirect_to overseer_topics_path(selected: target.id),
                    notice: t("overseer.topics.merged", name: @topic.name, into: target.name)
      else
        redirect_to edit_overseer_topic_path(@topic),
                    alert: t("overseer.topics.merge_errors.#{result.error}", detail: result.detail)
      end
    end

    private

    def set_topic
      @topic = Topic.find(params[:id])
    end

    def topic_params
      params.require(:topic).permit(:name, :parent_id, pending_prerequisite_ids: [])
    end

    def prepare_form
      @detail = TopicDetail.new(@topic)
      @areas = Topic.roots.ordered.where.not(id: @topic.id)
      @candidates = Topic.leaves.ordered.includes(:parent).where.not(id: @topic.id)
      @blocked = TopicPrerequisite.blocked_for(@topic)
      @merge_targets = @candidates if @topic.persisted? && @topic.leaf?
      @bank_range = TopicStats.new.bank_range if @topic.persisted?
    end

    # The prerequisite map's columns: a topic with no prerequisites is in the
    # first, and every other one column right of its deepest prerequisite, so
    # each arrow in the reader's head points rightwards. A loop (refused since
    # the editor checks for them, but data predates the check) is cut where it
    # closes rather than recursing for ever.
    def prerequisite_layers(leaves)
      requires = @requires = TopicPrerequisite.pluck(:topic_id, :prerequisite_id).group_by(&:first)
                                              .transform_values { |pairs| pairs.map(&:last) }
      depth = {}
      measure = lambda do |id, seen|
        depth[id] ||= begin
          below = requires.fetch(id, []).reject { |other| seen.include?(other) }
          below.empty? ? 0 : below.map { |other| measure.call(other, seen + [ id ]) }.max + 1
        end
      end

      leaves.group_by { |leaf| measure.call(leaf.id, [ leaf.id ]) }.sort.map(&:last)
    end
  end
end
