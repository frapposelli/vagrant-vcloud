module VagrantPlugins
  module VCloud
    module Action
      class ForwardPorts
        include Util::CompileForwardedPorts

        def initialize(app, env)
          @app = app
          @logger = Log4r::Logger.new("vagrant_vcloud::action::forward_ports")
        end

        #--------------------------------------------------------------
        # Execution
        #--------------------------------------------------------------
        def call(env)
          @env = env

          # Get the ports we're forwarding
          env[:forwarded_ports] ||= compile_forwarded_ports(env[:machine].config)

          forward_ports

          @app.call(env)
        end

        def forward_ports
          ports = []

          # interfaces = @env[:machine].provider.driver.read_network_interfaces

          cfg = @env[:machine].provider_config
          cnx = cfg.vcloud_cnx.driver
          vmName = @env[:machine].name
          vAppId = @env[:machine].get_vapp_id

          cfg.org = cnx.get_organization_by_name(cfg.org_name)
          cfg.vdc_network_id = cfg.org[:networks][cfg.vdc_network_name]

          @logger.debug("Getting VM info...")
          vm = cnx.get_vapp(vAppId)
          vmInfo = vm[:vms_hash][vmName.to_sym]


          @env[:forwarded_ports].each do |fp|
            message_attributes = {
              :guest_port => fp.guest_port,
              :host_port => fp.host_port
            }

            # Assuming the only reason to establish port forwarding is
            # because the VM is using Virtualbox NAT networking. Host-only
            # bridged networking don't require port-forwarding and establishing
            # forwarded ports on these attachment types has uncertain behaviour.
            @env[:ui].info("Forwarding Ports: VM port #{fp.guest_port} -> vShield Edge port #{fp.host_port}")

            # Verify we have the network interface to attach to
            # if !interfaces[fp.adapter]
            #   raise Vagrant::Errors::ForwardPortAdapterNotFound,
            #     :adapter => fp.adapter.to_s,
            #     :guest => fp.guest_port.to_s,
            #     :host => fp.host_port.to_s
            # end

            # Port forwarding requires the network interface to be a NAT interface,
            # so verify that that is the case.
            # if interfaces[fp.adapter][:type] != :nat
            #   @env[:ui].info(I18n.t("vagrant.actions.vm.forward_ports.non_nat",
            #                         message_attributes))
            #   next
            # end

            # Add the options to the ports array to send to the driver later
            ports << {
              :guestip   => fp.guest_ip,
              :nat_internal_port => fp.guest_port,
              :hostip    => fp.host_ip,
              :nat_external_port  => fp.host_port,
              :name      => fp.id,
              :nat_protocol  => fp.protocol.upcase,
              :vapp_scoped_local_id => vmInfo[:vapp_scoped_local_id]
            }
          end

          if !ports.empty?
            # We only need to forward ports if there are any to forward

            @logger.debug("Port object to be passed: #{ports.inspect}")
            @logger.debug("Current network id #{cfg.vdc_network_id}")
            # @env[:machine].provider.driver.forward_ports(ports)

            # newvapp[:vms_hash].each do |key, value|

            # nat_rules << { :nat_external_port => j.to_s, :nat_internal_port => "873", :nat_protocol => "UDP", :vm_scoped_local_id => value[:vapp_scoped_local_id]}
            # j += 1

            ### Here we apply the nat_rules to the vApp we just built

            # puts "### Applying Port Forwarding NAT Rules"

            addports = cnx.add_vapp_port_forwarding_rules(
              vAppId,
              "Vagrant-vApp-Net",
              {
                :fence_mode => "natRouted",
                :parent_network => cfg.vdc_network_id,
                :nat_policy_type => "allowTraffic",
                :nat_rules => ports
              })

            wait = cnx.wait_task_completion(addports)

            if !wait[:errormsg].nil?
              raise Errors::ComposeVAppError, :message => wait[:errormsg]
            end


          end



        end
      end
    end
  end
end
