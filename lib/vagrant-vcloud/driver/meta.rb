#
#  Copyright 2012 Stefano Tortarolo
#  Copyright 2013 Fabio Rapposelli and Timo Sugliani
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#   limitations under the License.
#

require 'forwardable'
require 'log4r'
require 'nokogiri'
require 'httpclient'

require File.expand_path('../base', __FILE__)

module VagrantPlugins
  module VCloud
    module Driver
      class Meta < Base
        # We use forwardable to do all our driver forwarding
        extend Forwardable
        attr_reader :driver

        def initialize(hostname, username, password, org_name)
          # Setup the base
          super()

          @logger = Log4r::Logger.new('vagrant::provider::vcloud::meta')
          @hostname = hostname
          @username = username
          @password = password
          @org_name = org_name

          # Read and assign the version of vCloud we know which
          # specific driver to instantiate.
          @version = get_api_version(@hostname) || ''

          # Instantiate the proper version driver for vCloud
          @logger.debug("Finding driver for vCloud version: #{@version}")
          driver_map   = {
            '5.1' => Version_5_1,
            # Binding vCloud 5.5 API on our current 5.1 implementation
            '5.5' => Version_5_1
          }

          if @version.start_with?('0.9') ||
             @version.start_with?('1.0') ||
             @version.start_with?('1.5')
            # We only support vCloud Director 5.1 or higher.
            raise Errors::VCloudOldVersion, :version => @version
          end

          driver_klass = nil
          driver_map.each do |key, klass|
            if @version.start_with?(key)
              driver_klass = klass
              break
            end
          end

          if !driver_klass
            supported_versions = driver_map.keys.sort.join(', ')
            raise Errors::VCloudInvalidVersion,
                  :supported_versions => supported_versions
          end

          @logger.info("Using vCloud driver: #{driver_klass}")
          @driver = driver_klass.new(@hostname, @username, @password, @org_name)
        end

        def_delegators  :@driver,
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
          # Create a new HTTP client
          clnt = HTTPClient.new

          # Disable SSL cert verification
          clnt.ssl_config.verify_mode = (OpenSSL::SSL::VERIFY_NONE)

          # Suppress SSL depth message
          clnt.ssl_config.verify_callback = proc { |ok, ctx|; true }

          url = "#{host_url}/api/versions"

          begin
            response = clnt.request('GET', url, nil, nil, nil)
            if !response.ok?
              raise "Warning: unattended code #{response.status} " +
                    "#{response.reason}"
            end

            version_info = Nokogiri.parse(response.body)
            # FIXME: Find a smarter way to check for vCloud API version
            # Changed from .first to .last because that's the way it's defined
            # in the request answer.
            api_version = version_info.css('VersionInfo Version')

            api_version.last.text
          rescue SocketError
            raise Errors::HostNotFound, :message => host_url
          rescue Errno::EADDRNOTAVAIL
            raise Errors::HostNotFound, :message => host_url
          end
        end
      end
    end
  end
end
