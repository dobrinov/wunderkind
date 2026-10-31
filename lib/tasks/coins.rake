namespace :coins do
  # Once, at launch: every track counted from the rows that already exist and
  # minted silently — stamped seen, so nobody is greeted by a dozen coins for
  # last month. Safe to run again; it only adds what is missing.
  desc "Mint every coin the existing records have earned, silently"
  task backfill: :environment do
    minted = 0
    User.where(role: :student).find_each do |user|
      minted += Coins.refresh!(user, silent: true).size
    end
    puts "Minted #{minted} coins for #{User.where(role: :student).count} students."
  end
end
