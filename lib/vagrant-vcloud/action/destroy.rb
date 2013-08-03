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

          env[:ui].info("Destroy vApp Id: #{vAppId}")
         
          cfg = env[:machine].provider_config
          cnx = cfg.vcloud_cnx.driver
          vAppId = env[:machine].get_vapp_id

          env[:ui].info("Destory vApp Id: #{vAppId}")

          cnx.delete_vapp(vAppId)

          @app.call env
        end

      end
    end
  end
end
