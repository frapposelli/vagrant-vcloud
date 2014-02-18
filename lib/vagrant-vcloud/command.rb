require 'awesome_print'
require 'terminal-table'

module VagrantPlugins
  module VCloud
    class Command < Vagrant.plugin("2", :command)
      
      def self.synopsis
        "outputs status of the vCloud Director setup [ONLY for vCloud Provider]"
      end

      def execute
        options = {}
        opts = OptionParser.new do |o|
          o.banner = "Usage: vagrant vcloud-status [--all]"

          # We can probably extend this if needed for specific information
          o.on("-a", "--all", "Displays all available information") do |f|
            options[:all] = true
          end
        end

        @argv = parse_options(opts)
        return if !@argv

        # initialize some variables
        vAppId = nil
        cfg = nil

        # Go through the vagrant machines
        with_target_vms(@argv) do |machine|

          # FIXME/Bug: why does the provider switch to virtualbox when destroying
          #            VMs within the the vApp: .vagrant/machines/<machine>/virtualbox
          #            Cannot trace why this happens :-( (tsugliani)
          if machine.provider_name != :vcloud
            # Not a vCloud Director provider, exit with explicit error message
            puts "#{machine.provider_name} provider is incompatible with this command" 
            exit 1
          end
          
          # Force reloads on objects by fetching the ssh_info       
          machine.provider.ssh_info
          
          # populate cfg & vApp Id for later use.
          cfg = machine.provider_config
          vAppId = machine.get_vapp_id
          break 
        end

        # Set our handlers to the driver and objects
        cnx = cfg.vcloud_cnx.driver
        vApp = cnx.get_vapp(vAppId)

        organization = cnx.get_organization_by_name(cfg.org_name)
        cfg.vdc_id = cnx.get_vdc_id_by_name(organization, cfg.vdc_name)

        # Create a new table for the general information     
        table = Terminal::Table.new 
        table.title = "Vagrant vCloud Director Status : #{cfg.hostname}"
        
        table << ['Organization Name', cfg.org_name]
        table << ['Organization vDC Name', cfg.vdc_name]
        table << ['Organization vDC ID', cfg.vdc_id]
        table << ['Organization vDC Network Name', cfg.vdc_network_name]
        table << ['Organization vDC Edge Gateway Name', cfg.vdc_edge_gateway]
        table << ['Organization vDC Edge IP', cfg.vdc_edge_gateway_ip]
        table << :separator
        table << ['vApp Name', vApp[:name]]
        table << ['vAppID', vAppId]

        vApp[:vms_hash].each do |vm|
          # This should be checked indivudually 
          # When 1 VM is destroyed, ID is still populated, should be cleaned.
          table << ["-> #{vm[0]}", vm[1][:id]]
        end

        # Print the General Information Table
        puts table

        # Display Network information only if --all is passed to the cmd
        if options[:all] == true

          vAppEdgeIp = cnx.get_vapp_edge_public_ip(vAppId)
          vAppEdgeRules = cnx.get_vapp_port_forwarding_rules(vAppId)
          edgeGatewayRules = cnx.get_edge_gateway_rules(cfg.vdc_edge_gateway, cfg.vdc_id)

          # Create a new table for the network information
          networkTable = Terminal::Table.new
          networkTable.title = "Vagrant vCloud Director Network Map"

          networkTable << ['VM Name', 'Destination NAT Mapping', 'Enabled']
          networkTable << :separator

          # Fetching Destination NAT Rules for each vApp/Edge/VM/Mapping
          edgeGatewayRules.each do |edgeGatewayRule|
            vAppEdgeRules.each do |vAppEdgeRule|

              # Only check DNAT and src/dst
              if edgeGatewayRule[:rule_type] == "DNAT" &&
                 edgeGatewayRule[:original_ip] == cfg.vdc_edge_gateway_ip &&
                 edgeGatewayRule[:translated_ip] == vAppEdgeIp

                 # Loop on every VM in the vApp
                 vApp[:vms_hash].each do |vm|
                  # Only Map valid vAppEdge scope to VM scope 
                  if vm[1][:vapp_scoped_local_id] == vAppEdgeRule[:vapp_scoped_local_id]
   
                    # Generate DNAT Mappings for the valid machines
                    # If rules don't match, you will not see them !
                    networkTable << [
                      "#{vm[0]}",
                      "#{cfg.vdc_edge_gateway_ip}:#{vAppEdgeRule[:nat_external_port]}" +
                      " -> #{vAppEdgeIp}:#{vAppEdgeRule[:nat_external_port]}" +
                      " -> #{vm[1][:addresses][0]}:#{vAppEdgeRule[:nat_internal_port]}",
                      edgeGatewayRule[:is_enabled]
                    ]
                  end
                end
              end
            end
          end

          # Fetching Source NAT Rules for the vApp
          networkTable << :separator
          networkTable << ['Network Name', 'Source NAT Mapping', 'Enabled']
          networkTable << :separator

          edgeGatewayRules.each do |edgeGatewayRule|
            # Only check SNAT and src/dst
            if edgeGatewayRule[:rule_type] == "SNAT" &&
               edgeGatewayRule[:original_ip] == vAppEdgeIp &&
               edgeGatewayRule[:translated_ip] == cfg.vdc_edge_gateway_ip

              networkTable << [
                edgeGatewayRule[:interface_name],
                "#{vAppEdgeIp} -> #{cfg.vdc_edge_gateway_ip}",
                edgeGatewayRule[:is_enabled]
              ]
            end
          end

          # Fetching Edge Gateway Firewall Rules 
          networkTable << :separator
          networkTable << ['Rule# - Description', 'Firewall Rules', 'Enabled']
          networkTable << :separator
          edgeGatewayRules.each do |edgeGatewayRule|
            # Only add firewall rules
            if edgeGatewayRule[:rule_type] == "Firewall"
              networkTable << [
                "#{edgeGatewayRule[:id]} - (#{edgeGatewayRule[:description]})",
                "#{edgeGatewayRule[:policy]} " +
                "SRC:#{edgeGatewayRule[:source_ip]}:#{edgeGatewayRule[:source_portrange]} to " +
                "DST:#{edgeGatewayRule[:destination_ip]}:#{edgeGatewayRule[:destination_portrange]}",
                "#{edgeGatewayRule[:is_enabled]}"
              ]
            end
          end

          # Print the Network Table
          puts 
          puts networkTable

        end

        0

      end
    end
  end
end