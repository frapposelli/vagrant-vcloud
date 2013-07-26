require "i18n"

module VagrantPlugins
  module VCloud
    module Action
      class Destroy

        # FIXME: Probably a lot of logic to change to cope with vCloud.

        def initialize(app, env)
          @app = app
        end

        def call(env)
          destroy_vm env
          env[:machine].id = nil

          @app.call env
        end

        def destroy_vm(env)
          vm = get_vm_by_uuid env[:vcloud_connection], env[:machine]
          return if vm.nil?

          begin
            env[:ui].info I18n.t("vcloud.destroy_vm")
            vm.Destroy_Task.wait_for_completion
          rescue Exception => e
            raise Errors::VCloudError, :message => e.message
          end
        end
      end
    end
  end
end
