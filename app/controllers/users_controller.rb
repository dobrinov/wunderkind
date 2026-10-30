class UsersController < ApplicationController
  layout "simple"

  # Self-registration covers students and parents; admins are promoted by
  # hand. Parents must verify their email before they can act on other
  # people's children — while `Mailing` is off, nothing is mailed and nothing
  # is gated.
  SELF_SERVICE_ROLES = %w[student parent].freeze

  rate_limit to: 5, within: 1.minute, only: :create

  # Two steps on one URL: with no role in it the page asks „Кой си ти?", with
  # one it is the short form for that role. A role dropdown under the email
  # field was the last thing a parent read, after typing their own name into a
  # form they took to be the child's — so the question that decides what the
  # rest of the form means is asked first, and asked as two links, which need
  # no JavaScript and give the browser's back button somewhere to go.
  def new
    @role = params[:role] if SELF_SERVICE_ROLES.include?(params[:role])
    @user = User.new
  end

  def create
    # A post with no role is a student, as it always was: that is what every
    # form before the chooser sent, and what a student-only form still sends.
    role = SELF_SERVICE_ROLES.include?(params[:role]) ? params[:role] : "student"
    @role = role
    @user = User.new_student(
      name: params[:name],
      email: params[:email],
      password: params[:password],
      role: role,
      name_for_children: (params[:name_for_children].to_s.strip.presence if role == "parent")
    )
    invitation = family_invitation_for(role)

    if family_invitation_refused?(invitation)
      render :new, status: :unprocessable_entity
    elsif @user.save
      join_family(invitation) if invitation
      # Same as signing in: a fresh session id, so a session fixed before the
      # account existed can't ride into it.
      reset_session
      session[:user_id] = @user.id
      @user.logged_in!
      UserMailer.email_verification(@user).deliver_later if Mailing.enabled? && !@user.student? && @user.verified_at.nil?
      # After reset_session, or the flash the event rides on is thrown away with
      # the session it was written into.
      track :signup, role: @user.role
      enter_competition(@user)
      # A new student is taken straight to the placement session. It is the one
      # moment where eight questions are worth more than any amount of
      # onboarding copy, and it is the only time the app can honestly say
      # „here is where you are starting".
      redirect_to(@user.student? ? new_placement_path : post_auth_path(@user),
                  notice: t("auth.welcome"))
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  # A parent signing up from an invitation link (the token rides in the form
  # on FamilyInvitationsController#show) or with a code typed into the parent
  # form. Only a parent's form carries either.
  def family_invitation_for(role)
    return nil unless role == "parent"

    if params[:family_token].present?
      FamilyInvitation.find_pending_by_token(params[:family_token])
    elsif params[:family_code].present?
      FamilyInvitation.find_by_code(params[:family_code])
    end
  end

  # A code that leads nowhere refuses the whole form rather than creating an
  # account that silently joined nothing — the person typed it expecting a
  # family on the other side. A spent link is the same, said on its own page.
  def family_invitation_refused?(invitation)
    return false if invitation || @role != "parent"
    return false if params[:family_token].blank? && params[:family_code].blank?

    @user.errors.add(:base, t("family.join.invalid_code"))
    true
  end

  # The invitation reached this address if it was mailed to it, which is what
  # confirming an email proves — so that account starts confirmed, the stance
  # a completed password reset takes.
  def join_family(invitation)
    @user.update!(verified_at: Time.current) if invitation.email.present? && invitation.email == @user.email&.downcase
    invitation.accept!(@user)
  rescue FamilyInvitation::Refused
    # Spent between the form loading and the account being made: the account
    # stands, and the family page offers the code box to try again.
    nil
  end

  # A visitor who pressed „Ще участвам" on a public competition page arrives
  # here with the competition in the URL; the account they make is entered in
  # it, so the press was not wasted on a sign-up form. Anything that is not a
  # competition is ignored — it came from a URL.
  def enter_competition(user)
    event = Competitions.find(params[:competition]) if params[:competition].present?
    return unless event && user.student?

    user.competition_entries.find_or_create_by!(competition_slug: event.slug, season: event.season)
  end
end
