namespace :competitions do
  # Loads db/seeds/competitions.yml into the competitions tables — once, when
  # the tables arrived, and on a fresh database. Idempotent: a competition is
  # matched by slug and keeps the editions it has. After that the tables are
  # edited at /overseer/competitions.
  desc "Import db/seeds/competitions.yml into the competitions tables"
  task import: :environment do
    puts "Imported #{Competitions.import!} competitions."
  end
end
