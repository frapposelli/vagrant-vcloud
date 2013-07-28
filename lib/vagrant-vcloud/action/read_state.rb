require "log4r"
require "vcloud-rest/connection"

module VagrantPlugins
  module VCloud
    module Action
      class ReadState

        def initialize(app, env)
          @app = app
          @logger = Log4r::Logger.new("vagrant_vcloud::action::read_state")
        end

        def call(env)

          vcloud_check_inventory(env)

          env = read_state(env)
            
          # What does this do ?
          @app.call env
        end

        def vcloud_upload_box(env)

          cfg = env[:machine].provider_config
          cnx = cfg.vcloud_cnx

          # testing with hardcoded value
          boxOVF = "/Users/tsugliani/.vagrant.d/boxes/precise32/vcloud/precise32.ovf"

          # Send the box to the vCloud Director catalog
          cnx.upload_ovf(
            cfg.vdc_id,
            cfg.catalog_item_name,
            "Vagrant Box",
            boxOVF,
            cfg.catalog_id,
            {}
          )

        end

        def vcloud_check_inventory(env)
          # Will check each mandatory config value against the vCloud Director
          # Instance and will setup the global environment config values
          cfg = env[:machine].provider_config
          cnx = cfg.vcloud_cnx

          cfg.org = cnx.get_organization_by_name(cfg.org_name)
          cfg.org_id = cnx.get_organization_id_by_name(cfg.org_name)

          cfg.vdc = cnx.get_vdc_by_name(cfg.org, cfg.vdc_name)
          cfg.vdc_id = cnx.get_vdc_id_by_name(cfg.org, cfg.vdc_name)

          cfg.catalog = cnx.get_catalog_by_name(cfg.org, cfg.catalog_name)
          cfg.catalog_id = cnx.get_catalog_id_by_name(cfg.org, cfg.catalog_name)

          cfg.catalog_item = cnx.get_catalog_item_by_name(cfg.catalog_id, cfg.catalog_item)

          # Checking Catalog mandatory requirements
          if !cfg.catalog
            @logger.info("Catalog [#{cfg.catalog_name}] does not exist!")
          end

          if !cfg.catalog_item
            @logger.info("Catalog item [#{cfg.catalog_item_name}] does not exist!")
            # Disabled for now, not working as expected ;-)
            # Need to handle OVF with & without Manifest files (.mf)
            # vcloud_upload_box(env)
          end

        end

        def read_state(env)

          cfg = env[:machine].provider_config

          #return :not_created  if machine.id.nil?

          #vm = connection.get_vapp(machine)

          #if vm.nil?
          #  return :not_created
          #end

          #if vm[:status].eql?(POWERED_ON)
          #  @logger.info("Machine is powered on.")
          #  :running
          #else
          #  @logger.info("Machine not found or terminated, assuming it got destroyed.")
          #  # If the VM is powered off or suspended, we consider it to be powered off. A power on command will either turn on or resume the VM
          #  :poweroff
          #end
        end
      end
    end
  end
end
