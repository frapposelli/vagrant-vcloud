#require "vcloud-rest/connection"
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
            # Avoid recreating a new session each time.
            if !config.vcloud_cnx
              @logger.info("Connecting to vCloud Director...")

              @logger.debug("config.hostname    : #{config.hostname}")
              @logger.debug("config.username    : #{config.username}")
              @logger.debug("config.password    : #{config.password}")
              @logger.debug("config.org_name    : #{config.org_name}")

              # Create the vcloud-rest connection object with the configuration 
              # information.



              ## config.vcloud_cnx = VCloudClient::Connection.new(

              # Switching to Driver Meta

              config.vcloud_cnx = Driver::Meta.new(
                config.hostname,
                config.username,
                config.password, 
                config.org_name
              )

              @logger.info("Logging into vCloud Director...")
              config.vcloud_cnx.login

              # Check for the vCloud Director authentication token
              if config.vcloud_cnx.driver.auth_key
                env[:ui].success("Successfully logged in to #{config.hostname}.")
                @logger.info("Logged in successfully!")
                @logger.debug(
                  "x-vcloud-authorization=#{config.vcloud_cnx.driver.auth_key}"
                )
              else
                @logger.info("DID NOT LOG IN!")
                env[:ui].error("Log in not successful #{config.hostname}.")
                raise
              end
            else
              @logger.info("Already logged in, using current session")
              @logger.debug(
                  "x-vcloud-authorization=#{config.vcloud_cnx.driver.auth_key}"
              )
            end

            @app.call env

          rescue Exception => e
            ### RAISED HERE!!! WHY?!?!?!
            @logger.debug("FAILING BADLY: #{e.inspect}")
            raise VagrantPlugins::VCloud::Errors::VCloudError, :message => e.message
          end

        end
      end
    end
  end
end
