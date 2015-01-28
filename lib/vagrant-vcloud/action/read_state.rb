module VagrantPlugins
  module VCloud
    module Action
      class ReadState
        def initialize(app, env)
          @app = app
          @logger = Log4r::Logger.new('vagrant_vcloud::action::read_state')
        end

        def call(env)
          env[:machine_state_id] = read_state(env)

          @app.call env
        end

        def read_state(env)
          # FIXME: this part needs some cleanup
          begin
            cfg = env[:machine].provider_config
            cnx = cfg.vcloud_cnx.driver
            vapp_id = env[:machine].get_vapp_id
            vm_name = cfg.name ? cfg.name.to_sym : env[:machine].name

            if env[:machine].id.nil?
              @logger.info("VM [#{vm_name}] is not created yet")
              return :not_created
            end

            vapp = cnx.get_vapp(vapp_id)
            vm_status = vapp[:vms_hash][vm_name][:status]

            if vm_status == 'stopped'
              @logger.info("VM [#{vm_name}] is stopped")
              return :stopped
            elsif vm_status == 'running'
              @logger.info("VM [#{vm_name}] is running")
              return :running
            elsif vm_status == 'paused'
              @logger.info("VM [#{vm_name}] is suspended")
              return :suspended
            end
          rescue Exception => e
            ### When bad credentials, we get here.
            @logger.debug("Couldn't Read VM State: #{e.message}")
            raise VagrantPlugins::VCloud::Errors::VCloudError,
                  :message => e.message
          end
        end
      end
    end
  end
end
