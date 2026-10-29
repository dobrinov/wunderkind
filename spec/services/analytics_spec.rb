require "rails_helper"

describe Analytics do
  describe ".enabled?" do
    it "is off outside production, where the script would only be noise" do
      Analytics.enabled?(build(:user)).should be(false)
    end

    it "is on for an ordinary visitor in production" do
      Rails.env.stub(:production?).and_return(true)

      Analytics.enabled?(nil).should be(true)
      Analytics.enabled?(build(:user)).should be(true)
    end

    # The owner is the heaviest user of this app by a distance, and on a site
    # this size their own sessions would be most of the dashboard.
    it "is off for an admin" do
      Rails.env.stub(:production?).and_return(true)

      Analytics.enabled?(build(:user, role: :admin)).should be(false)
    end
  end

  describe ".trace_identity" do
    it "is the same hash every time for one person and a different one for the next" do
      student, other = create(:user), create(:user)

      Analytics.trace_identity(student).should match(/\A\h{32}\z/)
      Analytics.trace_identity(student).should eq(Analytics.trace_identity(student))
      Analytics.trace_identity(other).should_not eq(Analytics.trace_identity(student))
    end

    # Trace counts people; it never gets anything it could look one up by.
    it "carries neither the id nor the email" do
      student = create(:user)
      identity = Analytics.trace_identity(student)

      identity.should_not eq(student.id.to_s)
      identity.should_not include(student.email.to_s)
    end

    it "is nothing for a visitor nobody signed in" do
      Analytics.trace_identity(nil).should be_nil
    end
  end

  describe ".event_name" do
    it "resolves a key to the name the dashboard matches character for character" do
      Analytics.event_name(:session_started).should eq("Session Started")
    end

    # A goal that never fires is invisible; a mistyped key should not be.
    it "raises on a name nothing declares" do
      -> { Analytics.event_name(:sessions_started) }.should raise_error(KeyError)
    end
  end
end
