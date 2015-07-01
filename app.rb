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
    set :bind, OnlineKitchen.config.bind
    set :protection, :origin_whitelist => OnlineKitchen.config.allowed_origin

    use Rack::PostBodyContentTypeParser

    before { auth }
    before do
      content_type 'application/json'
      response['Access-Control-Allow-Origin'] = OnlineKitchen.config.allowed_origin
    end

    namespace OnlineKitchen.config.base_url do
      options "*" do
        response.headers["Allow"] = "HEAD,GET,PUT,DELETE,OPTIONS"

        # Needed for AngularJS
        response.headers["Access-Control-Allow-Headers"] = "X-Requested-With, X-HTTP-Method-Override, Content-Type, Cache-Control, Accept, userName, authenticationToken"

        halt HTTP_STATUS_OK
      end

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
