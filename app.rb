# Service providing the Online Kitchen functionality

$: << 'lib'
require 'sinatra/base'
require 'bundler/setup'
require 'online_kitchen'
require 'active_support'

module OnlineKitchen
  class App < Sinatra::Base

    set :bind, '0.0.0.0'

    # TODO: namespace '/api/v1/' do
      get '/api/v1/templates' do
        common_request_setup
        OnlineKitchenTemplate.all.to_json
      end

      post '/api/v1/configurations' do
        common_request_setup
        @configuration_specification = get_body_as_json
      end

      get '/api/v1/configurations' do
        common_request_setup
      end

      put '/api/v1/configurations' do
        common_request_setup
        @configuration_modification = get_body_as_json
      end

      delete '/api/v1/configurations/:configuration_id' do |configuration_id|
        common_request_setup
      end
    #end

    private

    def auth
      @userName = headers['userName']
      @authenticationToken = headers['authenticationToken']

      unless @userName.blank? && @authenticationToken.blank?
        status 401
        {:result => 'error', :message => "Invalid user credentials"}.to_json
      end
    end

    def common_request_setup
      auth
      content_type :json
      response['Access-Control-Allow-Origin'] = '*'
    end

    def get_body_as_json
      request.body.rewind
      JSON.parse request.body.read
    end

    run! if app_file == $0 # This makes the app launchanble like "ruby app.rb"
  end
end
