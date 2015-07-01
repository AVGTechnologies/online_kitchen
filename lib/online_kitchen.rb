require 'yaml'
require 'logger'
require 'active_record'
require 'raven'
require 'strip_attributes'
require 'settingslogic'
require 'online_kitchen/database'
require 'online_kitchen/labmanager'

module OnlineKitchen
  class << self

    def env
      ENV['ENV'] || ENV['RACK_ENV'] || ENV['RAILS_ENV'] || ENV['APP_ENV'] || 'development'
    end

    def logger
      @logger ||= Logger.new(STDOUT)
    end

    def root
      File.expand_path('../..', __FILE__)
    end

    def setup
      OnlineKitchen::Database.connect

      Logger.level = OnlineKitchenConfig.log_level || Logger::WARN

      if env == 'production'
        ::Raven.configure do |config|
          config.dsn = OnlineKitchenConfig.sentry_dsn
          config.excluded_exceptions = %w{atra::NotFound}
        end
      end
    end

  end

  require 'models'
end
