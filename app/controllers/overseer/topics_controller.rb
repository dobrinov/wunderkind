module Overseer
  class TopicsController < BaseController
    def index
      @topics = Topic.includes(:parent).left_joins(:questions).group(:id).select("topics.*, COUNT(questions.id) AS questions_count").ordered.page params[:page]
    end

    def new
      @topic = Topic.new(parent_id: params[:parent_id])
    end

    def create
      @topic = Topic.new(topic_params)

      if @topic.save
        redirect_to overseer_topics_path, notice: t("overseer.topics.created")
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      @topic = Topic.find params[:id]
    end

    def update
      @topic = Topic.find params[:id]

      if @topic.update(topic_params)
        redirect_to overseer_topics_path, notice: t("overseer.topics.updated")
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def topic_params
      params.require(:topic).permit(:name, :parent_id, :position)
    end
  end
end
