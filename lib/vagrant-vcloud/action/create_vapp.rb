module VagrantPlugins
  module VCloud
    module Action
      class CreateVApp
        def initialize(app, env)
          @app = app
          @logger = Log4r::Logger.new("vagrant_vcloud::action::create_vapp")
        end

        def call(env)

          cfg = env[:machine].provider_config
          cnx = cfg.vcloud_cnx.driver

          env[:ui].info("Creating vApp ...")
          @logger.info("Creating vApp ...")

          vmName = env[:machine].name

          compose = cnx.compose_vapp_from_vm(
            cfg.vdc_id, 
            "Vagrant-vApp-#{Time.now.to_i.to_s}", # FIXME: To be changed
            "vApp built by vagrant-vcloud", # FIXME: I might use this as the
                                            # container for all the information
            { 
              vmName => cfg.catalog_item[:vms_hash][cfg.catalog_item_name][:id]
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

          # Wait for the task to finish.
          wait = cnx.wait_task_completion(compose[:task_id])

          # Fetch thenewly created vApp ID
          vAppId = compose[:vapp_id]

          # putting the vApp Id for now here, as it's the important stuff.
          # We could then loop into that vApp to find each node/VM Id
          env[:machine].id = vAppId

          # Fetching new vApp object to check stuff.
          newVApp = cnx.get_vapp(vAppId)
          ap newVApp

          # FIXME: Add a lot of error handling for each step here !

          if newVApp
            env[:ui].success("vApp #{newVApp[:name]} created successfully!")
            @logger.info("vApp #{newVApp[:name]} created successfully!")
          else
            env[:ui].error("vApp #{newVApp[:name]} creation failed!")
            @logger.error("vApp #{newVApp[:name]} creation failed!")
          end 

          @app.call env

        end
      end
    end
  end
end
