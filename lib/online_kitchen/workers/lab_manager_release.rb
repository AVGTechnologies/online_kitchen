class OnlineKitchen::LabManagerRelease
  include Sidekiq::Worker

  def perform(machine_id)
    machine = Machine.find(machine_id)
    #TODO marks time to graphite
    vm = OnlineKitchen::LabManager.destroy(machine.provision_id)
    machine.destroy!
  end

end
