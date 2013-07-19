require 'rbvmomi'
require 'i18n'
require 'vSphere/action/vim_helpers'

module VagrantPlugins
  module VCloud
    module Action
      class PowerOff
        include VimHelpers

        def initialize(app, env)
          @app = app
        end

        # FIXME: vCloud Abstraction layer/logic (vApp)

        def call(env)
          vm = get_vm_by_uuid env[:vcloud_connection], env[:machine]

          unless vm.nil?
            env[:ui].info I18n.t('vcloud.power_off_vm')
            vm.PowerOffVM_Task.wait_for_completion
          end

          @app.call env
        end
      end
    end
  end
end
