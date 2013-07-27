require "vcloud-rest/connection"

module VagrantPlugins
  module VCloud
    module Action
      class DisconnectVCloud
        def initialize(app, env)
          @app = app
          @logger = Log4r::Logger.new("vagrant_vcloud::action::disconnect_vcloud")
        end

        def call(env)
          begin

            @logger.info("Disconnecting from vCloud Director...")

            env[:vcloud_connection].logout

            if !env[:vcloud_connection].auth_key
              @logger.info("Disconnected from vCloud Director successfully!")
              @logger.debug(
                "x-vcloud-authorization=#{env[:vcloud_connection].auth_key}"
              )
            end

          rescue Exception => e
            #raise a properly namespaced error for Vagrant
            raise Errors::VCloudError, :message => e.message
          end
        end
      end
    end
  end
end
