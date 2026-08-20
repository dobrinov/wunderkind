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

  def text_to_doc(text)
    paragraphs = text.to_s.split(/\r?\n/).map do |line|
      content = line.blank? ? [] : [ { "type" => "text", "text" => line } ]
      { "type" => "paragraph", "content" => content }
    end
    { "type" => "doc", "content" => paragraphs }
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
      latex = node.dig("attrs", "latex").to_s
      %(<span data-controller="math" data-math-latex-value="#{ERB::Util.html_escape(latex)}">#{ERB::Util.html_escape(latex)}</span>)
    when "hardBreak"
      "<br>"
    else
      ""
    end
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

  def node_text(node)
    case node["type"]
    when "text" then node["text"].to_s
    when "math" then node.dig("attrs", "latex").to_s
    when "hardBreak" then " "
    else Array(node["content"]).map { |child| node_text(child) }.join
    end
  end
end
