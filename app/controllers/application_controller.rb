class ApplicationController < ActionController::Base
  helper_method :current_user

  private

  def current_user
    @current_user ||= User.find_by(id: session[:user_id])
  end

  def home_path_for(user)
    case user.role
    when "admin" then overseer_root_path
    when "teacher" then teachers_classrooms_path
    when "parent" then parents_children_path
    else calendar_path
    end
  end
end
