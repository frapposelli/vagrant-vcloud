require 'securerandom'
require 'etc'
require 'netaddr'

module VagrantPlugins
  module VCloud
    module Action
      class BuildVApp
        def initialize(app, env)
          @app = app
          @logger = Log4r::Logger.new('vagrant_vcloud::action::build_vapp')
        end

        def call(env)
          # FIXME: we need to find a way to clean things up when a SIGINT get
          # called... see env[:interrupted] in the vagrant code

          cfg = env[:machine].provider_config
          cnx = cfg.vcloud_cnx.driver
          vm_name = env[:machine].name

          if !cfg.ip_subnet.nil?
            if cfg.ip_dns.nil?
              dns_address1 = '8.8.8.8'
              dns_address2 = '8.8.4.4'
            else
              dns_address1 = cfg.ip_dns.shift
              dns_address2 = cfg.ip_dns.shift
            end
            @logger.debug("Input address: #{cfg.ip_subnet}")

            begin
              cidr = NetAddr::CIDR.create(cfg.ip_subnet)
            rescue NetAddr::ValidationError
              raise Errors::InvalidSubnet, :message => cfg.ip_subnet
            end

            if cidr.bits > 30
              @logger.debug('Subnet too small!')
              raise Errors::SubnetTooSmall, :message => cfg.ip_subnet
            end

            range_addresses = cidr.range(0)

            @logger.debug("Range: #{range_addresses}")

            # Delete the "network" address from the range.
            range_addresses.shift
            # Retrieve the first usable IP, to be used as a gateway.
            gateway_ip = range_addresses.shift
            # Reverse the array in place.
            range_addresses.reverse!
            # Delete the "broadcast" address from the range.
            range_addresses.shift
            # Reverse back the array.
            range_addresses.reverse!

            @logger.debug("Gateway IP: #{gateway_ip.to_s}")
            @logger.debug("Netmask: #{cidr.wildcard_mask}")
            @logger.debug(
              "IP Pool: #{range_addresses.first}-#{range_addresses.last}"
            )
            @logger.debug("DNS1: #{dns_address1} DNS2: #{dns_address2}")

            network_options = {
              :name               => 'Vagrant-vApp-Net',
              :gateway            => gateway_ip.to_s,
              :netmask            => cidr.wildcard_mask,
              :start_address      => range_addresses.first,
              :end_address        => range_addresses.last,
              :fence_mode         => 'natRouted',
              :ip_allocation_mode => 'POOL',
              :parent_network     => cfg.vdc_network_id,
              :enable_firewall    => 'false',
              :dns1               => dns_address1,
              :dns2               => dns_address2
            }

          elsif !cfg.network_bridge.nil?
            # Bridged mode, avoid deploying a vShield Edge altogether.
            network_options = {
              :name               => 'Vagrant-vApp-Net',
              :fence_mode         => 'bridged',
              :ip_allocation_mode => 'POOL',
              :parent_network     => cfg.vdc_network_id
            }

            env[:bridged_network] = true

          elsif !cfg.advanced_network.nil?
            # Advanced network definition
            env[:advanced_network] = true
            network_options = []
            if cfg.networks[:org]
              cfg.networks[:org].each do |net|
                net_id = cfg.org[:networks][net]
                if !net_id
                  # TEMP FIX: permissions issues at the Org Level for vApp authors
                  #           to "view" Org vDC Networks but they can see them at the
                  #           Organization vDC level (tsugliani)
                  net_id = cfg.vdc[:networks][net]
                  if !net_id
                    raise 'vCloud User credentials has insufficient privileges'
                  end
                end
                network_options.push({
                  :name               => net,
                  :fence_mode         => 'bridged',
                  :parent_network     => net_id
                })
              end
            end
            if cfg.networks[:vapp]
              cfg.networks[:vapp].each_with_index do |net, i|
                if net[:ip_dns].nil?
                  dns_address1 = '8.8.8.8'
                  dns_address2 = '8.8.4.4'
                else
                  dns_address1 = net[:ip_dns].shift
                  dns_address2 = net[:ip_dns].shift
                end
                @logger.debug("Input address[#{i}]: #{net[:ip_subnet]}")

                begin
                  cidr = NetAddr::CIDR.create(net[:ip_subnet])
                rescue NetAddr::ValidationError
                  raise Errors::InvalidSubnet, :message => net[:ip_subnet]
                end

                if cidr.bits > 30
                  @logger.debug('Subnet too small!')
                  raise Errors::SubnetTooSmall, :message => net[:ip_subnet]
                end

                range_addresses = cidr.range(0)

                @logger.debug("Range[#{i}]: #{range_addresses}")

                # Delete the "network" address from the range.
                range_addresses.shift
                # Retrieve the first usable IP, to be used as a gateway.
                gateway_ip = range_addresses.shift
                # Reverse the array in place.
                range_addresses.reverse!
                # Delete the "broadcast" address from the range.
                range_addresses.shift
                # Reverse back the array.
                range_addresses.reverse!

                @logger.debug("Gateway IP[#{i}]: #{gateway_ip.to_s}")
                @logger.debug("Netmask[#{i}]: #{cidr.wildcard_mask}")
                @logger.debug("IP Pool[#{i}]: #{range_addresses.first}-#{range_addresses.last}")
                @logger.debug("DNS1[#{i}]: #{dns_address1} DNS2[#{i}]: #{dns_address2}")
                n =  {
                  :name               => net[:name],
                  :gateway            => gateway_ip.to_s,
                  :netmask            => cidr.wildcard_mask,
                  :start_address      => range_addresses.first,
                  :end_address        => range_addresses.last,
                  :fence_mode         => 'natRouted',
                  :ip_allocation_mode => 'POOL',
                  :enable_firewall    => 'false',
                  :dns1               => dns_address1,
                  :dns2               => dns_address2
                }
                if net[:connection]
                  net_id = cfg.org[:networks][net[:connection]]
                  if !net_id
                    # TEMP FIX: permissions issues at the Org Level for vApp authors
                    #           to "view" Org vDC Networks but they can see them at the
                    #           Organization vDC level (tsugliani)
                    net_id = cfg.vdc[:networks][net[:connection]]
                    if !net_id
                      raise 'vCloud User credentials has insufficient privileges'
                    end
                  end
                  n[:parent_network] = net[:connection]
                end

                network_options.push(n)
              end
            end

          else
            if cfg.ip_dns.nil?
              dns_address1 = '8.8.8.8'
              dns_address2 = '8.8.4.4'
            else
              dns_address1 = cfg.ip_dns.shift
              dns_address2 = cfg.ip_dns.shift
            end

            @logger.debug("DNS1: #{dns_address1} DNS2: #{dns_address2}")
            # No IP subnet specified, reverting to defaults
            network_options = {
              :name               => 'Vagrant-vApp-Net',
              :gateway            => '10.1.1.1',
              :netmask            => '255.255.255.0',
              :start_address      => '10.1.1.2',
              :end_address        => '10.1.1.254',
              :fence_mode         => 'natRouted',
              :ip_allocation_mode => 'POOL',
              :parent_network     => cfg.vdc_network_id,
              :enable_firewall    => 'false',
              :dns1               => dns_address1,
              :dns2               => dns_address2
            }

          end

          if env[:machine].get_vapp_id.nil?
            env[:ui].info('Building vApp...')

            if cfg.vapp_name
              vapp_name = cfg.vapp_name
            else
              vapp_prefix = cfg.vapp_prefix
              vapp_prefix = 'Vagrant' if vapp_prefix.nil?
              vapp_name = "#{vapp_prefix}-#{Etc.getlogin}-#{Socket.gethostname.downcase}-" +
                          "#{SecureRandom.hex(4)}"
            end

            compose = cnx.compose_vapp_from_vm(
              cfg.vdc_id,
              vapp_name,
              "vApp created by #{Etc.getlogin} running on " +
              "#{Socket.gethostname.downcase} using vagrant-vcloud on " +
              "#{Time.now.strftime("%B %d, %Y")}",
              {
                vm_name => cfg.catalog_item[:vms_hash].first.last[:id]
              },
              network_options
            )
            @logger.debug('Launch Compose vApp...')
            # Wait for the task to finish.
            wait = cnx.wait_task_completion(compose[:task_id])

            unless wait[:errormsg].nil?
              fail Errors::ComposeVAppError, :message => wait[:errormsg]
            end

            # Fetch thenewly created vApp ID
            vapp_id = compose[:vapp_id]

            # putting the vApp Id in a globally reachable var and file.
            env[:machine].vappid = vapp_id

            # Fetching new vApp object to check stuff.
            new_vapp = cnx.get_vapp(vapp_id)

            # FIXME: Add a lot of error handling for each step here !
            if new_vapp
              env[:ui].success("vApp #{new_vapp[:name]} successfully created.")

              # Add the vm id as machine.id
              new_vm_properties = new_vapp[:vms_hash].fetch(vm_name)
              env[:machine].id = new_vm_properties[:id]

              ### SET GUEST CONFIG
              @logger.info(
                "Setting Guest Customization on ID: [#{vm_name}] " +
                "of vApp [#{new_vapp[:name]}]"
              )
              env[:ui].info('Setting VM guest customization...')
              set_custom = cnx.set_vm_guest_customization(
                new_vm_properties[:id],
                vm_name,
                {
                  :enabled              => true,
                  :admin_passwd_enabled => false
                }
              )
              cnx.wait_task_completion(set_custom)

            else
              env[:ui].error("vApp #{new_vapp[:name]} creation failed!")
              raise # FIXME: error handling missing.
            end

          else
            env[:ui].info('Adding VM to existing vApp...')

            recompose = cnx.recompose_vapp_from_vm(
              env[:machine].get_vapp_id,
              {
                vm_name => cfg.catalog_item[:vms_hash].first.last[:id]
              },
              network_options
            )

            @logger.info('Waiting for the recompose task to complete ...')

            # Wait for the task to finish.
            cnx.wait_task_completion(recompose[:task_id])

            new_vapp = cnx.get_vapp(env[:machine].get_vapp_id)
            # FIXME: Add a lot of error handling for each step here !
            if new_vapp
              new_vm_properties = new_vapp[:vms_hash].fetch(vm_name)
              env[:machine].id = new_vm_properties[:id]

              ### SET GUEST CONFIG
              @logger.info(
                "Setting Guest Customization on ID: [#{vm_name}] " +
                "of vApp [#{new_vapp[:name]}]"
              )
              env[:ui].info('Setting VM guest customization...')
              set_custom = cnx.set_vm_guest_customization(
                new_vm_properties[:id],
                vm_name,
                {
                  :enabled              => true,
                  :admin_passwd_enabled => false
                }
              )
              cnx.wait_task_completion(set_custom)

            else
              env[:ui].error("VM #{vm_name} add to #{new_vapp[:name]} failed!")
              raise
            end
          end

          @app.call env
        end
      end
    end
  end
end
