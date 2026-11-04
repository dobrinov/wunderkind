require "spec_helper"
require "yaml"

# CLAUDE.md is loaded into every Claude Code session and Claude Code warns
# past 150k characters. Area detail lives in .claude/rules/*.md, which load
# only when a matching file is touched; this keeps the split from eroding.
RSpec.describe "CLAUDE.md" do
  root = File.expand_path("../..", __dir__)
  claude_md = File.read(File.join(root, "CLAUDE.md"))
  rules = Dir[File.join(root, ".claude/rules/*.md")].sort

  it "stays within its budget" do
    expect(claude_md.length).to be < 30_000,
      "CLAUDE.md is #{claude_md.length} chars: put area detail in .claude/rules/ instead"
  end

  it "lists every rule file in its index" do
    rules.each do |path|
      expect(claude_md).to include("`.claude/rules/#{File.basename(path)}`")
    end
  end

  it "gives every rule file paths to load on" do
    rules.each do |path|
      front = File.read(path)[/\A---\n(.*?)\n---\n/m, 1]
      expect(front).not_to be_nil, "#{path} has no frontmatter"
      paths = YAML.safe_load(front)["paths"]
      expect(paths).to be_an(Array).and(be_present_array), "#{path} has no paths:"
    end
  end

  RSpec::Matchers.define(:be_present_array) { match { |a| a.any? } }
end
