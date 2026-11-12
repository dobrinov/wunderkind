# „Наръчник": the formula sheets, the „Обяснено просто" articles and the
# multiplication table, inside the app — the same material as the public pages
# (Formulas, Explainers, TimesTablesController), in the app's own chrome and
# opened on the student's own grade.
#
# The public pages are written for a parent arriving from a search; a student
# who is already here should not have to leave the app, lose the tab bar and
# be offered a sign-up to look up a formula. So this renders the same partials
# under the app layout and picks the grade for them: the student's estimated
# school grade (User#estimated_grade, from the optional birth year) when there
# is one, otherwise whichever grade they choose — the page works without a
# birth year, it just starts with the question.
#
# Presentation only, like Curriculum: nothing here is read by the answer flow,
# and choosing another grade changes what is shown, never what is asked.
class HandbookController < AuthenticatedController
  def show
    @estimated = current_user.estimated_grade.then { |grade| grade if grade.is_a?(Integer) }
    @grade = chosen_grade || @estimated
    return if @grade.nil?

    @view = Formulas.view("#{@grade}-klas")
    @topics = Formulas.for(@view)
    @count = @topics.sum { |_, formulas| formulas.size }
    @explainers = Explainers.all.index_by(&:topic_name)
    @articles = Explainers.all.select { |article| article.grades.cover?(@grade) }
  end

  def article
    @article = Explainers.find(params[:slug]) || raise(ActionController::RoutingError, "No such article")
    @topic = @article.topic
  end

  def times_table
    @range = TimesTablesController::RANGE
  end

  private

  # A grade asked for in the address, when it is one.
  def chosen_grade
    grade = params[:grade].to_i
    grade if SchoolGrade::GRADES.cover?(grade)
  end
end
