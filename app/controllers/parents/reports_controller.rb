module Parents
  # A child's report, seen and answered by their parent. The parent reads the
  # same conversation the child does and can write in it — more detail the
  # child could not put into words, a question for the team, „it is still
  # wrong" on a closed report — but cannot confirm the fix, archive the report
  # or mark anything read: those are the child's.
  class ReportsController < BaseController
    before_action :find_report

    def show
    end

    def comment
      if @report.family_comment!(by: current_user, body: params[:body])
        redirect_to parents_child_report_path(@child, @report), notice: t("my_reports.sent.comment")
      else
        redirect_to parents_child_report_path(@child, @report), alert: t("my_reports.empty_message")
      end
    end

    private

    def find_report
      @child = current_user.children.find(params[:child_id])
      @report = @child.question_reports.includes(:question, messages: [ :author, :corrected_question ]).find(params[:id])
    end
  end
end
