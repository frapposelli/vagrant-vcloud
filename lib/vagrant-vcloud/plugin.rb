begin
  require 'vagrant'
rescue LoadError
  raise 'The Vagrant vCloud plugin must be run within Vagrant.'
end

if Vagrant::VERSION < '1.2.0'
  fail 'The Vagrant vCloud plugin is only compatible with Vagrant 1.2+'
end

module VagrantPlugins
  module VCloud
    class Plugin < Vagrant.plugin('2')
      name 'VMware vCloud Director Provider'
      description 'Allows Vagrant to manage machines with VMware vCloud
                    Director(R)'

      config(:vcloud, :provider) do
        require_relative 'config'
        Config
      end

      provider(:vcloud) do
        # TODO: add logging
        setup_logging
        setup_i18n

        # Return the provider
        require_relative 'provider'
        Provider
      end

      # Added a vagrant vcloud-status command to enhance troubleshooting and
      # visibility.
      command('vcloud') do
        require_relative 'command'
        Command
      end

      def self.setup_i18n
        I18n.load_path << File.expand_path('locales/en.yml', VCloud.source_root)
        I18n.reload!
      end

      # This sets up our log level to be whatever VAGRANT_LOG is.
      def self.setup_logging
        require 'log4r'

        level = nil
        begin
          level = Log4r.const_get(ENV['VAGRANT_LOG'].upcase)
        rescue NameError
          # This means that the logging constant wasn't found,
          # which is fine. We just keep `level` as `nil`. But
          # we tell the user.
          level = nil
        end

        # Some constants, such as 'true' resolve to booleans, so the
        # above error checking doesn't catch it. This will check to make
        # sure that the log level is an integer, as Log4r requires.
        level = nil unless level.is_a?(Integer)

        # Set the logging level on all 'vagrant' namespaced
        # logs as long as we have a valid level.
        if level
          logger = Log4r::Logger.new('vagrant_vcloud')
          logger.outputters = Log4r::Outputter.stderr
          logger.level = level
          # logger = nil
        end
      end
    end
    module Driver
      autoload :Meta, File.expand_path('../driver/meta', __FILE__)
      autoload :Version_5_1, File.expand_path('../driver/version_5_1', __FILE__)
    end
    module Model
      autoload :ForwardedPort,
               File.expand_path('../model/forwarded_port', __FILE__)
    end

    module Util
      autoload :CompileForwardedPorts,
               File.expand_path('../util/compile_forwarded_ports', __FILE__)
    end
  end
end
