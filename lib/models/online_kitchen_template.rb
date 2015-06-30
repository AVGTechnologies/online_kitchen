
class OnlineKitchenTemplate < Settingslogic
  source "#{OnlineKitchen.root}/config/templates.yml"
  namespace OnlineKitchen.env
  # TODO: suppres_errors OnlineKitchen.env.production?
  load!

  def all
    templates
  end
end
