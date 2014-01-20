require "vagrant"

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

      # Port forwarding rules
      #
      # @return [Hash]
      attr_reader :port_forwarding_rules

      # Name of the edge gateway [optional]
      #
      # @return [String]
      attr_accessor :vdc_edge_gateway

      # Public IP of the edge gateway [optional, required if :vdc_edge_gateway is specified]
      #
      # @return [String]
      attr_accessor :vdc_edge_gateway_ip
     
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

      def validate(machine)
        errors = _detected_errors

        # TODO: add blank?
        errors << I18n.t("vagrant_vcloud.config.hostname") if hostname.nil?
        errors << I18n.t("vagrant_vcloud.config.org_name") if org_name.nil?
        errors << I18n.t("vagrant_vcloud.config.username") if username.nil?
        errors << I18n.t("vagrant_vcloud.config.password") if password.nil?
        
        if !ip_dns.nil?
          errors << I18n.t("vagrant_vcloud.config.ip_dns") if !ip_dns.kind_of?(Array)
        end
        errors << I18n.t("vagrant_vcloud.config.catalog_name") if catalog_name.nil?
        errors << I18n.t("vagrant_vcloud.config.vdc_name") if vdc_name.nil?
        errors << I18n.t("vagrant_vcloud.config.vdc_network_name") if vdc_network_name.nil?

        { "vCloud Provider" => errors }
      end
    end
  end
end
