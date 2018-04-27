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
#  limitations under the License.
#

require 'ruby-progressbar'
require 'set'
require 'netaddr'
require 'uri'

module VagrantPlugins
  module VCloud
    module Driver
      # Main class to access vCloud rest APIs
      class Version_5_1 < Base
        attr_reader :auth_key, :id

        ##
        # Init the driver with the Vagrantfile information
        def initialize(hostname, username, password, org_name)
          @logger = Log4r::Logger.new('vagrant::provider::vcloud::driver_5_1')
          uri = URI(hostname)
          @api_url = "#{uri.scheme}://#{uri.host}:#{uri.port}/api"
          @host_url = "#{uri.scheme}://#{uri.host}:#{uri.port}"
          @username = username
          @password = password
          @org_name = org_name
          @api_version = '5.5'
          @id = nil

          @cached_vapp_edge_public_ips = {}
        end

        ##
        # Authenticate against the specified server
        def login
          params = {
            'method'  => :post,
            'command' => '/sessions'
          }

          _response, headers = send_request(params)

          if !headers.key?('x-vcloud-authorization')
            raise 'Failed to authenticate: ' \
                  'missing x-vcloud-authorization header'
          end

          @auth_key = headers['x-vcloud-authorization']
        end

        ##
        # Destroy the current session
        def logout
          params = {
            'method'  => :delete,
            'command' => '/session'
          }

          _response, _headers = send_request(params)
          # reset auth key to nil
          @auth_key = nil
        end

        ##
        # Fetch existing organizations and their IDs
        def get_organizations
          params = {
            'method'  => :get,
            'command' => '/org'
          }

          response, _headers = send_request(params)
          orgs = response.css('OrgList Org')

          results = {}
          orgs.each do |org|
            results[org['name']] = URI(org['href']).path.gsub('/api/org/', '')
          end
          results
        end

        ##
        # friendly helper method to fetch an Organization Id by name
        # - name (this isn't case sensitive)
        def get_organization_id_by_name(name)
          result = nil

          # Fetch all organizations
          organizations = get_organizations

          organizations.each do |organization|
            if organization[0].downcase == name.downcase
              result = organization[1]
            end
          end
          result
        end

        ##
        # friendly helper method to fetch an Organization by name
        # - name (this isn't case sensitive)
        def get_organization_by_name(name)
          result = nil

          # Fetch all organizations
          organizations = get_organizations

          organizations.each do |organization|
            if organization[0].downcase == name.downcase
              result = get_organization(organization[1])
            end
          end
          result
        end

        ##
        # Fetch details about an organization:
        # - catalogs
        # - vdcs
        # - networks
        def get_organization(org_id)
          params = {
            'method'  => :get,
            'command' => "/org/#{org_id}"
          }

          response, _headers = send_request(params)

          catalogs = {}
          response.css(
            "Link[type='application/vnd.vmware.vcloud.catalog+xml']"
          ).each do |item|
            catalogs[item['name']] = URI(item['href']).path.gsub(
              '/api/catalog/', ''
            )
          end

          vdcs = {}
          response.css(
            "Link[type='application/vnd.vmware.vcloud.vdc+xml']"
          ).each do |item|
            vdcs[item['name']] = URI(item['href']).path.gsub(
              '/api/vdc/', ''
            )
          end

          networks = {}
          response.css(
            "Link[type='application/vnd.vmware.vcloud.orgNetwork+xml']"
          ).each do |item|
            networks[item['name']] = URI(item['href']).path.gsub(
              '/api/network/', ''
            )
          end

          tasklists = {}
          response.css(
            "Link[type='application/vnd.vmware.vcloud.tasksList+xml']"
          ).each do |item|
            tasklists[item['name']] = URI(item['href']).path.gsub(
              '/api/tasksList/', ''
            )
          end

          {
            :catalogs   => catalogs,
            :vdcs       => vdcs,
            :networks   => networks,
            :tasklists  => tasklists
          }
        end

        ##
        # Fetch details about a given catalog
        def get_catalog(catalog_id)
          params = {
            'method'  => :get,
            'command' => "/catalog/#{catalog_id}"
          }

          response, _headers = send_request(params)
          description = response.css('Description').first
          description = description.text unless description.nil?

          items = {}
          response.css(
            "CatalogItem[type='application/vnd.vmware.vcloud.catalogItem+xml']"
          ).each do |item|
            items[item['name']] = URI(item['href']).path.gsub(
              '/api/catalogItem/', ''
            )
          end
          { :description => description, :items => items }
        end

        ##
        # Friendly helper method to fetch an catalog id by name
        # - organization hash (from get_organization/get_organization_by_name)
        # - catalog name
        def get_catalog_id_by_name(organization, catalog_name)
          result = nil

          organization[:catalogs].each do |catalog|
            if catalog[0].downcase == catalog_name.downcase
              result = catalog[1]
            end
          end

          if result.nil?
            # catalog not found, search in global catalogs as well
            # that are not listed in organization directly
            params = {
              'method'  => :get,
              'command' => '/catalogs/query/',
              'cacheable' => true
            }

            response, _headers = send_request(params)

            catalogs = {}
            response.css(
              'CatalogRecord'
            ).each do |item|
              catalogs[item['name']] = URI(item['href']).path.gsub(
                '/api/catalog/', ''
              )
            end

            catalogs.each do |catalog|
              if catalog[0].downcase == catalog_name.downcase
                result = catalog[1]
              end
            end

          end

          result
        end

        ##
        # Friendly helper method to fetch an catalog by name
        # - organization hash (from get_organization/get_organization_by_name)
        # - catalog name
        def get_catalog_by_name(organization, catalog_name)
          result = nil

          organization[:catalogs].each do |catalog|
            if catalog[0].downcase == catalog_name.downcase
              result = get_catalog(catalog[1])
            end
          end

          result
        end

        ##
        # Fetch details about a given vdc:
        # - description
        # - vapps
        # - networks
        def get_vdc(vdc_id)
          params = {
            'method'  => :get,
            'command' => "/vdc/#{vdc_id}"
          }

          response, _headers = send_request(params)
          description = response.css('Description').first
          description = description.text unless description.nil?

          vapps = {}
          response.css(
            "ResourceEntity[type='application/vnd.vmware.vcloud.vApp+xml']"
          ).each do |item|
            vapps[item['name']] = URI(item['href']).path.gsub(
              '/api/vApp/vapp-', ''
            )
          end

          networks = {}
          response.css(
            "Network[type='application/vnd.vmware.vcloud.network+xml']"
          ).each do |item|
            networks[item['name']] = URI(item['href']).path.gsub(
              '/api/network/', ''
            )
          end
          {
            :description => description, :vapps => vapps, :networks => networks
          }
        end

        ##
        # Friendly helper method to fetch a Organization VDC Id by name
        # - Organization object
        # - Organization VDC Name
        def get_vdc_id_by_name(organization, vdc_name)
          result = nil

          organization[:vdcs].each do |vdc|
            if vdc[0].downcase == vdc_name.downcase
              result = vdc[1]
            end
          end

          result
        end

        ##
        # Friendly helper method to fetch a Organization VDC by name
        # - Organization object
        # - Organization VDC Name
        def get_vdc_by_name(organization, vdc_name)
          result = nil

          organization[:vdcs].each do |vdc|
            if vdc[0].downcase == vdc_name.downcase
              result = get_vdc(vdc[1])
            end
          end

          result
        end

        ##
        # Fetch details about a given catalog item:
        # - description
        # - vApp templates
        def get_catalog_item(catalog_item_id)
          params = {
            'method'  => :get,
            'command' => "/catalogItem/#{catalog_item_id}"
          }

          response, _headers = send_request(params)
          description = response.css('Description').first
          description = description.text unless description.nil?

          items = {}
          response.css(
            "Entity[type='application/vnd.vmware.vcloud.vAppTemplate+xml']"
          ).each do |item|
            items[item['name']] = URI(item['href']).path.gsub(
              '/api/vAppTemplate/vappTemplate-', ''
            )
          end
          { :description => description, :items => items }
        end

        ##
        # friendly helper method to fetch an catalogItem  by name
        # - catalogId (use get_catalog_name(org, name))
        # - catalagItemName
        def get_catalog_item_by_name(catalog_id, catalog_item_name)
          result = nil
          catalog_elems = get_catalog(catalog_id)

          catalog_elems[:items].each do |catalog_elem|

            catalog_item = get_catalog_item(catalog_elem[1])
            if catalog_item[:items][catalog_item_name]
              # This is a vApp Catalog Item

              # fetch CatalogItemId
              catalog_item_id = catalog_item[:items][catalog_item_name]

              # Fetch the catalogItemId information
              params = {
                'method'  => :get,
                'command' => "/vAppTemplate/vappTemplate-#{catalog_item_id}"
              }
              response, _headers = send_request(params)

              # VMs Hash for all the vApp VM entities
              vms_hash = {}
              response.css('/VAppTemplate/Children/Vm').each do |vm_elem|
                vm_name = vm_elem['name']
                vm_id = URI(vm_elem['href']).path.gsub(
                  '/api/vAppTemplate/vm-', ''
                )

                # Add the VM name/id to the VMs Hash
                vms_hash[vm_name] = { :id => vm_id }
              end
              result = {
                catalog_item_name => catalog_item_id, :vms_hash => vms_hash
              }
            end
          end
          result
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
        def get_vapp(vapp_id)
          params = {
            'method'  => :get,
            'command' => "/vApp/vapp-#{vapp_id}"
          }

          response, _headers = send_request(params)

          vapp_node = response.css('VApp').first
          if vapp_node
            name = vapp_node['name']
            status = convert_vapp_status(vapp_node['status'])
          end

          description = response.css('Description').first
          description = description.text unless description.nil?

          ip = response.css('IpAddress').first
          ip = ip.text unless ip.nil?

          vms = response.css('Children Vm')
          vms_hash = {}

          # ipAddress could be namespaced or not:
          # see https://github.com/astratto/vcloud-rest/issues/3
          vms.each do |vm|
            vapp_local_id = vm.css('VAppScopedLocalId')
            addresses = vm.css('rasd|Connection').collect {
              |n| n['vcloud:ipAddress'] || n['ipAddress']
            }
            vms_hash[vm['name'].to_sym] = {
              :addresses            => addresses,
              :status               => convert_vapp_status(vm['status']),
              :id                   => URI(vm['href']).path.gsub('/api/vApp/vm-', ''),
              :vapp_scoped_local_id => vapp_local_id.text
            }
          end

          # TODO: EXPAND INFO FROM RESPONSE
          {
            :name         => name,
            :description  => description,
            :status       => status,
            :ip           => ip,
            :vms_hash     => vms_hash
          }
        end

        ##
        # Delete a given vapp
        # NOTE: It doesn't verify that the vapp is shutdown
        def delete_vapp(vapp_id)
          params = {
            'method'  => :delete,
            'command' => "/vApp/vapp-#{vapp_id}"
          }

          _response, headers = send_request(params)
          task_id = URI(headers['Location']).path.gsub('/api/task/', '')
          task_id
        end

        ##
        # Shutdown a given vapp
        def poweroff_vapp(vapp_id)
          builder = Nokogiri::XML::Builder.new do |xml|
            xml.UndeployVAppParams(
              'xmlns' => 'http://www.vmware.com/vcloud/v1.5'
            ) { xml.UndeployPowerAction 'powerOff' }
          end

          params = {
            'method'  => :post,
            'command' => "/vApp/vapp-#{vapp_id}/action/undeploy"
          }

          _response, headers = send_request(
            params,
            builder.to_xml,
            'application/vnd.vmware.vcloud.undeployVAppParams+xml'
          )
          task_id = URI(headers['Location']).path.gsub('/api/task/', '')
          task_id
        end

        ##
        # Suspend a given vapp
        def suspend_vapp(vapp_id)
          params = {
            'method'  => :post,
            'command' => "/vApp/vapp-#{vapp_id}/power/action/suspend"
          }

          _response, headers = send_request(params)
          task_id = URI(headers['Location']).path.gsub('/api/task/', '')
          task_id
        end

        ##
        # reboot a given vapp
        # This will basically initial a guest OS reboot, and will only work if
        # VMware-tools are installed on the underlying VMs.
        # vShield Edge devices are not affected
        def reboot_vapp(vapp_id)
          params = {
            'method'  => :post,
            'command' => "/vApp/vapp-#{vapp_id}/power/action/reboot"
          }

          _response, headers = send_request(params)
          task_id = URI(headers['Location']).path.gsub('/api/task/', '')
          task_id
        end

        ##
        # reset a given vapp
        # This will basically reset the VMs within the vApp
        # vShield Edge devices are not affected.
        def reset_vapp(vapp_id)
          params = {
            'method'  => :post,
            'command' => "/vApp/vapp-#{vapp_id}/power/action/reset"
          }

          _response, headers = send_request(params)
          task_id = URI(headers['Location']).path.gsub('/api/task/', '')
          task_id
        end

        ##
        # Boot a given vapp
        def poweron_vapp(vapp_id)
          params = {
            'method'  => :post,
            'command' => "/vApp/vapp-#{vapp_id}/power/action/powerOn"
          }

          _response, headers = send_request(params)
          task_id = URI(headers['Location']).path.gsub('/api/task/', '')
          task_id
        end

        #### VM operations ####
        ##
        # Delete a given vm
        # NOTE: It doesn't verify that the vm is shutdown
        def delete_vm(vm_id)
          params = {
            'method'  => :delete,
            'command' => "/vApp/vm-#{vm_id}"
          }

          _response, headers = send_request(params)
          task_id = URI(headers['Location']).path.gsub('/api/task/', '')
          task_id
        end

        ##
        # Poweroff a given VM
        # Using undeploy as a REAL powerOff
        # Only poweroff will put the VM into a partially powered off state.
        def poweroff_vm(vm_id)
          builder = Nokogiri::XML::Builder.new do |xml|
            xml.UndeployVAppParams(
            'xmlns' => 'http://www.vmware.com/vcloud/v1.5'
          ) { xml.UndeployPowerAction 'powerOff' }
          end

          params = {
            'method'  => :post,
            'command' => "/vApp/vm-#{vm_id}/action/undeploy"
          }

          _response, headers = send_request(
            params,
            builder.to_xml,
            'application/vnd.vmware.vcloud.undeployVAppParams+xml'
          )
          task_id = URI(headers['Location']).path.gsub('/api/task/', '')
          task_id
        end

        ##
        # Shutdown a given VM
        # Using undeploy with shutdown, without VMware Tools this WILL FAIL.
        #
        def shutdown_vm(vm_id)
          builder = Nokogiri::XML::Builder.new do |xml|
            xml.UndeployVAppParams(
            'xmlns' => 'http://www.vmware.com/vcloud/v1.5'
          ) { xml.UndeployPowerAction 'shutdown' }
          end

          params = {
            'method'  => :post,
            'command' => "/vApp/vm-#{vm_id}/action/undeploy"
          }

          _response, headers = send_request(
            params,
            builder.to_xml,
            'application/vnd.vmware.vcloud.undeployVAppParams+xml'
          )
          task_id = URI(headers['Location']).path.gsub('/api/task/', '')
          task_id
        end

        ##
        # Suspend a given VM
        def suspend_vm(vm_id)
          builder = Nokogiri::XML::Builder.new do |xml|
            xml.UndeployVAppParams(
              'xmlns' => 'http://www.vmware.com/vcloud/v1.5'
            ) { xml.UndeployPowerAction 'suspend' }
          end

          params = {
            'method'  => :post,
            'command' => "/vApp/vm-#{vm_id}/action/undeploy"
          }

          _response, headers = send_request(
            params,
            builder.to_xml,
            'application/vnd.vmware.vcloud.undeployVAppParams+xml'
          )
          task_id = URI(headers['Location']).path.gsub('/api/task/', '')
          task_id
        end

        ##
        # reboot a given VM
        # This will basically initial a guest OS reboot, and will only work if
        # VMware-tools are installed on the underlying VMs.
        # vShield Edge devices are not affected
        def reboot_vm(vm_id)
          params = {
            'method'  => :post,
            'command' => "/vApp/vm-#{vm_id}/power/action/reboot"
          }

          _response, headers = send_request(params)
          task_id = URI(headers['Location']).path.gsub('/api/task/', '')
          task_id
        end

        ##
        # reset a given VM
        # This will basically reset the VMs within the vApp
        # vShield Edge devices are not affected.
        def reset_vm(vm_id)
          params = {
            'method'  => :post,
            'command' => "/vApp/vm-#{vm_id}/power/action/reset"
          }

          _response, headers = send_request(params)
          task_id = URI(headers['Location']).path.gsub('/api/task/', '')
          task_id
        end

        ##
        # Boot a given VM
        def poweron_vm(vm_id)
          params = {
            'method'  => :post,
            'command' => "/vApp/vm-#{vm_id}/power/action/powerOn"
          }

          _response, headers = send_request(params)
          task_id = URI(headers['Location']).path.gsub('/api/task/', '')
          task_id
        end

        ##
        # Create a catalog in an organization
        def create_catalog(org_id, catalog_name, catalog_description)
          builder = Nokogiri::XML::Builder.new do |xml|
            xml.AdminCatalog(
              'xmlns' => 'http://www.vmware.com/vcloud/v1.5',
              'name' => catalog_name
            ) { xml.Description catalog_description }

          end

          params = {
            'method'  => :post,
            'command' => "/admin/org/#{org_id}/catalogs"
          }

          response, _headers = send_request(
            params,
            builder.to_xml,
            'application/vnd.vmware.admin.catalog+xml'
          )
          task_id = URI(response.css(
              "AdminCatalog Tasks Task[operationName='catalogCreateCatalog']"
            ).first[:href]).path.gsub('/api/task/', '')

          catalog_id = URI(response.css(
              "AdminCatalog Link[type='application/vnd.vmware.vcloud.catalog+xml']"
            ).first[:href]).path.gsub('/api/catalog/', '')

          { :task_id => task_id, :catalog_id => catalog_id }
        end

        ##
        # Create a vapp starting from a template
        #
        # Params:
        # - vdc: the associated VDC
        # - vapp_name: name of the target vapp
        # - vapp_description: description of the target vapp
        # - vapp_templateid: ID of the vapp template
        def create_vapp_from_template(vdc, vapp_name, vapp_description, vapp_template_id, poweron = false)
          builder = Nokogiri::XML::Builder.new do |xml|
            xml.InstantiateVAppTemplateParams(
              'xmlns'     => 'http://www.vmware.com/vcloud/v1.5',
              'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
              'xmlns:ovf' => 'http://schemas.dmtf.org/ovf/envelope/1',
              'name'      => vapp_name,
              'deploy'    => 'true',
              'powerOn'   => poweron
            ) { xml.Description vapp_description xml.Source(
                'href' => "#{@api_url}/vAppTemplate/#{vapp_template_id}"
              )
            }
          end

          params = {
            'method'  => :post,
            'command' => "/vdc/#{vdc}/action/instantiateVAppTemplate"
          }

          response, headers = send_request(
            params,
            builder.to_xml,
            'application/vnd.vmware.vcloud.instantiateVAppTemplateParams+xml'
          )

          vapp_id = URI(headers['Location']).path.gsub('/api/vApp/vapp-', '')

          task = response.css(
            "VApp Task[operationName='vdcInstantiateVapp']"
          ).first

          task_id = URI(task['href']).path.gsub('/api/task/', '')

          { :vapp_id => vapp_id, :task_id => task_id }
        end

        ##
        # Compose a vapp using existing virtual machines
        #
        # Params:
        # - vdc: the associated VDC
        # - vapp_name: name of the target vapp
        # - vapp_description: description of the target vapp
        # - vm_list: hash with IDs of the VMs used in the composing process
        # - network_config: hash of the network configuration for the vapp
        def compose_vapp_from_vm(vdc, vapp_name, vapp_description, vm_list = {}, network_config = [], _cfg)
          builder = Nokogiri::XML::Builder.new do |xml|
            xml.ComposeVAppParams('xmlns' => 'http://www.vmware.com/vcloud/v1.5',
                                  'xmlns:ovf' => 'http://schemas.dmtf.org/ovf/envelope/1',
                                  'deploy' => 'false',
                                  'powerOn' => 'false',
                                  'name' => vapp_name) {
              xml.Description vapp_description
              xml.InstantiationParams {
                xml.NetworkConfigSection {
                  xml['ovf'].Info 'Configuration parameters for logical networks'
                  network_config.each do |network|
                    xml.NetworkConfig('networkName' => network[:name]) {
                      xml.Configuration {
                        if network[:fence_mode] != 'bridged'
                          xml.IpScopes {
                          xml.IpScope {
                            xml.IsInherited(network[:is_inherited] || 'false')
                            xml.Gateway network[:gateway]
                            xml.Netmask network[:netmask]
                            xml.Dns1 network[:dns1] if network[:dns1]
                            xml.Dns2 network[:dns2] if network[:dns2]
                            xml.DnsSuffix network[:dns_suffix] if network[:dns_suffix]
                            xml.IpRanges {
                              xml.IpRange {
                                xml.StartAddress network[:start_address]
                                xml.EndAddress network[:end_address]
                                }
                              }
                            }
                          }
                        end
                        xml.ParentNetwork("href" => "#{@api_url}/network/#{network[:parent_network]}") if network[:parent_network]
                        xml.FenceMode network[:fence_mode]
                        if network[:fence_mode] != 'bridged'
                          xml.Features {
                            if network[:dhcp_enabled] == 'true'
                              xml.DhcpService {
                                xml.IsEnabled "true"
                                xml.DefaultLeaseTime "3600"
                                xml.MaxLeaseTime "7200"
                                xml.IpRange {
                                  xml.StartAddress network[:dhcp_start]
                                  xml.EndAddress network[:dhcp_end]
                                }
                              }
                            end
                            xml.FirewallService {
                              xml.IsEnabled(network[:enable_firewall] || "false")
                            }
                            xml.NatService {
                              xml.IsEnabled "true"
                              xml.NatType "portForwarding"
                              xml.Policy(network[:nat_policy_type] || "allowTraffic")
                            }
                          }
                        end
                      }
                    }
                  end #networks
                }
              }
              vm_list.each do |vm_name, vm_id|
                xml.SourcedItem {
                  xml.Source('href' => "#{@api_url}/vAppTemplate/vm-#{vm_id}", 'name' => vm_name)
                  xml.InstantiationParams {
                    if _cfg.enable_guest_customization.nil? || _cfg.enable_guest_customization
                      xml.GuestCustomizationSection(
                        'xmlns' => 'http://www.vmware.com/vcloud/v1.5',
                        'xmlns:ovf' => 'http://schemas.dmtf.org/ovf/envelope/1') {
                          xml['ovf'].Info 'VM Guest Customization configuration'
                          xml.Enabled true
                          if _cfg.guest_customization_change_sid == true
                            xml.ChangeSid true
                            if _cfg.guest_customization_join_domain == true
                              xml.JoinDomainEnabled true
                              xml.DomainName _cfg.guest_customization_domain_name
                              xml.DomainUserName _cfg.guest_customization_domain_user_name
                              xml.DomainUserPassword _cfg.guest_customization_domain_user_password
                              xml.MachineObjectOU _cfg.guest_customization_domain_ou if !_cfg.guest_customization_domain_ou.nil?
                            end
                          end
                          if _cfg.guest_customization_admin_password_enabled
                            xml.AdminPasswordEnabled true
                            xml.AdminPasswordAuto true if _cfg.guest_customization_admin_password_auto
                            xml.AdminPassword _cfg.guest_customization_admin_password if !_cfg.guest_customization_admin_password.nil?
                            if _cfg.guest_customization_admin_auto_login == true
                              xml.AdminAutoLogonEnabled true
                              xml.AdminAutoLogonCount _cfg.guest_customization_admin_auto_login_count
                            end
                          else
                            xml.AdminPasswordEnabled false
                          end
                          xml.ResetPasswordRequired _cfg.guest_customization_admin_password_reset if !_cfg.guest_customization_admin_password_reset.nil?
                          xml.CustomizationScript{ xml.cdata(_cfg.guest_customization_script) } if !_cfg.guest_customization_script.nil?
                          xml.ComputerName vm_name
                      }
                    end
                    if _cfg.nics.nil? && network_config.length == 1
                      xml.NetworkConnectionSection(
                        'xmlns:ovf' => 'http://schemas.dmtf.org/ovf/envelope/1',
                        'type' => 'application/vnd.vmware.vcloud.networkConnectionSection+xml',
                        'href' => "#{@api_url}/vAppTemplate/vm-#{vm_id}/networkConnectionSection/") {
                          xml['ovf'].Info 'Network config for sourced item'
                          xml.PrimaryNetworkConnectionIndex '0'
                          xml.NetworkConnection('network' => network_config[0][:name]) {
                            xml.NetworkConnectionIndex '0'
                            xml.IsConnected 'true'
                            xml.IpAddressAllocationMode(network_config[0][:ip_allocation_mode] || 'POOL')
                        }
                      }
                    end
                  }
                  xml.NetworkAssignment('containerNetwork' => network_config[0][:name], 'innerNetwork' => network_config[0][:name]) if _cfg.nics.nil? && network_config.length == 1
                }
              end
              xml.AllEULAsAccepted 'true'
            }
          end

          params = {
            'method'  => :post,
            'command' => "/vdc/#{vdc}/action/composeVApp"
          }

          response, headers = send_request(
            params,
            builder.to_xml,
            'application/vnd.vmware.vcloud.composeVAppParams+xml'
          )

          vapp_id = URI(headers['Location']).path.gsub("/api/vApp/vapp-", '')

          task = response.css("VApp Task[operationName='vdcComposeVapp']").first
          task_id = URI(task['href']).path.gsub('/api/task/', '')

          { :vapp_id => vapp_id, :task_id => task_id }
        end

        ##
        # Recompose an existing vapp using existing virtual machines
        #
        # Params:
        # - vdc: the associated VDC
        # - vapp_name: name of the target vapp
        # - vapp_description: description of the target vapp
        # - vm_list: hash with IDs of the VMs to be used in the composing process
        # - network_config: hash of the network configuration for the vapp

        def recompose_vapp_from_vm(vapp_id, vm_list = {}, network_config = [], _cfg)
          original_vapp = get_vapp(vapp_id)

          builder = Nokogiri::XML::Builder.new do |xml|
          xml.RecomposeVAppParams(
            'xmlns' => 'http://www.vmware.com/vcloud/v1.5',
            'xmlns:ovf' => 'http://schemas.dmtf.org/ovf/envelope/1',
            'name' => original_vapp[:name]) {
            xml.Description original_vapp[:description]
            xml.InstantiationParams {}
            vm_list.each do |vm_name, vm_id|
                xml.SourcedItem {
                  xml.Source('href' => "#{@api_url}/vAppTemplate/vm-#{vm_id}", 'name' => vm_name)
                  xml.InstantiationParams {
                    if _cfg.enable_guest_customization.nil? || _cfg.enable_guest_customization
                      xml.GuestCustomizationSection(
                        'xmlns' => 'http://www.vmware.com/vcloud/v1.5',
                        'xmlns:ovf' => 'http://schemas.dmtf.org/ovf/envelope/1') {
                          xml['ovf'].Info 'VM Guest Customization configuration'
                          xml.Enabled true
                          if _cfg.guest_customization_change_sid == true
                            xml.ChangeSid true
                            if _cfg.guest_customization_join_domain == true
                              xml.JoinDomainEnabled true
                              xml.DomainName _cfg.guest_customization_domain_name
                              xml.DomainUserName _cfg.guest_customization_domain_user_name
                              xml.DomainUserPassword _cfg.guest_customization_domain_user_password
                              xml.MachineObjectOU _cfg.guest_customization_domain_ou if !_cfg.guest_customization_domain_ou.nil?
                            end
                          end
                          if _cfg.guest_customization_admin_password_enabled
                            xml.AdminPasswordEnabled true
                            xml.AdminPasswordAuto true if _cfg.guest_customization_admin_password_auto
                            xml.AdminPassword _cfg.guest_customization_admin_password if !_cfg.guest_customization_admin_password.nil?
                            if _cfg.guest_customization_admin_auto_login == true
                              xml.AdminAutoLogonEnabled true
                              xml.AdminAutoLogonCount _cfg.guest_customization_admin_auto_login_count
                            end
                          else
                            xml.AdminPasswordEnabled false
                          end
                          xml.ResetPasswordRequired _cfg.guest_customization_admin_password_reset if !_cfg.guest_customization_admin_password_reset.nil?
                          xml.CustomizationScript{ xml.cdata(_cfg.guest_customization_script) } if !_cfg.guest_customization_script.nil?
                          xml.ComputerName vm_name
                      }
                    end
                    if _cfg.nics.nil? && network_config.length == 1
                      xml.NetworkConnectionSection(
                        'xmlns:ovf' => 'http://schemas.dmtf.org/ovf/envelope/1',
                        'type' => 'application/vnd.vmware.vcloud.networkConnectionSection+xml',
                        'href' => "#{@api_url}/vAppTemplate/vm-#{vm_id}/networkConnectionSection/") {
                          xml['ovf'].Info 'Network config for sourced item'
                          xml.PrimaryNetworkConnectionIndex '0'
                          xml.NetworkConnection('network' => network_config[0][:name]) {
                            xml.NetworkConnectionIndex '0'
                            xml.IsConnected 'true'
                            xml.IpAddressAllocationMode(network_config[0][:ip_allocation_mode] || 'POOL')
                        }
                      }
                    end
                  }
                  xml.NetworkAssignment('containerNetwork' => network_config[0][:name], 'innerNetwork' => network_config[0][:name]) if _cfg.nics.nil? && network_config.length == 1
              }
            end
            xml.AllEULAsAccepted 'true'
          }
          end

          params = {
            'method'  => :post,
            'command' => "/vApp/vapp-#{vapp_id}/action/recomposeVApp"
          }

          response, headers = send_request(
            params,
            builder.to_xml,
            'application/vnd.vmware.vcloud.recomposeVAppParams+xml'
          )

          vapp_id = URI(headers['Location']).path.gsub('/api/vApp/vapp-', '')
          task = response.css("Task[operationName='vdcRecomposeVapp']").first
          task_id = URI(task['href']).path.gsub('/api/task/', '')

          { :vapp_id => vapp_id, :task_id => task_id }
        end

        # Fetch details about a given vapp template:
        # - name
        # - description
        # - Children VMs:
        #   -- ID
        def get_vapp_template(vapp_id)
          params = {
            'method'  => :get,
            'command' => "/vAppTemplate/vappTemplate-#{vapp_id}"
          }

          response, _headers = send_request(params)

          vapp_node = response.css('VAppTemplate').first
          if vapp_node
            name = vapp_node['name']
            convert_vapp_status(vapp_node['status'])
          end

          description = response.css('Description').first
          description = description.text unless description.nil?

          # FIXME: What are those 2 lines for ? disabling for now (tsugliani)
          # ip = response.css('IpAddress').first
          # ip = ip.text unless ip.nil?

          vms = response.css('Children Vm')
          vms_hash = {}

          vms.each do |vm|
            vms_hash[vm['name']] = {
              :id => URI(vm['href']).path.gsub('/api/vAppTemplate/vm-', '')
            }
          end

          # TODO: EXPAND INFO FROM RESPONSE
          { :name => name, :description => description, :vms_hash => vms_hash }
        end

        ##
        # Set vApp port forwarding rules
        #
        # - vapp_id: id of the vapp to be modified
        # - network_name: name of the vapp network to be modified
        # - config: hash with network configuration specifications, must contain an array inside :nat_rules with the nat rules to be applied.
        def set_vapp_port_forwarding_rules(vapp_id, network_name, config = {})
          builder = Nokogiri::XML::Builder.new do |xml|
          xml.NetworkConfigSection(
            'xmlns' => 'http://www.vmware.com/vcloud/v1.5',
            'xmlns:ovf' => 'http://schemas.dmtf.org/ovf/envelope/1') {
            xml['ovf'].Info 'Network configuration'
            xml.NetworkConfig('networkName' => network_name) {
              xml.Configuration {
                xml.ParentNetwork('href' => "#{@api_url}/network/#{config[:parent_network]}")
                xml.FenceMode(config[:fence_mode] || 'isolated')
                xml.Features {
                  xml.NatService {
                    xml.IsEnabled 'true'
                    xml.NatType 'portForwarding'
                    xml.Policy(config[:nat_policy_type] || 'allowTraffic')
                    config[:nat_rules].each do |nat_rule|
                      xml.NatRule {
                        xml.VmRule {
                          xml.ExternalPort nat_rule[:nat_external_port]
                          xml.VAppScopedVmId nat_rule[:vapp_scoped_local_id]
                          xml.VmNicId(nat_rule[:nat_vmnic_id] || '0')
                          xml.InternalPort nat_rule[:nat_internal_port]
                          xml.Protocol(nat_rule[:nat_protocol] || 'TCP')
                        }
                      }
                    end
                  }
                }
              }
            }
          }
          end

          params = {
            'method'  => :put,
            'command' => "/vApp/vapp-#{vapp_id}/networkConfigSection"
          }

          _response, headers = send_request(
            params,
            builder.to_xml,
            'application/vnd.vmware.vcloud.networkConfigSection+xml'
          )

          task_id = URI(headers['Location']).path.gsub("/api/task/", '')
          task_id
        end

        ##
        # Add vApp port forwarding rules
        #
        # - vapp_id: id of the vapp to be modified
        # - network_name: name of the vapp network to be modified
        # - config: hash with network configuration specifications,
        #   must contain an array inside :nat_rules with the nat rules to add.
        #   nat_rules << {
        #     :nat_external_port    => j.to_s,
        #     :nat_internal_port    => "22",
        #     :nat_protocol         => "TCP",
        #     :vm_scoped_local_id   => value[:vapp_scoped_local_id]
        #   }

        def add_vapp_port_forwarding_rules(vapp_id, network_name, edge_network_name, config = {})
          params = {
            'method'  => :get,
            'command' => "/vApp/vapp-#{vapp_id}/networkConfigSection"
          }
          response, _headers = send_request(params)

          nat_svc = response.css("/NetworkConfigSection/NetworkConfig[networkName='#{network_name}']/Configuration/Features/NatService").first

          config[:nat_rules].each do |nr|
            nat_svc << (
              "<NatRule>" +
                "<VmRule>" +
                  "<ExternalPort>#{nr[:nat_external_port]}</ExternalPort>" +
                  "<VAppScopedVmId>#{nr[:vapp_scoped_local_id]}</VAppScopedVmId>" +
                  "<VmNicId>#{nr[:nat_vmnic_id]}</VmNicId>" +
                  "<InternalPort>#{nr[:nat_internal_port]}</InternalPort>" +
                  "<Protocol>#{nr[:nat_protocol]}</Protocol>" +
                "</VmRule>" +
              "</NatRule>"
            )
          end

          params = {
            'method'  => :put,
            'command' => "/vApp/vapp-#{vapp_id}/networkConfigSection"
          }

          _response, headers = send_request(
            params,
            response.to_xml,
            'application/vnd.vmware.vcloud.networkConfigSection+xml'
          )

          task_id = URI(headers['Location']).path.gsub('/api/task/', '')
          task_id
        end
        ##
        # Get vApp port forwarding rules
        #
        # - vapp_id: id of the vApp
        def get_vapp_port_forwarding_rules(vapp_id, network_name=nil)
          params = {
            'method'  => :get,
            'command' => "/vApp/vapp-#{vapp_id}/networkConfigSection"
          }

          response, _headers = send_request(params)

          # FIXME: this will return nil if the vApp uses multiple vApp Networks
          # with Edge devices in natRouted/portForwarding mode.
          nconfig = response.css(
            'NetworkConfigSection/NetworkConfig'
          )
          config = nil
          if nconfig.size > 1
            nconfig.each {|c|
              pn = c.css('/Configuration/ParentNetwork')
              next if pn.size == 0
              if pn.first['name'] == network_name
                config = c.css('/Configuration')
                break
              end
            }
          else
            config = nconfig.css('/Configuration')
          end
          fence_mode = config.css('/FenceMode').text
          nat_type = config.css('/Features/NatService/NatType').text

          unless fence_mode == 'natRouted'
            raise InvalidStateError,
                  'Invalid request because FenceMode must be natRouted.'
          end

          unless nat_type == 'portForwarding'
            raise InvalidStateError,
                  'Invalid request because NatType must be portForwarding.'
          end

          nat_rules = []
          config.css('/Features/NatService/NatRule').each do |rule|
            # portforwarding rules information
            vm_rule = rule.css('VmRule')

            nat_rules << {
              :nat_external_ip      => vm_rule.css('ExternalIpAddress').text,
              :nat_external_port    => vm_rule.css('ExternalPort').text,
              :vapp_scoped_local_id => vm_rule.css('VAppScopedVmId').text,
              :vm_nic_id            => vm_rule.css('VmNicId').text,
              :nat_internal_port    => vm_rule.css('InternalPort').text,
              :nat_protocol         => vm_rule.css('Protocol').text
            }
          end
          nat_rules
        end

        ##
        # Find an edge gateway id from the edge name and vdc_id
        #
        # - edge_gateway_name: Name of the vSE
        # - vdc_id: virtual datacenter id
        #
        def find_edge_gateway_id(edge_gateway_name, vdc_id)
          params = {
            'method'  => :get,
            'command' => '/query?type=edgeGateway&' \
                         'format=records&' \
                         "filter=vdc==#{@api_url}/vdc/#{vdc_id}&" +
                         "filter=name==#{edge_gateway_name}"
          }

          response, _headers = send_request(params)

          edge_gateway = response.css('EdgeGatewayRecord').first

          if edge_gateway
            return URI(edge_gateway['href']).path.gsub(
              '/api/admin/edgeGateway/', ''
            )
          else
            return nil
          end
        end

        ##
        # Redeploy the vShield Edge Gateway VM, due to some knowns issues
        # where the current rules are not "applied" and the EdgeGW is in an
        # unmanageable state.
        #
        def redeploy_edge_gateway(edge_gateway_id)
          params = {
            'method'  => :post,
            'command' => "/admin/edgeGateway/#{edge_gateway_id}/action/redeploy"
          }

          _response, headers = send_request(params)
          task_id = URI(headers['Location']).path.gsub('/api/task/', '')
          task_id
        end

        ##
        # Find an edge gateway network from the edge name and vdc_id, and ip
        #
        # - edge_gateway_name: Name of the vSE
        # - vdc_id: virtual datacenter id
        # - edge_gateway_ip: public ip associated to that vSE
        #

        def find_edge_gateway_network(edge_gateway_name, vdc_id, edge_gateway_ip)
          params = {
            'method'  => :get,
            'command' => '/query?type=edgeGateway&' \
                         'format=records&' \
                         "filter=vdc==#{@api_url}/vdc/#{vdc_id}&" +
                         "filter=name==#{edge_gateway_name}"
          }

          response, _headers = send_request(params)

          edge_gateway = response.css('EdgeGatewayRecord').first

          if edge_gateway
            edge_gateway_id = URI(edge_gateway['href']).path.gsub(
              '/api/admin/edgeGateway/', ''
            )
          end

          params = {
            'method'  => :get,
            'command' => "/admin/edgeGateway/#{edge_gateway_id}"
          }

          response, _headers = send_request(params)
          response.css(
            'EdgeGateway Configuration GatewayInterfaces GatewayInterface'
          ).each do |gw|
            # Only check uplinks, avoid another check
            if gw.css('InterfaceType').text == 'uplink'

              # Loop on all sub-allocation pools
              gw.css('SubnetParticipation IpRanges IpRange').each do |cur_range|

                low_ip = cur_range.css('StartAddress').first.text
                high_ip = cur_range.css('EndAddress').first.text

                range_ip_low = NetAddr.ip_to_i(low_ip)
                range_ip_high = NetAddr.ip_to_i(high_ip)
                test_ip = NetAddr.ip_to_i(edge_gateway_ip)

                # FIXME: replace "===" (tsugliani)
                if (range_ip_low..range_ip_high) === test_ip
                  return gw.css('Network').first[:href]
                end
              end
            end
          end
        end

        ##
        # Get Org Edge port forwarding and firewall rules
        #
        # - vapp_id: id of the vapp to be modified
        # - network_name: name of the vapp network to be modified
        # - config: hash with network configuration specifications,
        #           must contain an array inside :nat_rules with the nat rules
        #           to be applied.
        def get_edge_gateway_rules(edge_gateway_name, vdc_id)
          edge_gateway_id = find_edge_gateway_id(edge_gateway_name, vdc_id)

          params = {
            'method'  => :get,
            'command' => "/admin/edgeGateway/#{edge_gateway_id}"
          }

          response, _headers = send_request(params)

          nat_fw_rules = []

          interesting = response.css(
            'EdgeGateway Configuration EdgeGatewayServiceConfiguration'
          )
          interesting.css('NatService NatRule').each do |node|
            if node.css('RuleType').text == 'DNAT'
              gw_node = node.css('GatewayNatRule')
              nat_fw_rules << {
                :rule_type        => 'DNAT',
                :original_ip      => gw_node.css('OriginalIp').text,
                :original_port    => gw_node.css('OriginalPort').text,
                :translated_ip    => gw_node.css('TranslatedIp').text,
                :translated_port  => gw_node.css('TranslatedPort').text,
                :protocol         => gw_node.css('Protocol').text,
                :is_enabled       => node.css('IsEnabled').text
              }

            end
            if node.css('RuleType').text == 'SNAT'
              gw_node = node.css('GatewayNatRule')
              nat_fw_rules << {
                :rule_type      => 'SNAT',
                :interface_name => gw_node.css('Interface').first['name'],
                :original_ip    => gw_node.css('OriginalIp').text,
                :translated_ip  => gw_node.css('TranslatedIp').text,
                :is_enabled     => node.css('IsEnabled').text
              }
            end
          end

          interesting.css('FirewallService FirewallRule').each do |node|
            if node.css('Port').text == '-1'
              nat_fw_rules << {
                :rule_type             => 'Firewall',
                :id                    => node.css('Id').text,
                :policy                => node.css('Policy').text,
                :description           => node.css('Description').text,
                :destination_ip        => node.css('DestinationIp').text,
                :destination_portrange => node.css('DestinationPortRange').text,
                :source_ip             => node.css('SourceIp').text,
                :source_portrange      => node.css('SourcePortRange').text,
                :is_enabled            => node.css('IsEnabled').text
              }
            end
          end

          nat_fw_rules
        end

        ##
        # Remove NAT/FW rules from a edge gateway device
        #
        # - edge_gateway_name: Name of the vSE
        # - vdc_id: virtual datacenter id
        # - edge_gateway_ip: public ip associated the vSE
        # - vapp_id: vApp identifier to correlate with the vApp Edge

        def remove_edge_gateway_rules(edge_gateway_name, vdc_id, edge_gateway_ip, vapp_id)
          edge_vapp_ip = get_vapp_edge_public_ip(vapp_id)
          edge_gateway_id = find_edge_gateway_id(edge_gateway_name, vdc_id)

          params = {
           'method'  => :get,
           'command' => "/admin/edgeGateway/#{edge_gateway_id}"
          }

          response, _headers = send_request(params)

          interesting = response.css(
            'EdgeGateway Configuration EdgeGatewayServiceConfiguration'
          )
          interesting.css('NatService NatRule').each do |node|
            if node.css('RuleType').text == 'DNAT' &&
               node.css('GatewayNatRule/OriginalIp').text == edge_gateway_ip &&
               node.css('GatewayNatRule/TranslatedIp').text == edge_vapp_ip
              node.remove
            end
            if node.css('RuleType').text == 'SNAT' &&
               node.css('GatewayNatRule/OriginalIp').text == edge_vapp_ip &&
               node.css('GatewayNatRule/TranslatedIp').text == edge_gateway_ip
              node.remove
            end
          end

          interesting.css('FirewallService FirewallRule').each do |node|
            if node.css('Port').text == '-1' &&
               node.css('DestinationIp').text == edge_gateway_ip &&
               node.css('DestinationPortRange').text == 'Any'
              node.remove
            end
          end

          builder = Nokogiri::XML::Builder.new
          builder << interesting

          remove_edge_rules = Nokogiri::XML(builder.to_xml)

          xml = remove_edge_rules.at_css 'EdgeGatewayServiceConfiguration'
          xml['xmlns'] = 'http://www.vmware.com/vcloud/v1.5'

          params = {
            'method'  => :post,
            'command' => "/admin/edgeGateway/#{edge_gateway_id}/action/" +
                         'configureServices'
          }

          _response, headers = send_request(
            params,
            remove_edge_rules.to_xml,
            'application/vnd.vmware.admin.edgeGatewayServiceConfiguration+xml'
          )

          task_id = URI(headers['Location']).path.gsub('/api/task/', '')
          task_id
        end

        #
        # Add Org Edge port forwarding and firewall rules
        #
        # - vapp_id: id of the vapp to be modified
        # - network_name: name of the vapp network to be modified
        # - ports: array with port numbers to forward 1:1 to vApp.
        def add_edge_gateway_rules(edge_gateway_name, vdc_id, edge_gateway_ip, vapp_id, ports)
          edge_vapp_ip = get_vapp_edge_public_ip(vapp_id)
          edge_network_id = find_edge_gateway_network(
            edge_gateway_name,
            vdc_id,
            edge_gateway_ip
          )
          edge_gateway_id = find_edge_gateway_id(edge_gateway_name, vdc_id)

          ### FIXME: tsugliani
          # We need to check the previous variables, especially (edge_*)
          # which can fail in some *weird* situations.
          params = {
             'method'   => :get,
             'command'  => "/admin/edgeGateway/#{edge_gateway_id}"
           }

          response, _headers = send_request(params)

          interesting = response.css(
            'EdgeGateway Configuration EdgeGatewayServiceConfiguration'
          )

          add_snat_rule = true
          interesting.css('NatService NatRule').each do |node|
            if node.css('RuleType').text == 'DNAT' &&
               node.css('GatewayNatRule/OriginalIp').text == edge_gateway_ip &&
               node.css('GatewayNatRule/TranslatedIp').text == edge_vapp_ip &&
               node.css('GatewayNatRule/OriginalPort').text == 'any'
               # remove old DNAT rule any -> any from older vagrant-vcloud versions
              node.remove
            end
            if node.css('RuleType').text == 'SNAT' &&
               node.css('GatewayNatRule/OriginalIp').text == edge_vapp_ip &&
               node.css('GatewayNatRule/TranslatedIp').text == edge_gateway_ip
              add_snat_rule = false
            end
          end

          add_firewall_rule = true
          interesting.css('FirewallService FirewallRule').each do |node|
            if node.css('Port').text == '-1' &&
               node.css('DestinationIp').text == edge_gateway_ip &&
               node.css('DestinationPortRange').text == 'Any'
              add_firewall_rule = false
            end
          end

          builder = Nokogiri::XML::Builder.new
          builder << interesting

          set_edge_rules = Nokogiri::XML(builder.to_xml) do |config|
            config.default_xml.noblanks
          end

          nat_rules = set_edge_rules.at_css('NatService')

          # Add all DNAT port rules edge -> vApp for the given list
          ports.each do |port|
            nat_rule = Nokogiri::XML::Builder.new do |xml|
                xml.NatRule {
                  xml.RuleType 'DNAT'
                  xml.IsEnabled 'true'
                  xml.GatewayNatRule {
                    xml.Interface('href' => edge_network_id )
                    xml.OriginalIp edge_gateway_ip
                    xml.OriginalPort port
                    xml.TranslatedIp edge_vapp_ip
                    xml.TranslatedPort port
                    xml.Protocol 'tcpudp'
                  }
                }
            end
            nat_rules << nat_rule.doc.root.to_xml
          end

          if (add_snat_rule)
            snat_rule = Nokogiri::XML::Builder.new do |xml|
                xml.NatRule {
                  xml.RuleType 'SNAT'
                  xml.IsEnabled 'true'
                  xml.GatewayNatRule {
                    xml.Interface('href' => edge_network_id )
                    xml.OriginalIp edge_vapp_ip
                    xml.TranslatedIp edge_gateway_ip
                    xml.Protocol 'any'
                  }
                }
            end
            nat_rules << snat_rule.doc.root.to_xml
          end


          if (add_firewall_rule)
          firewall_rule_1 = Nokogiri::XML::Builder.new do |xml|
              xml.FirewallRule {
                xml.IsEnabled 'true'
                xml.Description 'Allow Vagrant Communications'
                xml.Policy 'allow'
                xml.Protocols {
                  xml.Any 'true'
                }
                xml.DestinationPortRange 'Any'
                xml.DestinationIp edge_gateway_ip
                xml.SourcePortRange 'Any'
                xml.SourceIp 'Any'
                xml.EnableLogging 'false'
              }
          end
          fw_rules = set_edge_rules.at_css('FirewallService')
            fw_rules << firewall_rule_1.doc.root.to_xml
          end

          xml = set_edge_rules.at_css 'EdgeGatewayServiceConfiguration'
          xml['xmlns'] = 'http://www.vmware.com/vcloud/v1.5'

          params = {
            'method'  => :post,
            'command' => "/admin/edgeGateway/#{edge_gateway_id}/action/" +
                         'configureServices'
          }

          _response, headers = send_request(
            params,
            set_edge_rules.to_xml,
            'application/vnd.vmware.admin.edgeGatewayServiceConfiguration+xml'
          )

          task_id = URI(headers['Location']).path.gsub('/api/task/', '')
          task_id
        end


        ##
        # get vApp edge public IP from the vApp ID
        # Only works when:
        # - vApp needs to be poweredOn
        # - FenceMode is set to "natRouted"
        # - NatType" is set to "portForwarding
        # This will be required to know how to connect to VMs behind the Edge
        # device.
        def get_vapp_edge_public_ip(vapp_id, network_name=nil)
          return @cached_vapp_edge_public_ips["#{vapp_id}#{network_name}"] unless @cached_vapp_edge_public_ips["#{vapp_id}#{network_name}"].nil?

          # Check the network configuration section
          params = {
            'method' => :get,
            'command' => "/vApp/vapp-#{vapp_id}/networkConfigSection"
          }

          response, _headers = send_request(params)

          # FIXME: this will return nil if the vApp uses multiple vApp Networks
          # with Edge devices in natRouted/portForwarding mode.
          nconfig = response.css(
            'NetworkConfigSection/NetworkConfig'
          )
          config = nil
          if nconfig.size > 1
            nconfig.each {|c|
              pn = c.css('/Configuration/ParentNetwork')
              next if pn.size == 0
              if pn.first['name'] == network_name
                config = c.css('/Configuration')
                break
              end
            }
          else
            config = nconfig.css('/Configuration')
          end

          fence_mode = config.css('/FenceMode').text
          nat_type = config.css('/Features/NatService/NatType').text

          unless fence_mode == 'natRouted'
            raise InvalidStateError,
                  'Invalid request because FenceMode must be natRouted.'
          end

          unless nat_type == 'portForwarding'
            raise InvalidStateError,
                  'Invalid request because NatType must be portForwarding.'
          end

          # Check the routerInfo configuration where the global external IP
          # is defined
          edge_ip = config.css('/RouterInfo/ExternalIp').text
          if edge_ip == ''
            return nil
          else
            @cached_vapp_edge_public_ips["#{vapp_id}#{network_name}"] = edge_ip
            return edge_ip
          end
        end

        ##
        # Upload an OVF package
        # - vdc_id
        # - vappName
        # - vappDescription
        # - ovfFile
        # - catalogId
        # - uploadOptions {}
        def upload_ovf(vdc_id, vapp_name, vapp_description, ovf_file, catalog_id, upload_options = {})
          # if send_manifest is not set, setting it true
          if upload_options[:send_manifest].nil? ||
             upload_options[:send_manifest]
            upload_manifest = 'true'
          else
            upload_manifest = 'false'
          end

          builder = Nokogiri::XML::Builder.new do |xml|
            xml.UploadVAppTemplateParams(
              'xmlns' => 'http://www.vmware.com/vcloud/v1.5',
              'xmlns:ovf' => 'http://schemas.dmtf.org/ovf/envelope/1',
              'manifestRequired' => upload_manifest,
              'name' => vapp_name) {
              xml.Description vapp_description
            }
          end

          params = {
            'method'  => :post,
            'command' => "/vdc/#{vdc_id}/action/uploadVAppTemplate"
          }

          @logger.debug('Sending uploadVAppTemplate request...')

          response, headers = send_request(
            params,
            builder.to_xml,
            'application/vnd.vmware.vcloud.uploadVAppTemplateParams+xml'
          )

          # Get vAppTemplate Link from location
          vapp_template = URI(headers['Location']).path.gsub(
            '/api/vAppTemplate/vappTemplate-', ''
          )

          @logger.debug("Getting vAppTemplate ID: #{vapp_template}")
          descriptor_upload = URI(response.css(
            "Files Link[rel='upload:default']"
          ).first[:href]).path.gsub('/transfer/', '')
          transfer_guid = descriptor_upload.gsub('/descriptor.ovf', '')

          ovf_file_basename = File.basename(ovf_file, '.ovf')
          ovf_dir = File.dirname(ovf_file)

          # Send OVF Descriptor
          @logger.debug('Sending OVF Descriptor...')
          upload_url = "/transfer/#{descriptor_upload}"
          upload_filename = "#{ovf_dir}/#{ovf_file_basename}.ovf"
          upload_file(
            upload_url,
            upload_filename,
            vapp_template,
            upload_options
          )

          # Begin the catch for upload interruption
          begin
            params = {
              'method'  => :get,
              'command' => "/vAppTemplate/vappTemplate-#{vapp_template}"
            }

            response, _headers = send_request(params)

            task = response.css(
              "VAppTemplate Task[operationName='vdcUploadOvfContents']"
            ).first
            task_id = URI(task['href']).path.gsub('/api/task/', '')

            # Loop to wait for the upload links to show up in the vAppTemplate
            # we just created
            @logger.debug(
              'Waiting for the upload links to show up in the vAppTemplate ' \
              'we just created.'
            )
            while true
              response, _headers = send_request(params)
              @logger.debug('Request...')
              break unless response.css("Files Link[rel='upload:default']").count == 1
              sleep 1
            end

            if upload_manifest == 'true'
              upload_url = "/transfer/#{transfer_guid}/descriptor.mf"
              upload_filename = "#{ovf_dir}/#{ovf_file_basename}.mf"
              upload_file(
                upload_url,
                upload_filename,
                vapp_template,
                upload_options
              )
            end

            # Start uploading OVF VMDK files
            params = {
              'method'  => :get,
              'command' => "/vAppTemplate/vappTemplate-#{vapp_template}"
            }
            response, _headers = send_request(params)
            response.css(
              "Files File[bytesTransferred='0'] Link[rel='upload:default']"
            ).each do |file|
              file_name = URI(file[:href]).path.gsub("/transfer/#{transfer_guid}/", '')
              upload_filename = "#{ovf_dir}/#{file_name}"
              upload_url = "/transfer/#{transfer_guid}/#{file_name}"
              upload_file(
                upload_url,
                upload_filename,
                vapp_template,
                upload_options
              )
            end

            # Add item to the catalog catalog_id
            builder = Nokogiri::XML::Builder.new do |xml|
              xml.CatalogItem(
                'xmlns' => 'http://www.vmware.com/vcloud/v1.5',
                'type' => 'application/vnd.vmware.vcloud.catalogItem+xml',
                'name' => vapp_name) {
                xml.Description vapp_description
                xml.Entity(
                  'href' => "#{@api_url}/vAppTemplate/" +
                            "vappTemplate-#{vapp_template}"
                  )
              }
            end

            params = {
              'method'  => :post,
              'command' => "/catalog/#{catalog_id}/catalogItems"
            }
            # No debug here (tsugliani)
            _response, _headers = send_request(
              params,
              builder.to_xml,
              'application/vnd.vmware.vcloud.catalogItem+xml'
            )

            task_id

            ######

          rescue Exception => e
            puts "Exception detected: #{e.message}."
            puts 'Aborting task...'

            # Get vAppTemplate Task
            params = {
              'method'  => :get,
              'command' => "/vAppTemplate/vappTemplate-#{vapp_template}"
            }
            response, _headers = send_request(params)

            # Cancel Task
            cancel_hook = URI(response.css(
              "Tasks Task Link[rel='task:cancel']"
            ).first[:href]).path.gsub('/api', '')

            params = {
              'method'  => :post,
              'command' => cancel_hook
            }
            # No debug here (tsugliani)
            _response, _headers = send_request(params)
            raise
          end
        end

        ##
        # Fetch information for a given task
        def get_task(task_id)
          params = {
            'method'  => :get,
            'command' => "/task/#{task_id}"
          }

          response, _headers = send_request(params)

          task = response.css('Task').first
          status = task['status']
          start_time = task['startTime']
          end_time = task['endTime']

          {
            :status     => status,
            :start_time => start_time,
            :end_time   => end_time,
            :response   => response
          }
        end

        ##
        # Poll a given task until completion
        def wait_task_completion(task_id)
          task, errormsg = nil
          loop do
            task = get_task(task_id)
            # @logger.debug(
            #  "Evaluating taskid: #{task_id}, current status #{task[:status]}"
            # )
            break if !['queued','preRunning','running'].include?(task[:status])
            sleep 5
          end

          if task[:status] == 'error'
            @logger.debug('Task Error')
            errormsg = task[:response].css('Error').first
            @logger.debug(
              "Task Error Message #{errormsg['majorErrorCode']} - " +
              "#{errormsg['message']}"
            )
            errormsg =
            "Error code #{errormsg['majorErrorCode']} - #{errormsg['message']}"
          end

          {
            :status     => task[:status],
            :errormsg   => errormsg,
            :start_time => task[:start_time],
            :end_time   => task[:end_time]
          }
        end

        ##
        # Set vApp Network Config
        def set_vapp_network_config(vapp_id, network_name, config = {})
          builder = Nokogiri::XML::Builder.new do |xml|
            xml.NetworkConfigSection(
              'xmlns' => 'http://www.vmware.com/vcloud/v1.5',
              'xmlns:ovf' => 'http://schemas.dmtf.org/ovf/envelope/1'
            ) {
              xml['ovf'].Info 'Network configuration'
              xml.NetworkConfig('networkName' => network_name) {
                xml.Configuration {
                  xml.FenceMode(config[:fence_mode] || 'isolated')
                  xml.RetainNetInfoAcrossDeployments(config[:retain_net] || false)
                  xml.ParentNetwork('href' => config[:parent_network])
                }
              }
            }
          end

          params = {
            'method'  => :put,
            'command' => "/vApp/vapp-#{vapp_id}/networkConfigSection"
          }

          _response, headers = send_request(
            params,
            builder.to_xml,
            'application/vnd.vmware.vcloud.networkConfigSection+xml'
          )

          task_id = URI(headers['Location']).path.gsub('/api/task/', '')
          task_id
        end

        ##
        # Set VM Network Config
        def set_vm_network_config(vm_id, network_name, config = {})
          builder = Nokogiri::XML::Builder.new do |xml|
            xml.NetworkConnectionSection(
              'xmlns' => 'http://www.vmware.com/vcloud/v1.5',
              'xmlns:ovf' => 'http://schemas.dmtf.org/ovf/envelope/1') {
              xml['ovf'].Info 'VM Network configuration'
              xml.PrimaryNetworkConnectionIndex(config[:primary_index] || 0)
              xml.NetworkConnection(
                'network' => network_name,
                'needsCustomization' => true
              ) {
                xml.NetworkConnectionIndex(config[:network_index] || 0)
                xml.IpAddress config[:ip] if config[:ip]
                xml.IsConnected(config[:is_connected] || true)
                xml.IpAddressAllocationMode config[:ip_allocation_mode] if config[:ip_allocation_mode]
              }
            }
          end

          params = {
            'method'  => :put,
            'command' => "/vApp/vm-#{vm_id}/networkConnectionSection"
          }

          _response, headers = send_request(
            params,
            builder.to_xml,
            'application/vnd.vmware.vcloud.networkConnectionSection+xml'
          )

          task_id = URI(headers['Location']).path.gsub('/api/task/', '')
          task_id
        end

        ##
        # Set VM Network Connection state
        def set_vm_network_connected(vm_id)
          params = {
            'method'  => :get,
            'command' => "/vApp/vm-#{vm_id}/networkConnectionSection"
          }
          response, _headers = send_request(params)

          changed = false
          response.css('NetworkConnection').each do |net|
            ic = net.css('IsConnected')
            if ic.text != 'true'
              ic.first.content = 'true'
              changed = true
            end
          end

          if changed
            params = {
              'method'  => :put,
              'command' => "/vApp/vm-#{vm_id}/networkConnectionSection"
            }

            _response, headers = send_request(
              params,
              response.to_xml,
              'application/vnd.vmware.vcloud.networkConnectionSection+xml'
            )

            task_id = URI(headers['Location']).path.gsub('/api/task/', '')
          end
          task_id
        end

        ##
        # Set VM Guest Customization Config
        def set_vm_guest_customization(vm_id, computer_name, config = {})
          builder = Nokogiri::XML::Builder.new do |xml|
          xml.GuestCustomizationSection(
            'xmlns' => 'http://www.vmware.com/vcloud/v1.5',
            'xmlns:ovf' => 'http://schemas.dmtf.org/ovf/envelope/1') {
              xml['ovf'].Info 'VM Guest Customization configuration'
              xml.Enabled config[:enabled] if config[:enabled]
              xml.AdminPasswordEnabled config[:admin_passwd_enabled] if config[:admin_passwd_enabled]
              xml.AdminPassword config[:admin_passwd] if config[:admin_passwd]
              xml.ComputerName computer_name
          }
          end

          params = {
            'method'  => :put,
            'command' => "/vApp/vm-#{vm_id}/guestCustomizationSection"
          }

          _response, headers = send_request(
            params,
            builder.to_xml,
            'application/vnd.vmware.vcloud.guestCustomizationSection+xml'
          )
          task_id = URI(headers['Location']).path.gsub('/api/task/', '')
          task_id
        end

        # Enable VM Nested Hardware-Assisted Virtualization
        def set_vm_nested_hypervisor(vm_id, enable)
          vm = get_vm(vm_id)
          if enable && vm[:hypervisor_enabled] == 'true'
            return nil
          elsif !enable && vm[:hypervisor_enabled] == 'false'
            return nil
          end

          action = enable ? "enable" : "disable"
          params = {
            'method'  => :post,
            'command' => "/vApp/vm-#{vm_id}/action/#{action}NestedHypervisor"
          }

          _response, headers = send_request(params)
          task_id = URI(headers['Location']).path.gsub('/api/task/', '')
          task_id
        end

        ##
        # Set memory and number of cpus in virtualHardwareSection of a given vm
        # returns task_id or nil if there is no task to wait for
        def set_vm_hardware(vm_id, cfg)
          params = {
            'method'  => :get,
            'command' => "/vApp/vm-#{vm_id}/virtualHardwareSection"
          }

          changed = false
          instance_id = -1
          hdd_address_on_parent = -1
          hdd_parent_id = nil
          hdd_bus_type = nil
          hdd_bus_sub_type = nil
          hdd_count = 0
          nic_count = 0
          nic_address_on_parent = -1
          response, _headers = send_request(params)

          response.css('ovf|Item').each do |item|
            type = item.css('rasd|ResourceType').first
            instance_id = [ instance_id, item.css('rasd|InstanceID').first.text.to_i ].max
            if type.content == '3'
              # cpus
              if cfg.cpus
                if item.at_css('rasd|VirtualQuantity').content != cfg.cpus.to_s
                  item.at_css('rasd|VirtualQuantity').content = cfg.cpus
                  item.at_css('rasd|ElementName').content = "#{cfg.cpus} virtual CPU(s)"
                  changed = true
                end
              end
            elsif type.content == '4'
              # memory
              if cfg.memory
                if item.at_css('rasd|VirtualQuantity').content != cfg.memory.to_s
                  item.at_css('rasd|VirtualQuantity').content = cfg.memory
                  item.at_css('rasd|ElementName').content = "#{cfg.memory} MB of memory"
                  changed = true
                end
              end
            elsif type.content == '10'
              # network card
              nic_address_on_parent = nic_address_on_parent + 1
              # nic_address_on_parent = [ nic_address_on_parent, item.css('rasd|AddressOnParent').first.text.to_i ].max
              next if !cfg.nics || nic_count == cfg.nics.length
              nic = cfg.nics[nic_count]

              orig_mac = item.css('rasd|Address').first.text
              orig_ip = item.css('rasd|Connection').first['vcloud:ipAddress']
              orig_address_mode = item.css('rasd|Connection').first['vcloud:ipAddressingMode']
              orig_primary = item.css('rasd|Connection').first['vcloud:primaryNetworkConnection']
              orig_network = item.css('rasd|Connection').first.text
              orig_parent = item.css('rasd|AddressOnParent').first.text
              # resourceSubType cannot be changed for an existing network card

              if !nic[:mac].nil?
                changed = true if nic[:mac].upcase != orig_mac.upcase
              end
              if !nic[:ip].nil?
                changed = true if orig_ip.nil? || nic[:ip].upcase != orig_ip.upcase
              end
              changed = true if nic[:ip_mode].upcase != orig_address_mode.upcase
              changed = true if nic[:primary] != orig_primary
              changed = true if nic[:network].upcase != orig_network.upcase
              changed = true if nic_address_on_parent != orig_parent

              if changed
                item.css('rasd|Address').first.content = nic[:mac] if !nic[:mac].nil?
                item.css('rasd|AddressOnParent').first.content = nic_address_on_parent if nic_address_on_parent != orig_parent
                conn = item.css('rasd|Connection').first
                conn.content = nic[:network]
                if nic[:ip_mode].upcase == 'DHCP'
                  conn['vcloud:ipAddressingMode'] = 'DHCP'
                elsif nic[:ip_mode].upcase == 'STATIC'
                  conn['vcloud:ipAddressingMode'] = 'MANUAL'
                  conn['vcloud:ipAddress'] = nic[:ip]
                elsif nic[:ip_mode].upcase == 'POOL'
                  conn['vcloud:ipAddressingMode'] = 'POOL'
                  conn['vcloud:ipAddress'] = nic[:ip] if !nic[:ip].nil?
                end
                conn['vcloud:primaryNetworkConnection'] = nic[:primary]
              end
              nic_count = nic_count + 1
            elsif type.content == '17'
              # hard disk
              hdd_count = hdd_count + 1
              if hdd_parent_id.nil?
                hdd_parent_id = item.css('rasd|Parent').first.text
                hdd_bus_type = item.css('rasd|HostResource').first[:busType]
                hdd_bus_sub_type = item.css('rasd|HostResource').first[:busSubType]
              end
              if hdd_parent_id == item.css('rasd|Parent').first.text
                hdd_address_on_parent = [ hdd_address_on_parent,  item.css('rasd|AddressOnParent').first.text.to_i ].max
              end
            end
          end

          if cfg.add_hdds
            changed = true
            cfg.add_hdds.each do |hdd_size|
              hdd_address_on_parent = hdd_address_on_parent + 1
              instance_id = instance_id + 1
              newhdd = Nokogiri::XML::Builder.new do |xml|
                xml.root('xmlns:rasd' => 'http://schemas.dmtf.org/wbem/wscim/1/cim-schema/2/CIM_ResourceAllocationSettingData',
                         'xmlns:ovf' => 'http://schemas.dmtf.org/ovf/envelope/1') do
                  xml['ovf'].Item {
                    xml['rasd'].AddressOnParent(hdd_address_on_parent)
                    xml['rasd'].Description("Hard disk")
                    xml['rasd'].ElementName("Hard disk #{hdd_address_on_parent+1}")
                    xml['rasd'].HostResource()
                    xml['rasd'].InstanceID(instance_id)
                    xml['rasd'].Parent(hdd_parent_id)
                    xml['rasd'].ResourceType(17)
                  }
                end
              end
              hr = newhdd.doc.css('rasd|HostResource').first
              hr['xmlns:vcloud'] = 'http://www.vmware.com/vcloud/v1.5'
              hr['vcloud:busSubType'] = hdd_bus_sub_type
              hr['vcloud:busType'] = hdd_bus_type
              hr['vcloud:capacity'] = hdd_size
              response.css('ovf|Item').last.add_next_sibling(newhdd.doc.css('ovf|Item'))
            end
          end

          if cfg.nics
            cfg.nics.each_with_index do |nic, i|
              next if i < nic_count
              changed = true
              nic_address_on_parent = nic_address_on_parent + 1
              instance_id = instance_id + 1
              newnic = Nokogiri::XML::Builder.new do |xml|
                xml.root('xmlns:rasd' => 'http://schemas.dmtf.org/wbem/wscim/1/cim-schema/2/CIM_ResourceAllocationSettingData',
                         'xmlns:ovf' => 'http://schemas.dmtf.org/ovf/envelope/1') do
                  xml['ovf'].Item {
                    xml['rasd'].Address(nic[:mac]) if !nic[:mac].nil?
                    xml['rasd'].AddressOnParent(nic_address_on_parent)
                    xml['rasd'].AutomaticAllocation(true)
                    xml['rasd'].Connection(nic[:network])
                    xml['rasd'].Description("#{nic[:type] || :vmxnet3} ethernet adapter")
                    xml['rasd'].ElementName("Network adapter #{nic_count}")
                    xml['rasd'].InstanceID(instance_id)
                    xml['rasd'].ResourceSubType(nic[:type] || :vmxnet3)
                    xml['rasd'].ResourceType(10)
                  }
                end
              end
              conn = newnic.doc.css('rasd|Connection').first
              conn['xmlns:vcloud'] = 'http://www.vmware.com/vcloud/v1.5'
              if nic[:ip_mode].upcase == 'DHCP'
                conn['vcloud:ipAddressingMode'] = 'DHCP'
              elsif nic[:ip_mode].upcase == 'STATIC'
                conn['vcloud:ipAddressingMode'] = 'MANUAL'
                conn['vcloud:ipAddress'] = nic[:ip]
              elsif nic[:ip_mode].upcase == 'POOL'
                conn['vcloud:ipAddressingMode'] = 'POOL'
                conn['vcloud:ipAddress'] = nic[:ip] if !nic[:ip].nil?
              end
              conn['vcloud:primaryNetworkConnection'] = nic[:primary]
              response.css('ovf|Item').last.add_next_sibling(newnic.doc.css('ovf|Item'))
            end
          end

          if changed
            params = {
              'method'  => :put,
              'command' => "/vApp/vm-#{vm_id}/virtualHardwareSection"
            }

            _response, headers = send_request(
              params,
              response.to_xml,
              'application/vnd.vmware.vcloud.virtualhardwaresection+xml'
            )

            task_id = URI(headers['Location']).path.gsub('/api/task/', '')
            task_id
          else
            return nil
          end
        end


        ##
        # Add metadata
        def set_vapp_metadata(id, data)
          task_id = set_metadata "vApp/vapp-#{id}", data
          task_id
        end


        ##
        # Add metadata
        def set_vm_metadata(id, data)
          task_id = set_metadata "vApp/vm-#{id}", data
          task_id
        end


        ##
        # Add metadata
        def set_metadata(link, data)
          params = {
            'method'  => :post,
            'command' => "/#{link}/metadata"
          }

          md = Nokogiri::XML::Builder.new do |xml|
            xml.Metadata('xmlns' => 'http://www.vmware.com/vcloud/v1.5',
                         'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
                         'type' => 'application/vnd.vmware.vcloud.metadata+xml') do
              data.each do |d|
                xml.MetadataEntry('type' => 'application/vnd.vmware.vcloud.metadata.value+xml') {
                  xml.Key(d[0])
                  if d[1].kind_of?(Integer)
                    typ = 'MetadataNumberValue'
                  elsif !!d[1] == d[1] # boolean
                    typ = 'MetadataBooleanValue'
                  else
                    typ = 'MetadataStringValue'
                  end
                  xml.TypedValue('xsi:type' => typ) {
                    xml.Value(d[1])
                  }
                }
              end
            end
          end

          _response, headers = send_request(
            params,
            md.to_xml,
            'application/vnd.vmware.vcloud.metadata+xml'
          )

          task_id = URI(headers['Location']).path.gsub('/api/task/', '')
          task_id

        end

        ##
        # Set OVF data
        def set_ovf_properties(vm_id, properties)
          params = {
            'method'  => :get,
            'command' => "/vApp/vm-#{vm_id}/productSections"
          }
          response, _headers = send_request(params)

          changed = false
          response.css('ovf|Property').each do |prop|
            next if prop['ovf:userConfigurable'] == 'false'
            key = prop['ovf:key']
            next if !properties[ key ]
            if properties[ key ] != prop['ovf:value']
              changed = true
              prop['ovf:value'] = properties[ key ]
            end
          end

          if changed
            params = {
              'method'  => :put,
              'command' => "/vApp/vm-#{vm_id}/productSections"
            }
            _response, headers = send_request(
              params,
              response.to_xml,
              'application/vnd.vmware.vcloud.productSections+xml'
            )

            task_id = URI(headers['Location']).path.gsub('/api/task/', '')
            return task_id
          end
          return nil
        end

        ##
        # Fetch details about a given VM
        def get_vm(vm_id)
          params = {
            'method'  => :get,
            'command' => "/vApp/vm-#{vm_id}"
          }

          response, _headers = send_request(params)

          hypervisor_enabled = response[:nestedHypervisorEnabled]
          os_desc = response.css('ovf|OperatingSystemSection ovf|Description').first.text

          networks = {}
          primary_network = response.css('PrimaryNetworkConnectionIndex').first.text.to_i
          response.css('NetworkConnection').each do |network|
            ip = network.css('IpAddress').first
            ip = ip.text if ip
            primary = false
            primary = true if network.css('NetworkConnectionIndex').first.text.to_i == primary_network

            networks[network['network']] = {
              :primary            => primary,
              :index              => network.css('NetworkConnectionIndex').first.text,
              :ip                 => ip,
              :is_connected       => network.css('IsConnected').first.text,
              :mac_address        => network.css('MACAddress').first.text,
              :ip_allocation_mode => network.css('IpAddressAllocationMode').first.text
            }
          end

          admin_password = response.css('GuestCustomizationSection AdminPassword').first
          admin_password = admin_password.text if admin_password

          # make the lines shorter by adjusting the nokogiri css namespace
          guest_css = response.css('GuestCustomizationSection')
          guest_customizations = {
            :enabled                => guest_css.css('Enabled').first.text,
            :admin_passwd_enabled   => guest_css.css('AdminPasswordEnabled').first.text,
            :admin_passwd_auto      => guest_css.css('AdminPasswordAuto').first.text,
            :admin_passwd           => admin_password,
            :reset_passwd_required  => guest_css.css('ResetPasswordRequired').first.text,
            :computer_name          => guest_css.css('ComputerName').first.text
          }

          {
            :os_desc              => os_desc,
            :networks             => networks,
            :guest_customizations => guest_customizations,
            :hypervisor_enabled   => hypervisor_enabled
          }
        end
      end # Class Version 5.1
    end # Module Driver
  end # Module VCloud
end # Module VagrantPlugins
