require 'benchmark'
require 'online_kitchen/workers/lab_manager_provision'

module OnlineKitchen
  # Prepares specified machine via labManager
  class LabManagerProvision
    include Sidekiq::Worker
    sidekiq_options queue: :lab_manager, retry: false

    def perform(machine_id)
      OnlineKitchen.logger.info "Provision machine id:#{machine_id}"

      machine = Machine.find(machine_id)
      return if machine.state == 'destroy_queued'

      provision(machine)
      OnlineKitchen.logger.info "Machine id:#{machine_id} provisioned."
    rescue ActiveRecord::RecordNotFound
      OnlineKitchen.logger.error "Provision machine: record not found id: #{machine_id}"
      Metriks.meter('online_kitchen.worker.provision.error').mark
      raise
    rescue Savon::SOAPFault => err
      OnlineKitchen.logger.error "Provision machine id: #{machine_id}, soap error: #{err}"
      Metriks.meter('online_kitchen.worker.provision.error').mark
      raise
    rescue PG::UnableToSend => exception
      ::Raven.capture_exception(exception)
      OnlineKitchen.logger.warn("PG::UnableToSend occurred, job: #{machine_id} re-enqueued")
      self.class.perform_in(rand(5..12).seconds, machine_id)
    end

    private

    def builder(machine)
      {
        vms_folder: machine.folder_name,
        image: machine.image,
        requestor: machine.user.name,
        job_id: machine.job_id
      }
    end

    def provision(machine)
      time = Benchmark.realtime do
        vm = OnlineKitchen::LabManager4.create(builder(machine))
        machine.reload # labmanager takes too long, model could be changed

        machine.ip = vm.ip
        machine.provider_id = vm.name
        machine.state = 'ready'
        machine.save!
      end
      Metriks.timer('online_kitchen.worker.provision').update(time)
    end
  end
end
