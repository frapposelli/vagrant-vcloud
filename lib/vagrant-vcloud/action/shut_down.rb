module VagrantPlugins
  module VCloud
    module Action
      class ShutDown
        def initialize(app, env)
          @app = app
          @logger = Log4r::Logger.new('vagrant_vcloud::action::shutdown')
        end

        def call(env)
          cfg = env[:machine].provider_config
          cnx = cfg.vcloud_cnx.driver

          vapp_id = env[:machine].get_vapp_id
          vm_id = env[:machine].id

          test_vapp = cnx.get_vapp(vapp_id)

          @logger.debug(
            "Number of VMs in the vApp: #{test_vapp[:vms_hash].count}"
          )

          # Shutdown VM
          env[:ui].info('Shutting down VM...')
          task_id = cnx.shutdown_vm(vm_id)
          cnx.wait_task_completion(task_id)

          @app.call env
        end
      end
    end
  end
end
