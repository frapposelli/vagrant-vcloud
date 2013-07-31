module VagrantPlugins
  module VCloud
    module Action
      class IsCreated
        def initialize(app, env)
          @app = app
        end

        def call(env)
          #puts "DUMPING MACHINE STUFF: " + env[:machine].inspect
          env[:result] = env[:machine].provider_config.vcloud_cnx.driver.id != :not_created
          @app.call env
        end
      end
    end
  end
end
