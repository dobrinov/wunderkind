# Renders the rich question documents (a restricted ProseMirror-style JSON tree)
# to HTML, and projects them to plain text for search and AI prompting.
#
# Supported nodes: doc, paragraph, text (bold/italic marks), math (inline LaTeX),
# hardBreak. Anything unknown is ignored, so a document can never inject markup.
module RichContent
  module_function

  def render(doc)
    return "" if doc.blank?

    render_nodes(Array(doc["content"])).html_safe
  end

  def plain_text(doc)
    return "" if doc.blank?

    Array(doc["content"]).map { |node| node_text(node) }.join("\n").strip
  end

  # A fraction as a problem file writes it: "3/4", "1/2 от 12". The bank is
  # authored as plain text, but "3/4" is not how a fraction is written in a
  # maths problem, so the text-to-document conversion promotes each one to a
  # math node and it is set over its bar like the textbook sets it. Guarded on
  # both sides so a decimal ("0,5/2") and a run of slashes ("1/2/3") are left as
  # they were typed, and so a longer number is taken whole ("1/25", not "1/2").
  FRACTION = %r{(?<![\d,./])(\d+)/(\d+)(?![\d/]|[.,]\d)}

  # The inverse, for the plain-text projection: body_text is what the importer
  # dedupes on and what an export writes back to the file, so a promoted
  # fraction has to read back exactly as the source text wrote it.
  LATEX_FRACTION = %r{\\frac\{(-?\d+)\}\{(\d+)\}}

  def text_to_doc(text)
    paragraphs = text.to_s.split(/\r?\n/).map do |line|
      { "type" => "paragraph", "content" => inline_nodes(line) }
    end
    { "type" => "doc", "content" => paragraphs }
  end

  def inline_nodes(line)
    return [] if line.blank?

    nodes = []
    remainder = line.to_s

    while (match = FRACTION.match(remainder))
      nodes << { "type" => "text", "text" => match.pre_match } unless match.pre_match.empty?
      nodes << { "type" => "math", "attrs" => { "latex" => "\\frac{#{match[1]}}{#{match[2]}}" } }
      remainder = match.post_match
    end

    nodes << { "type" => "text", "text" => remainder } unless remainder.empty?
    nodes
  end

  def render_nodes(nodes)
    nodes.map { |node| render_node(node) }.join
  end

  def render_node(node)
    case node["type"]
    when "paragraph"
      "<p>#{render_nodes(Array(node['content']))}</p>"
    when "text"
      wrap_marks(ERB::Util.html_escape(node["text"].to_s), Array(node["marks"]))
    when "math"
      render_math(node.dig("attrs", "latex").to_s)
    when "hardBreak"
      "<br>"
    else
      ""
    end
  end

  # A fraction of plain integers is set with .frac — the CSS stacked fraction —
  # and not handed to KaTeX. A question body and the multiple-choice options
  # under it show fractions inches apart, and the options are plain strings with
  # no document to put a math node in, so KaTeX in one and .frac in the other
  # would put two different fractions on one card. The same three spans are
  # written in shared/_frac (for those values) and in lib/frac.js (for widget
  # labels); this is the third place, and all any of them do is stack two
  # numbers. Everything else in a math node is real LaTeX and goes to KaTeX.
  SIMPLE_FRACTION = %r{\A\\frac\{(-?\d+)\}\{(\d+)\}\z}

  def render_math(latex)
    match = SIMPLE_FRACTION.match(latex)
    return %(<span class="frac"><span>#{match[1]}</span><span>#{match[2]}</span></span>) if match

    escaped = ERB::Util.html_escape(latex)
    %(<span data-controller="math" data-math-latex-value="#{escaped}">#{escaped}</span>)
  end

  def wrap_marks(html, marks)
    marks.reduce(html) do |inner, mark|
      case mark["type"]
      when "bold" then "<strong>#{inner}</strong>"
      when "italic" then "<em>#{inner}</em>"
      else inner
      end
    end
  end

  def math_text(latex)
    latex.gsub(LATEX_FRACTION, '\\1/\\2')
  end

  def node_text(node)
    case node["type"]
    when "text" then node["text"].to_s
    when "math" then math_text(node.dig("attrs", "latex").to_s)
    when "hardBreak" then " "
    else Array(node["content"]).map { |child| node_text(child) }.join
    end
  end
end
