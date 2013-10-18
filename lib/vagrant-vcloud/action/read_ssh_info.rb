require "awesome_print"

module VagrantPlugins
  module VCloud
    module Action
      class ReadSSHInfo

        # FIXME: More work needed here for vCloud logic (vApp, VM IPs, etc.)

        def initialize(app, env)
          @app = app
          @logger = Log4r::Logger.new("vagrant_vcloud::action::read_ssh_info")
        end

        def call(env)
          env[:machine_ssh_info] = read_ssh_info(env)

          @app.call env
        end


        def read_ssh_info(env)
          return nil if env[:machine].id.nil?

          cfg = env[:machine].provider_config
          cnx = cfg.vcloud_cnx.driver
          vmName = env[:machine].name
          vAppId = env[:machine].get_vapp_id

          @logger.debug("Getting vapp info...")
          vm = cnx.get_vapp(vAppId)
          myhash = vm[:vms_hash][vmName.to_sym]

          if vm.nil?
            # The machine can't be found
            @logger.info("Machine couldn't be found, assuming it got destroyed.")
            machine.id = nil
            return nil
          end

          @logger.debug("Getting port forwarding rules...")
          rules = cnx.get_vapp_port_forwarding_rules(vAppId)
          
          rules.each do |rule|
            if rule[:vapp_scoped_local_id] == myhash[:vapp_scoped_local_id] && rule[:nat_internal_port] == "22"              
              @externalIP = rule[:nat_external_ip]
              @externalPort = rule[:nat_external_port]
              break
            end
          end

          if cfg.vdc_edge_gateway_ip && cfg.vdc_edge_gateway
            @logger.debug("We're running vagrant behind an org edge")
            @externalIP = cfg.vdc_edge_gateway_ip
          end

          # FIXME: fix the selfs and create a meaningful info message
          # @logger.debug("Our variables: IP #{@externalIP} and Port #{@externalPort}")

          return {
            # FIXME: these shouldn't be self
              :host => @externalIP,
              :port => @externalPort
          }
        end
      end
    end
  end
end
