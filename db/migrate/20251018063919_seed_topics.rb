class SeedTopics < ActiveRecord::Migration[8.0]
  def up
    [
      "събиране",
      "изваждане",
      "умножение",
      "деление",
      "цели числа",
      "дроби",
      "проценти",
      "отрицателни числа",
      "степенуване",
      "коренуване",
      "до 10",
      "до 20",
      "до 100"
    ].each do |name|
      Topic.create! name:
  end
  end

  def down
    Topic.destroy_all
  end
end
