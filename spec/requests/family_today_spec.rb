require "rails_helper"

# The family page opens on today: who has practised, who has not and whose
# streak ends tonight, and what is owed — and a big family's children fold
# into one menu in the header instead of a button each.
describe "The family page's „Днес“", type: :request do
  let(:parent) { create(:user, role: :parent, verified_at: Time.current) }

  def child!(name, practised: false, streak_yesterday: false)
    child = User.create_managed_child!(parent: parent, name: name)
    if streak_yesterday
      practise!(child, at: 1.day.ago)
      child.update!(current_streak: 1, last_active_on: Time.zone.yesterday)
    end
    practise!(child, at: Time.current) if practised
    child
  end

  def practise!(child, at:)
    assignment = Assignment.create!(user: child)
    row = assignment.assignment_questions.create!(question: create(:question), position: 1)
    row.create_user_answer!(user: child, value: "42", correct: true, response: { "value" => "42" }, duration_ms: 120_000, created_at: at)
  end

  it "says who practised, who has not, and whose streak ends tonight" do
    child!("Ния Петрова", practised: true)
    child!("Сашо Петров", streak_yesterday: true)

    sign_in parent
    get parents_children_path

    page = Nokogiri::HTML(response.body).at_css("section[aria-labelledby=family-today]")
    page.text.should include(I18n.t("parents.today.practised", count: 1), "Ния")
    page.text.should include(I18n.t("parents.today.not_yet", count: 1), "Сашо")
    page.text.should include(I18n.t("parents.today.streaks_end", names: "Сашо"))
  end

  it "folds a big family into one menu in the header" do
    %w[Ваня Боян Катя Митко].each { |name| child!("#{name} Петров") }

    sign_in parent
    get parents_children_path

    Nokogiri::HTML(response.body).css(".child-switcher-button").should be_empty
    response.body.should include("child-switcher-menu")
  end
end
