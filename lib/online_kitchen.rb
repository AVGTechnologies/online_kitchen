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
      
      setup_sidekiq
      setup_raven
      setup_metriks
    end
    
    def setup_sidekiq
      Sidekiq.default_worker_options = { 'backtrace' => true } if
        config.log_level == Logger::DEBUG
        
      Sidekiq.configure_server do |config|
        config.redis = OnlineKitchen.config.redis
      end
      
      Sidekiq.configure_client do |config|
        config.redis = OnlineKitchen.config.redis
      end      
    end

    def setup_raven
      return unless config.sentry_dsn

      ::Raven.configure do |config|
        config.dsn = OnlineKitchen.config.sentry_dsn
        config.current_environment = OnlineKitchen.env
        config.excluded_exceptions = %w(Sinatra::NotFound)
      end
    end

    def setup_metriks
      return unless config.graphite

      reporter = Metriks::Reporter::Graphite.new(
        config.graphite.host,
        config.graphite.port,
        config.graphite.options || {}
      )
      reporter.start
    end
  end

  require 'online_kitchen/config'
  require 'online_kitchen/database'

  require 'models'

  require 'online_kitchen/labmanager'
  require 'online_kitchen/workers/lab_manager_provision'
  require 'online_kitchen/workers/lab_manager_release'
end
