require 'spec_helper'

describe 'Configuration' do

  let!(:configuration) { FactoryGirl.build(:configuration, machines: [])  }
  subject { configuration }

  describe "state" do

    it "equals 'ready' when all machines ready" do
      configuration.machines = FactoryGirl.build_list(:machine, 2, state: :ready)

      expect(subject.state).to eq 'ready'
    end

    it "equals 'destroy_queued' when all machines destroy_queued" do
      subject.machines = FactoryGirl.build_list(:machine, 2, state: :destroy_queued)

      expect(subject.state).to eq 'destroy_queued'
    end

    it "equals 'updating' when some machine is not in final state" do
      subject.machines = FactoryGirl.build_list(:machine, 2, state: :queued)
      subject.machines.last.state = 'ready'

      expect(subject.state).to eq 'updating'
    end

  end

  it "validates name to contain only alphanumeric characters, dot, space and underscore" do
    goodConfiguration = FactoryGirl.build(:configuration, name: "MyFolder.Is_Good 42")
    expect(goodConfiguration.valid?).to be true

    badConfiguration = FactoryGirl.build(:configuration, name: "čučoriedka")
    badConfiguration.valid?
    expect(badConfiguration.errors).to have_key(:name)
  end

  it "does not allow change of folder_name after creation" do
    subject.save!
    subject.folder_name = "and_now_for_something_completely_different"

    expect(subject.valid?).to be false
    expect(subject.errors).to have_key(:folder_name)
  end

  it "does set folder_name on creation to name of configuration" do
    subject.save!

    expect(subject.folder_name).to eq(subject.name)
  end

  it "does not allow name longer than 32 characters" do
    badConfiguration = FactoryGirl.build(:configuration,
      name: "This_Is_Indeed_A_Very_Long_Name_Whose_Usability_With_VMWare_Is_Risky")

    expect(badConfiguration.valid?).to be false
    expect(badConfiguration.errors).to have_key(:name)
  end


end
