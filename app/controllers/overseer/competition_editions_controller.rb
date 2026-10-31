module Overseer
  # One year of a competition: its rounds (dates, exact or „около") and, when
  # that year's paper differed, its own format — see CompetitionEdition.
  class CompetitionEditionsController < BaseController
    before_action :set_competition
    before_action :set_edition, only: [ :edit, :update, :destroy ]

    def new
      @edition = @competition.editions.new(year: Time.zone.today.year)
      2.times { @edition.rounds.build }
    end

    def create
      @edition = @competition.editions.new(edition_params)
      if @edition.save
        redirect_to edit_overseer_competition_path(@competition.slug), notice: t("overseer.competitions.saved")
      else
        render :new, status: :unprocessable_content
      end
    end

    def edit
      2.times { @edition.rounds.build }
    end

    def update
      if @edition.update(edition_params)
        redirect_to edit_overseer_competition_path(@competition.slug), notice: t("overseer.competitions.saved")
      else
        render :edit, status: :unprocessable_content
      end
    end

    def destroy
      @edition.destroy!
      redirect_to edit_overseer_competition_path(@competition.slug), notice: t("overseer.competitions.edition_deleted", year: @edition.year)
    end

    private

    def set_competition
      @competition = Competition.find_by!(slug: params[:competition_slug])
    end

    def set_edition
      @edition = @competition.editions.find(params[:id])
    end

    def edition_params
      permitted = params.require(:competition_edition).permit(
        :year, format: %i[bg en],
        rounds_attributes: [ :id, :date, :approximate, :_destroy, { name: %i[bg en], note: %i[bg en] } ]
      )
      # An empty override means „as the competition usually is".
      permitted[:format] = nil if permitted[:format] && permitted[:format].values.all?(&:blank?)
      permitted
    end
  end
end
