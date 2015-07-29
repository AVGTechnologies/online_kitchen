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
require 'active_support/core_ext/object/blank'

module OnlineKitchen
  class LabManager

    attr_reader :vm

    class << self
      def create(opts = {})
        new.provision_machine(opts)
      end

      def release_machine(name)
        response = client.call(:release_machine, message: { machine_name: name } )
      rescue Savon::SOAPFault => err #TODO: specify exceptions
        OnlineKitchen.logger.error "Release machine failed: #{err.inspect}, #{$@}"
        raise
      end
      alias :destroy :release_machine

      def client
        @client ||= Savon.client(client_config)
      end

      def client_config
        soap_config = OnlineKitchen.config.soap_config
        raise "soap.service_endpoint must be specified in the config!" if soap_config[:service_endpoint].blank?
        res = {
          env_namespace: :s,
          namespace_identifier: nil,
          element_form_default: :qualified,
          open_timeout: 1200,
          read_timeout: 1600
        }.deep_merge(soap_config[:service_config].symbolize_keys)
        res[:wsdl] = soap_config[:service_endpoint]
        res[:wsdl] << "?wsdl" unless res[:wsdl] =~ /\?wsdl\z/
        res
      end

    end

    def initialize
      @vm = {}
    end

    def destroy
      self.class.release_machine(vm[:name]) if vm and vm[:name]
      @vm = {}
      self
    end

    def ip
      vm[:ip]
    end

    def name
      vm[:name]
    end

    def provision_machine(opts = {})
      begin
        response = client.call(:provision_machine, message: { specification: provision_machine_builder(opts).doc.root.to_s } )
        px =  Nokogiri.parse(response.body[:provision_machine_response][:provision_machine_result]);
        ip = px.xpath("//IP").first.inner_html.to_s
        name = px.xpath("//name").first.inner_html.to_s

        OnlineKitchen.logger.info "Got PC with IP: #{ip}, name: #{name}"
        @vm = {:name => name, :ip => ip}
        self
      rescue
        OnlineKitchen.logger.error "Deploy machine failed: #{$!.inspect}, #{$@}"
        raise
      end
    end

    private
      def client
        @client ||= self.class.client
      end

      def client_config
        self.class.client_config
      end

      def provision_machine_builder(opts)
        Nokogiri::XML::Builder.new do |xml|
          xml.xml {
            xml.folder opts[:vms_folder]
            xml.templateName opts[:template_name]
            xml.guid opts[:uuid] || SecureRandom.uuid
            xml.requestorUserName (opts[:requestor])
            xml.testId opts[:job_id]
          }
        end
      end
  end
end
