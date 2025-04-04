desc "Drops all database connection"
task drop_connections: :environment do
  env = Rails.env
  config = Rails.configuration.database_configuration[env]
  raise "Could not find db config entry for environment = #{env}" unless config

  database = config["primary"]["database"]

  ActiveRecord::Base.connection.execute <<-SQL.squish
    SELECT pg_terminate_backend(pg_stat_activity.pid)
    FROM pg_stat_activity
    WHERE pg_stat_activity.datname = '#{database}'
      AND pid <> pg_backend_pid();
  SQL
  ActiveRecord::Base.remove_connection
end

task drop: :drop_connections
