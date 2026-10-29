module Overseer
  # „Входящи": reports and suggestions as one list of tickets, filtered by
  # where they stand (waiting on us first, since that is the work) and by
  # kind, with the chosen ticket open beside the list. Picking a row swaps
  # only the pane (a turbo-frame) and keeps the address, so a reload or a
  # shared link opens the same ticket; anything pressed inside the pane posts
  # to the ticket's own actions and comes back here.
  class InboxController < BaseController
    def index
      @inbox = TicketInbox.new(filter: params[:filter], kind: params[:kind], question_id: params[:question_id])
      @tickets = @inbox.tickets.includes(:user, :question, :messages).page(params[:page]).per(TicketInbox::PER_PAGE)
      @state_counts = @inbox.state_counts
      @kind_counts = @inbox.kind_counts
      @my_children_ids = current_user.children.ids
      # How many students reported the same question and are still waiting —
      # the „×2" on a row. One grouped query for the page.
      @active_on_question = QuestionReport.report.active.where(question_id: @tickets.map(&:question_id)).group(:question_id).count

      @ticket = params[:ticket].present? ? QuestionReport.find_by(id: params[:ticket]) : @tickets.first
      return unless @ticket

      @ticket = QuestionReport.includes(:question, :user, messages: [ :author, :corrected_question ]).find(@ticket.id)
      @related = @ticket.question.reports.where.not(id: @ticket.id).includes(:user).order(:created_at)
    end
  end
end
