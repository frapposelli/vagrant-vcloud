require "vagrant"

module VagrantPlugins
  module VCloud
    class Config < Vagrant.plugin('2', :config)

      # login attributes

      # The vCloud hostname
      #
      # @return [String]
      attr_accessor :host

      # The Organization Name to log in to
      #
      # @return [String]
      attr_accessor :orgname

      # The username used to log in
      #
      # @return [String]
      attr_accessor :user

      # The password used to log in
      #
      # @return [String]
      attr_accessor :password

      # API version to be used
      #
      # @return [String]
      attr_accessor :api_version

      # WIP on these

      # Catalog Name where the item resides
      #
      # @return [String]
      attr_accessor :catalog_name

      # Catalog Item to be used as a template
      #
      # @return [String]
      attr_accessor :catalog_item
      
      # Virtual Data Center to be used
      #
      # @return [String]
      attr_accessor :vdc_name

      # IP allocation type
      #
      # @return [String]
      attr_accessor :ip_allocation_type

      # IP subnet
      #
      # @return [String]
      attr_accessor :ip_subnet

      # Port forwarding rules
      #
      # @return [Hash]
      attr_reader :port_forwarding_rules

      def initialize
        env[:ui].info "vagrant-vcloud initialize"
      end
      
      def validate(machine)
        errors = _detected_errors

        #TODO: add blank?
        errors << I18n.t('config.host') if host.nil?
        errors << I18n.t('config.orgname') if orgname.nil?
        errors << I18n.t('config.user') if user.nil?
        errors << I18n.t('config.password') if password.nil?

        errors << I18n.t('config.api_version') if api_version.nil?
        
        errors << I18n.t('config.catalog_name') if catalog_name.nil?
        errors << I18n.t('config.catalog_item') if compute_resource_name.nil?
        errors << I18n.t('config.vdc_name') if vdc_name.nil?

        { 'vCloud Provider' => errors }
      end
    end
  end
end
