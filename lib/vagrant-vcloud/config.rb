require 'vagrant'

module VagrantPlugins
  module VCloud
    class Config < Vagrant.plugin('2', :config)
      # login attributes

      # The vCloud Director hostname
      #
      # @return [String]
      attr_accessor :hostname

      # The Organization Name to log in to
      #
      # @return [String]
      attr_accessor :org_name

      # The username used to log in
      #
      # @return [String]
      attr_accessor :username

      # The password used to log in
      #
      # @return [String]
      attr_accessor :password

      # WIP on these

      # Catalog Name where the item resides
      #
      # @return [String]
      attr_accessor :catalog_name

      # Catalog Item to be used as a template
      #
      # @return [String]
      attr_accessor :catalog_item_name

      # Chunksize for upload in bytes (default 1048576 == 1M)
      #
      # @return [Integer]
      attr_accessor :upload_chunksize

      # Virtual Data Center to be used
      #
      # @return [String]
      attr_accessor :vdc_name

      # Virtual Data Center Network to be used
      #
      # @return [String]
      attr_accessor :vdc_network_name

      # Virtual Data Center Network Id to be used
      #
      # @return [String]
      attr_accessor :vdc_network_id

      # IP allocation type
      #
      # @return [String]
      attr_accessor :ip_allocation_type

      # IP subnet
      #
      # @return [String]
      attr_accessor :ip_subnet

      # DNS
      #
      # @return [Array]
      attr_accessor :ip_dns

      # Bridge Mode
      #
      # @return [Bool]
      attr_accessor :network_bridge

      # Port forwarding rules
      #
      # @return [Hash]
      attr_reader :port_forwarding_rules

      # Name of the edge gateway [optional]
      #
      # @return [String]
      attr_accessor :vdc_edge_gateway

      # Public IP of the edge gateway [optional, required if :vdc_edge_gateway
      # is specified]
      #
      # @return [String]
      attr_accessor :vdc_edge_gateway_ip

      # Name of the vApp prefix [optional, defaults to 'Vagrant' ]
      #
      # @return [String]
      attr_accessor :vapp_prefix

      # Name of the VM [optional]
      #
      # @return [String]
      attr_accessor :name

      ##
      ## vCloud Director config runtime values
      ##

      # connection handle
      attr_accessor :vcloud_cnx

      # org object (Hash)
      attr_accessor :org

      # org id (String)
      attr_accessor :org_id

      # vdc object (Hash)
      attr_accessor :vdc

      # vdc id (String)
      attr_accessor :vdc_id

      # catalog object (Hash)
      attr_accessor :catalog

      # catalog id (String)
      attr_accessor :catalog_id

      # catalog item object (Hash)
      attr_accessor :catalog_item

      # vApp Name (String)
      attr_accessor :vAppName

      # vApp Id (String)
      attr_accessor :vAppId

      # VM memory size in MB (Integer)
      attr_accessor :memory

      # VM number of cpus (Integer)
      attr_accessor :cpus

      # NestedHypervisor (Bool)
      attr_accessor :nested_hypervisor

      # Specify a vApp name (String)
      attr_accessor :vapp_name

      # Use advanced networking settings (Bool = false)
      attr_accessor :advanced_network

      # Specify networks to add to the vApp (Hash)
      #   networks: {
      #     org: [ 'Organization VDC network' ],
      #     vapp: [ {
      #               name: 'vApp network',
      #               ip_subnet: '172.16.4.0/255.255.255.0'
      #           } ]
      #   }
      #
      attr_accessor :networks

      # Add hard disks to the VM (Array)
      #   add_hdds: [ 20480 ]
      #
      attr_accessor :add_hdds

      # Update / add network cards to the VM (Array)
      # type is not updated for existing network cards
      #   nics: [ {
      #     type: :vmxnet3,
      #     connected: true,
      #     network: "vApp network",
      #     primary: true,
      #     ip_mode: "static",
      #     ip: "10.10.10.1",
      #     mac: "00:50:56:00:00:01"
      #   } ]
      #
      attr_accessor :nics

      # Power on the VM once created (Bool = true)
      attr_accessor :power_on

      # Attempt to connect via SSH to the VM (Bool = true)
      attr_accessor :ssh_enabled

      # Attempt to sync files to the VM (Bool = true)
      attr_accessor :sync_enabled

      # Turn DHCP on for this network (Bool = false)
      attr_accessor :dhcp_enabled

      # POOL ip range if dhcp is enabled (Array)
      attr_accessor :pool_range

      # DHCP ip range if enabled (Array)
      attr_accessor :dhcp_range

      # Add metadata to the vApp (Array)
      #   metadata_vapp: [
      #     [ 'key', 'value' ]
      #   ]
      #
      attr_accessor :metadata_vapp

      # Add metadata to the VM (Array)
      #   metadata_vapp: [
      #     [ 'key', 'value' ]
      #   ]
      #
      attr_accessor :metadata_vm

      # Auto answer "Yes" to upload the box to vCloud (Bool = false)
      attr_accessor :auto_yes_for_upload

      # ability to disable gc for vms without tools installed
      attr_accessor :enable_guest_customization

      # scripts to run on machine boot
      attr_accessor :guest_customization_script

      # guest customization change sid setting (Windows only) (Bool = false)
      attr_accessor :guest_customization_change_sid

      # guest customization join domain (Windows only) (Bool = false)
      attr_accessor :guest_customization_join_domain

      # guest customization domain name (Windows only) (String)
      attr_accessor :guest_customization_domain_name

      # guest customization domain user name (Windows only) (String)
      attr_accessor :guest_customization_domain_user_name

      # guest customization domain user password (Windows only) (String)
      attr_accessor :guest_customization_domain_user_password

      # guest customization domain machine ou (Windows only) (String)
      attr_accessor :guest_customization_domain_ou

      # guest customization local admin (Bool = false)
      attr_accessor :guest_customization_admin_password_enabled

      # guest customization auto generate admin password (Bool = false)
      attr_accessor :guest_customization_admin_password_auto

      # guest customization specify admin password (String)
      attr_accessor :guest_customization_admin_password

      # guest customization admin auto login (Windows only) (Bool = false)
      attr_accessor :guest_customization_admin_auto_login

      # guest customization admin auto login count (Windows only) (Integer)
      attr_reader :guest_customization_admin_auto_login_count
      def guest_customization_admin_auto_login_count=(count)
        @guest_customization_admin_auto_login_count = count.to_i
      end

      # guest customization admin require password reset (Bool = false)
      attr_accessor :guest_customization_admin_password_reset

      # ovf properties object (Hash)
      attr_accessor :ovf_properties

      def validate(machine)
        errors = _detected_errors

        # TODO: add blank?
        errors << I18n.t('vagrant_vcloud.config.hostname') if hostname.nil?
        errors << I18n.t('vagrant_vcloud.config.org_name') if org_name.nil?
        errors << I18n.t('vagrant_vcloud.config.username') if username.nil?
        errors << I18n.t('vagrant_vcloud.config.password') if password.nil?

        unless ip_dns.nil?
          unless ip_dns.kind_of?(Array)
            errors << I18n.t('vagrant_vcloud.config.ip_dns')
          end
        end

        if catalog_name.nil?
          errors << I18n.t('vagrant_vcloud.config.catalog_name')
        end

        if vdc_name.nil?
          errors << I18n.t('vagrant_vcloud.config.vdc_name')
        end

        if networks.nil? && vdc_network_name.nil?
          errors << I18n.t('vagrant_vcloud.config.vdc_network_name')
        end

        # guest customization
        if enable_guest_customization.nil? ||
           enable_guest_customization == false
          if guest_customization_change_sid == true
            errors << I18n.t('vagrant_vcloud.gc.change_sid')
          end
          if !guest_customization_admin_password_enabled.nil?
            errors << I18n.t('vagrant_vcloud.gc.admin_password')
          end
          if !guest_customization_admin_password_reset.nil?
            errors << I18n.t('vagrant_vcloud.gc.admin_password_reset')
          end
          if !guest_customization_script.nil?
            errors << I18n.t('vagrant_vcloud.gc.script')
          end
        else
          if guest_customization_change_sid.nil? ||
             guest_customization_change_sid == false
            if guest_customization_join_domain == true
              errors << I18n.t('vagrant_vcloud.gc.domain')
            end
          else
            if guest_customization_join_domain == true
              if guest_customization_domain_name.nil? ||
                 guest_customization_domain_user_name.nil? ||
                 guest_customization_domain_user_password.nil?
                errors << I18n.t('vagrant_vcloud.gc.domain_join')
              end
            end
          end
          if guest_customization_admin_password_enabled.nil? ||
             guest_customization_admin_password_enabled == false
            if guest_customization_admin_auto_login == true
              errors << I18n.t('vagrant_vcloud.gc.auto_login')
            end
          else
            if guest_customization_admin_auto_login == true
              if guest_customization_admin_password_auto.nil? ||
                 guest_customization_admin_password_auto == false
                if guest_customization_admin_password.nil? ||
                   guest_customization_admin_password.empty?
                  errors << I18n.t('vagrant_vcloud.gc.admin_password_gs')
                end
              end
              if guest_customization_admin_auto_login_count.nil?
                errors << I18n.t('vagrant_vcloud.gc.auto_login_count_req')
              else
                if !( guest_customization_admin_auto_login_count >= 1 &&
                      guest_customization_admin_auto_login_count <= 100 )
                  errors << I18n.t('vagrant_vcloud.gc.auto_login_count')
                end
              end
            end
          end
        end

        { 'vCloud Provider' => errors }
      end
    end
  end
end
