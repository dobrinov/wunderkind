module Overseer
  class ReviewsController < BaseController
    def index
      @questions = Question.in_review.includes(:author, :topics).order(:updated_at).page params[:page]
    end

    def approve
      question = Question.in_review.find(params[:id])
      question.update!(status: :published)
      redirect_to overseer_reviews_path, notice: t("overseer_reviews.approved")
    end

    def reject
      question = Question.in_review.find(params[:id])
      question.update!(status: :private_library)
      redirect_to overseer_reviews_path, notice: t("overseer_reviews.rejected")
    end
  end
end
