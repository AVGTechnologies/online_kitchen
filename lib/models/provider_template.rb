
class ProviderTemplate < Settingslogic
  source "#{OnlineKitchen.root}/config/templates.yml"
  namespace OnlineKitchen.env
  # TODO: suppres_errors OnlineKitchen.env.production?
  load!

  delegate :first, :last, :to_a, to: :templates

  def all
    templates
  end

  #TODO add functionality for specific clusters?

end
