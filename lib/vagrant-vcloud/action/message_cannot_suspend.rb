module VagrantPlugins
  module VCloud
    module Action
      class MessageCannotSuspend
        def initialize(app, env)
          @app = app
        end

        def call(env)
          # FIXME: This error should be categorized
          env[:ui].info(I18n.t("vagrant_vcloud.vm_halted_cannot_suspend"))
          @app.call(env)
        end
      end
    end
  end
end
