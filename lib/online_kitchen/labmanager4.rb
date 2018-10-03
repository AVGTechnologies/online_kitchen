# = Wrapper for Online Kitchen SOAP service
#
# This library is an interface for Online Kitchen service which is an interface
# for creating and destroing virtual machines (currently only VMware vsphere)
#
# == Example
#
# lm = OnlineKitchen::LabManager.create(
#   vms_folder: 'myFolder',
#   template_name: 'w7x64',
#   requestor: 'CZ\\user.name',
#   uuid: ...,
#   job_id: ...
# )
# p lm.ip
# lm.destroy
# ...
#
# # destroy machine by name
# OnlineKitchen::LabManager.destroy('online_kitchen_8x64-5e448e10')
#

require 'securerandom'
require 'net/http'
require 'json'
require 'active_support/core_ext/object/blank'

module OnlineKitchen
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
          JSON.parse(response.body)['request_id']
        end

        OnlineKitchen.logger.debug(request_id)
      end

      alias destroy release_machine
    end

    def initialize
      @vm = {}
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

    def wait_for_machine_deployed(config, machine_id)
      rand_gen = Random.new
      (1..40).each do
        uri_get_machine = URI("#{config[:service_endpoint]}machines/#{machine_id}")

        machine = Net::HTTP.start(uri_get_machine.host, uri_get_machine.port) do |http|
          request = Net::HTTP::Get.new uri_get_machine
          request.basic_auth config[:username], config[:password]

          response = http.request request # Net::HTTPResponse object
          OnlineKitchen.logger.debug(response.body)
          JSON.parse(response.body)
        end

        return machine if machine['state'] == 'deployed'

        sleep(rand_gen.rand(2..8))
      end

      raise 'Error waiting for machine'
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

    def deploy_machine(config, image)
      uri_create = URI("#{config[:service_endpoint]}machines/")
      req1 = Net::HTTP::Post.new(uri_create)
      req1.content_type = 'application/json'
      req1.body = "{\"labels\":[\"template:#{image}\", \
                  \"config:networkInterface=#{config[:network_interface]}\"]}"
      req1.basic_auth config[:username], config[:password]
      res = Net::HTTP.start(uri_create.hostname, uri_create.port) do |http|
        http.request(req1)
      end

      request_id = JSON.parse(res.body)['request_id']
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

      request_id = deploy_machine(config, opts[:image])
      machine_id = get_machine_id(config, request_id)
      wait_for_machine_deployed(config, machine_id)
      start_machine(config, machine_id)

      @vm = { name: "#{opts[:image]}-#{machine_id}", ip: '1.1.1.1' }

      OnlineKitchen.logger.info "Got PC with IP: #{@vm[:ip]}, name: #{@vm[:name]}"
      self
    rescue
      OnlineKitchen.logger.error "Deploy machine failed: #{$ERROR_INFO.inspect}, #{$ERROR_POSITION}"
      raise
    end
  end
end
