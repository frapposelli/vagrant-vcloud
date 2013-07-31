module VagrantPlugins
  module VCloud
    module Action
      class ReadSSHInfo

        # FIXME: More work needed here for vCloud logic (vApp, VM IPs, etc.)

        def initialize(app, env)
          @app = app
          @logger = Log4r::Logger.new("vagrant_vcloud::action::read_ssh_info")
        end

        def call(env)
          env[:machine_ssh_info] = read_ssh_info(env[:vcloud_connection], env[:machine])

          @app.call env
        end


        def read_ssh_info(connection, machine)
          return nil if machine.id.nil?

          vm = connection.get_vapp(machine)

          if vm.nil?
            # The machine can't be found
            @logger.info("Machine couldn't be found, assuming it got destroyed.")
            machine.id = nil
            return nil
          end


          return {
              :host => vm[:ip],
              :port => 22
          }
        end
      end
    end
  end
end
