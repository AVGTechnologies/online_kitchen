# Wrapper for 4th generation of vCenter LabManager Unit
#
# This service has REST interface for vmWare machine management.
#

require 'securerandom'
require 'net/http'
require 'json'
require 'active_support/core_ext/object/blank'

module OnlineKitchen
  # LabManager communication encapsulation
  class LabManager4
    attr_reader :vm

    class DeployError < StandardError
    end

    class << self
      def create(opts = {})
        new.provision_machine(opts)
      end

      def release_machine(name, opts = {})
        config = get_config(opts)
        machine_id = /.*\-([^\-]*)/.match(name)[1]
        uri_del_machine = URI("#{config[:service_endpoint]}machines/#{machine_id}")

        request_id = Net::HTTP.start(
          uri_del_machine.host,
          uri_del_machine.port,
          config[:http_opts].symbolize_keys
        ) do |http|
          request = Net::HTTP::Delete.new uri_del_machine
          request.basic_auth config[:username], config[:password]

          response = http.request request # Net::HTTPResponse object
          OnlineKitchen.logger.debug(response.body)
          JSON.parse(response.body)['responses'][0]['request_id']
        end

        wait_for_request_completion(config, request_id)
      end

      def equip_machine_deployed?(name, opts = {})
        config = get_config(opts)
        machine_id = /.*\-([^\-]*)/.match(name)[1]
        uri_get_machine = URI("#{config[:service_endpoint]}machines/#{machine_id}")
        OnlineKitchen.logger.debug("equip_machine_deployed? url: #{uri_get_machine}")

        machine = Net::HTTP.start(
          uri_get_machine.host,
          uri_get_machine.port,
          config[:http_opts].symbolize_keys
        ) do |http|
          request = Net::HTTP::Get.new uri_get_machine
          request.basic_auth config[:username], config[:password]

          response = http.request request # Net::HTTPResponse object
          OnlineKitchen.logger.debug("equip_machine_deployed? resp body: #{response.body}")
          JSON.parse(response.body)
        end

        return true if machine['responses'][0]['result']['state'] == 'deployed'

        false
      rescue JSON::ParserError,
             Net::OpenTimeout,
             Net::ReadTimeout,
             Net::WriteTimeout,
             NoMethodError => e
        OnlineKitchen.logger.warn("Exception occured: #{e.inspect}")
        OnlineKitchen.logger.warn(machine) if machine
        false
      end

      def equip_machine_start(name, opts = {})
        config = get_config(opts)
        machine_id = /.*\-([^\-]*)/.match(name)[1]
        uri = URI("#{config[:service_endpoint]}machines/#{machine_id}")
        req1 = Net::HTTP::Put.new(uri)
        req1.content_type = 'application/json'
        req1.body = '{"action":"start"}'
        req1.basic_auth config[:username], config[:password]
        Net::HTTP.start(uri.hostname, uri.port, config[:http_opts].symbolize_keys) do |http|
          http.request(req1)
        end
      end

      def equip_create_clean_snapshot(name, opts = {})
        config = get_config(opts)
        machine_id = /.*\-([^\-]*)/.match(name)[1]
        uri = URI("#{config[:service_endpoint]}machines/#{machine_id}/snapshots")
        OnlineKitchen.logger.debug('creating clean snapshot')
        req1 = Net::HTTP::Post.new(uri)
        req1.content_type = 'application/json'
        req1.body = '{"name":"clean"}'
        req1.basic_auth config[:username], config[:password]
        request_id = Net::HTTP.start(
          uri.hostname,
          uri.port,
          config[:http_opts].symbolize_keys
        ) do |http|
          response = http.request(req1)
          JSON.parse(response.body)['responses'][0]['request_id']
        end

        OnlineKitchen.logger.debug('waiting for clean snapshot to be created')
        wait_for_request_completion(config, request_id)
        OnlineKitchen.logger.debug('waiting for clean snapshot to be created done')
      end

      def equip_machine_ip(name, opts = {})
        config = get_config(opts)
        machine_id = /.*\-([^\-]*)/.match(name)[1]
        uri_get_machine = URI("#{config[:service_endpoint]}machines/#{machine_id}")

        machine = Net::HTTP.start(
          uri_get_machine.host,
          uri_get_machine.port,
          config[:http_opts].symbolize_keys
        ) do |http|
          request = Net::HTTP::Get.new uri_get_machine
          request.basic_auth config[:username], config[:password]

          response = http.request request # Net::HTTPResponse object
          JSON.parse(response.body)
        end
        return { ip_addresses: machine['responses'][0]['result']['ip_addresses'].join(', ') } if
          machine['responses'][0]['result']['ip_addresses'] != []

        false
      end

      def get_config(opts = {})
        if opts.key?(:cluster) && OnlineKitchen.config.method_defined?(:cluster_rest_config)
          if OnlineKitchen.config.cluster_rest_config.key?(opts[:cluster])
            OnlineKitchen.logger.debug("\e[1;31m CLUSTER REST CONFIG GONNA BE APPLIED  \e[0m")
            return OnlineKitchen.config.cluster_rest_config[opts[:cluster]].symbolize_keys
          end
        end

        OnlineKitchen.config.rest_config.symbolize_keys
      end

      alias destroy release_machine

      private

      def get_response(config, uri_get_request)
        Net::HTTP.start(
          uri_get_request.host,
          uri_get_request.port,
          config[:http_opts].symbolize_keys
        ) do |http|
          request = Net::HTTP::Get.new uri_get_request
          request.basic_auth config[:username], config[:password]

          response = http.request request # Net::HTTPResponse object
          JSON.parse(response.body)
        end
      end

      def wait_for_request_completion(config, request_id)
        uri_get_request = URI("#{config[:service_endpoint]}requests/#{request_id}")

        config[:max_request_retries].times.each do
          OnlineKitchen.logger.debug("getting request info for request_id: #{request_id}")
          response = get_response(config, uri_get_request)

          begin
            return response if response['responses'][0]['result']['state'] == 'success'
          rescue NoMethodError
            OnlineKitchen.logger.debug("response: #{response.body} cannot be examined")
          end
        rescue Net::ReadTimeout
          OnlineKitchen.logger.warn(
            'Exception ReadTimeout occurred when comm to backend, delay to be extended'
          )
          sleep(Random.new.rand(config[:try_delay_min] * 2..config[:try_delay_max] * 2))
        ensure
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

    def deploy_machine(config, vm_options)
      uri_create = URI("#{config[:service_endpoint]}machines/")
      req1 = Net::HTTP::Post.new(uri_create)
      req1.content_type = 'application/json'
      req1.body = "{\"labels\":[\"template:#{vm_options[:image]}\", \
                  \"config:network_interface=#{config[:network_interface]}\", \
                  \"config:inventory_path=#{vm_options[:requestor]}\"]}"
      req1.basic_auth config[:username], config[:password]
      res = Net::HTTP.start(
        uri_create.hostname,
        uri_create.port,
        config[:http_opts].symbolize_keys
      ) do |http|
        http.request(req1)
      end

      info = JSON.parse(res.body)['responses'][0]
      if info.key?('request_id')
        request_id = JSON.parse(res.body)['responses'][0]['request_id']
        OnlineKitchen.logger.debug("post_request_id: #{request_id}")
        request_id
      else
        OnlineKitchen.logger.debug("deploy machine: error getting request_id: #{res.body}")
        raise DeployError
      end
    end

    def get_machine_id(config, request_id)
      uri_get_machine_id = URI("#{config[:service_endpoint]}requests/#{request_id}")

      machine_id = Net::HTTP.start(
        uri_get_machine_id.host,
        uri_get_machine_id.port,
        config[:http_opts].symbolize_keys
      ) do |http|
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

    def get_machine_name(config, machine_id, opts = {})
      if config[:unit_id]
        "#{opts[:image]}-#{config[:unit_id]}-#{machine_id}"
      else
        "#{opts[:image]}-#{machine_id}"
      end
    end

    def provision_machine(opts = {})
      config = self.class.get_config(opts)

      request_id = deploy_machine(config, opts)
      machine_id = get_machine_id(config, request_id)

      @vm = { name: get_machine_name(config, machine_id, opts), ip: '' }
      OnlineKitchen.logger.info "Got PC with name: #{@vm[:name]}"
      self
    rescue StandardError
      OnlineKitchen.logger.error "Deploy machine failed: #{$ERROR_INFO.inspect}, #{$ERROR_POSITION}"
      raise
    end
  end
end
