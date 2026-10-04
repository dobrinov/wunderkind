require "rails_helper"

describe "Telling people what changed", type: :request do
  let(:student) { create(:user) }

  # Behind by one release, whatever the file currently says.
  def behind!(user)
    previous = Changelog.entries[1]
    user.update!(last_changelog_version: previous.version)
    previous
  end

  describe Changelog do
    it "tells a brand new account nothing, and an account that predates the file everything" do
      create(:user).last_changelog_version.should eq(Changelog.current_version)
      Changelog.unseen_for(create(:user)).should be_empty

      old_account = create(:user)
      old_account.update!(last_changelog_version: nil)
      Changelog.unseen_for(old_account).map(&:version).should eq(Changelog.entries.map(&:version))
    end

    it "compares versions rather than counting them" do
      Changelog.newer?("1.10.0", "1.9.0").should be(true)
      Changelog.newer?("1.9.0", "1.10.0").should be(false)
      Changelog.newer?("1.2.0", "1.2.0").should be(false)
    end

    it "says nothing rather than everything when the stored version is not a version" do
      student.update!(last_changelog_version: "yesterday")

      Changelog.unseen_for(student).should be_empty
    end

    # The file is written by hand and read by children; these are the three
    # ways a hand-written file goes wrong without anybody noticing.
    describe "the shipped file" do
      # Changelog.parse swallows a malformed file so a typo cannot take sign-up
      # and every signed-in page down with it. This is where it fails instead.
      it "parses at all" do
        Changelog.entries.should be_present
        Changelog.current_version.should be_present
      end

      it "is in ascending version order with no duplicates" do
        versions = Changelog.entries.reverse.map { |entry| Gem::Version.new(entry.version) }

        versions.should eq(versions.sort)
        versions.uniq.should eq(versions)
      end

      it "carries both locales, with text in each" do
        Changelog.entries.each do |entry|
          %w[bg en].each do |locale|
            entry.titles[locale].to_s.should_not be_blank
            entry.item_lists[locale].should be_present
            entry.item_lists[locale].each { |item| item.to_s.should_not be_blank }
          end
        end
      end

      it "speaks to the people who use the app, not about the code" do
        jargon = /\b(controller|migration|refactor|endpoint|deploy|database|API|Elo|CSS)\b/i

        Changelog.entries.each do |entry|
          entry.item_lists.values.flatten.each do |item|
            item.should_not match(jargon)
          end
        end
      end
    end
  end

  describe "the dialog" do
    it "greets a user who is behind and names the release" do
      release = behind!(student)

      sign_in student
      get "/calendar"

      response.body.should include("changelog-dialog")
      response.body.should include(Changelog.entries.first.title)
      response.body.should_not include(release.title)
    end

    it "stays away from a user who is caught up" do
      sign_in student
      get "/calendar"

      response.body.should_not include("changelog-dialog")
    end

    it "is answered once, for every release at once" do
      behind!(student)

      sign_in student
      patch "/changelog"

      student.reload.last_changelog_version.should eq(Changelog.current_version)
      get "/calendar"
      response.body.should_not include("changelog-dialog")
    end

    it "does not interrupt a practice session, which uses another layout" do
      behind!(student)
      assignment = Assignment.create!(user: student)
      aq = assignment.assignment_questions.create!(question: create(:question), position: 1)

      sign_in student
      get "/questions/#{aq.id}"

      response.should have_http_status(:ok)
      response.body.should_not include("changelog-dialog")
    end
  end

  describe "the page" do
    it "lists every release, oldest last, and counts as having been told" do
      behind!(student)

      sign_in student
      get "/changelog"

      Changelog.entries.each { |entry| response.body.should include(entry.title) }
      student.reload.last_changelog_version.should eq(Changelog.current_version)
    end
  end

  describe "while an admin is viewing someone else's account" do
    let(:admin) { create(:user, role: :admin) }

    it "shows nothing and stamps nothing — the notes are not addressed to the admin" do
      behind!(student)

      sign_in admin
      post "/impersonate/#{student.id}"
      get "/calendar"

      response.body.should_not include("changelog-dialog")

      get "/changelog"
      response.should have_http_status(:ok)
      student.reload.last_changelog_version.should_not eq(Changelog.current_version)
    end
  end
end
