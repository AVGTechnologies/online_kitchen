require 'benchmark'
require 'online_kitchen/workers/lab_manager_provision'

class OnlineKitchen::LabManagerRelease
  include Sidekiq::Worker
  sidekiq_options queue: :lab_manager, retry: false

  def perform(machine_id)
    OnlineKitchen.logger.info "Releasing machine id:#{machine_id}"
    machine = Machine.find(machine_id)
    if machine.provider_id.blank?
      OnlineKitchen.logger.warn("Cannot release machine: #{machine_id} - provider_id is empty, reenqueueing...")
      self.class.perform_in(OnlineKitchen.config[:reenqueue_release_time].minutes, machine_id)
      return
    end
    time = Benchmark.realtime do
      vm = OnlineKitchen::LabManager.destroy(machine.provider_id)
      machine.update_attributes(state: :deleted)
      configuration = machine.configuration
      machine.destroy!
      configuration.schedule_destroy if configuration.machines.count == 0
    end
    OnlineKitchen.logger.info "Machine id:#{machine_id} destroyed in #{time.round(2)} seconds."
    Metriks.timer('online_kitchen.worker.release').update(time)
  rescue ActiveRecord::RecordNotFound
    OnlineKitchen.logger.error "Release machine: record not found id:#{machine_id}"
    Metriks.meter('online_kitchen.worker.release.error').mark
  rescue Savon::SOAPFault => err
    OnlineKitchen.logger.error "Release machine id:#{machine_id}, soap error: #{err}"
    Metriks.meter('online_kitchen.worker.release.error').mark
  end
end
