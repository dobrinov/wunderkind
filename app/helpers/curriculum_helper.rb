module CurriculumHelper
  # What a public page prints as the answer. A multiple-choice question keeps
  # its answer in the options, an exact-value one in the grading key, and an
  # interactive one has no answer that reads as a string at all — which is why
  # the samples are drawn from the first two.
  def curriculum_answer(question)
    if question.multiple_choice?
      question.correct_possible_answers.map(&:value).join(", ")
    else
      question.grading.to_h["expected"].to_s
    end
  end

  # "8 981" rather than "8981", and never the exact figure: the count moves with
  # every import and the page should not read as if it were counted by hand.
  def curriculum_rounded(count)
    return count.to_s if count < 100

    number_with_delimiter(count - (count % 100), delimiter: " ")
  end
end
