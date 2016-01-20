require 'vagrant/util/scoped_hash_override'

module VagrantPlugins
  module VCloud
    module Util
      module CompileForwardedPorts
        include Vagrant::Util::ScopedHashOverride

        # This method compiles the forwarded ports into {ForwardedPort}
        # models.
        def compile_forwarded_ports(machine)
          mappings = {}

          machine.config.vm.networks.each do |type, options|
            if type == :forwarded_port
              guest_port = options[:guest]
              host_port  = options[:host]
              options    = scoped_hash_override(options, :vcloud)
              id         = options[:id]

              # skip forwarded rules already found in handle_nat_port_collisions
              next if options[:already_exists]

              # skip forwarded rules if disabled
              next if !options[:disabled].nil? && options[:disabled] == true

              mappings[host_port] =
                Model::ForwardedPort.new(id, host_port, guest_port, 'Vagrant-vApp-Net', machine.provider_config.vdc_network_id, machine.provider_config.vdc_network_name, options)
            end
          end
          if !machine.provider_config.nics.nil?
            machine.provider_config.nics.each do |nic|
              next if nic[:forwarded_port].nil?
              nic[:forwarded_port].each do |fp|
                options = fp

                guest_port = options[:guest]
                host_port  = options[:host]
                options    = scoped_hash_override(options, :vcloud)
                id         = options[:id]

                # skip forwarded rules already found in handle_nat_port_collisions
                next if options[:already_exists]

                # skip forwarded rules if disabled
                next if !options[:disabled].nil? && options[:disabled] == true

                # find matching network
                edge_id = nil
                edge_name = nil
                if !machine.provider_config.networks.nil? && !machine.provider_config.networks[:vapp].nil?
                  machine.provider_config.networks[:vapp].each do |net|
                    next if net[:name] != nic[:network]
                    edge_id = net[:parent_network]
                    edge_name = net[:vdc_network_name]
                    break
                  end
                end
                if edge_id == nil || edge_name == nil
                  edge_id = machine.provider_config.vdc_network_id
                  edge_name = machine.provider_config.vdc_network_name
                end

                mappings[host_port] = Model::ForwardedPort.new(id, host_port, guest_port, nic[:network], edge_id, edge_name, options)

              end
            end
          end

          mappings.values
        end
      end
    end
  end
end
