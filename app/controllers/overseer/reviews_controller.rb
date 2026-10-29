module Overseer
  # „За одобрение": the inbox's suggestions waiting on us, one at a time and
  # oldest first. The problem as a student would see it, its topic and rating
  # editable where they stand, the checks a machine can make, the bank's
  # nearest problems, and four decisions plus skip, each on a key
  # (review_keys_controller). Every decision is an ordinary ticket action
  # (QuestionReportsController) that comes back here, to the next one.
  class ReviewsController < BaseController
    QUEUE_SHOWN = 6

    def show
      @queue = QuestionReport.suggestion.awaiting_team.joins(:question).where(questions: { status: :in_review }).
        includes(:user, :question).order(:created_at, :id)
      @queue_size = @queue.count
      @decided_today = QuestionReport.suggestion.closed.where(resolved_at: Time.current.all_day).
        includes(:question).order(:resolved_at).to_a

      queue = @queue.limit(200).to_a
      @ticket = queue.find { |ticket| ticket.id == params[:ticket].to_i } || queue.first
      return unless @ticket

      index = queue.index(@ticket)
      @shown = queue.first(QUEUE_SHOWN) | [ @ticket ]
      @skip_to = queue[index + 1] || (queue.first unless queue.first == @ticket)
      @ticket = QuestionReport.includes(:user, question: [ :topics, :possible_answers ], messages: :author).find(@ticket.id)
      @checks = SuggestionChecks.new(@ticket.question)
      @accepted_before = Question.where(suggested_by: @ticket.user, status: %i[published retired]).count
    end
  end
end
