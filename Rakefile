require File.expand_path('../config/application', __FILE__)
require 'active_record'

require 'online_kitchen'

include ActiveRecord::Tasks

DatabaseTasks.env = Rails.env
DatabaseTasks.db_dir = File.join(Rails.root, 'config')
DatabaseTasks.database_configuration = OnlineKitchen::Database.config
DatabaseTasks.migrations_paths = File.join(Rails.root, 'db', 'migrate')

task :environment do
  ActiveRecord::Base.configurations = DatabaseTasks.database_configuration
  ActiveRecord::Base.establish_connection DatabaseTasks.env.to_sym
end

load 'active_record/railties/databases.rake'


