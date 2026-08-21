require "rails_helper"

describe RatingBand do
  it "names the band a rating falls in" do
    RatingBand.new(840).name.should eq("Начинаещ")
    RatingBand.new(1000).name.should eq("Уверен")
    RatingBand.new(1199).name.should eq("Уверен")
    RatingBand.new(1200).name.should eq("Силен")
    RatingBand.new(1400).name.should eq("Отличен")
    RatingBand.new(2100).name.should eq("Състезател")
  end

  it "reports the distance to the next band" do
    band = RatingBand.new(1356)

    band.points_to_next.should eq(44)
    band.next_band.name.should eq("Отличен")
    band.should_not be_top
  end

  it "has nothing above the top band" do
    band = RatingBand.new(1700)

    band.should be_top
    band.points_to_next.should be_nil
  end

  it "positions the marker within the drawn scale, clamped at both ends" do
    RatingBand.new(RatingBand::SCALE_FLOOR).position.should eq(0.0)
    RatingBand.new(RatingBand::SCALE_CEILING).position.should eq(1.0)
    RatingBand.new(1300).position.should eq(0.5)

    RatingBand.new(200).position.should eq(0.0)
    RatingBand.new(3000).position.should eq(1.0)
  end
end
