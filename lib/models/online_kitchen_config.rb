
class OnlineKitchenConfig < Settingslogic
  source "#{OnlineKitchen.root}/config/online_kitchen.yml"
  namespace OnlineKitchen.env
  # TODO: suppres_errors OnlineKitchen.env.production?
  load!
end
