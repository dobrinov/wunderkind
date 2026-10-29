module PracticeFocusHelper
  # „Дроби, Ъгли и Площ" — the topics of a focus as a sentence says them.
  def focus_topic_names(focus)
    focus.topics.map(&:name).sort.to_sentence
  end

  # The child's half, said in the words the parent's preview promised.
  def focus_asked_by(focus)
    PracticeFocuses.asked_by(focus)
  end
end
