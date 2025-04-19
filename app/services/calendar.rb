class Calendar
  class Date
    attr_reader :assignments

    def initialize(date, assignments, user)
      @date = date
      @assignments = assignments
      @user = user
    end

    def day
      @date.day
    end

    def past?
      @date < Time.zone.today
    end

    def future?
      @date > Time.zone.today
    end

    def today?
      @date == Time.zone.today
    end

    def after_user_creation?
      @date >= @user.created_at.to_date
    end

    def assignments?
      @assignments.any?
    end

    def completed?
      @assignments.any?(&:completed_at?)
    end

    def to_s
      @date.to_s
    end
  end

  def initialize(user)
    @user = user
    @today = Time.zone.today
    @start_date = @today.beginning_of_month.beginning_of_week
    @end_date = @today.end_of_month.end_of_week
    @assignments_by_date =
      user.
        assignments.
        where(created_at: @start_date..@end_date).
        group_by { _1.created_at.to_date }
  end

  def each(&block)
    (@start_date..@end_date).each do |date|
      block.call Date.new(date, @assignments_by_date.fetch(date, []), @user)
    end
  end
end
