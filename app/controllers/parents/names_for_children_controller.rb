module Parents
  # „Как да те наричат децата?" — „Мама", „Тате", „Баба Ани". Shown wherever a
  # child reads who asked something of them, and to the other parent beside
  # each goal and reward, so two grown-ups in one family are told apart by the
  # name the children already use. Blank falls back to the first name.
  class NamesForChildrenController < BaseController
    def update
      current_user.update!(name_for_children: params[:name_for_children].to_s.strip.first(40).presence)
      redirect_to parents_children_path(anchor: "parents"), notice: t("family.parents.name_saved")
    end
  end
end
