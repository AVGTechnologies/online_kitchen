require 'yaml'
require 'logger'
require 'active_record'
require 'raven'
require 'online_kitchen/config'
require 'online_kitchen/database'

require 'models/configuration'
require 'models/machine'

module OnlineKitchen
  class << self

    def env
      ENV['ENV'] || ENV['RACK_ENV'] || ENV['RAILS_ENV'] || ENV['APP_ENV'] || 'development'
    end

    def logger
      @logger ||= Logger.new(STDOUT)
    end

    def root_path
      File.expand_path('../..', __FILE__)
    end

    def setup
      OnlineKitchen::Database.connect

      Logger.level = OnlineKitchen.config[:log_level] || Logger::WARN

      if env == 'production'
        ::Raven.configure do |config|
          config.dsn = OnlineKitchen.config[:sentry_dsn]
          config.excluded_exceptions = %w{atra::NotFound}
        end
      end
    end

  end
end
