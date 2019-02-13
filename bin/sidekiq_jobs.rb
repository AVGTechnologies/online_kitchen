$LOAD_PATH << 'lib'
require 'sidekiq'
require 'savon'
require 'online_kitchen'

OnlineKitchen.setup

Sidekiq::Logging.logger = OnlineKitchen.logger
Sidekiq::Logging.logger.level = OnlineKitchen.config.log_level
