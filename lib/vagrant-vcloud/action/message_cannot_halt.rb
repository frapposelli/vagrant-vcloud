module VagrantPlugins
  module VCloud
    module Action
      class MessageCannotHalt
        def initialize(app, env)
          @app = app
        end

        def call(env)
          env[:ui].info(I18n.t("vagrant_vcloud.vm_cannot_halt"))
          @app.call(env)
        end
      end
    end
  end
end
