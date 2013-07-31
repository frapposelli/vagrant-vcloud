module VagrantPlugins
  module VCloud
    module Action
      class CreateVApp
        def initialize(app, env)
          @app = app
          @logger = Log4r::Logger.new("vagrant_vcloud::action::create_vapp")
        end

        def call(env)

          @logger.info("Creating vApp ...")
          @app.call env

        end
      end
    end
  end
end
