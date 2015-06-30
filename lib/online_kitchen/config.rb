module OnlineKitchen
  class << self
    def config
      {
        sentry_dsn: '',
        log_level: Logger::DEBUG,
        time_zone: :utc,
        allowed_origin: '*',
        bind: '0.0.0.0',
        base_url: '/api/v1',
        soap_config: {
          service_config: {
            log_level: :debug,
            env_namespace: :s,
            namespace_identifier: nil,
            pretty_print_xml: true,
            log: true,
            element_form_default: :qualified,
            open_timeout: 1200,
            read_timeout: 1600
          },
          service_endpoint: 'http://10.5.0.26:8732/AVG.Ddtf.LabManager.Ivo/'
        }
      }
    end
  end
end
