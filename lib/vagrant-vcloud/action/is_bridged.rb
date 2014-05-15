module VagrantPlugins
  module VCloud
    module Action
      class IsBridged
        def initialize(app, env)
          @app = app
          @logger = Log4r::Logger.new('vagrant_vcloud::action::is_bridged')
        end

        def call(env)
          vapp_id = env[:machine].get_vapp_id

          cfg = env[:machine].provider_config
          cnx = cfg.vcloud_cnx.driver

          begin
            @logger.debug('Trying to get the vApp port forwarding rules')
            cnx.get_vapp_port_forwarding_rules(vapp_id)
          rescue
            @logger.debug('Setting the bridged_network environment var to true')
            env[:bridged_network] = true
          end

          @app.call env
        end
      end
    end
  end
end
