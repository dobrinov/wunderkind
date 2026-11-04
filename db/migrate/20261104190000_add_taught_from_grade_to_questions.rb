# The school grade that first teaches a question's kind of problem (TaughtFrom),
# read only by Dispatcher's grade hold. Nullable: an authored question with no
# family and no source has none, and is held by its topic alone.
class AddTaughtFromGradeToQuestions < ActiveRecord::Migration[8.1]
  def change
    add_column :questions, :taught_from_grade, :integer, limit: 2
  end
end
