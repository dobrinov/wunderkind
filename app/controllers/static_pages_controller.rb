class StaticPagesController < ApplicationController
  layout "landingpage"

  def landingpage
    redirect_to home_path_for(current_user) if current_user
  end
end
