require 'set'

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
          @logger = Log4r::Logger.new(
            'vagrant_vcloud::action::unmap_port_forwardings'
          )
        end

        def call(env)
          cfg = env[:machine].provider_config
          cnx = cfg.vcloud_cnx.driver
          vapp_id = env[:machine].get_vapp_id
          vm_name = cfg.name ? cfg.name.to_sym : env[:machine].name

          cfg.org = cnx.get_organization_by_name(cfg.org_name)
          cfg.vdc_network_id = cfg.org[:networks][cfg.vdc_network_name]

          @logger.debug('Getting vApp information...')
          vm = cnx.get_vapp(vapp_id)
          myhash = vm[:vms_hash][vm_name.to_sym]
          @logger.debug('Getting port forwarding rules...')
          rules = cnx.get_vapp_port_forwarding_rules(vapp_id)

          unless myhash.nil?
            # FIXME: not familiar with this syntax (tsugliani)
            new_rule_set = rules.select {
              |h| !myhash[:vapp_scoped_local_id].include? h[:vapp_scoped_local_id]
            }

            @logger.debug("OUR NEW RULE SET, PURGED: #{new_rule_set}")

            remove_ports = cnx.set_vapp_port_forwarding_rules(
              vapp_id,
              'Vagrant-vApp-Net',
              :fence_mode       => 'natRouted',
              :parent_network   => cfg.vdc_network_id,
              :nat_policy_type  => 'allowTraffic',
              :nat_rules        => new_rule_set
            )

            wait = cnx.wait_task_completion(remove_ports)

            unless wait[:errormsg].nil?
              fail Errors::ComposeVAppError, :message => wait[:errormsg]
            end
          end

          @app.call(env)
        end
      end
    end
  end
end
