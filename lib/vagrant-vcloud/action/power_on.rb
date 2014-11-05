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

          set_vm_hardware = cnx.set_vm_hardware(env[:machine].id, cfg)
          if set_vm_hardware
            cnx.wait_task_completion(set_vm_hardware)
          end

          env[:ui].info('Powering on VM...')

          if ! cfg.nested_hypervisor.nil?
            set_vm_nested_hypervisor = cnx.set_vm_nested_hypervisor(env[:machine].id, cfg.nested_hypervisor)
            if set_vm_nested_hypervisor
              cnx.wait_task_completion(set_vm_nested_hypervisor)
            end
          end

          poweron_vm = cnx.poweron_vm(env[:machine].id)
          cnx.wait_task_completion(poweron_vm)

          @app.call(env)
        end
      end
    end
  end
end
