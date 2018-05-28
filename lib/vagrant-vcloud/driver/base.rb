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

require 'log4r'
require 'vagrant/util/busy'
require 'vagrant/util/platform'
require 'vagrant/util/retryable'
require 'vagrant/util/subprocess'
require 'awesome_print'

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
          @logger = Log4r::Logger.new('vagrant::provider::vcloud::base')
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
        def get_organization(org_id)
        end

        ##
        # Fetch details about a given catalog
        def get_catalog(catalog_id)
        end

        ##
        # Friendly helper method to fetch an catalog id by name
        # - organization hash (from get_organization/get_organization_by_name)
        # - catalog name
        def get_catalog_id_by_name(organization, catalog_name)
        end

        ##
        # Friendly helper method to fetch an catalog by name
        # - organization hash (from get_organization/get_organization_by_name)
        # - catalog name
        def get_catalog_by_name(organization, catalog_name)
        end

        ##
        # Fetch details about a given vdc:
        # - description
        # - vapps
        # - networks
        def get_vdc(vdc_id)
        end

        ##
        # Friendly helper method to fetch a Organization VDC Id by name
        # - Organization object
        # - Organization VDC Name
        def get_vdc_id_by_name(organization, vdc_name)
        end

        ##
        # Friendly helper method to fetch a Organization VDC by name
        # - Organization object
        # - Organization VDC Name
        def get_vdc_by_name(organization, vdc_name)
        end

        ##
        # Fetch details about a given catalog item:
        # - description
        # - vApp templates
        def get_catalog_item(catalog_item_id)
        end

        ##
        # friendly helper method to fetch an catalogItem  by name
        # - catalogId (use get_catalog_name(org, name))
        # - catalagItemName
        def get_catalog_item_by_name(catalog_id, catalog_item_name)
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
        end

        ##
        # Delete a given vapp
        # NOTE: It doesn't verify that the vapp is shutdown
        def delete_vapp(vapp_id)
        end

        ##
        # Suspend a given vapp
        def suspend_vapp(vapp_id)
        end

        ##
        # reboot a given vapp
        # This will basically initial a guest OS reboot, and will only work if
        # VMware-tools are installed on the underlying VMs.
        # vShield Edge devices are not affected
        def reboot_vapp(vapp_id)
        end

        ##
        # reset a given vapp
        # This will basically reset the VMs within the vApp
        # vShield Edge devices are not affected.
        def reset_vapp(vapp_id)
        end

        ##
        # Boot a given vapp
        def poweron_vapp(vapp_id)
        end

        ##
        # Create a vapp starting from a template
        #
        # Params:
        # - vdc: the associated VDC
        # - vapp_name: name of the target vapp
        # - vapp_description: description of the target vapp
        # - vapp_templateid: ID of the vapp template
        def create_vapp_from_template(vdc, vapp_name, vapp_description,
                                      vapp_templateid, poweron = false)
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
        def compose_vapp_from_vm(vdc, vapp_name, vapp_description,
                                 vm_list = {}, network_config = {})
        end

        # Fetch details about a given vapp template:
        # - name
        # - description
        # - Children VMs:
        #   -- ID
        def get_vapp_template(vapp_id)
        end

        ##
        # Set vApp port forwarding rules
        #
        # - vappid: id of the vapp to be modified
        # - network_name: name of the vapp network to be modified
        # - config: hash with network configuration specifications, must contain
        #   an array inside :nat_rules with the nat rules to be applied.
        def set_vapp_port_forwarding_rules(vapp_id, network_name, config = {})
        end

        ##
        # Get vApp port forwarding rules
        #
        # - vappid: id of the vApp
        def get_vapp_port_forwarding_rules(vapp_id)
        end

        ##
        # get vApp edge public IP from the vApp ID
        # Only works when:
        # - vApp needs to be poweredOn
        # - FenceMode is set to "natRouted"
        # - NatType" is set to "portForwarding
        # This will be required to know how to connect to VMs behind the Edge.
        def get_vapp_edge_public_ip(vapp_id)
        end

        ##
        # Upload an OVF package
        # - vdcId
        # - vappName
        # - vappDescription
        # - ovfFile
        # - catalogId
        # - uploadOptions {}
        def upload_ovf(vdc_id, vapp_name, vapp_description, ovf_file,
                       catalog_id, upload_options = {})
        end

        def set_vm_hardware(vm_id, cfg)
        end

        ##
        # Fetch information for a given task
        def get_task(task_id)
        end

        ##
        # Poll a given task until completion
        def wait_task_completion(task_id)
        end

        ##
        # Set vApp Network Config
        def set_vapp_network_config(vapp_id, network_name, config = {})
        end

        ##
        # Set VM Network Config
        def set_vm_network_config(vm_id, network_name, config = {})
        end

        ##
        # Set VM Guest Customization Config
        def set_vm_guest_customization(vm_id, computer_name, config = {})
        end

        ##
        # Fetch details about a given VM
        def get_vm(vm_Id)
        end

        private

          ##
          # Sends a synchronous request to the vCloud API and returns the
          # response as parsed XML + headers using HTTPClient.
          def send_request(params, payload = nil, content_type = nil)
            # Create a new HTTP client
            clnt = HTTPClient.new

            # Set SSL proto to TLSv1_2
            clnt.ssl_config.ssl_version = :TLSv1_2

            # Disable SSL cert verification
            clnt.ssl_config.verify_mode = (OpenSSL::SSL::VERIFY_NONE)

            # Suppress SSL depth message
            clnt.ssl_config.verify_callback = proc { |ok, ctx|; true }

            extheader = {}
            extheader['accept'] = "application/*+xml;version=#{@api_version}"

            unless content_type.nil?
              extheader['Content-Type'] = content_type
            end

            if @auth_key
              extheader['x-vcloud-authorization'] = @auth_key
            else
              clnt.set_auth(nil, "#{@username}@#{@org_name}", @password)
            end

            url = "#{@api_url}#{params['command']}"

            # Massive debug when LOG=DEBUG
            # Using awesome_print to get nice XML output for better readability
            if @logger.level == 1
              ap "[#{Time.now.ctime}] -> SEND #{params['method'].upcase} #{url}"
              if payload
                payload_xml = Nokogiri.XML(payload)
                ap 'SEND HEADERS'
                ap extheader
                ap 'SEND BODY'
                ap payload_xml
              end
            end

            begin
              response = clnt.request(
                params['method'],
                url,
                nil,
                payload,
                extheader
              )

              unless response.ok?
                if response.code == 400
                  error_message = Nokogiri.parse(response.body)
                  error = error_message.css('Error')
                  fail Errors::InvalidRequestError,
                       :message => error.first['message'].to_s
                else
                  fail Errors::UnattendedCodeError,
                       :message => response.status
                end
              end

              nicexml = Nokogiri.XML(response.body)

              # Massive debug when LOG=DEBUG
              # Using awesome_print to get nice XML output for readability
              if @logger.level == 1
                ap "[#{Time.now.ctime}] <- RECV #{response.status}"
                # Just avoid the task spam.
                unless url.index('/task/')
                  ap 'RECV HEADERS'
                  ap response.headers
                  ap 'RECV BODY'
                  ap nicexml
                end
              end

              [Nokogiri.parse(response.body), response.headers]
            rescue SocketError, Errno::EADDRNOTAVAIL
              raise Errors::EndpointUnavailable, :endpoint => @api_url
            end
          end

          ##
          # Upload a large file in configurable chunks, output an optional
          # progressbar
          def upload_file(upload_url, upload_file, vapp_template, config = {})
            # Set chunksize to 1M if not specified otherwise
            chunk_size = (config[:chunksize] || 1_048_576)
            @logger.debug("Set chunksize to #{chunk_size} bytes")

            # Set progressbar to default format if not specified otherwise
            progressbar_format = (
              config[:progressbar_format] || '%t Progress: %p%% %e'
            )

            # Open our file for upload
            upload_file_handle = File.new(upload_file, 'rb')
            file_name = File.basename(upload_file_handle)

            # FIXME: I removed the filename below because I recall a weird issue
            #        of upload failing because if a too long filename
            #        (tsugliani)
            progressbar_title = 'Uploading Box...'

            # Create a progressbar object if progress bar is enabled
            if config[:progressbar_enable] == true &&
               upload_file_handle.size.to_i > chunk_size
              progressbar = ProgressBar.create(
                :title        => progressbar_title,
                :starting_at  => 0,
                :total        => upload_file_handle.size.to_i,
                :format       => progressbar_format
              )
            else
              puts progressbar_title
            end
            # Create a new HTTP client
            clnt = HTTPClient.new

            # Set SSL proto to TLSv1_2
            clnt.ssl_config.ssl_version = :TLSv1_2

            # Disable SSL cert verification
            clnt.ssl_config.verify_mode = (OpenSSL::SSL::VERIFY_NONE)

            # Suppress SSL depth message
            clnt.ssl_config.verify_callback = proc { |ok, ctx|; true }

            # Perform ranged upload until the file reaches its end
            until upload_file_handle.eof?

              # Create ranges for this chunk upload
              range_start = upload_file_handle.pos
              range_stop = upload_file_handle.pos.to_i + chunk_size

              # Read current chunk
              file_content = upload_file_handle.read(chunk_size)

              # If statement to handle last chunk transfer if is > than filesize
              if range_stop.to_i > upload_file_handle.size.to_i
                content_range = "bytes #{range_start.to_s}-" +
                                "#{upload_file_handle.size.to_s}/" +
                                "#{upload_file_handle.size.to_s}"
                range_len = upload_file_handle.size.to_i - range_start.to_i
              else
                content_range = "bytes #{range_start.to_s}-" +
                                "#{range_stop.to_s}/" +
                                "#{upload_file_handle.size.to_s}"
                range_len = range_stop.to_i - range_start.to_i
              end

              # Build headers
              extheader = {
                'x-vcloud-authorization'  => @auth_key,
                'Content-Range'           => content_range,
                'Content-Length'          => range_len.to_s
              }

              upload_request = "#{@host_url}#{upload_url}"

              # Massive debug when LOG=DEBUG
              # Using awesome_print to get nice XML output for better readability
              if @logger.level == 1
                ap "[#{Time.now.ctime}] -> SEND PUT #{upload_request}"
                ap 'SEND HEADERS'
                ap extheader
                ap 'SEND BODY'
                ap '<data omitted>'
              end

              begin

                # FIXME: Add debug on the return status of "connection"
                # to enhance troubleshooting for this upload process.
                # (tsugliani)
                _connection = clnt.request(
                  'PUT',
                  upload_request,
                  nil,
                  file_content,
                  extheader
                )

                if config[:progressbar_enable] == true &&
                   upload_file_handle.size.to_i > chunk_size
                  params = {
                    'method'  => :get,
                    'command' => "/vAppTemplate/vappTemplate-#{vapp_template}"
                  }
                  response, _headers = send_request(params)

                  response.css(
                    "Files File [name='#{file_name}']"
                  ).each do |file|
                    progressbar.progress = file[:bytesTransferred].to_i
                  end
                end

              rescue
                # FIXME: HUGE FIXME!!!!
                # DO SOMETHING WITH THIS, IT'S JUST STUPID AS IT IS NOW!!!
                retry_time = (config[:retry_time] || 5)
                puts "Range #{content_range} failed to upload, " +
                      "retrying the chunk in #{retry_time.to_s} seconds, " +
                      'to stop this task press CTRL+C.'
                sleep retry_time.to_i
                retry
              end
            end
            upload_file_handle.close
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
