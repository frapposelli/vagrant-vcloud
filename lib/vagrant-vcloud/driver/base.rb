#
# Author:: Stefano Tortarolo (<stefano.tortarolo@gmail.com>)
# Copyright:: Copyright (c) 2012
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require 'rest-client'
require 'nokogiri'
require 'httpclient'
require 'ruby-progressbar'

module VagrantPlugins
  module VCloud
    module Driver
      class UnauthorizedAccess < StandardError; end
      class WrongAPIVersion < StandardError; end
      class WrongItemIDError < StandardError; end
      class InvalidStateError < StandardError; end
      class InternalServerError < StandardError; end
      class UnhandledError < StandardError; end

      # Main class to access vCloud rest APIs
      class Base
        attr_reader :api_url, :auth_key

        def initialize(host, username, password, org_name, api_version)

          # <SupportedVersions xmlns="http://www.vmware.com/vcloud/versions" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.vmware.com/vcloud/versions http://cloud.tsugliani.fr/api/versions/schema/versions.xsd">
          #  <VersionInfo>
          #   <Version>1.5</Version>


          @host = host
          @api_url = "#{host}/api"
          @host_url = "#{host}"
          @username = username
          @password = password
          @org_name = org_name
          @api_version = (api_version || "5.1")
        end

        ##
        # Authenticate against the specified server
        def login
        end

        ##
        # Destroy the current session
        def logout
        end

        ##
        # Fetch existing organizations and their IDs
        def get_organizations
        end

        ##
        # friendly helper method to fetch an Organization Id by name
        # - name (this isn't case sensitive)
        def get_organization_id_by_name(name)
        end


        ##
        # friendly helper method to fetch an Organization by name
        # - name (this isn't case sensitive)
        def get_organization_by_name(name)
        end

        ##
        # Fetch details about an organization:
        # - catalogs
        # - vdcs
        # - networks
        def get_organization(orgId)
        end

        ##
        # Fetch details about a given catalog
        def get_catalog(catalogId)
        end

        ##
        # Friendly helper method to fetch an catalog id by name
        # - organization hash (from get_organization/get_organization_by_name)
        # - catalog name
        def get_catalog_id_by_name(organization, catalogName)
        end

        ##
        # Friendly helper method to fetch an catalog by name
        # - organization hash (from get_organization/get_organization_by_name)
        # - catalog name
        def get_catalog_by_name(organization, catalogName)
        end

        ##
        # Fetch details about a given vdc:
        # - description
        # - vapps
        # - networks
        def get_vdc(vdcId)
        end

        ##
        # Friendly helper method to fetch a Organization VDC Id by name
        # - Organization object
        # - Organization VDC Name
        def get_vdc_id_by_name(organization, vdcName)
        end

        ##
        # Friendly helper method to fetch a Organization VDC by name
        # - Organization object
        # - Organization VDC Name
        def get_vdc_by_name(organization, vdcName)
        end

        ##
        # Fetch details about a given catalog item:
        # - description
        # - vApp templates
        def get_catalog_item(catalogItemId)
        end

        ##
        # friendly helper method to fetch an catalogItem  by name
        # - catalogId (use get_catalog_name(org, name))
        # - catalagItemName 
        def get_catalog_item_by_name(catalogId, catalogItemName)
        end  

        ##
        # Fetch details about a given vapp:
        # - name
        # - description
        # - status
        # - IP
        # - Children VMs:
        #   -- IP addresses
        #   -- status
        #   -- ID
        def get_vapp(vAppId)
        end

        ##
        # Delete a given vapp
        # NOTE: It doesn't verify that the vapp is shutdown
        def delete_vapp(vAppId)
        end

        ##
        # Suspend a given vapp
        def suspend_vapp(vAppId)
        end

        ##
        # reboot a given vapp
        # This will basically initial a guest OS reboot, and will only work if
        # VMware-tools are installed on the underlying VMs.
        # vShield Edge devices are not affected
        def reboot_vapp(vAppId)
        end

        ##
        # reset a given vapp
        # This will basically reset the VMs within the vApp
        # vShield Edge devices are not affected.
        def reset_vapp(vAppId)
        end

        ##
        # Boot a given vapp
        def poweron_vapp(vAppId)
        end

        ##
        # Create a vapp starting from a template
        #
        # Params:
        # - vdc: the associated VDC
        # - vapp_name: name of the target vapp
        # - vapp_description: description of the target vapp
        # - vapp_templateid: ID of the vapp template
        def create_vapp_from_template(vdc, vapp_name, vapp_description, vapp_templateid, poweron=false)
        end

        ##
        # Compose a vapp using existing virtual machines
        #
        # Params:
        # - vdc: the associated VDC
        # - vapp_name: name of the target vapp
        # - vapp_description: description of the target vapp
        # - vm_list: hash with IDs of the VMs to be used in the composing process
        # - network_config: hash of the network configuration for the vapp
        def compose_vapp_from_vm(vdc, vapp_name, vapp_description, vm_list={}, network_config={})
        end

        # Fetch details about a given vapp template:
        # - name
        # - description
        # - Children VMs:
        #   -- ID
        def get_vapp_template(vAppId)
        end

        ##
        # Set vApp port forwarding rules
        #
        # - vappid: id of the vapp to be modified
        # - network_name: name of the vapp network to be modified
        # - config: hash with network configuration specifications, must contain an array inside :nat_rules with the nat rules to be applied.
        def set_vapp_port_forwarding_rules(vappid, network_name, config={})
        end

        ##
        # Get vApp port forwarding rules
        #
        # - vappid: id of the vApp
        def get_vapp_port_forwarding_rules(vAppId)
        end

        ##
        # get vApp edge public IP from the vApp ID
        # Only works when:
        # - vApp needs to be poweredOn
        # - FenceMode is set to "natRouted"
        # - NatType" is set to "portForwarding
        # This will be required to know how to connect to VMs behind the Edge device.
        def get_vapp_edge_public_ip(vAppId)
        end

        ##
        # Upload an OVF package
        # - vdcId
        # - vappName
        # - vappDescription
        # - ovfFile
        # - catalogId
        # - uploadOptions {}
        def upload_ovf(vdcId, vappName, vappDescription, ovfFile, catalogId, uploadOptions={})
        end

        ##
        # Fetch information for a given task
        def get_task(taskid)
        end

        ##
        # Poll a given task until completion
        def wait_task_completion(taskid)
        end

        ##
        # Set vApp Network Config
        def set_vapp_network_config(vappid, network_name, config={})
        end

        ##
        # Set VM Network Config
        def set_vm_network_config(vmid, network_name, config={})
        end


        ##
        # Set VM Guest Customization Config
        def set_vm_guest_customization(vmid, computer_name, config={})
        end

        ##
        # Fetch details about a given VM
        def get_vm(vmId)
        end

        def get_api_version(host_url)

          request = RestClient::Request.new(:method => "GET",
                                           :url => "#{host_url}/api/versions")
          begin
            response = request.execute
            if ![200, 201, 202, 204].include?(response.code)
              puts "Warning: unattended code #{response.code}"
            end

          # <SupportedVersions xmlns="http://www.vmware.com/vcloud/versions" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.vmware.com/vcloud/versions http://cloud.tsugliani.fr/api/versions/schema/versions.xsd">
          #  <VersionInfo>
          #   <Version>1.5</Version>


          versionInfo = Nokogiri.parse(response)
          apiVersion = versionInfo.css("VersionInfo Version").first.to_s

          [apiVersion]
          rescue
            ## FIXME: Raise a realistic error, like host not found or url not found.
            raise
          end
        end


      end # class
    end
  end
end