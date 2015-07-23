require 'spec_helper'
require 'sidekiq/testing'

describe 'Machine' do
  let!(:machine) { Machine.new }
  subject { machine }

  it "sets deleted flag when appropriate state is set" do
    subject.state = "deleted"
    expect(machine.deleted?).to be true
  end

  it "sets destroy_queued flag when appropriate state is set" do
    subject.state = "destroy_queued"
    expect(machine.destroy_queued?).to be true
  end

  it "sets deleted_or_destroy_queued flag when deleted state is set" do
    subject.state = "deleted"
    expect(machine.deleted_or_destroy_queued?).to be true
  end

  it "sets deleted_or_destroy_queued flag when deleted state is set" do
    subject.state = "destroy_queued"
    expect(machine.deleted_or_destroy_queued?).to be true
  end

  it "sets state to destroy when schedule_destroy is called" do
    subject.schedule_destroy
    expect(machine.destroy_queued?).to be true
  end
end
