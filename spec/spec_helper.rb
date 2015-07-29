ENV['RACK_ENV'] = ENV['RAILS_ENV'] = ENV['RACK_ENV'] = ENV['ENV'] = 'test'

require 'rspec'
require 'factory_girl'
require 'factories'
require 'database_cleaner'
require File.expand_path('../../app.rb', __FILE__)
require File.expand_path('../../lib/online_kitchen/labmanager.rb', __FILE__)

RSpec.configure do |config|

  config.filter_run focus: true
  config.run_all_when_everything_filtered = true

  config.before(:suite) do
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.clean_with(:truncation)
  end

  config.around(:each) do |example|
    DatabaseCleaner.cleaning do
      example.run
    end
  end

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

end
