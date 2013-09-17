require "i18n"

module VagrantPlugins
  module VCloud
    module Action
      class PowerOn
        def initialize(app, env)
          @app = app
          @logger = Log4r::Logger.new("vagrant_vcloud::action::power_on")
        end

        def call(env)
          @env = env


          cfg = env[:machine].provider_config
          cnx = cfg.vcloud_cnx.driver
          vmName = env[:machine].name
          vAppId = env[:machine].get_vapp_id

	      env[:ui].info("Booting VM...")

        testIp = cnx.get_vapp_edge_public_ip(vAppId)

        poweronVM = cnx.poweron_vm(env[:machine].id)
        cnx.wait_task_completion(poweronVM)

        if testIp.nil? && cfg.vdc_edge_gateway_ip && cfg.vdc_edge_gateway
          @logger.debug("This is our first boot, we should map ports on org edge!")
          env[:ui].info("Mapping ip #{cfg.vdc_edge_gateway_ip} on #{cfg.vdc_edge_gateway} as our entry point.")
          edgeMap = cnx.set_edge_gateway_rules(cfg.vdc_edge_gateway, cfg.vdc_id, cfg.vdc_edge_gateway_ip, vAppId)
          cnx.wait_task_completion(edgeMap)
        end




          @app.call(env)
        end
      end
    end
  end
end



