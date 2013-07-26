require "vcloud-rest/connection"
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

          @logger.info("Connecting to vCloud Director...")

          @logger.debug("config.hostname    : #{config.hostname}")
          @logger.debug("config.username    : #{config.username}")
          @logger.debug("config.password    : #{config.password}")
          @logger.debug("config.orgname     : #{config.orgname}")
          @logger.debug("config.api_version : #{config.api_version}")

          begin
            # create a vcloud-rest connection object with the configuration 
            # information.
            env[:vcloud_connection] = VCloudClient::Connection.new(
              config.hostname,
              config.username,
              config.password, 
              config.orgname,
              config.api_version
            )

            @logger.info("Loggued into vCloud Director...")
            env[:vcloud_connection].login

            if env[:vcloud_connection].auth_key
              @logger.info("Login success!")
              @logger.debug(
                "x-vcloud-authorization=#{env[:vcloud_connection].auth_key}"
              )
            end
            
            @app.call env

          rescue Exception => e
            raise VagrantPlugins::VCloud::Errors::VCloudError, :message => e.message
          end

        end
      end
    end
  end
end
