require 'yaml'
require 'logger'
require 'active_record'
require 'raven'
require 'strip_attributes'
require 'settingslogic'
require 'metriks'
require 'metriks/reporter/graphite'
require 'sidekiq'

module OnlineKitchen
  class << self

    def config
      OnlineKitchen::Config
    end

    def env
      ENV['ENV'] || ENV['RACK_ENV'] || ENV['RAILS_ENV'] || ENV['APP_ENV'] || 'development'
    end

    def logger
      @logger ||= Logger.new("#{root}/log/#{env}.log")
    end

    def root
      File.expand_path('../..', __FILE__)
    end

    def setup
      OnlineKitchen::Database.connect

      logger.level = config.log_level || Logger::WARN

      if config.log_level == Logger::DEBUG
        Sidekiq.default_worker_options = { 'backtrace' => true }
      end

      if config.sentry_dsn && env == 'production'
        ::Raven.configure do |config|
          config.dsn = OnlineKitchen.config.sentry_dsn
          config.excluded_exceptions = %w{Sinatra::NotFound}
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
  require 'online_kitchen/database'

  require 'models'

  require 'online_kitchen/labmanager'
  require 'online_kitchen/workers/lab_manager_provision'
  require 'online_kitchen/workers/lab_manager_release'
end
