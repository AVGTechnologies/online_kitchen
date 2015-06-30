module OnlineKitchen
  module Database
    class << self

      def config
        YAML.load(File.read(File.join(OnlineKitchen.root, 'config', 'database.yml')))
      end

      def connect
        #ActiveRecord::Base.default_timezone = OnlineKitchen.config[:time_zone]
        ActiveRecord::Base.logger = OnlineKitchen.logger

        ActiveRecord::Base.configurations = Database.config
        ActiveRecord::Base.establish_connection(OnlineKitchen.env.to_sym)
      end
    end
  end
end
