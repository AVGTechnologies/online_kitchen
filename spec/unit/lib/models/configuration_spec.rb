require 'spec_helper'

describe 'Configuration' do

  describe "state" do

    let!(:configuration) { FactoryGirl.build(:configuration, machines: [])  }
    subject { configuration }

    it "equals 'ready' when all machines ready" do
      configuration.machines = FactoryGirl.build_list(:machine, 2, state: :ready)

      expect(subject.state).to eq 'ready'
    end

    it "equals 'destroy_queued' when all machines destroy_queued" do
      configuration.machines = FactoryGirl.build_list(:machine, 2, state: :destroy_queued)

      expect(subject.state).to eq 'destroy_queued'
    end

    it "equals 'updating' when some machine is not in final state" do
      configuration.machines = FactoryGirl.build_list(:machine, 2, state: :queued)
      configuration.machines.last.state = 'ready'

      expect(subject.state).to eq 'updating'
    end

  end
end
