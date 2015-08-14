#!/usr/bin/ruby


$: << 'lib'
require 'online_kitchen'

OnlineKitchen.setup

TOO_LONG_TIME = 1.hour.ago
VERY_LONG_TIME = 3.days.ago

def dump_machines(machines)
  machines.map do |m|
    "machine[%d]: %s, configuration: %d, created_at: %s, updated_at: %s" % [
      m.id,
      m.name,
      m.configuration_id,
      m.created_at,
      m.updated_at
    ]
  end.join("\n")
end

# check queued state doesnt take too long
freezed_machines = Machine.where(state: 'queued').where('updated_at < ?', TOO_LONG_TIME)
if freezed_machines.count > 0
  OnlineKitchen.logger.error("Removing freezed machines in queued state: #{dump_machines(freezed_machines.to_a)}")
  freezed_machines.delete_all
end

# check destroy_queued machines without provider_id
freezed_machines = Machine.where(state: 'destroy_queued').where("(provider_id IS NULL) OR (provider_id = ?)", '').where('updated_at < ?', TOO_LONG_TIME)
if freezed_machines.count > 0
  OnlineKitchen.logger.error("Removing freezed machines in destroy_queued state without privider_id: #{dump_machines(freezed_machines.to_a)}")
  freezed_machines.delete_all
end

# check destroy_queued take too long => requeue
freezed_machines = Machine.where(state: 'destroy_queued').where('updated_at < ?', TOO_LONG_TIME)
if freezed_machines.count > 0
  OnlineKitchen.logger.error("Reenqueues releasing freezed machines in destroy_queued state: #{dump_machines(freezed_machines.to_a)}")
  freezed_machines.find_each do |machine|
    OnlineKitchen::LabManagerRelease.perform_async(machine.id)
  end
end

# check destroy_queued and remove very old instances
freezed_machines = Machine.where(state: 'destroy_queued').where('updated_at < ?', VERY_LONG_TIME)
if freezed_machines.count > 0
  OnlineKitchen.logger.error("Removing freezed machines in destroyed_queued state: #{dump_machines(freezed_machines.to_a)}")
  freezed_machines.delete_all
end

# check deleted state doesnt take too long
freezed_machines = Machine.where(state: 'deleted').where('updated_at < ?', TOO_LONG_TIME)
if freezed_machines.count > 0
  OnlineKitchen.logger.error("Removing freezed machines in deleted state: #{dump_machines(freezed_machines.to_a)}")
  freezed_machines.delete_all
end

# check for empty configurations
empty_configurations = Configuration.where('id NOT IN (SELECT DISTINCT(configuration_id) FROM machines)')
if empty_configurations.count > 0
  OnlineKitchen.logger.error("Removing #{empty_configurations.count} empty configurations.")
  empty_configurations.delete_all
end
