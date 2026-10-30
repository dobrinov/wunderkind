class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  # The calendar day of a stored timestamp in the app's zone. Columns hold UTC
  # (timestamp without time zone), so a bare DATE() would cut days at UTC
  # midnight and disagree with Time.zone.today for three hours each night.
  def self.local_date_sql(column)
    "DATE((#{column} AT TIME ZONE 'UTC') AT TIME ZONE '#{Time.zone.tzinfo.name}')"
  end
end
