require "i18n"

module VagrantPlugins
  module VCloud
    module Action
      class Destroy

        def initialize(app, env)
          @app = app
          @logger = Log4r::Logger.new("vagrant_vcloud::action::destroy")
        end

        def call(env)

          cfg = env[:machine].provider_config
          cnx = cfg.vcloud_cnx.driver
          vAppId = env[:machine].get_vapp_id
          vmId = env[:machine].id

          cfg.org = cnx.get_organization_by_name(cfg.org_name)
          cfg.vdc_id = cnx.get_vdc_id_by_name(cfg.org, cfg.vdc_name)

          testvApp = cnx.get_vapp(vAppId)

          @logger.debug(
            "Number of VMs in the vApp: #{testvApp[:vms_hash].count}"
          )

          if testvApp[:vms_hash].count == 1
            env[:ui].info("Single VM left in the vApp, destroying the vApp...")

            if cfg.vdc_edge_gateway_ip && cfg.vdc_edge_gateway
              env[:ui].info(
                "Removing NAT rules on [#{cfg.vdc_edge_gateway}] " + 
                "for IP [#{cfg.vdc_edge_gateway_ip}]."
              )
              @logger.debug(
                "Deleting Edge Gateway rules - vdc id: #{cfg.vdc_id}"
              )
              edge_remove = cnx.remove_edge_gateway_rules(
                cfg.vdc_edge_gateway, 
                cfg.vdc_id, 
                cfg.vdc_edge_gateway_ip, 
                vAppId
              )
              cnx.wait_task_completion(edge_remove)
            end

            env[:ui].info("Destroying vApp...")
            vAppDeleteTask = cnx.delete_vapp(vAppId)
            @logger.debug("vApp Delete task id #{vAppDeleteTask}")
            cnx.wait_task_completion(vAppDeleteTask)


            # FIXME: Look into this.
            ####env[:machine].provider.driver.delete
            env[:machine].id = nil
            env[:machine].vappid = nil
          else
            env[:ui].info("Destroying VM...")
            vmDeleteTask = cnx.delete_vm(vmId)
            @logger.debug("VM Delete task id #{vmDeleteTask}")
            cnx.wait_task_completion(vmDeleteTask)
            env[:machine].id = nil
          end

          @app.call env
        end

      end
    end
  end
end
