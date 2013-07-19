require 'vcloud-rest/connection'
require "log4r"

module VagrantPlugins
  module VCloud
    module Action
      class ConnectVCloud
        def initialize(app, env)
          @app = app
          @logger = Log4r::Logger.new("vagrant_vcloud::action::connect_vcloud")
        end

        def call(env)
          config = env[:machine].provider_config


          begin

            # FIXME: Verify changes
            env[:vcloud_connection] = VCloudClient::Connection.new(config.host, config.user, config.password, config.orgname, config.api_version)
            env[:vcloud_connection].login
            @app.call env

          rescue Exception => e
            raise VagrantPlugins::VCloud::Errors::VCloudError, :message => e.message
          end

        end
      end
    end
  end
end
