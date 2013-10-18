require "securerandom"
require "etc"
require "netaddr"

module VagrantPlugins
  module VCloud
    module Action
      class BuildVApp
        def initialize(app, env)
          @app = app
          @logger = Log4r::Logger.new("vagrant_vcloud::action::build_vapp")
        end

        def call(env)

          # FIXME: we need to find a way to clean things up when a SIGINT get 
          # called... see env[:interrupted] in the vagrant code

          cfg = env[:machine].provider_config
          cnx = cfg.vcloud_cnx.driver
          vmName = env[:machine].name

          if cfg.ip_dns.nil?
            dnsAddress1 = nil
            dnsAddress2 = nil
          else
            dnsAddress1 = cfg.ip_dns.shift
            dnsAddress2 = cfg.ip_dns.shift
          end


          if !cfg.ip_subnet.nil?

            @logger.debug("Input address: #{cfg.ip_subnet}")

            begin
              cidr = NetAddr::CIDR.create(cfg.ip_subnet)
            rescue NetAddr::ValidationError
              raise Errors::InvalidSubnet, :message => cfg.ip_subnet
            end
              if cidr.bits > 30
                @logger.debug("Subnet too small!")
                raise Errors::SubnetTooSmall, :message => cfg.ip_subnet
              end

            rangeAddresses = cidr.range(0)

            @logger.debug("Range: #{rangeAddresses}")

            rangeAddresses.shift              # Delete the "network" address from the range.
            gatewayIp = rangeAddresses.shift  # Retrieve the first usable IP, to be used as a gateway.
            rangeAddresses.reverse!           # Reverse the array in place.
            rangeAddresses.shift              # Delete the "broadcast" address from the range.
            rangeAddresses.reverse!           # Reverse back the array.

            @logger.debug("Gateway IP: #{gatewayIp.to_s}")
            @logger.debug("Netmask: #{cidr.wildcard_mask}")
            @logger.debug("IP Pool: #{rangeAddresses.first}-#{rangeAddresses.last}")
            @logger.debug("DNS1: #{dnsAddress1} DNS2: #{dnsAddress2}")


            network_options = { 
              :name => "Vagrant-vApp-Net", 
              :gateway => gatewayIp.to_s, 
              :netmask => cidr.wildcard_mask, 
              :start_address => rangeAddresses.first, 
              :end_address => rangeAddresses.last, 
              :fence_mode => "natRouted",
              :ip_allocation_mode => "POOL",
              :parent_network =>  cfg.vdc_network_id,
              :enable_firewall => "false",
              :dns1 => dnsAddress1,
              :dns2 => dnsAddress2
            }

          else

            @logger.debug("DNS1: #{dnsAddress1} DNS2: #{dnsAddress2}")
            # No IP subnet specified, reverting to defaults
            network_options = { 
              :name => "Vagrant-vApp-Net", 
              :gateway => "10.1.1.1", 
              :netmask => "255.255.255.0", 
              :start_address => "10.1.1.2", 
              :end_address => "10.1.1.254", 
              :fence_mode => "natRouted",
              :ip_allocation_mode => "POOL",
              :parent_network =>  cfg.vdc_network_id,
              :enable_firewall => "false",
              :dns1 => dnsAddress1,
              :dns2 => dnsAddress2
            }

          end

          if env[:machine].get_vapp_id.nil?

            env[:ui].info("Building vApp...")

            compose = cnx.compose_vapp_from_vm(
              cfg.vdc_id, 
              "Vagrant-#{Etc.getlogin}-#{Socket.gethostname.downcase}-#{SecureRandom.hex(4)}",
              "vApp created by #{Etc.getlogin} running on #{Socket.gethostname.downcase} using vagrant-vcloud on #{Time.now.strftime("%B %d, %Y")}",
              { 
                vmName => cfg.catalog_item[:vms_hash][env[:machine].box.name.to_s][:id]
              }, 
              network_options
            )
            @logger.debug("Launched Compose vApp")
            # Wait for the task to finish.
            wait = cnx.wait_task_completion(compose[:task_id])

            if !wait[:errormsg].nil?
              raise Errors::ComposeVAppError, :message => wait[:errormsg]
            end


            # Fetch thenewly created vApp ID
            vAppId = compose[:vapp_id]

            # putting the vApp Id in a globally reachable var and file.
            env[:machine].vappid = vAppId

            # Fetching new vApp object to check stuff.
            newVApp = cnx.get_vapp(vAppId)            

            # FIXME: Add a lot of error handling for each step here !

            if newVApp
              env[:ui].success("vApp #{newVApp[:name]} successfully created.")

              # Add the vm id as machine.id
              newVMProperties = newVApp[:vms_hash].fetch(vmName)
              env[:machine].id = newVMProperties[:id]

              ### SET GUEST CONFIG

              @logger.info("Setting Guest Customization on ID: [#{vmName}] of vApp [#{newVApp[:name]}]")

              setCustom = cnx.set_vm_guest_customization(newVMProperties[:id], vmName, {
                :enabled => true,
                :admin_passwd_enabled => false
                })
              cnx.wait_task_completion(setCustom)

            else
              env[:ui].error("vApp #{newVApp[:name]} creation failed!")
              raise # FIXME: error handling missing.
           end 
          else
            env[:ui].info("Adding VM to existing vApp...")
            
            recompose = cnx.recompose_vapp_from_vm(
              env[:machine].get_vapp_id, 
              { 
                vmName => cfg.catalog_item[:vms_hash][env[:machine].box.name.to_s][:id]
              }, 
              network_options
            )

            @logger.info("Waiting for the add to complete ...")

            # Wait for the task to finish.
            wait = cnx.wait_task_completion(recompose[:task_id])

            newVApp = cnx.get_vapp(env[:machine].get_vapp_id)

            # FIXME: Add a lot of error handling for each step here !

            if newVApp

              newVMProperties = newVApp[:vms_hash].fetch(vmName)
              env[:machine].id = newVMProperties[:id]

              ### SET GUEST CONFIG
              
              @logger.info("Setting Guest Customization on ID: [#{newVMProperties[:id]}] of vApp [#{newVApp[:name]}]")
              
              setCustom = cnx.set_vm_guest_customization(newVMProperties[:id], vmName, {
                :enabled => true,
                :admin_passwd_enabled => false
                })
              cnx.wait_task_completion(setCustom)

            else

              env[:ui].error("VM #{vmName} add to #{newVApp[:name]} failed!")
              raise
            end 
          end

          @app.call env

        end
      end
    end
  end
end
