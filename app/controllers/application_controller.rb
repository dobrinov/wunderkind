class ApplicationController < ActionController::Base
  allow_browser versions: :modern

  def current_user
    @current_user ||= User.first
  end
end
