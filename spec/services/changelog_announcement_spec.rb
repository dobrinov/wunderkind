require "rails_helper"

RSpec.describe ChangelogAnnouncement do
  let(:dir) { Pathname.new(Dir.mktmpdir) }
  let(:state) { dir.join("announced") }
  let(:posted) { [] }
  let(:post) { ->(url, content) { posted << [ url, content ] } }
  let(:versions) { Changelog.entries.reverse.map(&:version) }

  after { FileUtils.rm_rf(dir) }

  def announce(url: "https://discord.example/hook")
    described_class.call(url: url, state_path: state, post: post)
  end

  it "does nothing without a webhook" do
    announce(url: nil).should eq(:disabled)
    state.exist?.should be(false)
  end

  it "only records the current version on its first run" do
    announce.should eq(:primed)
    posted.should be_empty
    state.read.should eq(Changelog.current_version)
  end

  it "posts every newer release once, oldest first" do
    state.write(versions[-3])

    announce.should eq(versions.last(2))
    posted.map(&:first).uniq.should eq([ "https://discord.example/hook" ])
    posted.first.last.should include(Changelog.entries.reverse[-2].titles["bg"])
    state.read.should eq(versions.last)

    announce.should eq([])
    posted.size.should eq(2)
  end

  it "keeps its place when a post fails halfway" do
    state.write(versions[-3])
    calls = 0
    failing = ->(_url, _content) { (calls += 1) == 2 ? raise("down") : nil }

    expect { described_class.call(url: "https://x", state_path: state, post: failing) }.to raise_error("down")
    state.read.should eq(versions[-2])
  end

  it "words a release in Bulgarian with its date and a link" do
    entry = Changelog.entries.first
    message = described_class.message_for(entry)
    message.should start_with("🆕 **#{entry.titles['bg']}**")
    message.should include(entry.date.year.to_s, "https://wunderkind.bg/changelog")
    message.length.should be <= described_class::MESSAGE_LIMIT
  end
end
