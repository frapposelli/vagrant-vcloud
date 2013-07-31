require "vagrant"
require "vagrant/action/builder"
require "awesome_print"

module VagrantPlugins
  module VCloud
    module Action
      include Vagrant::Action::Builtin

      # Vagrant commands
      def self.action_destroy
        Vagrant::Action::Builder.new.tap do |b|
          b.use Call, DestroyConfirm do |env, b2|
            if env[:result]
              b2.use ConfigValidate
              b2.use ConnectVCloud
              b2.use PowerOff
              b2.use Destroy
            else
              b2.use MessageWillNotDestroy
            end
          end
        end
      end

      def self.action_provision
        Vagrant::Action::Builder.new.tap do |b|
          b.use ConfigValidate
          b.use Call, IsCreated do |env, b2|
            if !env[:result]
              b2.use MessageNotCreated
              next
            end

            b2.use Provision
            ### TODO --- explore UNISON!
            b2.use SyncFolders
          end
        end
      end

      # This action is called to read the SSH info of the machine. The
      # resulting state is expected to be put into the `:machine_ssh_info`
      # key.
      def self.action_read_ssh_info
        Vagrant::Action::Builder.new.tap do |b|
          b.use ConfigValidate
          b.use ConnectVCloud
          b.use ReadSSHInfo
        end
      end

      # This action is called to read the state of the machine. The
      # resulting state is expected to be put into the `:machine_state_id`
      # key.
      def self.action_read_state
        Vagrant::Action::Builder.new.tap do |b|
          b.use ConfigValidate
          b.use ConnectVCloud
          b.use ReadState
        end
      end

      def self.action_ssh
        Vagrant::Action::Builder.new.tap do |b|
          b.use ConfigValidate
          b.use Call, IsCreated do |env, b2|
            if !env[:result]
              b2.use MessageNotCreated
              next
            end

            b2.use SSHExec
          end
        end
      end

      def self.action_ssh_run
        Vagrant::Action::Builder.new.tap do |b|
          b.use ConfigValidate
          b.use Call, IsCreated do |env, b2|
            if !env[:result]
              b2.use MessageNotCreated
              next
            end

            b2.use SSHRun
          end
        end
      end

      def self.action_up
        Vagrant::Action::Builder.new.tap do |b|
          b.use ConfigValidate
          b.use HandleBoxUrl # TODO: test this
          b.use ConnectVCloud
          b.use CatalogCheck
          b.use CreateVApp
          #b.use ReadState
          b.use Call, IsCreated do |env, b2|
            if env[:result]
              ap "!!!! DUMPING OBJECT !!!!"
              ap env[:machine].provider_config.vcloud_cnx.driver.inspect
              ap "!!!! DUMPING METHODS !!!!"
              ap env[:machine].provider_config.vcloud_cnx.driver.methods
              b2.use MessageAlreadyCreated
              next
            end

            #b2.use Clone
            # TODO: provision
            b2.use TimedProvision
            # TODO: sync folders
            b2.use SyncFolders
          end
          b.use DisconnectVCloud
        end
      end

      # The autoload farm
      action_root = Pathname.new(File.expand_path("../action", __FILE__))
      autoload :ConnectVCloud, action_root.join("connect_vcloud")
      autoload :DisconnectVCloud, action_root.join("disconnect_vcloud")
      autoload :IsCreated, action_root.join("is_created")
      autoload :MessageAlreadyCreated, action_root.join("message_already_created")
      autoload :MessageNotCreated, action_root.join("message_not_created")
      autoload :MessageWillNotDestroy, action_root.join("message_will_not_destroy")
      autoload :ReadSSHInfo, action_root.join("read_ssh_info")
      autoload :CatalogCheck, action_root.join("catalog_check")
      autoload :CreateVApp, action_root.join("create_vapp")
      autoload :ReadState, action_root.join("read_state")
      autoload :RunInstance, action_root.join("run_instance")
      autoload :SyncFolders, action_root.join("sync_folders")
      autoload :TimedProvision, action_root.join("timed_provision")
    end
  end
end

