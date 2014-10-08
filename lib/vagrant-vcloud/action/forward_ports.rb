module VagrantPlugins
  module VCloud
    module Action
      class ForwardPorts
        include Util::CompileForwardedPorts

        def initialize(app, env)
          @app = app
          @logger = Log4r::Logger.new('vagrant_vcloud::action::forward_ports')
        end

        def call(env)
          @env = env

          # Get the ports we are forwarding
          env[:forwarded_ports] ||= compile_forwarded_ports(
            env[:machine].config
          )

          forward_ports

          @app.call(env)
        end

        def forward_ports
          ports = []
          edge_ports = []

          cfg = @env[:machine].provider_config
          cnx = cfg.vcloud_cnx.driver
          vapp_id = @env[:machine].get_vapp_id
          vm_name = cfg.name ? cfg.name.to_sym : @env[:machine].name

          # FIXME: why are we overriding this here ?
          #        It's already been taken care during the initial
          #        InventoryCheck. (tsugliani)
          #
          # cfg.org = cnx.get_organization_by_name(cfg.org_name)
          # cfg.vdc_network_id = cfg.org[:networks][cfg.vdc_network_name]

          @logger.debug('Getting VM info...')
          vm = cnx.get_vapp(vapp_id)
          vm_info = vm[:vms_hash][vm_name.to_sym]

          @env[:forwarded_ports].each do |fp|

            @env[:ui].info(
              "Forwarding Ports: VM port #{fp.guest_port} -> " +
              "vShield Edge port #{fp.host_port}"
            )

            # Add the options to the ports array to send to the driver later
            ports << {
              :guestip                => fp.guest_ip,
              :nat_internal_port      => fp.guest_port,
              :hostip                 => fp.host_ip,
              :nat_external_port      => fp.host_port,
              :name                   => fp.id,
              :nat_protocol           => fp.protocol.upcase,
              :vapp_scoped_local_id   => vm_info[:vapp_scoped_local_id]
            }
          end

          if !ports.empty?
            # We only need to forward ports if there are any to forward
            @logger.debug("Port object to be passed: #{ports.inspect}")
            @logger.debug("Current network id #{cfg.vdc_network_id}")

            ### Here we apply the nat_rules to the vApp we just built
            add_ports = cnx.add_vapp_port_forwarding_rules(
              vapp_id,
              'Vagrant-vApp-Net',
              {
                :fence_mode       => 'natRouted',
                :parent_network   => cfg.vdc_network_id,
                :nat_policy_type  => 'allowTraffic',
                :nat_rules        => ports
              }
            )

            wait = cnx.wait_task_completion(add_ports)

            if !wait[:errormsg].nil?
              raise Errors::ComposeVAppError, :message => wait[:errormsg]
            end


            if cfg.vdc_edge_gateway_ip && \
               cfg.vdc_edge_gateway && \
               cfg.network_bridge.nil?

              vapp_edge_ip = cnx.get_vapp_edge_public_ip(vapp_id)
              @logger.debug('Getting edge gateway port forwarding rules...')
              edge_gateway_rules = cnx.get_edge_gateway_rules(cfg.vdc_edge_gateway,
                                                              cfg.vdc_id)
              vapp_edge_dnat_rules = edge_gateway_rules.select {|r| (r[:rule_type] == 'DNAT' &&
                                                                r[:translated_ip] == vapp_edge_ip)}
              vapp_edge_ports_in_use = vapp_edge_dnat_rules.map{|r| r[:original_port].to_i}.to_set

              ports.each do |port|
                if port[:vapp_scoped_local_id] == vm_info[:vapp_scoped_local_id] &&
                  !vapp_edge_ports_in_use.include?(port[:nat_external_port])
                  @env[:ui].info(
                    "Creating NAT rules on [#{cfg.vdc_edge_gateway}] " +
                    "for IP [#{vapp_edge_ip}] port #{port[:nat_external_port]}."
                  )

                  edge_ports << port[:nat_external_port]
                end
              end

              if !edge_ports.empty?
                # Add the vShield Edge Gateway rules
                add_ports = cnx.add_edge_gateway_rules(
                  cfg.vdc_edge_gateway,
                  cfg.vdc_id,
                  cfg.vdc_edge_gateway_ip,
                  vapp_id,
                  edge_ports
                )

                wait = cnx.wait_task_completion(add_ports)

                if !wait[:errormsg].nil?
                  raise Errors::ComposeVAppError, :message => wait[:errormsg]
                end
              end

            end
          end
        end
      end
    end
  end
end
