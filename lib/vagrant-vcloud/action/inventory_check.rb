require "etc"
require "log4r"

module VagrantPlugins
  module VCloud
    module Action
      class InventoryCheck

        def initialize(app, env)
          @app = app
          @logger = Log4r::Logger.new("vagrant_vcloud::action::inventory_check")
        end

        def call(env)
          vcloud_check_inventory(env)
            
          @app.call env
        end

        def vcloud_upload_box(env)

          cfg = env[:machine].provider_config
          cnx = cfg.vcloud_cnx.driver

          boxDir = env[:machine].box.directory.to_s
          boxFile = env[:machine].box.name.to_s

          boxOVF = "#{boxDir}/#{boxFile}.ovf"

          ### Still relying on ruby-progressbar because report_progress basically sucks.

          @logger.debug("OVF File: #{boxOVF}")
          uploadOVF = cnx.upload_ovf(
            cfg.vdc_id,
            env[:machine].box.name.to_s,
            "Vagrant Box",
            boxOVF,
            cfg.catalog_id,
            {
              :progressbar_enable => true
              #:chunksize => 262144
            }
          )

          env[:ui].info("Adding [#{env[:machine].box.name.to_s}] to Catalog [#{cfg.catalog_name}]")
          cnx.wait_task_completion(uploadOVF)
          ## Retrieve catalog_item ID
          cfg.catalog_item = cnx.get_catalog_item_by_name(cfg.catalog_id, env[:machine].box.name.to_s)

        end

        def vcloud_create_catalog(env)
          cfg = env[:machine].provider_config
          cnx = cfg.vcloud_cnx.driver

          catalogCreation = cnx.create_catalog(cfg.org_id, cfg.catalog_name, "Created by #{Etc.getlogin} running on #{Socket.gethostname.downcase} using vagrant-vcloud on #{Time.now.strftime("%B %d, %Y")}")
          cnx.wait_task_completion(catalogCreation[:task_id])

          @logger.debug("Catalog Creation result: #{catalogCreation.inspect}")

          env[:ui].info("Catalog [#{cfg.catalog_name}] created successfully.")

          cfg.catalog_id = catalogCreation[:catalog_id]

        end

        def vcloud_check_inventory(env)
          # Will check each mandatory config value against the vCloud Director
          # Instance and will setup the global environment config values
          cfg = env[:machine].provider_config
          cnx = cfg.vcloud_cnx.driver

          cfg.org = cnx.get_organization_by_name(cfg.org_name)
          cfg.org_id = cnx.get_organization_id_by_name(cfg.org_name)

          cfg.vdc = cnx.get_vdc_by_name(cfg.org, cfg.vdc_name)
          cfg.vdc_id = cnx.get_vdc_id_by_name(cfg.org, cfg.vdc_name)

          cfg.catalog = cnx.get_catalog_by_name(cfg.org, cfg.catalog_name)
          

          @logger.debug("BEFORE get_catalog_id_by_name")          
          cfg.catalog_id = cnx.get_catalog_id_by_name(cfg.org, cfg.catalog_name)
          @logger.debug("AFTER get_catalog_id_by_name: #{cfg.catalog_id}")


          if cfg.catalog_id.nil?
            env[:ui].warn("Catalog [#{cfg.catalog_name}] does not exist!")

            user_input = env[:ui].ask(
              "Would you like to create the [#{cfg.catalog_name}] catalog?\nChoice (yes/no): "
            )

            # FIXME: add an OR clause for just Y
            if user_input.downcase == "yes"
              vcloud_create_catalog(env)
            else
              env[:ui].error("Catalog not created, exiting...")

              raise VagrantPlugins::VCloud::Errors::VCloudError, 
                    :message => "Catalog not available, exiting..."

            end
          end

          
          @logger.debug("Getting catalog item with cfg.catalog_id: [#{cfg.catalog_id}] and machine name [#{env[:machine].box.name.to_s}]")
          cfg.catalog_item = cnx.get_catalog_item_by_name(cfg.catalog_id, env[:machine].box.name.to_s)
          @logger.debug("Catalog item is now #{cfg.catalog_item}")
          cfg.vdc_network_id = cfg.org[:networks][cfg.vdc_network_name]


          # Checking Catalog mandatory requirements
          if !cfg.catalog_id
            @logger.info("Catalog [#{cfg.catalog_name}] STILL does not exist!")
              raise VagrantPlugins::VCloud::Errors::VCloudError, 
                    :message => "Catalog not available, exiting..."

          else
            @logger.info("Catalog [#{cfg.catalog_name}] exists")
          end

          if !cfg.catalog_item
            env[:ui].warn("Catalog item [#{env[:machine].box.name.to_s}] in Catalog [#{cfg.catalog_name}] does not exist!")

            user_input = env[:ui].ask(
              "Would you like to upload the [#{env[:machine].box.name.to_s}] box to "\
              "[#{cfg.catalog_name}] Catalog?\nChoice (yes/no): "
            )

            # FIXME: add an OR clause for just Y
            if user_input.downcase == "yes"
              env[:ui].info("Uploading [#{env[:machine].box.name.to_s}]...")
              vcloud_upload_box(env)
            else
              env[:ui].error("Catalog item not available, exiting...")

              raise VagrantPlugins::VCloud::Errors::VCloudError, 
                    :message => "Catalog item not available, exiting..."

            end

          else
            #env[:ui].info("Using catalog item [#{env[:machine].box.name.to_s}] in Catalog [#{cfg.catalog_name}]...")
          end
        end

      end
    end
  end
end
