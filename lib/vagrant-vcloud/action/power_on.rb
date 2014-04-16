module VagrantPlugins
  module VCloud
    module Action
      class PowerOn
        def initialize(app, env)
          @app = app
          @logger = Log4r::Logger.new('vagrant_vcloud::action::power_on')
        end

        def call(env)
          @env = env

          cfg = env[:machine].provider_config
          cnx = cfg.vcloud_cnx.driver
          vapp_id = env[:machine].get_vapp_id

          env[:ui].info('Powering on VM...')

          poweron_vm = cnx.poweron_vm(env[:machine].id)
          cnx.wait_task_completion(poweron_vm)

          if cfg.network_bridge.nil?
            test_ip = cnx.get_vapp_edge_public_ip(vapp_id)
          end

          if test_ip.nil? && \
             cfg.vdc_edge_gateway_ip && \
             cfg.vdc_edge_gateway && \
             cfg.network_bridge.nil?

            @logger.debug(
              'This is our first boot, we should map ports on the ' \
              'Organization vDC vShield Edge Gateway!'
            )

            ### TMP FIX: tsugliani
            ### We need to verify the vShield Edge Gateway rules don't already
            ### exist.
            ### Removing any rule previously set for that same source IP

            # ----
            if cfg.vdc_edge_gateway_ip && cfg.vdc_edge_gateway
              env[:ui].info(
                "Removing NAT rules on [#{cfg.vdc_edge_gateway}] " +
                "for IP [#{cfg.vdc_edge_gateway_ip}]."
              )
              @logger.debug(
                'Cleaning possible conflicting Edge Gateway rules - ' +
                "Organization vDC id: #{cfg.vdc_id}"
              )

              edge_remove = cnx.remove_edge_gateway_rules(
                cfg.vdc_edge_gateway,
                cfg.vdc_id,
                cfg.vdc_edge_gateway_ip,
                vapp_id
              )
              cnx.wait_task_completion(edge_remove)
            end
            # ----

            env[:ui].info(
              "Creating NAT rules on [#{cfg.vdc_edge_gateway}] " +
              "for IP [#{cfg.vdc_edge_gateway_ip}]."
            )

            # Set the vShield Edge Gateway rules
            edge_map = cnx.set_edge_gateway_rules(
              cfg.vdc_edge_gateway,
              cfg.vdc_id,
              cfg.vdc_edge_gateway_ip,
              vapp_id
            )

            # Wait for task to complete.
            cnx.wait_task_completion(edge_map)
          end

          @app.call(env)
        end
      end
    end
  end
end
