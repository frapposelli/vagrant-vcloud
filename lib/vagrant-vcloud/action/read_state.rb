require "log4r"
require "vcloud-rest/connection"

module VagrantPlugins
  module VCloud
    module Action
      class ReadState

        def initialize(app, env)
          @app = app
          @logger = Log4r::Logger.new("vagrant_vcloud::action::read_state")
        end

        def call(env)

          # env[:machine_state_id] = read_state(env[:vcloud_connection], env[:machine])

          # What does this do ?
          # @app.call env
        end

        def read_state(connection, machine)

          



          #return :not_created  if machine.id.nil?

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
