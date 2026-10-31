namespace :past_papers do
  # Imports every paper under db/seeds/past (see PastPapers). Idempotent, like
  # problems:import: a problem is matched by its text, so running it again
  # updates rather than duplicates.
  desc "Import the real past papers in db/seeds/past into the bank"
  task import: :environment do
    count = PastPapers.import_all
    puts "Imported #{count} problems from past papers."
  end
end
