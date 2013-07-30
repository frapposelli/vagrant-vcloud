require "forwardable"
require "log4r"
require "rest-client"
require "nokogiri"


require File.expand_path("../base", __FILE__)

module VagrantPlugins
  module VCloud
    module Driver

      class Meta < Base

        class UnauthorizedAccess < StandardError; end
        class WrongAPIVersion < StandardError; end
        class WrongItemIDError < StandardError; end
        class InvalidStateError < StandardError; end
        class InternalServerError < StandardError; end
        class UnhandledError < StandardError; end


        # We use forwardable to do all our driver forwarding
        extend Forwardable
        attr_reader :driver
        

        def initialize(host, username, password, org_name)

          # Setup the base
          super()


          @logger = Log4r::Logger.new("vagrant::provider::vcloud::meta")
          @logger.debug("LOOK AT ME, I'M IN META!")
          @host = host
          @username = username
          @password = password
          @org_name = org_name
#          @api_version = (api_version || "5.1")


          # Read and assign the version of vCloud we know which
          # specific driver to instantiate.
          begin
            @version = get_api_version(@host) || ""
          rescue Vagrant::Errors::CommandUnavailable,
            Vagrant::Errors::CommandUnavailableWindows
            # This means that vCloud was not found, so we raise this
            # error here.
            raise Vagrant::Errors::VCloudNotDetected
          end

          # Instantiate the proper version driver for vCloud
          @logger.debug("Finding driver for vCloud version: #{@version}")
          driver_map   = {
            # API 1.5 maps to vCloud Director 5.1 - don't ask me why we're not on par with the release number...
            "1.5" => Version_5_1
          }

          if @version.start_with?("0.9")
            # vCloud Director 1.5 just doesn't work with our Vagrant provider, so show error
            raise Vagrant::Errors::VCloudOldVersion
          end

          driver_klass = nil
          driver_map.each do |key, klass|
            if @version.start_with?(key)
              driver_klass = klass
              break
            end
          end

          if !driver_klass
            supported_versions = driver_map.keys.sort.join(", ")
            raise Vagrant::Errors::VCloudInvalidVersion, :supported_versions => supported_versions
          end

          @logger.info("Using vCloud driver: #{driver_klass}")
          # @driver = driver_klass.new(@uuid)

          # FIXME: fix the hardcoded 5.1 value
          @driver = driver_klass.new(@host, @username, @password, @org_name)

        end

        def_delegators :@driver,
          :login,
          :logout,
          :get_organizations,
          :get_organization_id_by_name,
          :get_organization_by_name,
          :get_organization,
          :get_catalog,
          :get_catalog_id_by_name,
          :get_catalog_by_name,
          :get_vdc,
          :get_vdc_id_by_name,
          :get_vdc_by_name,
          :get_catalog_item,
          :get_catalog_item_by_name,
          :get_vapp,
          :delete_vapp,
          :poweroff_vapp,
          :suspend_vapp,
          :reboot_vapp,
          :reset_vapp,
          :poweron_vapp,
          :create_vapp_from_template,
          :compose_vapp_from_vm,
          :get_vapp_template,
          :set_vapp_port_forwarding_rules,
          :get_vapp_port_forwarding_rules,
          :get_vapp_edge_public_ip,
          :upload_ovf,
          :get_task,
          :wait_task_completion,
          :set_vapp_network_config,
          :set_vm_network_config,
          :set_vm_guest_customization,
          :get_vm,
          :send_request,
          :upload_file,
          :convert_vapp_status


        protected


        def get_api_version(host_url)

          request = RestClient::Request.new(:method => "GET",
                                           :url => "#{host_url}/api/versions")
          begin
            response = request.execute
            if ![200, 201, 202, 204].include?(response.code)
              puts "Warning: unattended code #{response.code}"
            end

          versionInfo = Nokogiri.parse(response)
          apiVersion = versionInfo.css("VersionInfo Version").first.text

          apiVersion
          rescue
            ## FIXME: Raise a realistic error, like host not found or url not found.
            raise
          end
        end








      end
    end
  end
end
