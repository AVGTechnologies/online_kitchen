require 'benchmark'
require 'online_kitchen/workers/lab_manager_equip'

module OnlineKitchen
  # deploys specified machine via labManager
  class LabManagerEquip
    include Sidekiq::Worker
    sidekiq_options queue: :lab_manager, retry: false

    def perform(equip_arg)
      OnlineKitchen.logger.info "machine #{equip_arg} equipping"
      return unless args_valid?(equip_arg)

      machine_id = equip_arg['machine_id']
      machine = Machine.find(machine_id)
      return unless machine_processable?(machine)

      unless equip_arg['started']
        perform_start(machine, equip_arg)
        return
      end

      perform_ipwait(machine, machine_id, equip_arg) unless equip_arg['waited_ip']
    rescue ActiveRecord::RecordNotFound
      OnlineKitchen.logger.error "Machine equipment: record not found id: #{machine_id}"
      Metriks.meter('online_kitchen.worker.equip.error').mark
      raise
    rescue Savon::SOAPFault => e
      OnlineKitchen.logger.error "Machine equipment id: #{machine_id}, soap error: #{e}"
      Metriks.meter('online_kitchen.worker.equip.error').mark
      raise
    rescue PG::UnableToSend => e
      ::Raven.capture_exception(e)
      OnlineKitchen.logger.warn("PG::UnableToSend occurred, job: #{equip_arg} re-enqueued")
      self.class.perform_in(rand(5..12).seconds, equip_arg)
    end

    private

    def args_valid?(arg)
      result = true
      unless arg.key?('machine_id')
        OnlineKitchen.logger.warn('machine_id is not given to LabManagerEquip, processing canceled')
        result = false
      end

      unless arg.key?('started')
        OnlineKitchen.logger.warn('started is not given to LabManagerEquip, processing canceled')
        result = false
      end

      unless arg.key?('waited_ip')
        OnlineKitchen.logger.warn('started is not given to LabManagerEquip, processing canceled')
        result = false
      end

      result
    end

    def machine_processable?(machine)
      if machine.state != 'deployed'
        OnlineKitchen.logger.info "machine #{machine} not in state deployed, equipping aborted"
        return false
      end

      true
    end

    def perform_start(machine, equip_arg)
      OnlineKitchen::LabManager4.equip_machine_start(machine.provider_id)
      self.class.perform_in(
        rand(3..10).seconds,
        equip_arg.merge('started' => true)
      )
    end

    def perform_ipwait(machine, machine_id, equip_arg)
      time = Benchmark.realtime do
        info = OnlineKitchen::LabManager4.equip_machine_ip(machine.provider_id)
        if !!info == info
          self.class.perform_in(rand(1..3).seconds, equip_arg)
          OnlineKitchen.logger.info "Machine id:#{machine_id} equipment rescheduled."
        else
          machine.ip = info[:ip_addresses]
          machine.state = 'ready'
          machine.save!
          OnlineKitchen.logger.info "Machine id:#{machine_id} equipment finished successfully."
        end
      end
      Metriks.timer('online_kitchen.worker.equip').update(time)
    end
  end
end
