require "set"

require "log4r"

module VagrantPlugins
  module VCloud
    module Action
      # This middleware class will detect and handle collisions with
      # forwarded ports, whether that means raising an error or repairing
      # them automatically.
      #
      # Parameters it takes from the environment hash:
      #
      #   * `:port_collision_repair` - If true, it will attempt to repair
      #     port collisions. If false, it will raise an exception when
      #     there is a collision.
      #
      #   * `:port_collision_extra_in_use` - An array of ports that are
      #     considered in use.
      #
      #   * `:port_collision_remap` - A hash remapping certain host ports
      #     to other host ports.
      #
      class UnmapPortForwardings


        def initialize(app, env)
          @app    = app
          @logger = Log4r::Logger.new("vagrant_vcloud::action::unmap_port_forwardings")
        end

        def call(env)
          
          cfg = env[:machine].provider_config
          cnx = cfg.vcloud_cnx.driver
          vmName = env[:machine].name
          vAppId = env[:machine].get_vapp_id

          cfg.org = cnx.get_organization_by_name(cfg.org_name)
          cfg.vdc_network_id = cfg.org[:networks][cfg.vdc_network_name]

          @logger.debug("Getting vapp info...")
          vm = cnx.get_vapp(vAppId)
          myhash = vm[:vms_hash][vmName.to_sym]

          @logger.debug("Getting port forwarding rules...")
          rules = cnx.get_vapp_port_forwarding_rules(vAppId)

          newRuleSet = rules.select { |h| !myhash[:vapp_scoped_local_id].include? h[:vapp_scoped_local_id] }

          @logger.debug("OUR NEW RULE SET, PURGED: #{newRuleSet}")

          removePorts = cnx.set_vapp_port_forwarding_rules(
            vAppId,
            "Vagrant-vApp-Net",
            {
              :fence_mode => "natRouted",
              :parent_network => cfg.vdc_network_id,
              :nat_policy_type => "allowTraffic",
              :nat_rules => newRuleSet
            })

          wait = cnx.wait_task_completion(removePorts)

          if !wait[:errormsg].nil?
            raise Errors::ComposeVAppError, :message => wait[:errormsg]
          end


          @app.call(env)
        end
      end
    end
  end
end
