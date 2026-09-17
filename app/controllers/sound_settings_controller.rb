# The speaker button on the practice and duel screens, which is the same switch
# as the one in Настройки and writes the same column. Kept apart from
# ProfilesController#update because that action redirects and flashes, and this
# one is pressed in the middle of a question: the answer is a status code.
class SoundSettingsController < AuthenticatedController
  def update
    current_user.update!(sound_effects: ActiveModel::Type::Boolean.new.cast(params[:enabled]))

    head :no_content
  end
end
