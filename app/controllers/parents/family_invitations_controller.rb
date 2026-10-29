module Parents
  # The inviting half of „Покани втори родител" on the family page, and the
  # code box for the parent on the other end — see FamilyInvitation.
  #
  # An email invitation is mailed only while Mailing is on; with it off the row
  # still exists and the family page shows its link and code to pass on by
  # hand, so the feature works the same either way and only the envelope is
  # missing.
  class FamilyInvitationsController < BaseController
    # A code is six characters out of thirty, so guessing one is a matter of
    # attempts — limited the way signing in is.
    rate_limit to: Rails.env.local? ? 1000 : 10, within: 1.minute, only: :redeem

    # Joining is not acting on somebody else's child the way the email gate
    # means: a verified parent of these children chose to share them by
    # handing over the code. The new parent's own goals and settings stay
    # behind the gate until their address is confirmed.
    skip_before_action :require_verified_email, only: :redeem

    def create
      return redirect_to(parents_children_path, alert: t("family.invite.no_children")) unless current_user.children.exists?

      invitation = current_user.sent_family_invitations.new(email: params[:email].to_s.strip.presence)
      return redirect_to(parents_children_path(anchor: "parents"), alert: t("family.invite.email_required")) if invitation.email.nil?

      if invitation.save
        if Mailing.enabled?
          ParentMailer.family_invitation(invitation).deliver_later
          flash[:notice] = t("family.invite.sent", email: invitation.email)
        else
          flash[:notice] = t("family.invite.created")
        end
      else
        flash[:alert] = invitation.errors.full_messages.join(", ")
      end

      redirect_to parents_children_path(anchor: "parents")
    end

    # „Нов код": the code read out loud. Whatever code this parent had out is
    # withdrawn — a code is a thing said across a room, and one that may have
    # been overheard is replaced rather than added to.
    def code
      return redirect_to(parents_children_path, alert: t("family.invite.no_children")) unless current_user.children.exists?

      FamilyInvitation.transaction do
        current_user.sent_family_invitations.pending.where(email: nil).find_each(&:revoke!)
        current_user.sent_family_invitations.create!
      end

      redirect_to parents_children_path(anchor: "parents")
    end

    # Either parent of the family can take back an invitation either of them
    # sent: they are equals, and the card lists them all.
    def destroy
      invitation = FamilyInvitation.where(inviter_id: current_user.family_parents.select(:id)).find_by!(token: params[:token])
      invitation.revoke!

      redirect_to parents_children_path(anchor: "parents"), notice: t("family.invite.revoked")
    end

    # The other end: a parent typing the code they were given.
    def redeem
      invitation = FamilyInvitation.find_by_code(params[:code])
      return redirect_to(parents_children_path(anchor: "join"), alert: t("family.join.invalid_code")) if invitation.nil?

      invitation.accept!(current_user, name_for_children: params[:name_for_children])
      redirect_to parents_children_path, notice: t("family.join.joined", name: invitation.inviter.name)
    rescue FamilyInvitation::Refused => refusal
      redirect_to parents_children_path(anchor: "join"), alert: t("family.join.refused.#{refusal.reason}")
    end
  end
end
