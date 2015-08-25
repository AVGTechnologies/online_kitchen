require 'spec_helper'

describe 'Machine' do
  let!(:machine) { Machine.new }
  subject { machine }

  it 'sets deleted flag when appropriate state is set' do
    subject.state = 'deleted'
    expect(machine.deleted?).to be true
  end

  it 'sets destroy_queued flag when appropriate state is set' do
    subject.state = 'destroy_queued'
    expect(machine.destroy_queued?).to be true
  end

  it 'sets deleted_or_destroy_queued flag when deleted state is set' do
    subject.state = 'deleted'
    expect(machine.deleted_or_destroy_queued?).to be true
  end

  it 'sets deleted_or_destroy_queued flag when deleted state is set' do
    subject.state = 'destroy_queued'
    expect(machine.deleted_or_destroy_queued?).to be true
  end

  it 'sets state to destroy when schedule_destroy is called' do
    subject.schedule_destroy
    expect(machine.destroy_queued?).to be true
  end

  it 'converts template with cluster to cluster and image' do
    machine.template = 'alvin.TA_7x64'

    expect(machine.cluster).to eq('alvin')
    expect(machine.image).to eq('TA_7x64')
  end

  it 'allows to write and read template' do
    machine.template = 'alvin.TA_7x64'

    expect(machine.template).to eq('alvin.TA_7x64')
    expect(machine.cluster).to eq('alvin')
    expect(machine.image).to eq('TA_7x64')
  end

  it 'contains template field when represented as json' do
    expect(machine.as_json).to have_key('template')
  end

  context 'when state is ready' do
    let(:machine) { FactoryGirl.build(:machine, state: 'ready', provider_id: nil) }

    it 'validates provider_id presence' do
      expect(machine.valid?).to be false
      expect(machine.errors).to have_key(:provider_id)
    end
  end

  it 'validates name for alphanumeric, bracket and special characters' do
    properly_named_machine = FactoryGirl.build(:machine, name: 'Az9#()<>:|[]/\\-')

    expect(properly_named_machine.valid?).to be true
  end
end
