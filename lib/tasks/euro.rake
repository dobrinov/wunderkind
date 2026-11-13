namespace :problems do
  # Rewrites the site's own published problems from leva to euro, in place:
  # the row keeps its id, its Elo and its answers, so nothing is re-imported
  # and no rating is reset (an import would add the euro wording as a new row
  # beside the old one). Past papers (`source` set) and problems with a figure
  # are left alone — a figure may print „лв." where the text cannot follow.
  # Safe to run twice. `DRY=1` only lists what would change.
  desc "Reword the site's own problems from leva to euro, in place"
  task euro: :environment do
    # Published only: the retired rows include the leva wordings the euro
    # corpus replaced, and rewording those would only make copies of what is
    # already served.
    scope = Question.published.where(source: nil).where("body_text ~ ? OR explanation ~ ?", "лв|лев|стотинк", "лв|лев|стотинк")
    changed = skipped = 0

    scope.includes(:possible_answers).find_each do |question|
      next unless EuroWording.mentions?(question.body_text) || EuroWording.mentions?(question.explanation) ||
                  question.possible_answers.any? { |option| EuroWording.mentions?(option.value) }

      if question.image
        skipped += 1
        puts "skipped (has a figure) ##{question.id}: #{question.body_text.squish[0, 80]}"
        next
      end

      puts "##{question.id}: #{question.body_text.squish[0, 70]} → #{EuroWording.convert(question.body_text).squish[0, 70]}"
      changed += 1
      next if ENV["DRY"].present?

      Question.transaction do
        question.update!(body: EuroWording.convert_doc(question.body), explanation: EuroWording.convert(question.explanation).presence)
        question.possible_answers.each do |option|
          option.update!(value: EuroWording.convert(option.value)) if EuroWording.mentions?(option.value)
        end
      end
    end

    puts "#{ENV["DRY"].present? ? "would reword" : "reworded"} #{changed}, skipped #{skipped} with a figure"
  end
end
