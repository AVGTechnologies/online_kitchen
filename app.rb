# Service providing the Online Kitchen functionality

$: << 'lib'
require 'bundler/setup'

require 'rack'
require 'rack/contrib'
require 'sinatra/base'
require "sinatra/namespace"

require 'online_kitchen'
require 'active_support'

module OnlineKitchen
  class App < Sinatra::Base

    register Sinatra::Namespace
    set :bind, OnlineKitchenConfig.bind
    use Rack::PostBodyContentTypeParser

    before { auth }
    before do
      content_type 'application/json'
      response['Access-Control-Allow-Origin'] = OnlineKitchenConfig.allowed_origin
    end

    namespace OnlineKitchenConfig.base_url do
      get '/templates' do
        OnlineKitchenTemplate.all.as_json
      end

      get '/configurations' do
      end

      post '/configurations' do
      end

      put '/configurations/:id' do |id|
        params.inspect
      end

      delete '/configurations/:id' do |id|
      end

    end

    private

    def auth
      @userName = env['HTTP_USERNAME']
      @authenticationToken = env['HTTP_AUTHENTICATIONTOKEN']

      if @userName.blank? or @authenticationToken.blank?
        halt 401, {:result => 'error', :message => "Invalid user credentials"}.to_json
      end
    end

    run! if app_file == $0 # This makes the app launchanble like "ruby app.rb"
  end
end
