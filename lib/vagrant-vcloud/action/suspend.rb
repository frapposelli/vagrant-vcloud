require "i18n"

module VagrantPlugins
  module VCloud
    module Action
      class Suspend

        def initialize(app, env)
          @app = app
          @logger = Log4r::Logger.new("vagrant_vcloud::action::suspend")
        end

        def call(env)

          cfg = env[:machine].provider_config
          cnx = cfg.vcloud_cnx.driver

          vAppId = env[:machine].get_vapp_id
          vmId = env[:machine].id
          vmName = env[:machine].name

          env[:ui].info("Suspending VM #{vmName} with id #{vmId} in vApp Id #{vAppId}")
          task_id = cnx.suspend_vm(vmId)
          wait = cnx.wait_task_completion(task_id)

          true

          @app.call env
        end
      end
    end
  end
end