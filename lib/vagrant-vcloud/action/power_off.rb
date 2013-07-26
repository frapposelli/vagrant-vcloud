require "i18n"

module VagrantPlugins
  module VCloud
    module Action
      class PowerOff

        def initialize(app, env)
          @app = app
          @logger = Log4r::Logger.new("vagrant_vcloud::action::PowerOff")
        end

        def call(env)
          # Simple idea
          # env[:vcloud_connection].delete_vapp(env[:machine])

          # What does this do ?
          @app.call env
        end
      end
    end
  end
end
