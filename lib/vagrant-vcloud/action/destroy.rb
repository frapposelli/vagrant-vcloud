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

          cfg = env[:machine].provider_config
          cnx = cfg.vcloud_cnx.driver
          vAppId = env[:machine].get_vapp_id
          vmId = env[:machine].id

          testvApp = cnx.get_vapp(vAppId)

          @logger.debug("Number of VMs in the vApp: #{testvApp[:vms_hash].count}")

          if testvApp[:vms_hash].count == 1
            env[:ui].info("Single VM left in the vApp, destroying the vApp...")
            env[:ui].info("Powering off vApp...")
            vAppStopTask = cnx.poweroff_vapp(vAppId)
            cnx.wait_task_completion(vAppStopTask)
            env[:ui].info("Destroying vApp...")
            vAppDeleteTask = cnx.delete_vapp(vAppId)
            @logger.debug("vApp Delete task id #{vAppDeleteTask}")
            cnx.wait_task_completion(vAppDeleteTask)

            # FIXME: Look into this.
            ####env[:machine].provider.driver.delete
            env[:machine].id=nil
            env[:machine].vappid=nil
          else
#            env[:ui].info("Powering off VM #{env[:machine].name} with id #{vmId} in vApp Id #{vAppId}")
#            task_id = cnx.poweroff_vm(vmId)
#            wait = cnx.wait_task_completion(task_id)
            env[:ui].info("Destroying VM...")
            vmDeleteTask = cnx.delete_vm(vmId)
            @logger.debug("VM Delete task id #{vmDeleteTask}")
            cnx.wait_task_completion(vmDeleteTask)
            env[:machine].id=nil
          end

          @app.call env
        end

      end
    end
  end
end
