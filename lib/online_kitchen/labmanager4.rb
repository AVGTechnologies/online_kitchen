# Wrapper for 4th generation of vCenter LabManager Unit
#
# This service has REST interface for vmWare machine management.
#

require 'securerandom'
require 'net/http'
require 'json'
require 'active_support/core_ext/object/blank'

module OnlineKitchen
  class DeployError < StandardError
  end

  class IPsError < StandardError
  end

  # LabManager communication encapsulation
  class LabManager4
    attr_reader :vm

    class << self
      def create(opts = {})
        new.provision_machine(opts)
      end

      def release_machine(name)
        config = OnlineKitchen.config.rest_config
        machine_id = /.*\-([^\-]*)/.match(name)[1]
        uri_del_machine = URI("#{config[:service_endpoint]}machines/#{machine_id}")

        request_id = Net::HTTP.start(uri_del_machine.host, uri_del_machine.port) do |http|
          request = Net::HTTP::Delete.new uri_del_machine
          request.basic_auth config[:username], config[:password]

          response = http.request request # Net::HTTPResponse object
          OnlineKitchen.logger.debug(response.body)
          JSON.parse(response.body)['responses'][0]['request_id']
        end

        wait_for_machine_released(config, request_id)
      end

      alias destroy release_machine

      private

      def get_response(config, uri_get_request)
        Net::HTTP.start(uri_get_request.host, uri_get_request.port) do |http|
          request = Net::HTTP::Get.new uri_get_request
          request.basic_auth config[:username], config[:password]

          response = http.request request # Net::HTTPResponse object
          JSON.parse(response.body)
        end
      end

      def wait_for_machine_released(config, request_id)
        uri_get_request = URI("#{config[:service_endpoint]}requests/#{request_id}")

        config[:max_request_retries].times.each do
          response = get_response(config, uri_get_request)

          begin
            return response if response['responses'][0]['result']['state'] == 'success'
          rescue NoMethodError
            OnlineKitchen.logger.debug("response: #{response.body} cannot be examined")
          end

          sleep(Random.new.rand(config[:try_delay_min]..config[:try_delay_max]))
        end

        raise 'Error machine deletion waiting'
      end
    end

    def initialize
      @vm = {}
      @rand_gen = Random.new
    end

    def destroy
      self.class.release_machine(vm[:name]) if vm && vm[:name]
      @vm = {}
      self
    end

    def ip
      vm[:ip]
    end

    def name
      vm[:name]
    end

    def sleep_between_tries(config)
      sleep(@rand_gen.rand(config[:try_delay_min]..config[:try_delay_max]))
    end

    def wait_for_machine_deployed(config, machine_id)
      uri_get_machine = URI("#{config[:service_endpoint]}machines/#{machine_id}")

      config[:max_request_retries].times.each do
        machine = Net::HTTP.start(uri_get_machine.host, uri_get_machine.port) do |http|
          request = Net::HTTP::Get.new uri_get_machine
          request.basic_auth config[:username], config[:password]

          response = http.request request # Net::HTTPResponse object
          OnlineKitchen.logger.debug(response.body)
          JSON.parse(response.body)
        end

        return machine if machine['responses'][0]['result']['state'] == 'deployed'

        sleep_between_tries(config)
      end

      raise DeployError, 'Error machine waiting'
    end

    def wait_for_machine_ips(config, machine_id)
      uri_get_machine = URI("#{config[:service_endpoint]}machines/#{machine_id}")

      (config[:max_request_retries] / 8).ceil.times.each do
        machine = Net::HTTP.start(uri_get_machine.host, uri_get_machine.port) do |http|
          request = Net::HTTP::Get.new uri_get_machine
          request.basic_auth config[:username], config[:password]

          response = http.request request # Net::HTTPResponse object
          JSON.parse(response.body)
        end

        return machine['responses'][0]['result']['ip_addresses'] if
          machine['responses'][0]['result']['ip_addresses'] != []

        sleep_between_tries(config)
      end

      raise IPsError, "Error machine #{machine_id} waiting"
    end

    def start_machine(config, machine_id)
      uri = URI("#{config[:service_endpoint]}machines/#{machine_id}")
      req1 = Net::HTTP::Put.new(uri)
      req1.content_type = 'application/json'
      req1.body = '{"action":"start"}'
      req1.basic_auth config[:username], config[:password]
      Net::HTTP.start(uri.hostname, uri.port) do |http|
        http.request(req1)
      end
    end

    def deploy_machine(config, vm_options)
      uri_create = URI("#{config[:service_endpoint]}machines/")
      req1 = Net::HTTP::Post.new(uri_create)
      req1.content_type = 'application/json'
      req1.body = "{\"labels\":[\"template:#{vm_options[:image]}\", \
                  \"config:network_interface=#{config[:network_interface]}\", \
                  \"config:inventory_path=#{vm_options[:requestor]}\"]}"
      req1.basic_auth config[:username], config[:password]
      res = Net::HTTP.start(uri_create.hostname, uri_create.port) do |http|
        http.request(req1)
      end

      request_id = JSON.parse(res.body)['responses'][0]['request_id']
      OnlineKitchen.logger.debug("post_request_id: #{request_id}")
      request_id
    end

    def get_machine_id(config, request_id)
      uri_get_machine_id = URI("#{config[:service_endpoint]}requests/#{request_id}")

      machine_id = Net::HTTP.start(uri_get_machine_id.host, uri_get_machine_id.port) do |http|
        request = Net::HTTP::Get.new uri_get_machine_id
        request.basic_auth config[:username], config[:password]

        response = http.request request # Net::HTTPResponse object
        data = JSON.parse(response.body)
        data['responses'].each_with_object({}) do |element, result|
          result['id'] = element['result']['machine_id'] if element['type'] == 'return_value'
        end['id']
      end

      OnlineKitchen.logger.debug("machine_id: #{machine_id}")
      machine_id
    end

    def provision_machine(opts = {})
      config = OnlineKitchen.config.rest_config

      request_id = deploy_machine(config, opts)
      machine_id = get_machine_id(config, request_id)
      wait_for_machine_deployed(config, machine_id)
      start_machine(config, machine_id)
      ips = wait_for_machine_ips(config, machine_id)

      @vm = { name: "#{opts[:image]}-#{machine_id}", ip: ips.join(', ') }

      OnlineKitchen.logger.info "Got PC with IP: #{@vm[:ip]}, name: #{@vm[:name]}"
      self
    rescue IPsError
      @vm = { name: "#{opts[:image]}-#{machine_id}", ip: 'not obtained' }

      OnlineKitchen.logger.info "Got PC with IP: #{@vm[:ip]}, name: #{@vm[:name]}"
      self
    rescue
      OnlineKitchen.logger.error "Deploy machine failed: #{$ERROR_INFO.inspect}, #{$ERROR_POSITION}"
      raise
    end
  end
end
