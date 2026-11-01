# „Минали теми" for one competition or exam: its real past papers, by grade and
# year, each sat as the paper was — see PastPapers.
class PastPapersController < CompetitionsController
  def index
    @grades = PastPapers.grades(event.slug)
    return redirect_to competitions_path, alert: t("past_papers.none") if @grades.empty?

    @grade = chosen_grade
    @papers = PastPapers.available(event.slug, grade: @grade)
    # The best result per year, so a paper already sat says how it went.
    @results = current_user.assignments.mock.where(competition_slug: event.slug, paper_grade: @grade)
                           .where.not(completed_at: nil).order(:completed_at)
                           .index_by(&:paper_year).transform_values { |assignment| MockExam.result(assignment) }
  end

  def new
    grade = params[:grade].to_i
    year = params[:year].to_i
    paper = PastPapers.find(event.slug, grade, year)
    count = PastPapers.questions(event.slug, grade, year).size
    raise PastPapers::NotFound if count.zero?

    render "mock_exams/ready", locals: { title: t("past_papers.paper", year: year, grade: grade), subtitle: event.name,
                                         count: count, minutes: paper.minutes,
                                         running: MockExam.running(current_user, event.slug, year: year, grade: grade),
                                         start_path: competition_papers_path(event.slug), params: { grade: grade, year: year } }
  rescue PastPapers::NotFound
    redirect_to competition_papers_path(event.slug), alert: t("past_papers.none")
  end

  def create
    assignment = PastPapers.start!(user: current_user, event: event, grade: params[:grade].to_i, year: params[:year].to_i)
    track :session_started, kind: assignment.kind
    redirect_to question_path(assignment.next_assignment_question)
  rescue PastPapers::NotFound
    redirect_to competition_papers_path(event.slug), alert: t("past_papers.none")
  end

  private

  # The grade asked for, else the child's own when the competition has it,
  # else the nearest one it has.
  def chosen_grade
    asked = params[:grade].to_i
    return asked if @grades.include?(asked)

    own = current_user.estimated_grade
    return own if own.is_a?(Integer) && @grades.include?(own)

    own.is_a?(Integer) ? @grades.min_by { |grade| (grade - own).abs } : @grades.first
  end
end
