#!/usr/bin/ruby

$LOAD_PATH << 'lib'
require 'online_kitchen'

OnlineKitchen.setup

TOO_LONG_TIME = 1.hour.ago
VERY_LONG_TIME = 3.days.ago

def dump_machines(machines)
  machines.map do |m|
    'machine[%d]: %s, configuration: %d, created_at: %s, updated_at: %s' % [
      m.id,
      m.name,
      m.configuration_id,
      m.created_at,
      m.updated_at
    ]
  end.join("\n")
end

# check queued state doesnt take too long
lonq_queued = Machine.queued_older_than(TOO_LONG_TIME)
if lonq_queued.count > 0
  OnlineKitchen.logger.error(
    'Removing freezed machines in queued state: ' \
    "#{dump_machines(lonq_queued.to_a)}")
  lonq_queued.delete_all
end

# check destroy_queued machines without provider_id
machines = Machine.destroy_queued_machines_without_provider_id(TOO_LONG_TIME)
if machines.count > 0
  OnlineKitchen.logger.error(
    'Removing freezed machines in destroy_queued state without provider_id: ' \
    "#{dump_machines(machines.to_a)}")
  machines.delete_all
end

# check destroy_queued take too long => requeue
destroy_queued = Machine.destroy_queued_older_than(TOO_LONG_TIME)
if destroy_queued.count > 0
  OnlineKitchen.logger.error(
    'Reenqueues releasing freezed machines in destroy_queued state: ' \
    "#{dump_machines(destroy_queued.to_a)}")
  destroy_queued.find_each do |machine|
    OnlineKitchen::LabManagerRelease.perform_async(machine.id)
  end
end

# check destroy_queued and remove very old instances
freezed_machines = Machine.destroy_queued_older_than(VERY_LONG_TIME)
if freezed_machines.count > 0
  OnlineKitchen.logger.error(
    'Removing freezed machines in destroyed_queued state: ' \
    "#{dump_machines(freezed_machines.to_a)}")
  freezed_machines.delete_all
end

# check deleted state doesnt take too long
deleted_machines = Machine.deleted_older_than(TOO_LONG_TIME)
if deleted_machines.count > 0
  OnlineKitchen.logger.error(
    'Removing freezed machines in deleted state: ' \
    "#{dump_machines(deleted_machines.to_a)}")
  deleted_machines.delete_all
end

# check for empty configurations
empty_configurations = Configuration.empty_configurations
if empty_configurations.count > 0
  OnlineKitchen.logger.error(
    "Removing #{empty_configurations.count} empty configurations.")
  empty_configurations.delete_all
end
