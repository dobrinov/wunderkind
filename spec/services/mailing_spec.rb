require "rails_helper"

describe Mailing do
  around do |example|
    saved = ENV["SMTP_ADDRESS"]
    example.run
  ensure
    ENV["SMTP_ADDRESS"] = saved
  end

  it "is on exactly when the environment names an SMTP server" do
    ENV["SMTP_ADDRESS"] = nil
    Mailing.enabled?.should be(false)

    ENV["SMTP_ADDRESS"] = "smtp.example.com"
    Mailing.enabled?.should be(true)
  end
end
