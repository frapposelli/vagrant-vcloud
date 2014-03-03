module VagrantPlugins
  module VCloud
    module Action
      class IsCreated
        def initialize(app, env)
          @app = app
          @logger = Log4r::Logger.new('vagrant_vcloud::action::is_created')
        end

        def call(env)
          vapp_id = env[:machine].get_vapp_id

          if vapp_id.nil?
            @logger.warn('vApp has not been created')
            env[:result] = false
          else
            @logger.info("vApp has been created and ID is: [#{vapp_id}]")

            vm_id = env[:machine].id
            if vm_id
              @logger.info("VM has been added to vApp and ID is: [#{vm_id}]")
              env[:result] = true
            else
              @logger.warn('VM has not been added to vApp')
              env[:result] = false
            end

          end

          @app.call env
        end
      end
    end
  end
end
