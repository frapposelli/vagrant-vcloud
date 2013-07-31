require "log4r"

module VagrantPlugins
  module VCloud
    module Action
      class CatalogCheck

        def initialize(app, env)
          @app = app
          @logger = Log4r::Logger.new("vagrant_vcloud::action::catalog_check")
        end

        def call(env)

          vcloud_check_inventory(env)
            
          # What does this do ?
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
          cnx.upload_ovf(
            cfg.vdc_id,
            cfg.catalog_item_name,
            "Vagrant Box",
            boxOVF,
            cfg.catalog_id,
            {
              :progressbar_enable => true,
              :chunksize => 262144
            }
          )

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

          cfg.catalog_item = cnx.get_catalog_item_by_name(cfg.catalog_id, cfg.catalog_item_name)

          # Checking Catalog mandatory requirements
          if !cfg.catalog
            env[:ui].error("Catalog [#{cfg.catalog_name}] does not exist!")
            @logger.info("Catalog [#{cfg.catalog_name}] does not exist!")
          else
            env[:ui].success("Catalog [#{cfg.catalog_name}] exists")
            @logger.info("Catalog [#{cfg.catalog_name}] exists")
          end

          if !cfg.catalog_item
            @logger.info("Catalog item [#{cfg.catalog_item_name}] does not exist!")
            env[:ui].warn("Catalog item [#{cfg.catalog_item_name}] does not exist!")

            user_input = env[:ui].ask(
              "Would you like to upload the [#{cfg.catalog_item_name}] box to "\
              "vCloud Director [#{cfg.catalog_name}] Catalog?\nChoice (yes/no): "
            )

            if user_input.downcase == "yes"
              env[:ui].warn("Uploading [#{cfg.catalog_item_name}] process...")
              vcloud_upload_box(env)
            else
              env[:ui].error("Catalog item not available, exiting...")

              raise VagrantPlugins::VCloud::Errors::VCloudError, 
                    :message => "Catalog item not available, exiting..."

            end
          else
            @logger.info("Catalog item [#{cfg.catalog_item_name}] exists")
            env[:ui].success("Catalog item [#{cfg.catalog_item_name}] exists")
          end
        end

      end
    end
  end
end
