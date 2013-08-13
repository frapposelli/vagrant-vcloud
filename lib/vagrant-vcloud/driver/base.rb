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

require "log4r"
require "vagrant/util/busy"
require "vagrant/util/platform"
require "vagrant/util/retryable"
require "vagrant/util/subprocess"


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
        include Vagrant::Util::Retryable

        def initialize
          @logger = Log4r::Logger.new("vagrant::provider::vcloud::base")
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

        private
          ##
          # Sends a synchronous request to the vCloud API and returns the response as parsed XML + headers.
          def send_request(params, payload=nil, content_type=nil)
            headers = {:accept => "application/*+xml;version=#{@api_version}"}
            if @auth_key
              headers.merge!({:x_vcloud_authorization => @auth_key})
            end

            if content_type
              headers.merge!({:content_type => content_type})
            end

            request = RestClient::Request.new(:method => params['method'],
                                             :user => "#{@username}@#{@org_name}",
                                             :password => @password,
                                             :headers => headers,
                                             :url => "#{@api_url}#{params['command']}",
                                             :payload => payload)


            begin
              response = request.execute
              if ![200, 201, 202, 204].include?(response.code)
                puts "Warning: unattended code #{response.code}"
              end

              # TODO: handle asynch properly, see TasksList
              [Nokogiri.parse(response), response.headers]
            rescue RestClient::ResourceNotFound => e
              raise Errors::ObjectNotFound
            rescue RestClient::Unauthorized => e
              raise UnauthorizedAccess, "Client not authorized. Please check your credentials."
            rescue RestClient::BadRequest => e
              body = Nokogiri.parse(e.http_body)
              message = body.css("Error").first["message"]

              case message
              when /The request has invalid accept header/
                raise WrongAPIVersion, "Invalid accept header. Please verify that the server supports v.#{@api_version} or specify a different API Version."
              when /validation error on field 'id': String value has invalid format or length/
                raise WrongItemIDError, "Invalid ID specified. Please verify that the item exists and correctly typed."
              when /The requested operation could not be executed on vApp "(.*)". Stop the vApp and try again/
                raise Errors::InvalidStateError, :message => "Invalid request because vApp is running. Stop vApp '#{$1}' and try again."
              when /The requested operation could not be executed since vApp "(.*)" is not running/
                raise Errors::InvalidStateError, :message => "Invalid request because vApp is stopped. Start vApp '#{$1}' and try again."
              when /The administrator password cannot be empty when it is enabled and automatic password generation is not selected/
                raise Errors::InvalidConfigError
              else
                raise UnhandledError, "BadRequest - unhandled error: #{message}.\nPlease report this issue."
              end
            rescue RestClient::Forbidden => e
              body = Nokogiri.parse(e.http_body)
              message = body.css("Error").first["message"]
              raise UnauthorizedAccess, "Operation not permitted: #{message}."
            rescue RestClient::InternalServerError => e
              body = Nokogiri.parse(e.http_body)
              message = body.css("Error").first["message"]
              raise InternalServerError, "Internal Server Error: #{message}."
            end
          end

          ##
          # Upload a large file in configurable chunks, output an optional progressbar
          def upload_file(uploadURL, uploadFile, vAppTemplate, config={})

            # Set chunksize to 10M if not specified otherwise
            chunkSize = (config[:chunksize] || 10485760)

            # Set progress bar to default format if not specified otherwise
            progressBarFormat = (config[:progressbar_format] || "%t Progress: %p%% %e")

            # Set progress bar length to 120 if not specified otherwise
            progressBarLength = (config[:progressbar_length] || 80)

            # Open our file for upload
            uploadFileHandle = File.new(uploadFile, "rb" )
            fileName = File.basename(uploadFileHandle)

            progressBarTitle = "Uploading: " + fileName.to_s

            # Create a progressbar object if progress bar is enabled
            if config[:progressbar_enable] == true && uploadFileHandle.size.to_i > chunkSize
              progressbar = ProgressBar.create(
                :title => progressBarTitle,
                :starting_at => 0,
                :total => uploadFileHandle.size.to_i,
                ##:length => progressBarLength,
                :format => progressBarFormat
              )
            else
              puts progressBarTitle
            end
            # Create a new HTTP client
            clnt = HTTPClient.new

            # Disable SSL cert verification
            clnt.ssl_config.verify_mode=(OpenSSL::SSL::VERIFY_NONE)

            # Suppress SSL depth message
            clnt.ssl_config.verify_callback=proc{ |ok, ctx|; true };

            # Perform ranged upload until the file reaches its end
            until uploadFileHandle.eof?

              # Create ranges for this chunk upload
              rangeStart = uploadFileHandle.pos
              rangeStop = uploadFileHandle.pos.to_i + chunkSize

              # Read current chunk
              fileContent = uploadFileHandle.read(chunkSize)

              # If statement to handle last chunk transfer if is > than filesize
              if rangeStop.to_i > uploadFileHandle.size.to_i
                contentRange = "bytes #{rangeStart.to_s}-#{uploadFileHandle.size.to_s}/#{uploadFileHandle.size.to_s}"
                rangeLen = uploadFileHandle.size.to_i - rangeStart.to_i
              else
                contentRange = "bytes #{rangeStart.to_s}-#{rangeStop.to_s}/#{uploadFileHandle.size.to_s}"
                rangeLen = rangeStop.to_i - rangeStart.to_i
              end

              # Build headers
              extheader = {
                'x-vcloud-authorization' => @auth_key,
                'Content-Range' => contentRange,
                'Content-Length' => rangeLen.to_s
              }

              begin
                uploadRequest = "#{@host_url}#{uploadURL}"
                connection = clnt.request('PUT', uploadRequest, nil, fileContent, extheader)

                if config[:progressbar_enable] == true && uploadFileHandle.size.to_i > chunkSize
                  params = {
                    'method' => :get,
                    'command' => "/vAppTemplate/vappTemplate-#{vAppTemplate}"
                  }
                  response, headers = send_request(params)

                  response.css("Files File [name='#{fileName}']").each do |file|
                    progressbar.progress=file[:bytesTransferred].to_i
                  end
                end
              rescue
                retryTime = (config[:retry_time] || 5)
                puts "Range #{contentRange} failed to upload, retrying the chunk in #{retryTime.to_s} seconds, to stop the action press CTRL+C."
                sleep retryTime.to_i
                retry
              end
            end
            uploadFileHandle.close
          end


          ##
          # Convert vApp status codes into human readable description
          def convert_vapp_status(status_code)
            case status_code.to_i
              when 0
                'suspended'
              when 3
                'paused'
              when 4
                'running'
              when 8
                'stopped'
              when 10
                'mixed'
              else
                "Unknown #{status_code}"
            end
          end

      end # class
    end
  end
end