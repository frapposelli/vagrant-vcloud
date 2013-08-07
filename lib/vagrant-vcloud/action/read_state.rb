require "log4r"

module VagrantPlugins
  module VCloud
    module Action
      class ReadState

        def initialize(app, env)
          @app = app
          @logger = Log4r::Logger.new("vagrant_vcloud::action::read_state")
        end

        def call(env)
          env = read_state(env)
            
          @app.call env
        end

        def read_state(env)

          begin
            cfg = env[:machine].provider_config
            cnx = cfg.vcloud_cnx.driver
            vAppId = env[:machine].get_vapp_id
            vmName = env[:machine].name

            if env[:machine].id.nil?
              @logger.info("VM [#{vmName}] is not created yet")
              env[:machine_state_id] = "notcreated"
            end

            vApp = cnx.get_vapp(vAppId)
            vmStatus = vApp[:vms_hash][vmName][:status]

            if vmStatus == "stopped"
              @logger.info("VM [#{vmName}] is stopped")
              env[:machine_state_id] = "stopped"
            elsif vmStatus == "running"
              @logger.info("VM [#{vmName}] is running")
              env[:machine_state_id] = "running"
            elsif vmStatus == "paused"
              @logger.info("VM [#{vmName}] is suspended")
              env[:machine_state_id] = "suspended"
            end
          rescue Exception => e
            ### When bad credentials, we get here.
            @logger.debug("Couldn't Read VM State: #{e.message}")
            raise VagrantPlugins::VCloud::Errors::VCloudError, :message => e.message
          end
          
        end
      end
    end
  end
end
