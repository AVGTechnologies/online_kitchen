
class OnlineKitchenTemplate < Settingslogic
  source "#{OnlineKitchen.root}/config/templates.yml"
  namespace OnlineKitchen.env
  load!

  def all
    templates
  end
end
