module Parents
  # „Покажи всичко веднага": a parent's switch to skip the gradual introduction
  # of duels, friends, leaderboards and the rest (FeatureVisibility) for a
  # child who already knows the app — an older sibling, a child moving over
  # from a classmate's account. Any linked child: it changes what the app
  # pushes forward, not what the child may use, so it is the parent's call
  # whether or not the child has a login of their own.
  class FeaturesController < BaseController
    def update
      child = current_user.children.find(params[:child_id])
      show_all = params[:show_all] == "1"
      child.update!(show_all_features: show_all)

      redirect_to parents_child_path(child, tab: "goals", anchor: "features"),
                  notice: t(show_all ? "parents.features.shown" : "parents.features.gradual", name: child.name)
    end
  end
end
