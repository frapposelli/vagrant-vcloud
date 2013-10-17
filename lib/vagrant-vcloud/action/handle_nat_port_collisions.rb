require "set"
require "log4r"

module VagrantPlugins
  module VCloud
    module Action
      # This middleware class will detect and handle collisions with
      # forwarded ports, whether that means raising an error or repairing
      # them automatically.
      #
      # Parameters it takes from the environment hash:
      #
      #   * `:port_collision_repair` - If true, it will attempt to repair
      #     port collisions. If false, it will raise an exception when
      #     there is a collision.
      #
      #   * `:port_collision_extra_in_use` - An array of ports that are
      #     considered in use.
      #
      #   * `:port_collision_remap` - A hash remapping certain host ports
      #     to other host ports.
      #
      class HandleNATPortCollisions

        def initialize(app, env)
          @app    = app
          @logger = Log4r::Logger.new("vagrant_vcloud::action::handle_port_collisions")
        end

        def call(env)
          @logger.info("Detecting any forwarded port collisions...")

          # Determine a list of usable ports for repair
          usable_ports = Set.new(env[:machine].config.vm.usable_port_range)

          # Pass one, remove all defined host ports from usable ports
          with_forwarded_ports(env) do |options|
            usable_ports.delete(options[:host])
          end

          cfg = env[:machine].provider_config
          cnx = cfg.vcloud_cnx.driver
          vmName = env[:machine].name
          vAppId = env[:machine].get_vapp_id

          @logger.debug("Getting vapp info...")
          vm = cnx.get_vapp(vAppId)
          myhash = vm[:vms_hash][vmName.to_sym]

          @logger.debug("Getting port forwarding rules...")
          rules = cnx.get_vapp_port_forwarding_external_ports(vAppId)

          # Pass two, detect/handle any collisions
          with_forwarded_ports(env) do |options|
            guest_port = options[:guest]
            host_port  = options[:host]

            # If the port is open (listening for TCP connections)
            if rules.include?(host_port)
              if !options[:auto_correct]
                raise Errors::ForwardPortCollision,
                  :guest_port => guest_port.to_s,
                  :host_port  => host_port.to_s
              end

              @logger.info("Attempting to repair FP collision: #{host_port}")

              repaired_port = nil
              while !usable_ports.empty?
                # Attempt to repair the forwarded port
                repaired_port = usable_ports.to_a.sort[0]
                usable_ports.delete(repaired_port)

                # If the port is in use, then we can't use this either...
                if rules.include?(repaired_port)
                  @logger.info("Repaired port also in use: #{repaired_port}. Trying another...")
                  next
                end

                # We have a port so break out
                break
              end

              # If we have no usable ports then we can't repair
              if !repaired_port && usable_ports.empty?
                raise Errors::ForwardPortAutolistEmpty,
                  :vm_name    => env[:machine].name,
                  :guest_port => guest_port.to_s,
                  :host_port  => host_port.to_s
              end

              # Modify the args in place
              options[:host] = repaired_port

              @logger.info("Repaired FP collision: #{host_port} to #{repaired_port}")

              # Notify the user
              env[:ui].info(I18n.t("vagrant.actions.vm.forward_ports.fixed_collision",
                                   :host_port  => host_port.to_s,
                                   :guest_port => guest_port.to_s,
                                   :new_port   => repaired_port.to_s))
            end
          end

          @app.call(env)
        end

        protected

        def with_forwarded_ports(env)
          env[:machine].config.vm.networks.each do |type, options|
            # Ignore anything but forwarded ports
            next if type != :forwarded_port

            yield options
          end
        end
      end
    end
  end
end
