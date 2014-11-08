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
      attr_accessor :vapp_name
      attr_accessor :networks
      attr_accessor :advanced_network
      attr_accessor :add_hdds
      attr_accessor :nics
      attr_accessor :ssh_enabled
      attr_accessor :sync_enabled
      attr_accessor :power_on

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

        { 'vCloud Provider' => errors }
      end
    end
  end
end
