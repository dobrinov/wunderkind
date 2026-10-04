require "rails_helper"

describe "The badge collection", type: :request do
  let(:student) { create(:user) }

  def award!(key)
    student.badge_awards.create!(badge_key: key)
  end

  describe Badges do
    it "strikes every badge with a family, a tier and a glyph" do
      Badges.all.each do |badge|
        Badges::FAMILIES.should include(badge.family)
        Badges::TIERS.should include(badge.tier)
        badge.glyph.should be_present
      end
    end

    # A badge whose glyph has no file renders a blank medal, which reads as a
    # broken medal rather than a missing asset.
    it "has a vendored file behind every glyph" do
      Badges.glyphs.each do |glyph|
        Rails.root.join("app/assets/images/badges/#{glyph}.svg").should exist
      end
    end

    it "builds one ladder per family, ordered bronze to legend" do
      streak = Badges.collection_for(student).find { |ladder| ladder.family == "streak" }

      streak.rungs.map { |rung| rung.badge.key }.should eq(%w[streak_3 streak_7 streak_30 streak_100])
      streak.rungs.map { |rung| rung.badge.tier }.should eq(%w[bronze silver gold legend])
      streak.size.should eq(4)
      streak.earned_count.should be_zero
    end

    it "fills a locked rung by its progress and an earned one completely" do
      award!("streak_3")
      student.update!(current_streak: 4)

      streak = Badges.collection_for(student).find { |ladder| ladder.family == "streak" }
      streak.earned_count.should eq(1)
      streak.rungs.first.fill.should eq(1.0)
      # 4 of the 7 the next rung asks for.
      streak.rungs.second.fill.should be_within(0.01).of(4 / 7.0)
    end

    it "counts what is held, by tier, newest metal first" do
      award!("streak_3")
      award!("answers_100")
      award!("early_bird")

      Badges.tally_for(student).should eq([ [ "special", 1 ], [ "silver", 1 ], [ "bronze", 1 ] ])
    end

    # A secret badge is only charming because it is a surprise; a goal a child
    # could be working towards must never be one.
    it "gives nothing away about a secret badge until it is earned" do
      secret = Badges.find("upset_win")
      secret.should be_secret

      secret.display_name(false).should eq("???")
      secret.display_glyph(false).should eq("lock")
      secret.display_name(true).should eq(secret.name)
      secret.display_glyph(true).should eq("mountain-snow")
    end

    it "keeps every other badge legible while locked" do
      Badges.all.reject(&:secret?).each do |badge|
        badge.display_name(false).should eq(badge.name)
        badge.display_glyph(false).should eq(badge.glyph)
      end
    end
  end

  describe "the profile" do
    it "draws the ladders, the near misses and a dialog per badge" do
      award!("streak_3")
      student.update!(current_streak: 5)

      sign_in student
      get "/profile"

      response.should have_http_status(:ok)
      response.body.should include("medal medal-m medal-streak medal-bronze")
      response.body.should include(I18n.t("badges.families.streak"))
      response.body.should include(I18n.t("badges_page.closest"))

      # One dialog per badge, so tapping a medal needs no round trip.
      Badges.all.each { |badge| response.body.should include(%(id="badge-#{badge.key}")) }
    end

    it "shows a locked medal filling rather than a greyed-out one" do
      student.update!(current_streak: 5)

      sign_in student
      get "/profile"

      # 5 of 7 on the way to „Седмица серия".
      response.body.should match(/medal-streak is-locked[^"]*"\s+style="--fill: 71%/)
    end

    it "hides a secret badge's name behind ???" do
      sign_in student
      get "/profile"

      response.body.should include("???")
      response.body.should_not include(Badges.find("upset_win").name)
    end
  end
end
