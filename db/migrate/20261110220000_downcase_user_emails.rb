# Sign-in and the password reset look an address up in lower case, but sign-up
# stored it as typed, so an account made as „Ivan@…" could never sign in again.
# User now downcases on the way in; this brings the rows already stored into
# line. The unique index is on lower(email), so no two rows can collide.
class DowncaseUserEmails < ActiveRecord::Migration[8.1]
  def up
    execute "UPDATE users SET email = lower(email) WHERE email <> lower(email)"
  end

  def down
  end
end
