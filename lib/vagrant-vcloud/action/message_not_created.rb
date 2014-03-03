module VagrantPlugins
  module VCloud
    module Action
      class MessageNotCreated
        def initialize(app, env)
          @app = app
        end

        def call(env)
          # FIXME: this error should be categorized
          env[:ui].info(I18n.t('vcloud.vm_not_created'))
          @app.call(env)
        end
      end
    end
  end
end
