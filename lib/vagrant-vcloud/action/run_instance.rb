require "log4r"
require "vagrant/util/retryable"

# FIXME: Change vSphere logic to vCloud clone logic (vApp, etc...)

module VagrantPlugins
  module VCloud
    module Action
      class RunInstance
        include Vagrant::Util::Retryable
        

        def initialize(app, env)
          @app = app
          @logger = Log4r::Logger.new("vagrant_vcloud::action::run_instance")
        end

        def call(env)
          config = env[:machine].provider_config


          begin
            build = env[:vcloud_connection].create_vapp_from_template(
              config[:vdc],
              config[:name],
              config[:description],
              config[:catalog_item],
              false
            )
          rescue Exception => e
            raise Errors::VCloudError, :message => e.message
          else
            env[:ui].info(I18n.t("vcloud.creating_cloned_vm"))
            env[:ui].info " -- Template VM: #{config.catalog_item}"
            env[:vcloud_connection].wait_task_completion(build[:task_id])
          end

          #TODO: handle interrupted status in the environment, should the vm be destroyed?

          env[:machine].id = env[:vcloud_connection].get_vapp(build[:vapp_id])

          @app.call env
        end
      end
    end
  end
end
