# Whether a right or wrong answer makes a sound. On by default: the cue is the
# fastest feedback in the app — it lands before the eye has found the card —
# and a child who does not want it turns it off from the speaker button on the
# practice screen, which writes this same column.
class AddSoundEffectsToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :sound_effects, :boolean, null: false, default: true
  end
end
