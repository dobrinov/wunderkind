require "rails_helper"

describe ExactValue do
  describe ".parse" do
    it "parses integers, decimals, and negative numbers" do
      ExactValue.parse("42").should eq(42)
      ExactValue.parse("-3.5").should eq(Rational(-7, 2))
    end

    it "parses Bulgarian decimal commas" do
      ExactValue.parse("0,75").should eq(Rational(3, 4))
    end

    it "parses fractions and mixed numbers" do
      ExactValue.parse("3/4").should eq(Rational(3, 4))
      ExactValue.parse("1 1/2").should eq(Rational(3, 2))
      ExactValue.parse("-1 1/2").should eq(Rational(-3, 2))
    end

    # What the MathLive keyboard's fraction key actually sends.
    it "parses a fraction whose parts arrive parenthesized" do
      ExactValue.parse("(1)/(2)").should eq(Rational(1, 2))
      ExactValue.parse("(12)/(5)").should eq(Rational(12, 5))
      ExactValue.parse("1(1)/(2)").should eq(Rational(3, 2))
      ExactValue.parse("-(3)/(4)").should eq(Rational(-3, 4))
      ExactValue.parse("(-3)/(4)").should eq(Rational(-3, 4))
    end

    it "parses percentages" do
      ExactValue.parse("75%").should eq(Rational(3, 4))
    end

    it "returns nil for non-numeric input and division by zero" do
      ExactValue.parse("abc").should be_nil
      ExactValue.parse("1/0").should be_nil
      ExactValue.parse("").should be_nil
    end
  end

  describe ".equivalent?" do
    it "treats equivalent numeric forms as equal" do
      ExactValue.equivalent?("3/4", "0,75").should be(true)
      ExactValue.equivalent?("3/4", "75%").should be(true)
      ExactValue.equivalent?("0.5", "1/2").should be(true)
    end

    it "accepts the fraction key's own notation for a typed fraction" do
      ExactValue.equivalent?("1/2", "(1)/(2)").should be(true)
      ExactValue.equivalent?("1 1/2", "1(1)/(2)").should be(true)
      ExactValue.equivalent?("0,5", "(1)/(2)").should be(true)
    end

    it "rejects different values" do
      ExactValue.equivalent?("3/4", "0.7").should be(false)
    end

    it "honors tolerance" do
      ExactValue.equivalent?("3.14", "3.1", tolerance: 0.05).should be(true)
      ExactValue.equivalent?("3.14", "3.0", tolerance: 0.05).should be(false)
    end

    # What children actually typed in the family field test, every one of
    # them right and marked wrong.
    it "reads an answer written the way school writes it" do
      ExactValue.equivalent?("5152", "5 152").should be(true)
      ExactValue.equivalent?("6253416", "6 253 416").should be(true)
      ExactValue.equivalent?("72", "x = 72").should be(true)
      ExactValue.equivalent?("0", "x=0").should be(true)
      ExactValue.equivalent?("43", "43°").should be(true)
      ExactValue.equivalent?("8", "8 евро").should be(true)
      ExactValue.equivalent?("10", "10банана").should be(true)
      ExactValue.equivalent?("34", "34 m/s").should be(true)
      ExactValue.equivalent?("14", "с 14").should be(true)
      ExactValue.equivalent?("-26", "−26").should be(true)
      ExactValue.equivalent?("1/2", "1/2 от тортата").should be(true)
      ExactValue.equivalent?("3/2", "1 1/2 часа").should be(true)
      ExactValue.equivalent?("40320", "8!").should be(true)
    end

    it "takes a percent answer either way, whichever the question meant" do
      ExactValue.equivalent?("40", "40%").should be(true)
      ExactValue.equivalent?("2/5", "40%").should be(true)
      ExactValue.equivalent?("40", "40 % от тях").should be(true)
      ExactValue.equivalent?("40", "41%").should be(false)
    end

    it "does not guess when there is more than one number, or none" do
      ExactValue.equivalent?("34", "3 4").should be(false)
      ExactValue.equivalent?("12", "12 и 5").should be(false)
      ExactValue.equivalent?("5", "5 1/2 и 3").should be(false)
      ExactValue.equivalent?("8", "осем").should be(false)
      ExactValue.equivalent?("72", "x = 27").should be(false)
    end

    it "keeps stored answers strict" do
      ExactValue.parse("5 152").should be_nil
      ExactValue.parse("8 евро").should be_nil
    end

    it "falls back to case- and whitespace-insensitive text comparison" do
      ExactValue.equivalent?("Питагор", " питагор ").should be(true)
      ExactValue.equivalent?("Питагор", "Евклид").should be(false)
    end
  end
end
