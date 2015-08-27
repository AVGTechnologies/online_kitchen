require 'spec_helper'
require 'sidekiq/testing'

describe 'Configurations' do
  Sidekiq::Testing.fake!

  include Rack::Test::Methods

  def app
    OnlineKitchen::App
  end

  let!(:user) { FactoryGirl.create(:user, name: 'franta.lopata') }
  let(:configuration) { {
    name: 'machine.name',
    template: ProviderTemplate.first
  } }

  context 'no user specified' do
    let(:headers) do
      {
        'HTTP_ACCEPT' => 'application/json',
        'HTTP_USERNAME' => 'NuLl',
        'HTTP_AUTHENTICATIONTOKEN' => 'secret'
      }
    end

    context 'returns 401' do
      it 'GET /templates' do
        response = get '/api/v1/templates', {}, headers
        expect(response.status).to eq 401
      end

      it 'GET /configurations' do
        response = get '/api/v1/configurations', {}, headers
        expect(response.status).to eq 401
      end

      it 'GET /configurations/:id' do
        response = get '/api/v1/configurations/12345', {}, headers
        expect(response.status).to eq 401
      end

      it 'PUT /configuration/:id' do
        response = put '/api/v1/configurations/1', {}, headers
        expect(response.status).to eq 401
      end

      it 'DELETE /configuration/:id' do
        response = delete '/api/v1/configurations/1', {}, headers
        expect(response.status).to eq 401
      end
    end
  end

  context 'user specified' do
    let(:headers) do
      {
        'HTTP_ACCEPT' => 'application/json',
        'HTTP_USERNAME' => user.name,
        'HTTP_AUTHENTICATIONTOKEN' => 'secret'
      }
    end

    it 'GET /templates returns all templates' do
      response = get '/api/v1/templates', {}, headers
      payload = JSON.parse(response.body)
      expect(payload.size).to eq ProviderTemplate.all.size
    end

    context 'GET /configurations' do
      context 'when user does not exist' do
        it 'creates the user' do
          response = get '/api/v1/configurations',
            {},
            headers.update(
              'HTTP_USERNAME' => 'new_user')
          expect(response.status).to eq 200
        end
      end

      context 'when no configuration defined' do
        it 'returns empty list' do
          response = get '/api/v1/configurations', {}, headers
          expect(response.status).to eq 200
          configurations = JSON.parse(response.body)
          expect(configurations).to be_empty
        end
      end

      context 'when configurations exists' do
        let!(:configuration) { FactoryGirl.create(:configuration_with_machines, user: user) }

        it 'returns JSON representations' do
          response = get '/api/v1/configurations', {}, headers
          expect(response.status).to eq 200
          configurations = JSON.parse(response.body)
          expect(configurations).to eq [JSON.load(configuration.to_json)]
        end
      end
    end

    context 'GET /configurations/:id' do
      context 'when configuration ID does not exists' do
        it 'response 404 status code' do
          response = get '/api/v1/configurations/12345', {}, headers
          expect(response.status).to eq 404
        end
      end

      context 'when configuration exists' do
        let!(:configuration) { FactoryGirl.create(:configuration_with_machines, user: user) }

        it 'returns configuration attributes with machines' do
          response = get "/api/v1/configurations/#{configuration.id}", {}, headers
          expect(response.status).to eq 200

          result = JSON.parse(response.body)
          expect(result).to include('user_id' => user.id, 'name' => configuration.name, 'folder_name' => configuration.folder_name)
          expect(result['machines_attributes'].size).to eq 3
        end

        it 'returns template in machines attributes' do
          response = get "/api/v1/configurations/#{configuration.id}", {}, headers

          result = JSON.parse(response.body)

          expect(result['machines_attributes'][0]).to have_key('template')
        end
      end
    end

    context 'PUT /configuration/:id' do
      let!(:configuration) { FactoryGirl.create(:configuration_with_machines, user: user) }

      it 'schedule release VMs for deleted ones' do
        second_machine = configuration.machines[0]
        payload = {
          configuration: {
            machines_attributes: [
              { id: second_machine.id, _destroy: '1' },
              { id: configuration.machines[0].id } # this one should not be scheduled
            ]
          }
        }

        expect do
          response = put "/api/v1/configurations/#{configuration.id}", payload, headers
          expect(response.status).to eq 200

          result = JSON.parse(response.body)
          machine_states = result['configuration']['machines_attributes'].map do |m|
            m['state']
          end.sort
          expect(machine_states).to eq %w(destroy_queued queued queued)
        end.to change { OnlineKitchen::LabManagerRelease.jobs.size }.by(1)
      end

      it 'schedule provision VMs for created ones', sidekiq: true do
        payload = {
          configuration: {
            machines_attributes: [
              { id: configuration.machines[0].id, name: 'xxx' }, # should not be scheduled
              { name: 'new_machine', template: ProviderTemplate.last }
            ]
          }
        }

        expect do
          response = put "/api/v1/configurations/#{configuration.id}", payload, headers
          expect(response.status).to eq 200
        end.to change { OnlineKitchen::LabManagerProvision.jobs.size }.by(1)
      end
    end

    context 'POST /configuration/:id' do
      let(:payload) do
        {
          configuration: {
            name: 'CreateConfigurationTest',
            folder_name: 'folder',
            user_id: user.id,
            machines_attributes: [
              { name: 'firstMachine', template: ProviderTemplate.first },
              { name: 'secondMachnine', template: ProviderTemplate.first }
            ]
          }
        }
      end
      it 'schedule provision of VM', sidekiq: true do
        expect do
          response = post '/api/v1/configurations', payload, headers
          expect(response.status).to eq 200
          result = JSON.parse(response.body)
          machine_states = result['configuration']['machines_attributes'].map do |m|
            m['state']
          end
          expect(machine_states).to eq %w(queued queued)
        end.to change { OnlineKitchen::LabManagerProvision.jobs.size }.by(2)
      end
    end

    context 'DELETE /configuration/:id' do
      context 'when VM is running' do
        let!(:configuration) { FactoryGirl.create(:configuration_with_machines, user: user) }

        it 'schedule release of VM' do
          expect do
            response = delete "/api/v1/configurations/#{configuration.id}", {}, headers
            expect(response.status).to eq 200
            result = JSON.parse(response.body)
            machine_states = result['configuration']['machines_attributes'].map do |m|
              m['state']
            end
            expect(machine_states).to eq %w(destroy_queued destroy_queued destroy_queued)
          end.to change { OnlineKitchen::LabManagerRelease.jobs.size }.by(3)
          configuration.reload
          expect(configuration.deleted).to eq true
        end
      end

      context 'when all VMs are already deleted' do
        let!(:configuration) { FactoryGirl.create(:configuration_with_machines, user: user) }

        it 'destroy a configuration' do
          configuration.machines.each { |machine| machine.state = 'deleted' }
          configuration.save
          expect do
            expect do
              response = delete "/api/v1/configurations/#{configuration.id}", {}, headers
              expect(response.status).to eq 200
            end.to change { OnlineKitchen::LabManagerRelease.jobs.size }.by(0)
          end.to change { Configuration.count }.by(-1)
        end
      end
    end
  end
end
