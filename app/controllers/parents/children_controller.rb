module Parents
  class ChildrenController < BaseController
    def index
      @children = current_user.children.includes(:badge_awards)
    end

    def new
    end

    # Two paths in: link an existing student by their link code, or create a
    # fresh child account (the usual route for younger kids).
    def create
      if params[:link_code].present?
        link_existing_child
      else
        create_child_account
      end
    end

    private

    def link_existing_child
      child = User.student.find_by(link_code: params[:link_code].to_s.strip.upcase)

      if child.nil?
        redirect_to new_parents_child_path, alert: t("parents.children.invalid_code")
      elsif current_user.children.include?(child)
        redirect_to parents_children_path, notice: t("parents.children.already_linked", name: child.name)
      else
        current_user.parent_links.create!(child: child)
        redirect_to parents_children_path, notice: t("parents.children.linked", name: child.name)
      end
    end

    def create_child_account
      child = User.new_student(
        name: params[:name],
        email: params[:email],
        password: params[:password],
        role: :student
      )

      ActiveRecord::Base.transaction do
        child.save!
        current_user.parent_links.create!(child: child)
      end

      redirect_to parents_children_path, notice: t("parents.children.created", name: child.name)
    rescue ActiveRecord::RecordInvalid => error
      redirect_to new_parents_child_path, alert: error.record.errors.full_messages.join(", ")
    end
  end
end
