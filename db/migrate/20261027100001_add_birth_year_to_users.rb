# Optional, students only: the year a child was born and how far their school
# start sits from the usual one, from which SchoolGrade estimates the grade.
class AddBirthYearToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :birth_year, :integer
    add_column :users, :grade_offset, :integer, null: false, default: 0
    add_check_constraint :users, "grade_offset BETWEEN -2 AND 2", name: "users_grade_offset_range"
  end
end
