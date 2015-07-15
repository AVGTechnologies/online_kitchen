# Service providing the Online Kitchen functionality

$: << 'lib'
require 'bundler/setup'

require 'rack'
require 'rack/contrib'
require 'sinatra/base'
require "sinatra/namespace"

require 'online_kitchen'
require 'active_support'

OnlineKitchen.setup

module OnlineKitchen
  class App < Sinatra::Base

    register Sinatra::Namespace
    set :bind, OnlineKitchen.config.bind
    set :protection, :origin_whitelist => OnlineKitchen.config.allowed_origin
    set :show_exceptions, false

    use Raven::Rack
    use Rack::PostBodyContentTypeParser

    before do
      content_type 'application/json'
      response['Access-Control-Allow-Origin'] = OnlineKitchen.config.allowed_origin
    end

    namespace OnlineKitchen.config.base_url do
      options "*" do
        response.headers["Allow"] = "HEAD,GET,PUT,DELETE,OPTIONS"

        # Needed for AngularJS
        response.headers["Access-Control-Allow-Headers"] = "X-Requested-With, X-HTTP-Method-Override, Content-Type, Cache-Control, Accept, userName, authenticationToken"

        halt 200
      end

      get '/templates' do
        auth
        ProviderTemplate.all.to_json
      end

      get '/configurations' do
        auth
        current_user.configurations.to_json
      end

      get '/configurations/:id' do |id|
        auth
        current_user.configurations.find(id).to_json
      end

      post '/configurations' do
        auth
        configuration = current_user.configurations.new(params[:configuration])
        if configuration.save
          halt 200, { status: :success, configuration: configuration }.to_json
        else
          halt 422, { status: :unprocessable_entity, errors: configuration.errors.to_h }.to_json
        end
      end

      put '/configurations/:id' do |id|
        auth
        configuration = current_user.configurations.find(id)
        if configuration.update_attributes(params[:configuration])
          halt 200, { status: :success, configuration: configuration }.to_json
        else
          halt 422, { status: :unprocessable_entity, errors: configuration.errors.to_h }.to_json
        end
      end

      delete '/configurations/:id' do |id|
        auth
        configuration = current_user.configurations.find(id)
        if configuration.schedule_destroy
          configuration = nil if configuration.destroyed?
          halt 200, { status: :success, configuration: configuration }.to_json
        else
          halt 422, { status: :unprocessable_entity, errors: configuration.errors.to_h }.to_json
        end
      end

    end

    error ActiveRecord::RecordNotFound do
      halt 404, { message: "Not found" }.to_json
    end

    error ActiveRecord::RecordInvalid do
      errors = env['sinatra.error'].record.errors.to_h
      halt 422, {
        message: 'Validation fails',
        errors: errors.to_h
      }.to_json
    end

    error ActiveRecord::UnknownAttributeError do
      record = env['sinatra.error'].record
      errors = record.errors.to_h
      halt 422, {
        message: record.valid? ? 'Validation fails' : env['sinatra.error'].to_s,
        errors: errors.to_h
      }.to_json
    end


    #FIXME: does not work
    error JSON::ParserError do
      halt 400, { message: "Cannot parse JSON" }.to_json
    end

    def current_user
      return nil unless @userName
      @current_user ||= User.find_or_create_by(name: @userName)
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
