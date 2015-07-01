module OnlineKitchen
  class Config < Settingslogic
    source "#{OnlineKitchen.root}/config/online_kitchen.yml"
    namespace OnlineKitchen.env
    load!
  end
end
