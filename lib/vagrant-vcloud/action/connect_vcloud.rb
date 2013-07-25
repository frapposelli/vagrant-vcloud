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

            puts "===> Connecting to vCloud Director"
            puts "hostname:    #{config.hostname}"
            puts "username:    #{config.username}"
            puts "password:    #{config.password}"
            puts "orgname:     #{config.orgname}"
            puts "api_version: #{config.api_version}"
            puts "---<"

            # FIXME: Verify changes
            env[:vcloud_connection] = VCloudClient::Connection.new(
              config.hostname, 
              config.username, 
              config.password, 
              config.orgname, 
              config.api_version
            )

            puts "==============> Login into vCloud Director"
            test = env[:vcloud_connection].login
            puts "===>>>"
            puts test
            puts "---"
            @app.call env

          rescue Exception => e
            raise VagrantPlugins::VCloud::Errors::VCloudError, :message => e.message
          end

        end
      end
    end
  end
end
