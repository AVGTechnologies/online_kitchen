class OnlineKitchen::LabManagerProvision
  include Sidekiq::Worker

  def perform(machine_id)
    machine = Machine.find(machine_id)
    #TODO marks time to graphite
    vm = OnlineKitchen::LabManager.create(builder(machine))
    machine.reload #labmanage takes too long, model could be changed

    machine.ip = vm.ip
    machine.provider_id = vm.name
    machine.state = :ready

    machine.save!
  end

  private

    def builder(machine)
      {
        vms_folder: machine.folder_name,
        template_name: machine.template,
        requestor: machine.user,
        job_id: machine.job_id
      }
    end
end
