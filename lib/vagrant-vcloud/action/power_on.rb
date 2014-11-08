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

          if !cfg.nics.nil? && cfg.nics.length > 0
            env[:ui].info('Setting VM network cards...')
            set_vm_nics = cnx.set_vm_nics(env[:machine].id, cfg)
            if set_vm_nics
              cnx.wait_task_completion(set_vm_nics)
            end
          end

          if !cfg.nested_hypervisor.nil? && cfg.nested_hypervisor == true
            env[:ui].info('Enabling nested hypervisor...')
            set_vm_nested_hypervisor = cnx.set_vm_nested_hypervisor(env[:machine].id, cfg.nested_hypervisor)
            if set_vm_nested_hypervisor
              cnx.wait_task_completion(set_vm_nested_hypervisor)
            end
          end

          if cfg.power_on.nil? || cfg.power_on == true
            env[:ui].info('Powering on VM...')
            poweron_vm = cnx.poweron_vm(env[:machine].id)
            cnx.wait_task_completion(poweron_vm)
          end

          @app.call(env)
        end
      end
    end
  end
end
