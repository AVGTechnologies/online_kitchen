require 'yaml'
require 'logger'
require 'active_record'
require 'raven'
require 'strip_attributes'
require 'settingslogic'
require 'online_kitchen/database'
require 'online_kitchen/labmanager'
require 'metriks'
require 'metriks/reporter/graphite'

module OnlineKitchen
  class << self

    def config
      OnlineKitchen::Config
    end

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

      Logger.level = config.log_level || Logger::WARN

      if config.sentry_dsn && env == 'production'
        ::Raven.configure do |config|
          config.dsn = OnlineKitchen.config.sentry_dsn
          config.excluded_exceptions = %w{Siatra::NotFound}
        end
      end

      Metriks::Reporter::Graphite.new(
        config.graphite.host,
        config.graphite.port,
        config.graphite.options || {}
      ) if config.graphite


    end
  end

  require 'online_kitchen/config'
  require 'models'
end
