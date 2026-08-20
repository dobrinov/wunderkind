module AuthHelpers
  def sign_in(user, password: "secret123")
    post "/sign-in", params: { email: user.email, password: password }
  end
end

RSpec.configure do |config|
  config.include AuthHelpers, type: :request
end
