class UsersController < ApplicationController
  layout "simple"

  # Self-registration covers students, teachers, and parents; admins are
  # promoted by hand. Teachers and parents must verify their email before they
  # can act on other people's children — while `Mailing` is off, nothing
  # is mailed and nothing is gated.
  SELF_SERVICE_ROLES = %w[student teacher parent].freeze

  rate_limit to: 5, within: 1.minute, only: :create

  def new
    @user = User.new
  end

  def create
    role = SELF_SERVICE_ROLES.include?(params[:role]) ? params[:role] : "student"
    @user = User.new_student(
      name: params[:name],
      email: params[:email],
      password: params[:password],
      role: role
    )

    if @user.save
      # Same as signing in: a fresh session id, so a session fixed before the
      # account existed can't ride into it.
      reset_session
      session[:user_id] = @user.id
      UserMailer.email_verification(@user).deliver_later if Mailing.enabled? && !@user.student?
      redirect_to post_auth_path(@user), notice: t("auth.welcome")
    else
      render :new, status: :unprocessable_entity
    end
  end
end
