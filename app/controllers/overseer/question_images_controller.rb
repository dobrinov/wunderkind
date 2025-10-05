module Overseer
  class QuestionImagesController < BaseController
    def index
      @question_images = QuestionImage.all
    end
  end
end
