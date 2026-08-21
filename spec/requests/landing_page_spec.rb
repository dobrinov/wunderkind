require "rails_helper"

RSpec.describe "Landing page", type: :request do
  it "renders the public page for a visitor" do
    get root_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(I18n.t("landing.hero.title"))
    expect(response.body).to include(I18n.t("landing.closing.body"))
  end

  it "reads every figure on the page off the constant that implements it" do
    get root_path

    expect(response.body).to include("#{Challenge::SECONDS_PER_QUESTION} секунди")
    expect(response.body).to include("#{Widgets::REGISTRY.size} вида")
    expect(response.body).to include("#{RatingBand::BANDS.size} нива")
    expect(response.body).to include(I18n.t("landing.duel.tags.no_effect"))
  end

  it "shows the minutes tile instead of a bank size when the bank is small" do
    get root_path

    expect(response.body).to include(I18n.t("landing.proof.minutes_label"))
  end

  it "shows the bank size once the bank is worth quoting, floored to a hundred" do
    allow(Rails.cache).to receive(:fetch).and_call_original
    allow(Rails.cache).to receive(:fetch).with("landing/bank_size", any_args).and_return(19_543)

    get root_path

    expect(response.body).to include("19 500 задачи")
    expect(response.body).not_to include(I18n.t("landing.proof.minutes_label"))
  end

  it "sends a signed-in student to their own home instead" do
    student = create(:user, role: :student)
    sign_in(student)

    get root_path

    expect(response).to redirect_to(calendar_path)
  end
end
