module Overseer
  class TopicsController < BaseController
    def index
      @topics = Topic.all.page params[:page]
    end

    def new
    end

    def create
    end
  end
end
