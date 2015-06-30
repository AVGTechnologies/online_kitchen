# Service providing the Online Kitchen functionality

$: << 'lib'
require 'bundler/setup'
require 'online_kitchen'
require 'sinatra/base'
require 'active_support'


module OnlineKitchen
  class App < Sinatra::Base

    set :bind, '0.0.0.0'
    before do
      auth
    end

    get '/templates' do
      content_type :json
      OnlineKitchenTemplate.all.to_json
    end

    private

    def auth
      @userName = headers['userName']
      @authenticationToken = headers['authenticationToken']

      unless @userName.blank? && @authenticationToken.blank?
        status 401
        {:result => 'error', :message => "Invalid user credentials"}.to_json
      end
    end

    run! if app_file == $0
  end
end
