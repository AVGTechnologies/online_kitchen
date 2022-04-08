require 'benchmark'
require 'online_kitchen/workers/lab_manager_equip'

module OnlineKitchen
  # deploys specified machine via labManager
  class LabManagerDeploy
    include Sidekiq::Worker
    sidekiq_options queue: :lab_manager, retry: false

    def perform(deploy_arg)
      OnlineKitchen.logger.info "machine #{deploy_arg} deploying"
      return unless args_valid?(deploy_arg)

      machine_id = deploy_arg['machine_id']
      machine = Machine.find(machine_id)
      return unless machine_processable?(machine)

      unless deploy_arg['deployed']
        perform_deploy(machine, machine_id, deploy_arg)
        return
      end

      perform_deployed(machine, machine_id, deploy_arg)
    rescue ActiveRecord::RecordNotFound
      OnlineKitchen.logger.error "Deploy machine: record not found id: #{machine_id}"
      Metriks.meter('online_kitchen.worker.deploy.error').mark
      raise
    rescue Savon::SOAPFault => e
      OnlineKitchen.logger.error "Deploy machine id: #{machine_id}, soap error: #{e}"
      Metriks.meter('online_kitchen.worker.deploy.error').mark
      raise
    rescue PG::UnableToSend => e
      ::Raven.capture_exception(e)
      OnlineKitchen.logger.warn("PG::UnableToSend occurred, job: #{deploy_arg} re-enqueued")
      self.class.perform_in(rand(5..12).seconds, deploy_arg)
    end

    private

    def builder(machine)
      {
        vms_folder: machine.folder_name,
        image: machine.image,
        requestor: machine.user.name,
        job_id: machine.job_id,
        cluster: machine.cluster,
        env: machine.environment
      }
    end

    def perform_deploy(machine, machine_id, deploy_arg)
      deploy(machine)
      if machine.state != 'failed'
        OnlineKitchen.logger.info "Machine id:#{machine_id} is being deployed."
        self.class.perform_in(rand(1..5).seconds, deploy_arg.merge('deployed' => true))
      end
    end

    def perform_deployed(machine, machine_id, deploy_arg)
      if deployed?(machine)
        OnlineKitchen.logger.info "Machine id:#{machine_id} deployed."
        OnlineKitchen::LabManagerEquip.perform_in(
          rand(1..3).seconds,
          machine_id: machine_id,
          started: false,
          waited_ip: false
        )
        OnlineKitchen.logger.info "Machine id:#{machine_id} is scheduled to be equipped."
      else
        self.class.perform_in(rand(1..2).seconds, deploy_arg)
      end
    end

    def args_valid?(deploy_arg)
      result = true
      unless deploy_arg.key?('machine_id')
        OnlineKitchen.logger.warn('invalid argument given to LabManagerDeploy, processing canceled')
        result = false
      end

      unless deploy_arg.key?('deployed')
        OnlineKitchen.logger.warn('invalid argument given to LabManagerDeploy, processing canceled')
        result = false
      end

      result
    end

    def machine_processable?(machine)
      if machine.state == 'destroy_queued'
        OnlineKitchen.logger.info(
          "machine id:#{machine_id} has been scheduled for deletion, cancelling deploy process"
        )
        return false
      end

      true
    end

    def deploy(machine)
      time = Benchmark.realtime do
        state = 'ok'
        OnlineKitchen.logger.info("\e[1;31m MACHINE CLUSTER: #{machine.cluster} \e[0m")
        vm =
          begin
            OnlineKitchen::LabManager4.create(builder(machine))
          rescue OnlineKitchen::LabManager4::DeployError
            state = 'failed'
          end
        machine.reload

        machine.ip = 'n/a now'
        machine.provider_id = vm.name if state == 'ok'
        machine.state = state if state != 'ok'
        machine.save!
      end
      Metriks.timer('online_kitchen.worker.deploy').update(time)
    end

    def deployed?(machine)
      result = false
      time = Benchmark.realtime do
        machine.reload
        if OnlineKitchen::LabManager4
           .equip_machine_deployed?(
             machine.provider_id,
             cluster: machine.cluster
           )
          machine.state = 'deployed'
          machine.save!
          result = true
        end
      end

      Metriks.timer('online_kitchen.worker.deployed').update(time)
      result
    end
  end
end
