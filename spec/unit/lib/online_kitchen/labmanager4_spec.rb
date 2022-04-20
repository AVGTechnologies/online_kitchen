require 'spec_helper'
require 'sidekiq/testing'
require 'rubygems'
require 'nokogiri'
require 'savon'
require 'json'

describe 'LabManager' do
  Sidekiq::Testing.fake!

  let(:labmanager) { OnlineKitchen::LabManager4.new }
  subject { labmanager }

  let(:provision_specs) do
    {
      vms_folder: 'folder_name',
      image: 'super_template',
      requestor: 'my.name',
      job_id: 'job_id'
    }
  end

  context 'interface' do
    context 'has implemented property' do
      it 'vm' do
        expect(subject).to respond_to(:vm)
      end
    end

    context 'has implemented method' do
      context ' in class' do
        it 'create' do
          expect(subject.class).to respond_to(:create)
        end

        it 'release_machine' do
          expect(subject.class).to respond_to(:release_machine)
        end

        it 'equip_machine_ip' do
          expect(subject.class).to respond_to(:equip_machine_ip)
        end

        it 'get_config' do
          expect(subject.class).to respond_to(:get_config)
        end

        it 'equip_create_clean_snapshot' do
          expect(subject.class).to respond_to(:equip_create_clean_snapshot)
        end

        it 'equip_machine_start' do
          expect(subject.class).to respond_to(:equip_machine_start)
        end

        it 'equip_machine_deployed?' do
          expect(subject.class).to respond_to(:equip_machine_deployed?)
        end
      end

      it 'ip' do
        expect(subject).to respond_to(:ip)
      end

      it 'name' do
        expect(subject).to respond_to(:name)
      end

      it 'provision_machine' do
        expect(subject).to respond_to(:provision_machine)
      end

      it 'construct_deploy_body' do
        expect(subject).to respond_to(:construct_deploy_body)
      end

      it 'deploy_machine' do
        expect(subject).to respond_to(:deploy_machine)
      end

      it 'get_machine_id' do
        expect(subject).to respond_to(:get_machine_id)
      end

      it 'get_machine_name' do
        expect(subject).to respond_to(:get_machine_name)
      end
    end
  end

  context 'destroy' do
    context 'when not provisioned first' do
      it 'does not raise' do
        expect { subject.destroy }.not_to raise_error
      end
    end
  end

  context 'provision_machine' do
    it 'sets ip and name' do
      allow(OnlineKitchen::LabManager4).to receive(:get_config).and_return({})
      allow(subject).to receive(:deploy_machine).and_return({})
      allow(subject).to receive(:get_machine_id).and_return({})
      allow(subject).to receive(:get_machine_name).and_return('foobar')

      subject.provision_machine(provision_specs)

      expect(subject.ip).to eq('')
      expect(subject.name).to eq('foobar')
    end
  end
  context 'construct_deploy_body' do
    context 'processes empty config and empty env' do
      it 'returns label correctly' do
        res = subject.construct_deploy_body('A', 'B', {}, {})
        expect(JSON.parse(res)).to have_key('labels')
        expect(JSON.parse(res)['labels']).to include('template:A')
      end

      it 'returns inventory path correctly' do
        res = subject.construct_deploy_body('A', 'B', {}, {})
        expect(JSON.parse(res)['labels']).to include('config:inventory_path=B')
      end

      it 'returns network based on default config correctly' do
        res = subject.construct_deploy_body('A', 'B', {}, network_interface: 'C')
        expect(JSON.parse(res)['labels']).to include('config:network_interface=C')
      end

      it 'even when env is nil' do
        res = subject.construct_deploy_body('A', 'B', nil, network_interface: 'C')
        expect(JSON.parse(res)['labels']).to include('config:network_interface=C')
      end
    end

    context 'processes one custom env config' do
      it 'env is nil result is untouched' do
        config = { custom_labels: { is_dev: ['HENK'] }, network_interface: 'E' }
        res = subject.construct_deploy_body('A', 'B', {}, config)
        expect(JSON.parse(res)['labels']).to include('config:network_interface=E')
      end

      it 'env var is set to FALSE result is untouched' do
        config = { custom_labels: { is_dev: ['HENK'] }, network_interface: 'E' }
        res = subject.construct_deploy_body('A', 'B', { is_dev: 'FALSE' }, config)
        expect(JSON.parse(res)['labels']).not_to include('config:network_interface=E')
      end

      it 'env var is set to TRUE labels are updated' do
        config = { custom_labels: { is_dev: ['HENK'] }, network_interface: 'E' }
        res = subject.construct_deploy_body('A', 'B', { is_dev: 'TRUE' }, config)
        expect(JSON.parse(res)['labels']).to include('HENK')
      end

      it 'env var is set to TRUE labels are updated with two labels' do
        config = { custom_labels: { is_dev: %w[HENK GARPLY] }, network_interface: 'E' }
        res = subject.construct_deploy_body('A', 'B', { is_dev: 'TRUE' }, config)
        expect(JSON.parse(res)['labels']).to include('HENK')
        expect(JSON.parse(res)['labels']).to include('GARPLY')
      end
    end
    context 'processes two custom env configs' do
      it 'one env var is set to TRUE, second to FALSE -> labels are updated with correct labels' do
        config = { custom_labels: { is_dev: %w[HENK GARPLY], is_proc: %w[FOO BER] },
                   network_interface: 'E' }
        res = subject.construct_deploy_body('A', 'B', { is_dev: 'TRUE', is_proc: 'FALSE' }, config)
        expect(JSON.parse(res)['labels']).to include('HENK')
        expect(JSON.parse(res)['labels']).to include('GARPLY')
      end

      it 'one env var is set to FALSE, second to TRUE -> labels are updated with correct labels' do
        config = { custom_labels: { is_dev: %w[HENK GARPLY], is_proc: %w[FOO BER] },
                   network_interface: 'E' }
        res = subject.construct_deploy_body('A', 'B', { is_dev: 'FALSE', is_proc: 'TRUE' }, config)
        expect(JSON.parse(res)['labels']).not_to include('HENK')
        expect(JSON.parse(res)['labels']).not_to include('GARPLY')
        expect(JSON.parse(res)['labels']).to include('BER')
        expect(JSON.parse(res)['labels']).to include('FOO')
      end

      it 'one env var is set to TRUE, second to TRUE -> labels are updated with correct labels' do
        config = { custom_labels: { is_dev: %w[HENK GARPLY], is_proc: %w[FOO BER] },
                   network_interface: 'E' }
        res = subject.construct_deploy_body('A', 'B', { is_dev: 'TRUE', is_proc: 'TRUE' }, config)
        expect(JSON.parse(res)['labels']).to include('HENK')
        expect(JSON.parse(res)['labels']).to include('GARPLY')
        expect(JSON.parse(res)['labels']).to include('BER')
        expect(JSON.parse(res)['labels']).to include('FOO')
      end

      it 'one env is TRUE, second is TRUE, config contains an empty array -> it adds no label' do
        config = { custom_labels: { is_dev: [], is_proc: %w[FOO BER] }, network_interface: 'E' }
        res = subject.construct_deploy_body('A', 'B', { is_dev: 'TRUE', is_proc: 'TRUE' }, config)
        expect(JSON.parse(res)['labels']).to include('BER')
        expect(JSON.parse(res)['labels']).to include('FOO')
      end

      it 'one env is set to TRUE, second to TRUE, config contains nothing -> it adds no label' do
        config = { network_interface: 'F' }
        res = subject.construct_deploy_body('A', 'B', { is_dev: 'TRUE', is_proc: 'TRUE' }, config)
        expect(JSON.parse(res)['labels']).to include('config:network_interface=F')
      end
    end
  end
end
