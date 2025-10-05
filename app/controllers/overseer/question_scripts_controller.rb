module Overseer
  class QuestionScriptsController < BaseController
    def index
      @question_scripts = QuestionScript.all
    end
  end
end
