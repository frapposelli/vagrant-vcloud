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

          testvApp = cnx.get_vapp(vAppId)

          @logger.debug("Number of VMs in the vApp: #{testvApp[:vms_hash].count}")

          if testvApp[:vms_hash].count == 1

            # Poweroff vApp
            env[:ui].info("Powering off vApp...")
            vAppStopTask = cnx.poweroff_vapp(vAppId)
            vAppStopWait = cnx.wait_task_completion(vAppStopTask)

            if !vAppStopWait[:errormsg].nil?
              raise Errors::StopVAppError, :message => vAppStopWait[:errormsg]
            end

          else
            # Poweroff VM
            env[:ui].info("Powering off VM...")
            task_id = cnx.poweroff_vm(vmId)
            wait = cnx.wait_task_completion(task_id)
          end

          true

          @app.call env
        end
      end
    end
  end
end
