module VagrantPlugins
  module VCloud
    module Action
      class IsLastVM
        def initialize(app, env)
          @app = app
        end

        def call(env)
          cfg = env[:machine].provider_config
          cnx = cfg.vcloud_cnx.driver

          vapp_id = env[:machine].get_vapp_id

          test_vapp = cnx.get_vapp(vapp_id)

          if test_vapp[:vms_hash].count == 1
          # Set the result to be true if the machine is running.
            env[:result] = true
          else
            env[:result] = false
          end

          # Call the next if we have one (but we shouldn't, since this
          # middleware is built to run with the Call-type middlewares)
          @app.call(env)
        end
      end
    end
  end
end
