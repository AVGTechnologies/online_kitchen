require 'spec_helper'
require 'sidekiq/testing'
require 'rubygems'
require 'nokogiri'
require 'savon'

describe 'LabManager' do
  Sidekiq::Testing.fake!

  let(:labmanager) { OnlineKitchen::LabManager.new }
  subject { labmanager }

  let(:provision_specs) { {
      vms_folder: "folder_name",
      template_name: "super_template",
      requestor: "my.name",
      job_id: "job_id"
  } }

  context 'interface' do

    context 'has implemented property' do
      it "vm" do
        expect(subject).to respond_to(:vm)
      end
    end

    context 'has implemented method' do

      context ' in class' do

        it "create" do
          expect(subject.class).to respond_to(:create)
        end

        it "release_machine" do
          expect(subject.class).to respond_to(:release_machine)
        end

        it "client" do
          expect(subject.class).to respond_to(:client)
        end

        it "client_config" do
          expect(subject.class).to respond_to(:client_config)
        end

      end

      it "ip" do
        expect(subject).to respond_to(:ip)
      end

      it "name" do
        expect(subject).to respond_to(:name)
      end

      it "provision_machine" do
        expect(subject).to respond_to(:provision_machine)
      end
    end

  end

  def override_use_of_default_savon_client
    response = double(Savon::Response)

    body = {
      provision_machine_response: {
        provision_machine_result: "<doc><IP>1.2.4.8</IP><name>maquinita</name></doc>"
      }
    }
    expect(response).to receive(:body).and_return(body)

    client = double(Savon)
    expect(client).to receive(:call).and_return(response).at_least(:once)

    allow(OnlineKitchen::LabManager).to receive(:client).and_return( client )
  end

  context 'destroy' do

    context 'when not provisioned first' do
      it 'does not raise' do
        expect { subject.destroy }.not_to raise_error
      end
    end

    context 'when provisioned' do
      it 'releases correctly' do
        override_use_of_default_savon_client

        subject.provision_machine(provision_specs)
        subject.destroy
        expect(subject.vm).to be {}
      end
    end

  end

  context 'provision_machine' do
    it 'sets ip and name' do
      override_use_of_default_savon_client

      subject.provision_machine(provision_specs)

      expect(subject.ip).to eq("1.2.4.8")
      expect(subject.name).to eq("maquinita")
    end
  end
end
