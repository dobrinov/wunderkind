# „Типови задачи": the kind of problem a question is, by the idea a child needs
# („Възрастови задачи", „Везни и равновесие") — a slug from
# config/problem_types.yml. One per question, set by the problem files.
class AddProblemTypeToQuestions < ActiveRecord::Migration[8.1]
  def change
    add_column :questions, :problem_type, :string
    add_index :questions, :problem_type, where: "problem_type IS NOT NULL"
  end
end
