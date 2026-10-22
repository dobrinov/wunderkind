# „Ще участвам" and taking it back. One entry per competition per season; a
# second press is a no-op rather than an error, since the button that sent it
# may be on a page that was open in another tab.
class CompetitionEntriesController < CompetitionsController
  def create
    entry = current_user.competition_entries.find_or_create_by!(competition_slug: event.slug, season: event.season)
    track :competition_joined, competition: event.slug if entry.previously_new_record?

    redirect_back_or_to competitions_path, notice: t("competitions.joined", name: event.name.to_s)
  end

  def destroy
    current_user.competition_entries.where(competition_slug: event.slug, season: event.season).destroy_all

    redirect_back_or_to competitions_path, notice: t("competitions.left", name: event.name.to_s)
  end
end
