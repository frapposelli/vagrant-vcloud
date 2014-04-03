module VagrantPlugins
  module VCloud
    module Action
      class Suspend
        def initialize(app, env)
          @app = app
          @logger = Log4r::Logger.new('vagrant_vcloud::action::suspend')
        end

        def call(env)
          cfg = env[:machine].provider_config
          cnx = cfg.vcloud_cnx.driver

          vm_id = env[:machine].id

          env[:ui].info('Suspending VM...')
          task_id = cnx.suspend_vm(vm_id)
          cnx.wait_task_completion(task_id)

          @app.call env
        end
      end
    end
  end
end