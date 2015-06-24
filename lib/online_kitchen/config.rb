module OnlineKitchen
  class << self
    def config
      {
        sentry_dsn: '',
        log_level: Logger::DEBUG,
        time_zone: :utc
      }
    end
  end
end
