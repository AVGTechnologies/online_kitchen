require 'spec_helper'

describe 'LabManagerRelease' do
  let!(:lab_manager_release) { OnlineKitchen::LabManagerRelease.new }
  subject { lab_manager_release }
  let(:machine_in_ready_state) do
    FactoryGirl.build(:machine, state: :ready, provider_id: :provisioned_machine)
  end
  let(:configuration_in_ready_state) do
    FactoryGirl.build(:configuration, machines: [machine_in_ready_state])
  end

  it 'releases configuration once last machine is dropped' do
    expect(configuration_in_ready_state).to receive(:schedule_destroy).once
    allow(OnlineKitchen::LabManager4).to receive(:destroy)
    allow(Machine).to receive(:find).and_return(machine_in_ready_state)

    subject.perform(machine_in_ready_state.id)
  end
end
