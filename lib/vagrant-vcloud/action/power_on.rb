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

          # add vm metadata
          if !cfg.metadata_vm.nil?
            env[:ui].info('Setting VM metadata...')
            set_metadata_vm = cnx.set_vm_metadata env[:machine].id, cfg.metadata_vm
            cnx.wait_task_completion(set_metadata_vm)
          end

          # add/update hardware
          env[:ui].info('Setting VM hardware...')
          set_vm_hardware = cnx.set_vm_hardware(env[:machine].id, cfg)
          if set_vm_hardware
            cnx.wait_task_completion(set_vm_hardware)
          end
          set_vm_network_connected = cnx.set_vm_network_connected(env[:machine].id)
          if set_vm_network_connected
            env[:ui].info('Connecting all NICs...')
            cnx.wait_task_completion(set_vm_network_connected)
          end

          # enable nested hypervisor
          if !cfg.nested_hypervisor.nil? && cfg.nested_hypervisor == true
            env[:ui].info('Enabling nested hypervisor...')
            set_vm_nested_hypervisor = cnx.set_vm_nested_hypervisor(env[:machine].id, true)
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
