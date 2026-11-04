module Parents
  # A child's name, birth year and school start, edited from their page.
  #
  # The birth year is what Dispatcher's grade hold and placement read
  # (SchoolGrade), and it is optional when a child is added — so a parent who
  # skipped it, or picked the wrong year, needs a way back to it that is not
  # „switch into the child, find Настройки". Any parent linked to the child
  # may set the two school fields; the name only for a managed child, whose
  # account lives inside the family — a child with a login of their own owns
  # their name.
  class ChildProfilesController < BaseController
    before_action :load_child

    def edit
    end

    def update
      attributes = {
        birth_year: params[:birth_year].presence,
        grade_offset: params[:grade_offset].presence || 0
      }
      attributes[:name] = params[:name].to_s.strip if @child.managed? && params[:name].present?

      if @child.update(attributes)
        redirect_to parents_child_path(@child), notice: t("parents.child_profile.saved", name: @child.name)
      else
        flash.now[:alert] = @child.errors.full_messages.to_sentence
        render :edit, status: :unprocessable_content
      end
    end

    private

    def load_child
      @child = current_user.children.find(params[:child_id])
    end
  end
end
