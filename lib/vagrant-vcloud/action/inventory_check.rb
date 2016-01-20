require 'etc'

module VagrantPlugins
  module VCloud
    module Action
      class InventoryCheck
        def initialize(app, env)
          @app = app
          @logger = Log4r::Logger.new('vagrant_vcloud::action::inventory_check')
        end

        def call(env)
          vcloud_check_inventory(env)

          @app.call env
        end

        def vcloud_upload_box(env)
          cfg = env[:machine].provider_config
          cnx = cfg.vcloud_cnx.driver

          box_dir = env[:machine].box.directory.to_s

          if env[:machine].box.name.to_s.include? '/'
            box_file = env[:machine].box.name.rpartition('/').last.to_s
            box_name = env[:machine].box.name.to_s
          else
            box_file = env[:machine].box.name.to_s
            box_name = box_file
          end

          box_ovf = "#{box_dir}/#{box_file}.ovf"

          # Still relying on ruby-progressbar because report_progress
          # basically sucks.
          @logger.debug("OVF File: #{box_ovf}")
          upload_ovf = cnx.upload_ovf(
            cfg.vdc_id,
            box_name,
            'Vagrant Box',
            box_ovf,
            cfg.catalog_id,
            {
              :progressbar_enable => true,
              :chunksize => (cfg.upload_chunksize || 1_048_576)
            }
          )

          env[:ui].info(
            "Adding [#{box_name}] to " +
            "Catalog [#{cfg.catalog_name}]"
          )
          add_ovf_to_catalog = cnx.wait_task_completion(upload_ovf)

          unless add_ovf_to_catalog[:errormsg].nil?
            fail Errors::CatalogAddError,
                 :message => add_ovf_to_catalog[:errormsg]
          end

          # Retrieve catalog_item ID
          cfg.catalog_item = cnx.get_catalog_item_by_name(
            cfg.catalog_id,
            box_name
          )
        end

        def vcloud_create_catalog(env)
          cfg = env[:machine].provider_config
          cnx = cfg.vcloud_cnx.driver

          catalog_creation = cnx.create_catalog(
            cfg.org_id,
            cfg.catalog_name,
            "Created by #{Etc.getlogin} " +
            "running on #{Socket.gethostname.downcase} " +
            "using vagrant-vcloud on #{Time.now.strftime("%B %d, %Y")}"
          )
          cnx.wait_task_completion(catalog_creation[:task_id])

          @logger.debug("Catalog Creation result: #{catalog_creation.inspect}")
          env[:ui].info("Catalog [#{cfg.catalog_name}] successfully created.")

          cfg.catalog_id = catalog_creation[:catalog_id]
        end

        def vcloud_check_inventory(env)
          # Will check each mandatory config value against the vCloud Director
          # Instance and will setup the global environment config values
          cfg = env[:machine].provider_config
          cnx = cfg.vcloud_cnx.driver

          if env[:machine].box.name.to_s.include? '/'
            box_file = env[:machine].box.name.rpartition('/').last.to_s
            box_name = env[:machine].box.name.to_s
          else
            box_file = env[:machine].box.name.to_s
            box_name = box_file
          end

          cfg.org = cnx.get_organization_by_name(cfg.org_name)
          cfg.org_id = cnx.get_organization_id_by_name(cfg.org_name)

          cfg.vdc = cnx.get_vdc_by_name(cfg.org, cfg.vdc_name)
          cfg.vdc_id = cnx.get_vdc_id_by_name(cfg.org, cfg.vdc_name)

          cfg.catalog = cnx.get_catalog_by_name(cfg.org, cfg.catalog_name)
          cfg.catalog_id = cnx.get_catalog_id_by_name(cfg.org, cfg.catalog_name)

          if cfg.catalog_id.nil?
            env[:ui].warn("Catalog [#{cfg.catalog_name}] does not exist!")

            user_input = env[:ui].ask(
              "Would you like to create the [#{cfg.catalog_name}] catalog?\n" +
              'Choice (yes/no): '
            )

            if user_input.downcase == 'yes' || user_input.downcase == 'y'
              vcloud_create_catalog(env)
            else
              env[:ui].error('Catalog not created, exiting...')

              # FIXME: wrong error message
              raise VagrantPlugins::VCloud::Errors::VCloudError,
                    :message => 'Catalog not available, exiting...'

            end
          end

          @logger.debug(
            "Getting catalog item with cfg.catalog_id: [#{cfg.catalog_id}] " +
            "and machine name [#{box_name}]"
          )
          cfg.catalog_item = cnx.get_catalog_item_by_name(
            cfg.catalog_id,
            box_name
          )

          @logger.debug("Catalog item is now #{cfg.catalog_item}")

          # This only works with Org Admin role or higher
          if cfg.vdc_network_name
            cfg.vdc_network_id = cfg.org[:networks][cfg.vdc_network_name]
            if !cfg.vdc_network_id
              # TEMP FIX: permissions issues at the Org Level for vApp authors
              #           to "view" Org vDC Networks but they can see them at the
              #           Organization vDC level (tsugliani)
              cfg.vdc_network_id = cfg.vdc[:networks][cfg.vdc_network_name]
              if !cfg.vdc_network_id
                raise 'vCloud User credentials has insufficient privileges'
              end
            end
          end

          # Checking Catalog mandatory requirements
          if !cfg.catalog_id
            @logger.info("Catalog [#{cfg.catalog_name}] STILL does not exist!")

              # FIXME: wrong error message
              raise VagrantPlugins::VCloud::Errors::VCloudError,
                    :message => 'Catalog not available, exiting...'

          else
            @logger.info("Catalog [#{cfg.catalog_name}] exists")
          end

          if !cfg.catalog_item
            env[:ui].warn(
              "Catalog item [#{box_name}] " +
              "in Catalog [#{cfg.catalog_name}] does not exist!"
            )

            if cfg.auto_yes_for_upload.nil? || cfg.auto_yes_for_upload == false
	            user_input = env[:ui].ask(
	              "Would you like to upload the [#{box_name}] " +
	              "box to [#{cfg.catalog_name}] Catalog?\n" +
	              'Choice (yes/no): '
	            )
	        else
	        	auto_upload = cfg.auto_yes_for_upload
	        end

            if !auto_upload.nil? || user_input.downcase == 'yes' || user_input.downcase == 'y'
              env[:ui].info("Uploading [#{box_name}]...")
              vcloud_upload_box(env)
            else
              env[:ui].error('Catalog item not available, exiting...')

              # FIXME: wrong error message
              raise VagrantPlugins::VCloud::Errors::VCloudError,
                    :message => 'Catalog item not available, exiting...'
            end

          else
            @logger.info(
              "Using catalog item [#{box_name}] " +
              "in Catalog [#{cfg.catalog_name}]..."
            )
          end
        end
      end
    end
  end
end
