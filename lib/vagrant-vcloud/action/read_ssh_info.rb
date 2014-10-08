module VagrantPlugins
  module VCloud
    module Action
      class ReadSSHInfo
        def initialize(app, env, port = 22)
          @app = app
          @port = port
          @logger = Log4r::Logger.new('vagrant_vcloud::action::read_ssh_info')
        end

        def call(env)
          env[:machine_ssh_info] = read_ssh_info(env)

          @app.call env
        end

        # Small method to check the tcp connection to an ip:port works.
        # Return false if anything fails, and true if it succeeded.
        def check_for_port(ip, port, port_name)
          begin
            Timeout::timeout(1) do
              begin
                s = TCPSocket.new(ip, port)
                s.close
                @logger.debug("#{port_name} Connection successful !")
                return true
              rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH, Errno::EHOSTDOWN
                @logger.debug("#{port_name} Connection Refused/Host Unreachable...")
                return false
              end
            end
          rescue Timeout::Error
            @logger.debug("#{port_name} Connection Timeout...")
          end

          return false
        end

        def read_ssh_info(env)
          return nil if env[:machine].id.nil?

          cfg = env[:machine].provider_config
          cnx = cfg.vcloud_cnx.driver
          vapp_id = env[:machine].get_vapp_id
          vm_name = cfg.name ? cfg.name.to_sym : env[:machine].name

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
            @logger.debug(
              'We\'re running in bridged mode, ' \
              'fetching the IP directly from the VM'
            )
            vm_info = cnx.get_vm(env[:machine].id)
            @logger.debug(
              "IP address for #{vm_name}: " \
              "#{vm_info[:networks]['Vagrant-vApp-Net'][:ip]}"
            )

            @external_ip = vm_info[:networks]['Vagrant-vApp-Net'][:ip]
            @external_port = "#{@port}"
          else

            @logger.debug('Getting port forwarding rules...')
            rules = cnx.get_vapp_port_forwarding_rules(vapp_id)

            rules.each do |rule|
              if rule[:vapp_scoped_local_id] == myhash[:vapp_scoped_local_id] && rule[:nat_internal_port] == "#{@port}"
                @external_ip = rule[:nat_external_ip]
                @external_port = rule[:nat_external_port]
                break

              end
            end

            if cfg.vdc_edge_gateway_ip && cfg.vdc_edge_gateway
              @logger.debug(
                "We're running vagrant behind an Organization vDC Edge"
              )

              #
              # Add config.ssh.host support
              # http://docs.vagrantup.com/v2/vagrantfile/ssh_settings.html
              #
              if env[:machine].config.ssh.host
                @logger.debug(
                  'SSH Host setting configured too: ' \
                  "#{env[:machine].config.ssh.host}"
                )
                @external_ip = env[:machine].config.ssh.host
              else
                @logger.debug(
                  "Using Edge Gateway IP: #{cfg.vdc_edge_gateway_ip}"
                )
                @external_ip = cfg.vdc_edge_gateway_ip
              end
            end
          end

          port_name = "SSH"
          if @port == 5985
            port_name = "WinRM"
          end

          @logger.debug(
            "#{port_name} INFO: IP #{@external_ip} and Port #{@external_port}"
          )

          # tsugliani: Temporary Fix for Issue #56
          # SSH unavailable makes the deployment fails.
          # Wait infinitely right now for SSH...
          # sleep_counter incremented by 1s each loop.
          #
          # This should be fixed with implementing Vagrant::Util::Retryable
          # and something like:
          #
          # retryable(:on => Vagrant::Errors::SSHSomething, :tries => 10, :sleep => 5) do
          #   check_for_port(ip, port, "SSH", :error_class => Vagrant::Errors::SSHSomething)
          # end
          #
          sleep_counter = 5

          if @port == 22 || @port == 5985
            while check_for_port(@external_ip, @external_port, port_name) == false
              env[:ui].info(
                "Waiting for #{port_name} Access on #{@external_ip}:#{@external_port} ... "
              )
              sleep sleep_counter
              sleep_counter += 1
            end
          end

          # If we are here, then SSH is ready, continue
          {
            :host => @external_ip,
            :port => @external_port
          }
        end
      end
    end
  end
end
