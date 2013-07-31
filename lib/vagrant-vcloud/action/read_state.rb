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

          cfg = env[:machine].provider_config

          if cnx.id.nil?
            @logger.debug("!!! Machine is not created yet. !!!")
            return :not_created
          end

          #vm = connection.get_vapp(machine)

          #if vm.nil?
          #  return :not_created
          #end

          #if vm[:status].eql?(POWERED_ON)
          #  @logger.info("Machine is powered on.")
          #  :running
          #else
          #  @logger.info("Machine not found or terminated, assuming it got destroyed.")
          #  # If the VM is powered off or suspended, we consider it to be powered off. A power on command will either turn on or resume the VM
          #  :poweroff
          #end
        end
      end
    end
  end
end
