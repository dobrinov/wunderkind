module Overseer
  # The admin question browser and editor share one idea: the editor is opened
  # *from a list*, and carries that list's params as `from[...]` so its bar can
  # say „3 от 214", walk to the next question and come back to the same list.
  module QuestionsHelper
    def edit_listed_question_path(question, list)
      list ? edit_overseer_question_path(question, from: list.to_params) : edit_overseer_question_path(question)
    end

    def questions_list_path(list, selected: nil)
      params = list ? list.to_params : {}
      params = params.merge(selected: selected.id) if selected
      overseer_questions_path(params)
    end

    # The list's params as hidden fields, so a form posted from the editor
    # keeps the list it was opened from. Array params become `name[]` fields.
    def list_hidden_fields(list)
      return "".html_safe unless list

      safe_join(list.to_params.flat_map do |key, value|
        Array(value).map { |item| hidden_field_tag(value.is_a?(Array) ? "from[#{key}][]" : "from[#{key}]", item, id: nil) }
      end)
    end

    # The facet checkboxes and Elo inputs sit outside the search form (a form
    # cannot hold the preview pane's own buttons), so each names it.
    def filter_form_id = "question-filter"

    def answer_type_label(question)
      if question.interactive?
        t("widgets.#{question.widget_type}", default: question.widget_type.to_s)
      elsif question.multiple_choice?
        t("overseer.questions.browser.choice_count", count: question.possible_answers.size)
      else
        t("overseer.questions.answer_types.#{question.answer_type}")
      end
    end

    def question_number(question)
      "##{number_with_delimiter(question.id)}"
    end

    # A revision's changes in one line: the fields that moved, and for the
    # short ones (Elo, status) what they moved between.
    def revision_summary(revision)
      parts = revision.diff.map do |field, (before, after)|
        name = t("overseer.questions.editor.fields.#{field}")
        case field
        when "elo" then before ? "#{name} #{before} → #{after}" : "#{name} #{after}"
        when "status"
          words = [ before, after ].compact.map { |status| t("overseer.questions.statuses.#{status}") }
          "#{name}: #{words.join(' → ')}"
        else name
        end
      end
      parts.join(" · ").presence || t("overseer.questions.editor.history.nothing")
    end
  end
end
