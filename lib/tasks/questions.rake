namespace :questions do
  # The grade hold's per-problem half (TaughtFrom), written onto the questions
  # already in the bank without a whole re-import: ladder problems and the
  # arithmetic facts matched by text the way the importer matches them, past
  # papers and the problems modelled on them by their source. Idempotent; run
  # after editing config/problem_type_grades.yml.
  desc "Write each question's taught-from grade (config/problem_type_grades.yml, the fact rule, past papers' grade)"
  task taught_from: :environment do
    TaughtFrom.reset!
    files = Dir[Rails.root.join("db/seeds/ladders/*.yml")].sort + [ Rails.root.join("db/seeds/arithmetic_facts.yml").to_s ]
    by_grade = Hash.new { |hash, key| hash[key] = [] }

    files.each do |file|
      next unless File.exist?(file)

      problems = YAML.safe_load_file(file).fetch("problems")
      rungs = TaughtFrom.rungs_by_family(problems)
      problems.each do |problem|
        grade = TaughtFrom.for_row(problem, rungs: rungs[problem["family"]])
        by_grade[grade] << problem["text"] if grade
      end
    end

    updated = by_grade.sum do |grade, texts|
      texts.each_slice(1000).sum do |slice|
        Question.where(source: nil, body_text: slice).where("taught_from_grade IS DISTINCT FROM ?", grade).update_all(taught_from_grade: grade)
      end
    end
    updated += Question.where("source ->> 'grade' ~ '^[0-9]+$'").
      where("taught_from_grade IS DISTINCT FROM (source ->> 'grade')::int").
      update_all("taught_from_grade = (source ->> 'grade')::int")

    puts "#{updated} questions updated; #{Question.where.not(taught_from_grade: nil).count} of #{Question.count} carry a grade"
    puts Question.where.not(taught_from_grade: nil).group(:taught_from_grade).order(:taught_from_grade).count.map { |grade, count| "  #{grade}: #{count}" }
  end
end
