require 'benchmark'

module OnlineKitchen
  # Releases machine via labManager
  class LabManagerRelease
    include Sidekiq::Worker
    sidekiq_options queue: :lab_manager, retry: false

    def perform(machine_id)
      OnlineKitchen.logger.info "Releasing machine id:#{machine_id}"
      machine = Machine.find(machine_id)
      if machine.provider_id.blank?
        reenqueue(machine_id)
      else
        release(machine_id)
      end
    rescue ActiveRecord::RecordNotFound
      OnlineKitchen.logger.error "Release machine: record not found id:#{machine_id}"
      Metriks.meter('online_kitchen.worker.release.error').mark
    rescue Savon::SOAPFault => e
      OnlineKitchen.logger.error "Release machine id:#{machine_id}, soap error: #{e}"
      Metriks.meter('online_kitchen.worker.release.error').mark
    rescue PG::UnableToSend => e
      ::Raven.capture_exception(e)
      OnlineKitchen.logger.warn("PG::UnableToSend occurred, job: #{machine_id} re-enqueued")
      self.class.perform_in(rand(5..12).seconds, machine_id)
    end

    private

    def reenqueue(machine_id)
      OnlineKitchen.logger
                   .warn("Cannot release machine: #{machine_id} - " \
                         'provider_id is empty, reenqueueing...')
      self.class.perform_in(OnlineKitchen.config[:reenqueue_release_time].minutes, machine_id)
    end

    def release(machine_id)
      machine = Machine.find(machine_id)
      time = Benchmark.realtime do
        OnlineKitchen::LabManager4.destroy(machine.provider_id, cluster: machine.cluster)
        machine.update_attributes(state: :deleted)
        configuration = machine.configuration
        machine.destroy!
        configuration.schedule_destroy if configuration.machines.count.zero?
      rescue OnlineKitchen::LabManager4::ReleaseError
        self.class.perform_in(rand(5..9).seconds, machine_id)
      end
      OnlineKitchen.logger.info "Machine id:#{machine_id} destroyed in #{time.round(2)} seconds."
      Metriks.timer('online_kitchen.worker.release').update(time)
    end
  end
end
