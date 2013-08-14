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
          #env = read_state(env)
            
          env[:machine_state_id] = read_state(env) 
          
          @app.call env
        end

        def read_state(env)

          # FIXME: this part needs some cleanup

          begin
            cfg = env[:machine].provider_config
            cnx = cfg.vcloud_cnx.driver
            vAppId = env[:machine].get_vapp_id
            vmName = env[:machine].name

            if env[:machine].id.nil?
              @logger.info("VM [#{vmName}] is not created yet")
              return :not_created
            end

            vApp = cnx.get_vapp(vAppId)
            vmStatus = vApp[:vms_hash][vmName][:status]

            if vmStatus == "stopped"
              @logger.info("VM [#{vmName}] is stopped")
              return :stopped
            elsif vmStatus == "running"
              @logger.info("VM [#{vmName}] is running")
              return :running
            elsif vmStatus == "paused"
              @logger.info("VM [#{vmName}] is suspended")
              return :suspended
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
