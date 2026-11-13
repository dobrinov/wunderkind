require "rails_helper"

# Leva to euro in a problem's words; the numbers are left alone.
RSpec.describe EuroWording do
  {
    "Цена от 40 лв. се увеличава с 10%. Колко лева става новата цена?" => "Цена от 40 евро се увеличава с 10%. Колко евро става новата цена?",
    "Мария има 24 лв. Купува книга за 9 лв. Колко лева ѝ остават?" => "Мария има 24 евро. Купува книга за 9 евро. Колко евро ѝ остават?",
    "Молив струва 2 лв, а гумата е с 1 лв по-евтина." => "Молив струва 2 евро, а гумата е с 1 евро по-евтина.",
    "24 − 9 = 15 лв." => "24 − 9 = 15 евро.",
    "Дете има 10 стотинки и купува дъвка за 4 стотинки. Колко стотинки му остават?" => "Дете има 10 цента и купува дъвка за 4 цента. Колко цента му остават?",
    "Дъвката струва 1 стотинка." => "Дъвката струва 1 цент."
  }.each do |lev, euro|
    it "rewords „#{lev[0, 40]}…“" do
      expect(described_class.convert(lev)).to eq(euro)
    end
  end

  # „лева" is also "left", and „Лев" a name: the word is money only where an
  # amount is being said.
  it "leaves „лева“ alone where it is not an amount" do
    [ "В лева колона има 5 числа, а в дясната — 3.", "Лев има 7 молива.", "Плевен е на 150 км.", "клевета" ].each do |text|
      expect(described_class.convert(text)).to eq(text)
      expect(described_class.mentions?(text)).to be(false)
    end
  end

  it "rewords the word after an amount, „колко“ or „няколко“" do
    expect(described_class.convert("Има 5 лева и няколко лева в джоба. Колко лева са общо?"))
      .to eq("Има 5 евро и няколко евро в джоба. Колко евро са общо?")
  end

  it "rewords every string of a document and nothing else" do
    doc = { "type" => "doc", "content" => [ { "type" => "paragraph", "content" => [ { "type" => "text", "text" => "Билет струва 7 лв." } ] } ] }

    converted = described_class.convert_doc(doc)

    expect(converted.dig("content", 0, "content", 0, "text")).to eq("Билет струва 7 евро.")
    expect(converted["type"]).to eq("doc")
  end

  it "is the same after a second pass" do
    once = described_class.convert("Билет струва 7 лв. Колко лева струват 5?")

    expect(described_class.convert(once)).to eq(once)
  end
end
