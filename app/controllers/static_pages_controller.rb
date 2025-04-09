class StaticPagesController < ApplicationController
  layout "landingpage"

  def landingpage
    redirect_to calendar_path if current_user
  end

  def canvas
  end
end
