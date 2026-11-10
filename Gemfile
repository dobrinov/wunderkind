source "https://rubygems.org"

gem "rails", "~> 8.1.4"
gem "propshaft"
gem "pg", "~> 1.1"
gem "puma", ">= 5.0"
gem "jsbundling-rails"
gem "tailwindcss-rails"
gem "stimulus-rails"
gem "turbo-rails"
gem "image_processing"
gem "jbuilder"
gem "bcrypt", "~> 3.1.22"
gem "tzinfo-data", platforms: %i[ windows jruby ]
gem "kaminari"
gem "sentry-ruby"
gem "sentry-rails"
gem "tracetells"

gem "bootsnap", require: false
gem "thruster", require: false
gem "aws-sdk-s3", require: false

group :development, :test do
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"
  gem "brakeman", require: false
  gem "rubocop-rails-omakase", require: false
  gem "dotenv"
end

group :test do
  gem "rspec-rails"
  gem "factory_bot_rails"
  gem "faker"
end

group :development do
  gem "web-console"
end

# Push notifications for duel invitations (WebPushDelivery). It wants the
# openssl gem; pinned to the version Ruby 3.4.2 ships as a default gem, because
# a newer one is a native build the image has no libssl-dev for.
gem "web-push", "~> 3.1"
gem "openssl", "3.3.0"
