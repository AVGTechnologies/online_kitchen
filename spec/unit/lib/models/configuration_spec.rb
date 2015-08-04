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

  it "validates name to contain only alphanumeric characters, dot and underscore" do
    goodConfiguration = FactoryGirl.build(:configuration, name: "MyFolder.Is_Good42")
    expect(goodConfiguration.valid?).to be true

    badConfiguration = FactoryGirl.build(:configuration, name: "čučoriedka")
    badConfiguration.valid?
    expect(badConfiguration.errors).to have_key(:name)
  end

end
