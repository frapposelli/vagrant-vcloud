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
          cfg.catalog_id = cnx.get_catalog_id_by_name(cfg.org, cfg.catalog_name)

          cfg.catalog_item = cnx.get_catalog_item_by_name(cfg.catalog_id, env[:machine].box.name.to_s)

          cfg.vdc_network_id = cfg.org[:networks][cfg.vdc_network_name]


          # Checking Catalog mandatory requirements
          if !cfg.catalog
            env[:ui].error("Catalog [#{cfg.catalog_name}] does not exist!")
            @logger.info("Catalog [#{cfg.catalog_name}] does not exist!")
          else
            env[:ui].success("Catalog [#{cfg.catalog_name}] exists")
            @logger.info("Catalog [#{cfg.catalog_name}] exists")
          end

          if !cfg.catalog_item
            @logger.info("Catalog item [#{env[:machine].box.name.to_s}] does not exist!")
            env[:ui].warn("Catalog item [#{env[:machine].box.name.to_s}] does not exist!")

            user_input = env[:ui].ask(
              "Would you like to upload the [#{env[:machine].box.name.to_s}] box to "\
              "vCloud Director [#{cfg.catalog_name}] Catalog?\nChoice (yes/no): "
            )

            # FIXME: add an OR clause for just Y
            if user_input.downcase == "yes"
              env[:ui].warn("Uploading [#{env[:machine].box.name.to_s}] process...")
              vcloud_upload_box(env)
            else
              env[:ui].error("Catalog item not available, exiting...")

              raise VagrantPlugins::VCloud::Errors::VCloudError, 
                    :message => "Catalog item not available, exiting..."

            end
          else
            @logger.info("Catalog item [#{env[:machine].box.name.to_s}] exists")
            env[:ui].success("Catalog item [#{env[:machine].box.name.to_s}] exists")
          end
        end

      end
    end
  end
end
