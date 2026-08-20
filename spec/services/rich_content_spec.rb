require "rails_helper"

describe RichContent do
  let(:doc) do
    {
      "type" => "doc",
      "content" => [
        {
          "type" => "paragraph",
          "content" => [
            { "type" => "text", "text" => "Колко е " },
            { "type" => "text", "text" => "половината", "marks" => [ { "type" => "bold" } ] },
            { "type" => "math", "attrs" => { "latex" => "\\frac{1}{2}" } }
          ]
        }
      ]
    }
  end

  it "renders paragraphs, marks, and math spans" do
    html = RichContent.render(doc)

    html.should include("<p>Колко е <strong>половината</strong>")
    html.should include('data-controller="math"')
    html.should include("data-math-latex-value")
  end

  it "escapes HTML in text and latex" do
    xss = { "type" => "doc", "content" => [ { "type" => "paragraph", "content" => [ { "type" => "text", "text" => "<script>x</script>" } ] } ] }

    RichContent.render(xss).should_not include("<script>")
  end

  it "ignores unknown node types" do
    weird = { "type" => "doc", "content" => [ { "type" => "iframe", "attrs" => { "src" => "evil" } } ] }

    RichContent.render(weird).should eq("")
  end

  it "projects plain text" do
    RichContent.plain_text(doc).should eq("Колко е половината\\frac{1}{2}")
  end

  it "round-trips plain text into a document" do
    doc = RichContent.text_to_doc("първи ред\nвтори ред")

    RichContent.plain_text(doc).should eq("първи ред\nвтори ред")
  end
end
