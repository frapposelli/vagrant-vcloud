require 'awesome_print'
require 'terminal-table'

module VagrantPlugins
  module VCloud
    class Command < Vagrant.plugin('2', :command)
      def self.synopsis
        'outputs status of the vCloud Director setup [vcloud provider only]'
      end

      def execute
        options = {}
        opts = OptionParser.new do |o|
          o.banner = 'Usage: vagrant vcloud-status [--all]'

          # We can probably extend this if needed for specific information
          o.on('-a', '--all', 'Displays all available information') do |f|
            options[:all] = true
          end
        end

        @argv = parse_options(opts)
        return unless @argv

        # initialize some variables
        vapp_id = nil
        cfg = nil

        # Go through the vagrant machines
        with_target_vms(@argv) do |machine|

          # FIXME/Bug: why does the provider switch to virtualbox when
          # destroying VMs within the the vApp:
          # .vagrant/machines/<machine>/virtualbox Cannot trace why this
          # happens :-( (tsugliani)
          if machine.provider_name != :vcloud
            # Not a vCloud Director provider, exit with explicit error message
            puts "#{machine.provider_name} provider is incompatible with " +
                  'this command'
            exit 1
          end

          # Force reloads on objects by fetching the ssh_info
          machine.provider.ssh_info

          # populate cfg & vApp Id for later use.
          cfg = machine.provider_config
          vapp_id = machine.get_vapp_id
          break
        end

        # Set our handlers to the driver and objects
        cnx = cfg.vcloud_cnx.driver
        vapp = cnx.get_vapp(vapp_id)

        organization = cnx.get_organization_by_name(cfg.org_name)
        cfg.vdc_id = cnx.get_vdc_id_by_name(organization, cfg.vdc_name)

        # Create a new table for the general information
        table = Terminal::Table.new
        table.title = "Vagrant vCloud Director Status : #{cfg.hostname}"

        table << ['Organization Name', cfg.org_name]
        table << ['Organization vDC Name', cfg.vdc_name]
        table << ['Organization vDC ID', cfg.vdc_id]
        table << ['Organization vDC Network Name', cfg.vdc_network_name]
        table << ['Organization vDC Edge Gateway Name',
                  cfg.vdc_edge_gateway] unless cfg.vdc_edge_gateway.nil?
        table << ['Organization vDC Edge IP',
                  cfg.vdc_edge_gateway_ip] unless cfg.vdc_edge_gateway_ip.nil?
        table << :separator
        table << ['vApp Name', vapp[:name]]
        table << ['vAppID', vapp_id]

        vapp[:vms_hash].each do |vm|
          # This should be checked indivudually
          # When 1 VM is destroyed, ID is still populated, should be cleaned.
          table << ["-> #{vm[0]}", vm[1][:id]]
        end

        # Print the General Information Table
        puts table

        # Display Network information only if --all is passed to the cmd
        if options[:all] == true

          # FIXME: this needs to be fixed to accomodate the bridged scenario
          # potentially showing only the assigned IPs in the VMs

          if !cfg.network_bridge.nil?

            # Create a new table for the network information
            network_table = Terminal::Table.new
            network_table.title = 'Network Map'

            network_table << ['VM Name', 'IP Address', 'Connection']
            network_table << :separator

            # ap vapp[:vms_hash]

            vapp[:vms_hash].each do |vm|
              # ap vm

              network_table << [vm[0], vm[1][:addresses][0], 'Direct']
            end
          else

            vapp_edge_ip = cnx.get_vapp_edge_public_ip(vapp_id)
            vapp_edge_rules = cnx.get_vapp_port_forwarding_rules(vapp_id)
            edge_gateway_rules = cnx.get_edge_gateway_rules(cfg.vdc_edge_gateway,
                                                            cfg.vdc_id)

            # Create a new table for the network information
            network_table = Terminal::Table.new
            network_table.title = 'Vagrant vCloud Director Network Map'

            network_table << ['VM Name', 'Destination NAT Mapping', 'Enabled']
            network_table << :separator

            # Fetching Destination NAT Rules for each vApp/Edge/VM/Mapping
            vapp_edge_rules.each do |vapp_edge_rule|
              edge_gateway_rule = edge_gateway_rules.find {|r|
                      (r[:rule_type] == 'DNAT' &&
                       r[:original_ip] == cfg.vdc_edge_gateway_ip &&
                       r[:translated_ip] == vapp_edge_ip)}

              # Loop on every VM in the vApp
              vapp[:vms_hash].each do |vm|
                # Only Map valid vAppEdge scope to VM scope
                vm_scope = vm[1][:vapp_scoped_local_id]
                vapp_edge_scope = vapp_edge_rule[:vapp_scoped_local_id]

                if vm_scope == vapp_edge_scope

                  # Generate DNAT Mappings for the valid machines
                  # If rules don't match, you will not see them !
                  if edge_gateway_rule
                    # DNAT rule from edge to vapp to vm
                    network_table << [
                      "#{vm[0]}",
                      "#{cfg.vdc_edge_gateway_ip}:" +
                      "#{vapp_edge_rule[:nat_external_port]}" +
                      " -> #{vapp_edge_ip}:" +
                      "#{vapp_edge_rule[:nat_external_port]}" +
                      " -> #{vm[1][:addresses][0]}:" +
                      "#{vapp_edge_rule[:nat_internal_port]}",
                      edge_gateway_rule[:is_enabled]
                    ]
                  else
                    # DNAT rule only from vapp to vm
                    network_table << [
                      "#{vm[0]}",
                      "#{vapp_edge_ip}:" +
                      "#{vapp_edge_rule[:nat_external_port]}" +
                      " -> #{vm[1][:addresses][0]}:" +
                      "#{vapp_edge_rule[:nat_internal_port]}",
                      true
                    ]
                  end
                end
              end
            end

            # Fetching Source NAT Rules for the vApp
            network_table << :separator
            network_table << ['Network Name', 'Source NAT Mapping', 'Enabled']
            network_table << :separator

            edge_gateway_rules.each do |edge_gateway_rule|
              # Only check SNAT and src/dst
              if edge_gateway_rule[:rule_type] == 'SNAT' &&
                 edge_gateway_rule[:original_ip] == vapp_edge_ip &&
                 edge_gateway_rule[:translated_ip] == cfg.vdc_edge_gateway_ip

                network_table << [
                  edge_gateway_rule[:interface_name],
                  "#{vapp_edge_ip} -> #{cfg.vdc_edge_gateway_ip}",
                  edge_gateway_rule[:is_enabled]
                ]
              end
            end

            # Fetching Edge Gateway Firewall Rules
            network_table << :separator
            network_table << ['Rule# - Description', 'Firewall Rules', 'Enabled']
            network_table << :separator
            edge_gateway_rules.each do |edge_gateway_rule|
              # Only add firewall rules
              if edge_gateway_rule[:rule_type] == 'Firewall'
                network_table << [
                  "#{edge_gateway_rule[:id]} - " +
                  "(#{edge_gateway_rule[:description]})",
                  "#{edge_gateway_rule[:policy]} " +
                  "SRC:#{edge_gateway_rule[:source_ip]}:" +
                  "#{edge_gateway_rule[:source_portrange]} to " +
                  "DST:#{edge_gateway_rule[:destination_ip]}:" +
                  "#{edge_gateway_rule[:destination_portrange]}",
                  "#{edge_gateway_rule[:is_enabled]}"
                ]
              end
            end
          end
          # Print the Network Table
          puts
          puts network_table

        end

        0
      end
    end
  end
end
