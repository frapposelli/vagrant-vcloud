require 'pathname'
require 'vagrant-vcloud/plugin'

module VagrantPlugins
  module VCloud
    lib_path = Pathname.new(File.expand_path('../vagrant-vcloud', __FILE__))
    autoload :Action, lib_path.join('action')
    autoload :Errors, lib_path.join('errors')

    # This returns the path to the source of this plugin.
    #
    # @return [Pathname]
    def self.source_root
      @source_root ||= Pathname.new(File.expand_path('../../', __FILE__))
    end
  end
end

module Vagrant
  class Machine
    attr_reader :vappid

    def vappid=(value)
      @logger.info("New vApp ID: #{value.inspect}")

      # The file that will store the id if we have one. This allows the
      # ID to persist across Vagrant runs.

      id_file = @data_dir.join('../../../vcloud_vappid')

      ### this should be ./.vagrant/vcloud_vappid

      if value
        # Write the "id" file with the id given.
        id_file.open('w+') do |f|
          f.write(value)
        end
      else
        # Delete the file, since the machine is now destroyed
        id_file.delete if id_file.file?
      end

      # Store the ID locally
      @vappid = value

      # Notify the provider that the ID changed in case it needs to do
      # any accounting from it.
      # @provider.machine_id_changed
    end

    # This returns the vCloud Director vApp ID.
    #
    # @return [vAppId]
    def get_vapp_id
      vappid_file = @data_dir.join('../../../vcloud_vappid')
      if vappid_file.file?
        @vappid = vappid_file.read
      else
        nil
      end
    end
  end
end
