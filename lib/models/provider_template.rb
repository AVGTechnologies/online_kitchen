
class ProviderTemplate < Settingslogic
  source "#{OnlineKitchen.root}/config/templates.yml"
  namespace OnlineKitchen.env
  # TODO: suppres_errors OnlineKitchen.env.production?
  load!

  delegate :first, :last, :to_a, to: :templates

  def all
    templates
  end

  def include_image?(image)
    templates.any? do |s|
      parsed_cloud, parsed_image = s.split('.', 2)
      image == parsed_image
    end
  end

  #TODO add functionality for specific clusters?

end
