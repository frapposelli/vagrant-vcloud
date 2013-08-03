require "i18n"

module VagrantPlugins
  module VCloud
    module Action
      class PowerOff

        def initialize(app, env)
          @app = app
          @logger = Log4r::Logger.new("vagrant_vcloud::action::poweroff")
        end

        def call(env)
          cfg = env[:machine].provider_config
          cnx = cfg.vcloud_cnx.driver

          vAppId = env[:machine].get_vapp_id
          vmId = env[:machine].id
          vmName = env[:machine].name

          env[:ui].info("Powering off VM #{vmName} with id #{vmId} in vApp Id #{vAppId}")
          cnx.poweroff_vapp(vAppId)

          true

          @app.call env
        end
      end
    end
  end
end
