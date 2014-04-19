module VagrantPlugins
  module VCloud
    module Action
      class PowerOff
        def initialize(app, env)
          @app = app
          @logger = Log4r::Logger.new('vagrant_vcloud::action::poweroff')
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

          if test_vapp[:vms_hash].count == 1
            # this is a helper to get vapp_edge_ip into cache for later destroy of edge gateway rules
            vapp_edge_ip = cnx.get_vapp_edge_public_ip(vapp_id)

            # Poweroff vApp
            env[:ui].info('Powering off vApp...')
            vapp_stop_task = cnx.poweroff_vapp(vapp_id)
            vapp_stop_wait = cnx.wait_task_completion(vapp_stop_task)

            unless vapp_stop_wait[:errormsg].nil?
              fail Errors::StopVAppError, :message => vapp_stop_wait[:errormsg]
            end

          else
            # Poweroff VM
            env[:ui].info('Powering off VM...')
            task_id = cnx.poweroff_vm(vm_id)
            cnx.wait_task_completion(task_id)
          end

          @app.call env
        end
      end
    end
  end
end
