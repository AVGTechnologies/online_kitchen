 ENV['RACK_ENV'] = ENV['RAILS_ENV'] = ENV['RACK_ENV'] = ENV['ENV'] = 'test'

require 'rspec'
require 'factory_girl'
require 'factories'
require 'database_cleaner'
require File.expand_path('../../app.rb', __FILE__)

RSpec.configure do |config|

  config.before(:suite) do
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.clean_with(:truncation)
  end

  config.around(:each) do |example|
    DatabaseCleaner.cleaning do
      example.run
    end
  end

end
