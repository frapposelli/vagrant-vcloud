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

          env[:ui].info('Setting VM hardware...')

          memory_size = 2048
          num_vcpus = 2
          set_vm_hardware = cnx.set_vm_hardware(env[:machine].id, cfg)
          if set_vm_hardware
            cnx.wait_task_completion(set_vm_hardware)
          end

          env[:ui].info('Powering on VM...')

          poweron_vm = cnx.poweron_vm(env[:machine].id)
          cnx.wait_task_completion(poweron_vm)

          @app.call(env)
        end
      end
    end
  end
end
