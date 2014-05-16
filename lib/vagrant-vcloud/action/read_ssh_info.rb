module VagrantPlugins
  module VCloud
    module Action
      class ReadSSHInfo
        # FIXME: More work needed here for vCloud logic (vApp, VM IPs, etc.)
        def initialize(app, env)
          @app = app
          @logger = Log4r::Logger.new('vagrant_vcloud::action::read_ssh_info')
        end

        def call(env)
          env[:machine_ssh_info] = read_ssh_info(env)

          @app.call env
        end

        def read_ssh_info(env)
          return nil if env[:machine].id.nil?

          cfg = env[:machine].provider_config
          cnx = cfg.vcloud_cnx.driver
          vapp_id = env[:machine].get_vapp_id
          vm_name = env[:machine].name

          @logger.debug('Getting vApp information...')
          vm = cnx.get_vapp(vapp_id)
          myhash = vm[:vms_hash][vm_name.to_sym]

          if vm.nil?
            # The Virtual Machine couldn't be found.
            @logger.info(
              'Machine couldn\'t be found, assuming it got destroyed.'
            )
            machine.id = nil
            return nil
          end

          if !cfg.network_bridge.nil?
            @logger.debug("We're running in bridged mode,
                          fetching the IP directly from the VM")
            vm_info = cnx.get_vm(env[:machine].id)
            @logger.debug("IP address for #{vm_name}:
                          #{vm_info[:networks]['Vagrant-vApp-Net'][:ip]}")
            @external_ip = vm_info[:networks]['Vagrant-vApp-Net'][:ip]
            @external_port = '22'
          else

            @logger.debug('Getting port forwarding rules...')
            rules = cnx.get_vapp_port_forwarding_rules(vapp_id)

            rules.each do |rule|
              if rule[:vapp_scoped_local_id] == myhash[:vapp_scoped_local_id] && rule[:nat_internal_port] == '22'
                @external_ip = rule[:nat_external_ip]
                @external_port = rule[:nat_external_port]
                break

              end
            end

            if cfg.vdc_edge_gateway_ip && cfg.vdc_edge_gateway
              @logger.debug("We're running vagrant behind an Organization vDC
                            edge")
              @external_ip = cfg.vdc_edge_gateway_ip
            end
          end

          # FIXME: fix the selfs and create a meaningful info message
          # @logger.debug(
          #  "Our variables: IP #{@external_ip} and Port #{@external_port}"
          # )

          {
              # FIXME: these shouldn't be self
              :host => @external_ip,
              :port => @external_port
          }
        end
      end
    end
  end
end
