module VagrantPlugins
  module VCloud
    module Cap
      module ForwardedPorts
        # Reads the forwarded ports that currently exist on the machine
        # itself. This raises an exception if the machine isn't running.
        #
        # This also may not match up with configured forwarded ports, because
        # Vagrant auto port collision fixing may have taken place.
        #
        # @return [Hash<Integer, Integer>] Host => Guest port mappings.
        def self.forwarded_ports(machine)
          result = {}

          cfg = machine.provider_config
          cnx = cfg.vcloud_cnx.driver
          vapp_id = machine.get_vapp_id
          vm_name = machine.name
          vm = cnx.get_vapp(vapp_id)
          myhash = vm[:vms_hash][vm_name.to_sym]

          return if vm.nil?

          if cfg.network_bridge.nil?
            rules = cnx.get_vapp_port_forwarding_rules(vapp_id)

            rules.each do |rule|
              if rule[:vapp_scoped_local_id] == myhash[:vapp_scoped_local_id]
                result[rule[:nat_external_port].to_i] = rule[:nat_internal_port].to_i
              end
            end
          end
          result
        end
      end
    end
  end
end
