# Service providing the Online Kitchen functionality

$LOAD_PATH << 'lib'
require 'bundler/setup'
require 'rack'
require 'rack/contrib'
require 'sinatra/base'
require 'sinatra/namespace'
require 'online_kitchen'
require 'active_support'

OnlineKitchen.setup

module OnlineKitchen
  # Custom exception covering the case of user name failing validation criteria
  class InvalidUserName < StandardError
  end

  # Application class
  class App < Sinatra::Base
    register Sinatra::Namespace
    set :bind, OnlineKitchen.config.bind
    set :protection, origin_whitelist: OnlineKitchen.config.allowed_origin
    set :show_exceptions, false

    use Raven::Rack
    use Rack::PostBodyContentTypeParser

    before do
      content_type 'application/json'
      response['Access-Control-Allow-Origin'] = OnlineKitchen.config.allowed_origin
      authenticate_user unless request.options?
    end

    namespace OnlineKitchen.config.base_url do
      options '*' do
        response.headers['Access-Control-Allow-Methods'] =
          'HEAD, GET, PUT, POST, DELETE, OPTIONS'
        # Needed for AngularJS
        response.headers['Access-Control-Allow-Headers'] =
          'X-Requested-With, ' \
          'X-HTTP-Method-Override, ' \
          'Content-Type, ' \
          'Cache-Control, ' \
          'Accept, ' \
          'userName, ' \
          'authenticationToken'
        halt 200
      end

      get '/templates' do
        # TODO: here get resources sidekiq job should be launched
        ProviderTemplate.all.to_json
      end

      get '/configurations' do
        current_user.configurations.to_json
      end

      get '/configurations/:id' do |id|
        current_user.configurations.find(id).to_json
      end

      post '/configurations' do
        configuration = current_user.configurations.new(params[:configuration])
        if configuration.save
          halt 200, {
            status: :success,
            configuration: configuration
          }.to_json
        else
          halt 422, {
            status: :unprocessable_entity,
            errors: configuration.errors.to_h
          }.to_json
        end
      end

      put '/configurations/:id' do |id|
        configuration = current_user.configurations.find(id)
        if configuration.update_attributes(params[:configuration])
          halt 200, {
            status: :success,
            configuration: configuration
          }.to_json
        else
          halt 422, {
            status: :unprocessable_entity,
            errors: configuration.errors.to_h
          }.to_json
        end
      end

      delete '/configurations/:id' do |id|
        configuration = current_user.configurations.find(id)
        if configuration.schedule_destroy
          configuration = nil if configuration.destroyed?
          halt 200, {
            status: :success,
            configuration: configuration
          }.to_json
        else
          halt 422, {
            status: :unprocessable_entity,
            errors: configuration.errors.to_h
          }.to_json
        end
      end

      get '/resources' do
        halt 200, {
          status: :sucess,
          resources: {
            foo: {
              slot_limit: 870,
              free_slots: 220,
            },
            bar: {
              slot_limit: 20,
              free_slots: 20,
            },
          }
        }.to_json
      end
    end

    error ActiveRecord::RecordNotFound do
      halt 404, { message: 'Not found' }.to_json
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

    error OnlineKitchen::InvalidUserName do
      halt 400, {
        message: 'User name is invalid',
        errors: @user_name
      }.to_json
    end

    # FIXME: does not work
    error JSON::ParserError do
      halt 400, { message: 'Cannot parse JSON' }.to_json
    end

    def current_user
      return nil unless @user_name

      @current_user ||= User.find_or_create_by(name: @user_name)
      raise OnlineKitchen::InvalidUserName unless @current_user.valid?

      @current_user
    end

    private

    def authenticate_user
      @user_name = get_header_value('UserName')
      @authentication_token = get_header_value('AuthenticationToken')

      return unless @user_name.blank? || @authentication_token.blank?

      halt 401, { result: 'error',
                  message: 'Invalid user credentials' }.to_json
    end

    def get_header_value(name)
      name.upcase!
      variable = "HTTP_#{name}"
      value = env[variable]

      return nil if value.nil?

      value.casecmp('null').zero? ? nil : value
    end

    # This makes the app launchanble like "ruby app.rb"
    run! if app_file == $PROGRAM_NAME
  end
end
