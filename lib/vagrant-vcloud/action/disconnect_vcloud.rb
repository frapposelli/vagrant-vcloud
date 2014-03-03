module VagrantPlugins
  module VCloud
    module Action
      class DisconnectVCloud
        def initialize(app, env)
          @app = app
          @logger = Log4r::Logger.new(
            'vagrant_vcloud::action::disconnect_vcloud'
          )
        end

        def call(env)
          begin
            @logger.info('Disconnecting from vCloud Director...')

            # Fetch the global vCloud Director connection handle
            cnx = env[:machine].provider_config.vcloud_cnx.driver

            # Delete the current vCloud Director Session
            cnx.logout

            # If session key doesn't exist, we are disconnected
            if !cnx.auth_key
              @logger.info('Disconnected from vCloud Director successfully!')
            end

          rescue Exception => e
            # Raise a properly namespaced error for Vagrant
            raise Errors::VCloudError, :message => e.message
          end
        end
      end
    end
  end
end
