require 'spec_helper'
require 'sidekiq/testing'

describe 'Machine' do
  let(:machine) { Machine.new }

  it "sets deleted flag when appropriate state is set" do
    machine.state = "deleted"
    expect(machine.deleted?).to be true
  end

  it "sets destroy_queued flag when appropriate state is set" do
    machine.state = "destroy_queued"
    expect(machine.destroy_queued?).to be true
  end

  it "sets deleted_or_destroy_queued flag when deleted state is set" do
    machine.state = "deleted"
    expect(machine.deleted_or_destroy_queued?).to be true
  end

  it "sets deleted_or_destroy_queued flag when deleted state is set" do
    machine.state = "destroy_queued"
    expect(machine.deleted_or_destroy_queued?).to be true
  end

  it "sets state to destroy when schedule_destroy is called" do
    machine.schedule_destroy
    expect(machine.destroy_queued?).to be true
  end
end
