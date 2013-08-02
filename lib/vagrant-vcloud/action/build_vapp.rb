require "securerandom"
require "etc"

module VagrantPlugins
  module VCloud
    module Action
      class BuildVApp
        def initialize(app, env)
          @app = app
          @logger = Log4r::Logger.new("vagrant_vcloud::action::build_vapp")
        end

        def call(env)

          cfg = env[:machine].provider_config
          cnx = cfg.vcloud_cnx.driver
          vmName = env[:machine].name

          if env[:machine].get_vapp_id.nil?

            env[:ui].info("Creating vApp ...")
            @logger.info("Creating vApp ...")

            compose = cnx.compose_vapp_from_vm(
              cfg.vdc_id, 
              "Vagrant-#{Etc.getlogin}-#{SecureRandom.hex(4)}", # FIXME: To be changed
              "vApp built by vagrant-vcloud", # FIXME: I might use this as the
                                              # container for all the information
              { 
                vmName => cfg.catalog_item[:vms_hash][env[:machine].box.name.to_s][:id]
              }, 
              { 
                # This is static and will not change. (behind NAT)
                # FIXME: We should let the user choose the subnet and then work out 
                # the gateway and address pool, maybe in the next release :-)
                :name => "Vagrant-vApp-Net", 
                :gateway => "10.250.254.251", 
                :netmask => "255.255.255.0", 
                :start_address => "10.250.254.11", 
                :end_address => "10.250.254.100", 
                :fence_mode => "natRouted",
                :ip_allocation_mode => "POOL",
                :parent_network =>  cfg.vdc_network_id,
                :enable_firewall => "false"
              }
            )

            # Wait for the task to finish.
            wait = cnx.wait_task_completion(compose[:task_id])

            # Fetch thenewly created vApp ID
            vAppId = compose[:vapp_id]

            # putting the vApp Id in a globally reachable var and file.
            env[:machine].vappid = vAppId

            # Fetching new vApp object to check stuff.
            newVApp = cnx.get_vapp(vAppId)            

            # FIXME: Add a lot of error handling for each step here !

            if newVApp

              env[:ui].success("vApp #{newVApp[:name]} created successfully!")
              @logger.info("vApp #{newVApp[:name]} created successfully!")

              # Add the vm id as machine.id
              newVMProperties = newVApp[:vms_hash].fetch(vmName)
              env[:machine].id = newVMProperties[:id]

              ### SET GUEST CONFIG
              @logger.info("Setting Guest Customization on ID: [#{newVMProperties[:id]}] of vApp [#{newVApp[:name]}]")
              env[:ui].info("Setting Guest Customization on ID: [#{vmName}] of vApp [#{newVApp[:name]}]")
              setCustom = cnx.set_vm_guest_customization(newVMProperties[:id], vmName, {
                :enabled => true,
                :admin_passwd_enabled => true,
                :admin_passwd => "vagrant"
                })
              cnx.wait_task_completion(setCustom)

              @logger.info("Starting VM [#{vmName}] - this will take a while as vShield Edge is getting deployed as well")
              env[:ui].info("Starting VM [#{vmName}] - this will take a while as vShield Edge is getting deployed as well")
              poweronVM = cnx.poweron_vm(newVMProperties[:id])
              cnx.wait_task_completion(poweronVM)

            else

              env[:ui].error("vApp #{newVApp[:name]} creation failed!")
              @logger.error("vApp #{newVApp[:name]} creation failed!")
              raise

            end 




          else

            env[:ui].info("Adding VM to existing vApp ID: [#{env[:machine].get_vapp_id}] ...")
            @logger.info("Adding VM to existing vApp ID: [#{env[:machine].get_vapp_id}] ...")


            
            
            recompose = cnx.recompose_vapp_from_vm(
              env[:machine].get_vapp_id, 
              { 
                vmName => cfg.catalog_item[:vms_hash][env[:machine].box.name.to_s][:id]
                # FIXME: Will need a for loop here for every VM defined in the
                # Vagrant file
              }, 
              { 
                # This is static and will not change. (behind NAT)
                :name => "Vagrant-vApp-Net", 
                :gateway => "10.250.254.251", 
                :netmask => "255.255.255.0", 
                :start_address => "10.250.254.11", 
                :end_address => "10.250.254.100", 
                :fence_mode => "natRouted",
                :ip_allocation_mode => "POOL",
                :parent_network =>  cfg.vdc_network_id,
                :enable_firewall => "false"
              }
            )

            env[:ui].info("Waiting for the add to complete ...")
            @logger.info("Waiting for the add to complete ...")

            # Wait for the task to finish.
            wait = cnx.wait_task_completion(recompose[:task_id])

            newVApp = cnx.get_vapp(env[:machine].get_vapp_id)

            # FIXME: Add a lot of error handling for each step here !

            if newVApp

              env[:ui].success("VM #{vmName} added to #{newVApp[:name]} successfully!")
              @logger.info("VM #{vmName} added to #{newVApp[:name]} successfully!")

              # Add the vm id as machine.id
              newVMProperties = newVApp[:vms_hash].fetch(vmName)
              env[:machine].id = newVMProperties[:id]

              ### SET GUEST CONFIG
              @logger.info("Setting Guest Customization on ID: [#{newVMProperties[:id]}] of vApp [#{newVApp[:name]}]")
              env[:ui].info("Setting Guest Customization on ID: [#{vmName}] of vApp [#{newVApp[:name]}]")
              setCustom = cnx.set_vm_guest_customization(newVMProperties[:id], vmName, {
                :enabled => true,
                :admin_passwd_enabled => true,
                :admin_passwd => "vagrant"
                })
              cnx.wait_task_completion(setCustom)

              @logger.info("Starting VM [#{vmName}]")
              env[:ui].info("Starting VM [#{vmName}]")
              poweronVM = cnx.poweron_vm(newVMProperties[:id])
              cnx.wait_task_completion(poweronVM)


            else

              env[:ui].error("VM #{vmName} add to #{newVApp[:name]} failed!")
              @logger.error("VM #{vmName} add to #{newVApp[:name]} failed!")
              raise

            end 


          end

          @app.call env

        end
      end
    end
  end
end
