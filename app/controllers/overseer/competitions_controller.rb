module Overseer
  # The competition calendar as data: every competition and exam with its
  # editions (one a year) and their rounds, and what needs the team's
  # attention — see Competitions and CompetitionAttention.
  class CompetitionsController < BaseController
    before_action :set_competition, only: [ :edit, :update, :next_edition ]

    def index
      @today = Time.zone.today
      @events = Competitions.calendar(@today)
      @flags = @events.to_h { |event| [ event.slug, CompetitionAttention.for(event, @today) ] }
      @papers = Question.published.where("questions.source ->> 'kind' = 'original'")
                        .group(Arel.sql("questions.source ->> 'competition'")).distinct
                        .count(Arel.sql("questions.source ->> 'year'"))
    end

    def new
      @competition = Competition.new(kind: "competition", style: "choice", grade_min: 1, grade_max: 4)
    end

    def create
      @competition = Competition.new(competition_params)
      if @competition.save
        redirect_to edit_overseer_competition_path(@competition.slug), notice: t("overseer.competitions.saved")
      else
        render :new, status: :unprocessable_content
      end
    end

    def edit; end

    def update
      if @competition.update(competition_params)
        redirect_to edit_overseer_competition_path(@competition.slug), notice: t("overseer.competitions.saved")
      else
        render :edit, status: :unprocessable_content
      end
    end

    # Next year's edition, copied from the last one a year on: the same rounds
    # a year later, every date marked approximate until the organiser
    # publishes it.
    def next_edition
      last = @competition.editions.includes(:rounds).last
      year = (last&.year || Time.zone.today.year) + 1
      edition = @competition.editions.create!(year: year, format: last&.format)
      last&.rounds&.each do |round|
        edition.rounds.create!(name: round.name, date: round.date.next_year, approximate: true, note: nil)
      end
      redirect_to edit_overseer_competition_edition_path(@competition.slug, edition), notice: t("overseer.competitions.edition_created", year: year)
    end

    private

    def set_competition
      @competition = Competition.find_by!(slug: params[:slug])
    end

    def competition_params
      permitted = params.require(:competition).permit(
        :slug, :kind, :short, :organizer, :grade_min, :grade_max, :style, :url, :archive_url, :grade_page,
        :programme_from, :programme_to, :topic_list,
        name: %i[bg en], description: %i[bg en], format: %i[bg en]
      )
      list = permitted.delete(:topic_list)
      permitted[:topic_names] = list.to_s.lines.map(&:strip).compact_blank unless list.nil?
      permitted
    end
  end
end
